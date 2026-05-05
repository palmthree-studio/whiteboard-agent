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
 * After download, we also auto-start the companion + tunnel by spawning
 * `wendy start` as a detached background process. This is the correct
 * architecture: `wendy start` is designed as a long-running daemon that owns
 * the tunnel lifecycle (it blocks on `waitForProcess` so the cloudflared pipe
 * never closes). Spawning cloudflared directly from postinstall caused it to
 * die the moment postinstall called `process.exit(0)` (SIGPIPE on closed pipe).
 *
 * For agent-mode installs (!process.stdin.isTTY) we additionally generate a
 * default username/password pair and persist them to config.json so the agent
 * can read them via the `get_setup_info` MCP tool. Interactive (human) installs
 * leave the existing onboarding flow untouched.
 *
 * Permanent (named) tunnels are configured later by the user via
 * `wendy configure-tunnel` — never provisioned at install time.
 */
'use strict';

const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { spawn } = require('child_process');

const RELEASE_BASE =
  'https://github.com/palmthree-studio/whiteboard-agent/releases/download/nightly';

// How long to wait (ms) for `wendy start` to get a public URL.
// Budget: ~5s companion startup + ~20s cloudflared announcement + margin.
const WENDY_START_TIMEOUT_MS = 35000;

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
 * Persist `config` to `configPath` with mode 0600.
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
  config.passwordChanged = false;
  writeConfig(configPath, config);
  return config;
}

/**
 * Poll `configPath` every 500 ms until `publicUrl` appears in the JSON or
 * `maxWaitMs` elapses. Resolves with the URL string, or `null` on timeout.
 *
 * `wendy start` writes `publicUrl` to config.json as soon as cloudflared
 * announces the tunnel — we rely on that contract here.
 */
function pollForPublicUrl(configPath, maxWaitMs) {
  return new Promise(function (resolve) {
    const deadline = Date.now() + maxWaitMs;
    function tick() {
      try {
        const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        if (typeof cfg.publicUrl === 'string' && cfg.publicUrl.length > 0) {
          resolve(cfg.publicUrl);
          return;
        }
      } catch (_) {
        /* config not yet written — keep polling */
      }
      if (Date.now() >= deadline) {
        resolve(null);
        return;
      }
      setTimeout(tick, 500);
    }
    tick();
  });
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

  function finalize() {
    // Ensure credentials exist for agentique installs.
    ensureAgentCredentials(configPath);

    if (!process.stdin.isTTY) {
      // Agent install: delegate companion + tunnel lifecycle to `wendy start`.
      //
      // Why not spawn companion + cloudflared directly here?
      // Because startQuickTunnel (lib/cloudflared.js) spawns cloudflared with
      // stdio pipes open on the parent. When postinstall exits, the pipe
      // read-end closes → SIGPIPE → cloudflared dies immediately.
      //
      // `wendy start` is designed to be a long-running daemon. It stays alive
      // via waitForProcess(cloudflaredProcess), keeping the pipe open and the
      // tunnel alive indefinitely.
      //
      // We spawn `wendy start` detached + stdio:ignore so it survives after
      // npm install completes, then we poll config.json for publicUrl (which
      // wendy start writes as soon as the tunnel URL is known).

      // Clear any stale publicUrl so pollForPublicUrl doesn't return an old value.
      const cfg = readConfig(configPath);
      if (cfg.publicUrl) {
        delete cfg.publicUrl;
        writeConfig(configPath, cfg);
      }

      const wendyCli = path.join(__dirname, '..', 'bin', 'cli.js');
      process.stdout.write(
        '[whiteboard-agent] starting companion and tunnel via wendy start...\n',
      );

      let wendyChild;
      try {
        wendyChild = spawn(process.execPath, [wendyCli, 'start'], {
          detached: true,
          stdio: 'ignore',
        });
        wendyChild.unref();
      } catch (err) {
        process.stderr.write(
          '[whiteboard-agent] failed to spawn wendy start: ' + String(err) + '\n',
        );
        process.exit(0);
        return;
      }

      process.stdout.write(
        '[whiteboard-agent] waiting for tunnel (up to ' +
          WENDY_START_TIMEOUT_MS / 1000 +
          's)...\n',
      );

      pollForPublicUrl(configPath, WENDY_START_TIMEOUT_MS).then(function (publicUrl) {
        if (publicUrl) {
          process.stdout.write('[whiteboard-agent] public URL: ' + publicUrl + '\n');
        } else {
          process.stderr.write(
            '[whiteboard-agent] tunnel did not come up within ' +
              WENDY_START_TIMEOUT_MS / 1000 +
              's — run `wendy status` to check.\n',
          );
        }
        process.exit(0);
      });
      return;
    }

    // Interactive (human) install — just exit; user runs `wendy start` manually.
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
      // finalize still sets up credentials and starts wendy start.
      finalize();
    });
})();
