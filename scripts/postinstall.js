#!/usr/bin/env node
/**
 * postinstall — download the whiteboard companion binary into
 * `~/.whiteboard-agent/companion(.exe)` so that the `wendy` CLI can
 * spawn it on demand.
 *
 * Constraints
 *  - CommonJS only (no ESM, no transpilation step).
 *  - Pure Node.js stdlib (https/fs/path/os/crypto/child_process) — must work
 *    on Node 18+.
 *  - NEVER fail the parent `npm install`: any error is logged to stderr and
 *    we exit 0. The CLI degrades gracefully if the companion is missing
 *    (it just prints a hint and lets the user run `wendy update`).
 *
 * After download, we also auto-start the companion. When the install runs in
 * non-interactive mode (`!process.stdin.isTTY` — typical of an agent running
 * `npm install whiteboard-agent` on the user's behalf) we additionally
 * generate a default username/password pair and persist them to
 * `~/.whiteboard-agent/config.json` so the agent can later expose them via
 * the `get_setup_info` MCP tool. Interactive (human) installs leave the
 * existing onboarding flow untouched.
 *
 * Tunnel mode: we always start a quick tunnel here. Permanent (named) tunnels
 * are configured later by the user via `wendy configure-tunnel`, and only
 * activated on subsequent `wendy start`s — never on first install.
 */
'use strict';

const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { spawn } = require('child_process');

const cloudflared = require('../lib/cloudflared');

const RELEASE_BASE =
  'https://github.com/palmthree-studio/whiteboard-agent/releases/download/nightly';

const COMPANION_LOCAL_URL = 'http://localhost:3001';
const TUNNEL_TIMEOUT_MS = 20000;

function artifactName() {
  const platform = process.platform;
  const arch = process.arch;
  if (platform === 'darwin' && arch === 'arm64') return 'companion-macos-arm64';
  if (platform === 'darwin' && arch === 'x64') return 'companion-macos-x64';
  if (platform === 'linux' && arch === 'x64') return 'companion-linux-x64';
  if (platform === 'win32' && arch === 'x64') return 'companion-windows-x64.exe';
  return null;
}

function targetPath(artifact) {
  const dir = path.join(os.homedir(), '.whiteboard-agent');
  const ext = artifact.endsWith('.exe') ? '.exe' : '';
  return { dir: dir, file: path.join(dir, 'companion' + ext) };
}

function randomHex(bytes) {
  return crypto.randomBytes(bytes).toString('hex');
}

function sha256(input) {
  return crypto.createHash('sha256').update(input).digest('hex');
}

/**
 * Stream-download `url` to `destPath`, following up to 5 redirects. Resolves
 * with the path on success, rejects with an Error on failure. The file is
 * written atomically: we download to `<destPath>.partial` and rename on
 * success.
 */
function download(url, destPath, redirects) {
  if (redirects === undefined) redirects = 0;
  return new Promise(function (resolve, reject) {
    if (redirects > 5) {
      reject(new Error('too many redirects'));
      return;
    }
    const tmpPath = destPath + '.partial';
    const out = fs.createWriteStream(tmpPath);
    const req = https.get(url, function (res) {
      // Handle 3xx redirects (GitHub release downloads typically redirect to
      // an S3 URL with a presigned token).
      if (
        res.statusCode &&
        res.statusCode >= 300 &&
        res.statusCode < 400 &&
        res.headers.location
      ) {
        out.close();
        try {
          fs.unlinkSync(tmpPath);
        } catch (_) {
          /* ignore */
        }
        resolve(download(res.headers.location, destPath, redirects + 1));
        return;
      }
      if (res.statusCode !== 200) {
        out.close();
        try {
          fs.unlinkSync(tmpPath);
        } catch (_) {
          /* ignore */
        }
        reject(new Error('HTTP ' + res.statusCode + ' for ' + url));
        return;
      }
      res.pipe(out);
      out.on('finish', function () {
        out.close(function (err) {
          if (err) {
            reject(err);
            return;
          }
          try {
            fs.renameSync(tmpPath, destPath);
          } catch (renameErr) {
            reject(renameErr);
            return;
          }
          resolve(destPath);
        });
      });
    });
    req.on('error', function (err) {
      out.close();
      try {
        fs.unlinkSync(tmpPath);
      } catch (_) {
        /* ignore */
      }
      reject(err);
    });
  });
}

/**
 * Read `~/.whiteboard-agent/config.json` (or {} on any error).
 */
function readConfig(configPath) {
  try {
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch (_) {
    return {};
  }
}

/**
 * If we're in agentique mode (no TTY) and credentials aren't already set,
 * generate a username/password pair and persist them to `config.json` with
 * mode 0o600 so the agent (and only the agent) can read them later.
 *
 * Returns the (possibly updated) config object.
 */
function ensureAgentCredentials(configPath) {
  const config = readConfig(configPath);
  if (process.stdin.isTTY) {
    return config; // human install — leave onboarding to the UI
  }
  if (config.username) {
    return config; // already provisioned
  }
  config.username = 'admin';
  config.password = randomHex(8); // 16 hex chars, plaintext for the agent
  config.passwordHash = sha256(config.password);
  config.setupMode = 'agent';
  try {
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2), { mode: 0o600 });
  } catch (err) {
    process.stderr.write(
      '[whiteboard-agent] failed to write ' + configPath + ': ' + String(err) + '\n',
    );
  }
  return config;
}

/**
 * Persist the (possibly updated) config back to disk with mode 0600.
 */
function writeConfig(configPath, config) {
  try {
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2), { mode: 0o600 });
  } catch (err) {
    process.stderr.write(
      '[whiteboard-agent] failed to write ' + configPath + ': ' + String(err) + '\n',
    );
  }
}

/**
 * Start a Cloudflare quick tunnel pointing at the companion. Listens to
 * stdout/stderr for the public `*.trycloudflare.com` URL, writes it to
 * `config.publicUrl`, then `unref()`s the child so `npm install` can return
 * even though the tunnel keeps running. Resolves with the URL (or null on
 * timeout / failure). Never throws.
 *
 * Permanent tunnels are not provisioned at install time — they require a
 * licensed user to run `wendy configure-tunnel` after the fact.
 */
function startTunnel(targetUrl, tunnelPidPath) {
  return cloudflared
    .startQuickTunnel(targetUrl, { timeoutMs: TUNNEL_TIMEOUT_MS })
    .then(function (result) {
      if (result.process && typeof result.process.pid === 'number') {
        try {
          fs.writeFileSync(tunnelPidPath, String(result.process.pid), 'utf8');
        } catch (_) {
          /* ignore */
        }
      }
      if (!result.url) {
        process.stderr.write(
          '[whiteboard-agent] cloudflared did not produce a public URL within ' +
            TUNNEL_TIMEOUT_MS / 1000 +
            's — continuing without tunnel.\n',
        );
      }
      return result.url;
    })
    .catch(function (err) {
      process.stderr.write(
        '[whiteboard-agent] failed to spawn cloudflared: ' + String(err) + '\n',
      );
      return null;
    });
}

/**
 * Spawn the companion in the background (fire-and-forget). Forwards
 * COMPANION_USERNAME / COMPANION_PASSWORD_HASH from the config when present
 * so that the companion boots already authenticated. Writes the PID to
 * `companion.pid`. Never throws.
 */
function spawnCompanion(companionPath, config, pidPath) {
  if (!fs.existsSync(companionPath)) return;
  const env = Object.assign({}, process.env);
  if (config && config.username) env['COMPANION_USERNAME'] = config.username;
  if (config && config.passwordHash) {
    env['COMPANION_PASSWORD_HASH'] = config.passwordHash;
  }
  try {
    const child = spawn(companionPath, [], {
      detached: true,
      stdio: 'ignore',
      env: env,
    });
    if (typeof child.pid === 'number') {
      try {
        fs.writeFileSync(pidPath, String(child.pid));
      } catch (_) {
        /* ignore PID file errors */
      }
      process.stderr.write(
        '[whiteboard-agent] companion started (pid ' + child.pid + ')\n',
      );
    }
    child.unref();
  } catch (err) {
    process.stderr.write(
      '[whiteboard-agent] failed to spawn companion: ' + String(err) + '\n',
    );
  }
}

(function main() {
  const artifact = artifactName();
  if (!artifact) {
    process.stderr.write(
      '[whiteboard-agent] platform ' +
        process.platform +
        '/' +
        process.arch +
        ' is not supported — skipping companion download.\n',
    );
    process.exit(0);
    return;
  }

  const target = targetPath(artifact);
  try {
    fs.mkdirSync(target.dir, { recursive: true });
  } catch (err) {
    process.stderr.write(
      '[whiteboard-agent] failed to create ' + target.dir + ': ' + String(err) + '\n',
    );
    process.exit(0);
    return;
  }

  const configPath = path.join(target.dir, 'config.json');
  const pidPath = path.join(target.dir, 'companion.pid');
  const tunnelPidPath = path.join(target.dir, 'tunnel.pid');

  function finalize() {
    const config = ensureAgentCredentials(configPath);
    spawnCompanion(target.file, config, pidPath);
    // Only spin up a Cloudflare tunnel for agentique installs — interactive
    // installs (TTY) keep the existing behaviour, the user runs `wendy start`
    // when they're ready. We block npm install for up to ~20s while the
    // tunnel announces its URL; this is acceptable for agent-driven installs
    // where the agent needs the public URL immediately via get_setup_info.
    if (!process.stdin.isTTY) {
      process.stdout.write(
        '[whiteboard-agent] starting Cloudflare tunnel, this may take ~10s...\n',
      );
      startTunnel(COMPANION_LOCAL_URL, tunnelPidPath)
        .then(function (publicUrl) {
          if (publicUrl) {
            const cfg = readConfig(configPath);
            cfg.publicUrl = publicUrl;
            writeConfig(configPath, cfg);
            process.stdout.write(
              '[whiteboard-agent] public URL: ' + publicUrl + '\n',
            );
          } else {
            process.stderr.write(
              '[whiteboard-agent] tunnel unavailable — companion is reachable only on ' +
                COMPANION_LOCAL_URL +
                '.\n',
            );
          }
          process.exit(0);
        })
        .catch(function (err) {
          process.stderr.write(
            '[whiteboard-agent] tunnel error: ' + String(err) + '\n',
          );
          process.exit(0);
        });
      return;
    }
    process.exit(0);
  }

  const url = RELEASE_BASE + '/' + artifact;
  download(url, target.file)
    .then(function () {
      // Make it executable on Unix-like systems.
      if (process.platform !== 'win32') {
        try {
          fs.chmodSync(target.file, 0o755);
        } catch (chmodErr) {
          process.stderr.write(
            '[whiteboard-agent] chmod failed on ' +
              target.file +
              ': ' +
              String(chmodErr) +
              '\n',
          );
        }
      }
      process.stdout.write(
        '[whiteboard-agent] companion installed at ' + target.file + '\n',
      );
      finalize();
    })
    .catch(function (err) {
      process.stderr.write(
        '[whiteboard-agent] companion download failed (' +
          String(err) +
          ') — run `wendy update` later or download the binary manually.\n',
      );
      // Even if download failed, an existing binary may still be usable —
      // try to start it. spawnCompanion is a no-op if the file is missing.
      finalize();
    });
})();
