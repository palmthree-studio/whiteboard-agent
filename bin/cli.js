#!/usr/bin/env node
/**
 * wendy — companion CLI for Whiteboard.
 *
 * Commands
 *  - wendy start                  Start the companion in the background (if not already running).
 *  - wendy stop                   Stop the companion (PID file or SIGTERM).
 *  - wendy status                 Show whether the companion is running, the public URL, and the licence status.
 *  - wendy activate <licence>     Register a LemonSqueezy licence key with the running companion.
 *  - wendy deactivate             Release the licence key registered with the companion.
 *  - wendy update                 Download the latest companion binary for this platform.
 *  - wendy configure-tunnel       Bind a Cloudflare named tunnel (PRO).
 *  - wendy help                   Show this list.
 *
 * Constraints
 *  - CommonJS only, Node.js stdlib only (no third-party deps beyond optional cloudflared).
 *  - Must work on Node 18+ on macOS, Linux and Windows.
 */
'use strict';

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn } = require('child_process');

const cloudflared = require('../lib/cloudflared');

const COMPANION_HOST = '127.0.0.1';
const COMPANION_PORT = 3001;
const COMPANION_URL = 'http://localhost:' + COMPANION_PORT;
const HEALTH_PATH = '/health';
const RELEASE_BASE =
  'https://github.com/palmthree-studio/whiteboard/releases/latest/download';

const AGENT_DIR = path.join(os.homedir(), '.whiteboard-agent');
const PID_FILE = path.join(AGENT_DIR, 'companion.pid');
const TUNNEL_PID_FILE = path.join(AGENT_DIR, 'tunnel.pid');
const CONFIG_FILE = path.join(AGENT_DIR, 'config.json');
const TUNNEL_TIMEOUT_MS = 20000;
const URL_PROBE_TIMEOUT_MS = 5000;

function artifactName() {
  const platform = process.platform;
  const arch = process.arch;
  if (platform === 'darwin' && arch === 'arm64') return 'companion-macos-arm64';
  if (platform === 'darwin' && arch === 'x64') return 'companion-macos-x64';
  if (platform === 'linux' && arch === 'x64') return 'companion-linux-x64';
  if (platform === 'win32' && arch === 'x64') return 'companion-windows-x64.exe';
  return null;
}

function companionBinaryPath() {
  const ext = process.platform === 'win32' ? '.exe' : '';
  return path.join(AGENT_DIR, 'companion' + ext);
}

/**
 * GET /health on the companion. Resolves with `{ ok: true, body: <json|null> }`
 * if reachable, `{ ok: false }` otherwise.
 */
function checkHealth(timeoutMs) {
  if (timeoutMs === undefined) timeoutMs = 1000;
  return new Promise(function (resolve) {
    const req = http.request(
      {
        host: COMPANION_HOST,
        port: COMPANION_PORT,
        path: HEALTH_PATH,
        method: 'GET',
        timeout: timeoutMs,
      },
      function (res) {
        let data = '';
        res.on('data', function (chunk) {
          data += chunk;
        });
        res.on('end', function () {
          if (res.statusCode === 200) {
            let body = null;
            try {
              body = JSON.parse(data);
            } catch (_) {
              body = null;
            }
            resolve({ ok: true, body: body });
          } else {
            resolve({ ok: false });
          }
        });
      },
    );
    req.on('error', function () {
      resolve({ ok: false });
    });
    req.on('timeout', function () {
      req.destroy();
      resolve({ ok: false });
    });
    req.end();
  });
}

/**
 * Generic localhost HTTP request helper for the companion API. Resolves with
 * `{ statusCode, body }` where `body` is the parsed JSON response (or `null`
 * when the response is empty / not JSON). Rejects with an Error tagged with
 * `code = 'COMPANION_DOWN'` when the companion is unreachable, so callers can
 * print a friendly message without leaking node error noise.
 */
function httpRequest(options, body) {
  return new Promise(function (resolve, reject) {
    const reqOptions = Object.assign(
      {
        host: COMPANION_HOST,
        port: COMPANION_PORT,
        timeout: 5000,
      },
      options || {},
    );
    const headers = Object.assign({ Accept: 'application/json' }, reqOptions.headers || {});
    let payload = null;
    if (body !== undefined && body !== null) {
      payload = Buffer.from(JSON.stringify(body), 'utf8');
      headers['Content-Type'] = 'application/json';
      headers['Content-Length'] = String(payload.length);
    }
    reqOptions.headers = headers;

    const req = http.request(reqOptions, function (res) {
      let data = '';
      res.setEncoding('utf8');
      res.on('data', function (chunk) {
        data += chunk;
      });
      res.on('end', function () {
        let parsed = null;
        if (data.length > 0) {
          try {
            parsed = JSON.parse(data);
          } catch (_) {
            parsed = null;
          }
        }
        resolve({ statusCode: res.statusCode || 0, body: parsed });
      });
    });
    req.on('error', function (err) {
      const wrapped = new Error('companion request failed: ' + String(err));
      // Map ECONNREFUSED / ENOTFOUND etc. to a friendlier marker for callers.
      if (err && (err.code === 'ECONNREFUSED' || err.code === 'ENOTFOUND')) {
        wrapped.code = 'COMPANION_DOWN';
      }
      reject(wrapped);
    });
    req.on('timeout', function () {
      req.destroy();
      const err = new Error('companion request timed out');
      err.code = 'COMPANION_DOWN';
      reject(err);
    });
    if (payload) req.write(payload);
    req.end();
  });
}

/**
 * Probe an arbitrary URL (HTTP or HTTPS) with a short timeout. Resolves with
 * `true` on any 2xx/3xx response (the URL is "reachable"), `false` otherwise.
 * Used by `wendy configure-tunnel` as a sanity check before persisting.
 */
function probeUrl(url, timeoutMs) {
  if (timeoutMs === undefined) timeoutMs = URL_PROBE_TIMEOUT_MS;
  return new Promise(function (resolve) {
    let parsed;
    try {
      parsed = new URL(url);
    } catch (_) {
      resolve(false);
      return;
    }
    const lib = parsed.protocol === 'http:' ? http : https;
    const req = lib.request(
      {
        method: 'GET',
        hostname: parsed.hostname,
        port: parsed.port || (parsed.protocol === 'http:' ? 80 : 443),
        path: parsed.pathname + (parsed.search || ''),
        timeout: timeoutMs,
      },
      function (res) {
        const status = res.statusCode || 0;
        // Drain so the socket is freed.
        res.on('data', function () {});
        res.on('end', function () {
          resolve(status >= 200 && status < 400);
        });
      },
    );
    req.on('error', function () {
      resolve(false);
    });
    req.on('timeout', function () {
      req.destroy();
      resolve(false);
    });
    req.end();
  });
}

function sleep(ms) {
  return new Promise(function (resolve) {
    setTimeout(resolve, ms);
  });
}

function readPidFile() {
  try {
    const raw = fs.readFileSync(PID_FILE, 'utf8').trim();
    const pid = parseInt(raw, 10);
    if (!Number.isFinite(pid) || pid <= 0) return null;
    return pid;
  } catch (_) {
    return null;
  }
}

function writePidFile(pid) {
  try {
    fs.mkdirSync(AGENT_DIR, { recursive: true });
    fs.writeFileSync(PID_FILE, String(pid), 'utf8');
  } catch (err) {
    process.stderr.write(
      '[wendy] failed to write PID file ' + PID_FILE + ': ' + String(err) + '\n',
    );
  }
}

function clearPidFile() {
  try {
    fs.unlinkSync(PID_FILE);
  } catch (_) {
    /* ignore */
  }
}

function isProcessAlive(pid) {
  try {
    process.kill(pid, 0);
    return true;
  } catch (_) {
    return false;
  }
}

function readConfig() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  } catch (_) {
    return {};
  }
}

function writeConfig(cfg) {
  try {
    fs.mkdirSync(AGENT_DIR, { recursive: true });
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(cfg, null, 2), { mode: 0o600 });
  } catch (err) {
    process.stderr.write(
      '[wendy] failed to write config ' + CONFIG_FILE + ': ' + String(err) + '\n',
    );
  }
}

function writeTunnelPid(pid) {
  if (typeof pid !== 'number') return;
  try {
    fs.mkdirSync(AGENT_DIR, { recursive: true });
    fs.writeFileSync(TUNNEL_PID_FILE, String(pid), 'utf8');
  } catch (_) {
    /* ignore PID file errors */
  }
}

/**
 * Spawn a Cloudflare quick tunnel pointing at the local companion. Resolves
 * with the public `https://<id>.trycloudflare.com` URL once cloudflared
 * announces it (within TUNNEL_TIMEOUT_MS); resolves with `null` on timeout
 * or failure (degraded mode — companion still reachable on localhost).
 */
async function startQuickTunnel(targetUrl) {
  try {
    const result = await cloudflared.startQuickTunnel(targetUrl, {
      timeoutMs: TUNNEL_TIMEOUT_MS,
    });
    writeTunnelPid(result.process && result.process.pid);
    if (!result.url) {
      process.stderr.write(
        '[wendy] cloudflared did not produce a public URL within ' +
          TUNNEL_TIMEOUT_MS / 1000 +
          's — continuing without tunnel.\n',
      );
    }
    return result.url;
  } catch (err) {
    process.stderr.write(
      '[wendy] failed to spawn cloudflared: ' + String(err) + '\n',
    );
    return null;
  }
}

/**
 * Spawn a Cloudflare named tunnel. The public URL is configured server-side
 * via the Cloudflare dashboard (we just read it back from `cfg.publicUrl`).
 * Returns true on successful spawn, false otherwise.
 */
async function startNamedTunnel(token) {
  try {
    const result = await cloudflared.startNamedTunnel(token, {
      onLog: function (line) {
        // Surface cloudflared chatter to stderr so connection failures are
        // visible to the user without swamping stdout.
        process.stderr.write('[cloudflared] ' + line + '\n');
      },
    });
    writeTunnelPid(result.process && result.process.pid);
    return true;
  } catch (err) {
    process.stderr.write(
      '[wendy] failed to spawn cloudflared (named tunnel): ' + String(err) + '\n',
    );
    return false;
  }
}

// ── start ────────────────────────────────────────────────────────────────────
async function cmdStart() {
  const initial = await checkHealth();
  if (initial.ok) {
    process.stdout.write('Companion already running at ' + COMPANION_URL + '\n');
    // Companion is running — check if a tunnel is already active.
    const cfg = readConfig();
    if (cfg.publicUrl) {
      process.stdout.write('Public URL: ' + cfg.publicUrl + '\n');
      return 0;
    }
    // Companion running but no tunnel active (e.g. stale process from a dev
    // session). Start just the tunnel so the agent gets a shareable URL.
    if (cfg.urlType === 'permanent' && cfg.tunnelToken) {
      process.stdout.write('Starting Cloudflare named tunnel...\n');
      const ok = await startNamedTunnel(cfg.tunnelToken);
      if (ok && cfg.publicUrl) {
        process.stdout.write('Public URL: ' + cfg.publicUrl + '\n');
      } else if (!ok) {
        process.stderr.write(
          '[wendy] named tunnel unavailable — companion reachable only on ' +
            COMPANION_URL +
            '.\n',
        );
      }
      return 0;
    }
    process.stdout.write('Starting Cloudflare tunnel, this may take ~10s...\n');
    const publicUrl = await startQuickTunnel(COMPANION_URL);
    if (publicUrl) {
      cfg.publicUrl = publicUrl;
      writeConfig(cfg);
      process.stdout.write('Public URL: ' + publicUrl + '\n');
    } else {
      process.stderr.write(
        '[wendy] tunnel unavailable — companion reachable only on ' +
          COMPANION_URL +
          '.\n',
      );
    }
    return 0;
  }

  const binary = companionBinaryPath();
  if (!fs.existsSync(binary)) {
    process.stderr.write(
      'Companion not installed. Run: npm i -g whiteboard-agent\n',
    );
    return 1;
  }

  // Load auth credentials persisted by the postinstall script (agentique
  // installs auto-generate them) so that the companion boots with the same
  // username/password the agent expects.
  const savedConfig = readConfig();
  const env = Object.assign({}, process.env);
  if (savedConfig.username) env['COMPANION_USERNAME'] = savedConfig.username;
  if (savedConfig.passwordHash) {
    env['COMPANION_PASSWORD_HASH'] = savedConfig.passwordHash;
  }

  let child;
  try {
    child = spawn(binary, [], { detached: true, stdio: 'ignore', env: env });
  } catch (err) {
    process.stderr.write(
      '[wendy] failed to spawn companion: ' + String(err) + '\n',
    );
    return 1;
  }
  if (typeof child.pid === 'number') {
    writePidFile(child.pid);
  }
  child.unref();

  // Poll /health for up to 5s (200ms interval).
  const maxAttempts = 25;
  let healthy = false;
  for (let i = 0; i < maxAttempts; i++) {
    await sleep(200);
    const probe = await checkHealth();
    if (probe.ok) {
      healthy = true;
      break;
    }
  }

  if (!healthy) {
    process.stderr.write(
      '[wendy] companion did not become ready within 5s — check ' +
        AGENT_DIR +
        ' and try `wendy status`.\n',
    );
    return 1;
  }

  process.stdout.write('Companion started at ' + COMPANION_URL + '\n');

  // Decide tunnel mode from the persisted config:
  //  - urlType === 'permanent' + tunnelToken → start a named tunnel (URL is
  //    fixed, no parsing). The local JWT is trusted (PRO licence verified
  //    when the user ran `wendy configure-tunnel`); we don't re-check on
  //    every start.
  //  - otherwise → start a Cloudflare quick tunnel (`*.trycloudflare.com`).
  if (savedConfig.urlType === 'permanent' && savedConfig.tunnelToken) {
    process.stdout.write('Starting Cloudflare named tunnel...\n');
    const ok = await startNamedTunnel(savedConfig.tunnelToken);
    if (ok) {
      const publicUrl = savedConfig.publicUrl || '';
      if (publicUrl) {
        process.stdout.write('Public URL: ' + publicUrl + '\n');
      } else {
        process.stdout.write(
          'Named tunnel started — public URL not configured locally; check the Cloudflare dashboard.\n',
        );
      }
    } else {
      process.stderr.write(
        '[wendy] named tunnel unavailable — companion is reachable only on ' +
          COMPANION_URL +
          '.\n',
      );
    }
    return 0;
  }

  // Quick tunnel (default).
  process.stdout.write(
    'Starting Cloudflare tunnel, this may take ~10s...\n',
  );
  const publicUrl = await startQuickTunnel(COMPANION_URL);
  if (publicUrl) {
    const cfg = readConfig();
    cfg.publicUrl = publicUrl;
    writeConfig(cfg);
    process.stdout.write('Public URL: ' + publicUrl + '\n');
  } else {
    process.stderr.write(
      '[wendy] tunnel unavailable — companion is reachable only on ' +
        COMPANION_URL +
        '.\n',
    );
  }

  return 0;
}

function stopTunnel() {
  let stopped = false;
  try {
    if (!fs.existsSync(TUNNEL_PID_FILE)) return false;
    const raw = fs.readFileSync(TUNNEL_PID_FILE, 'utf8').trim();
    const pid = parseInt(raw, 10);
    if (Number.isFinite(pid) && pid > 0) {
      try {
        process.kill(pid, 'SIGTERM');
        stopped = true;
      } catch (_) {
        /* process already gone */
      }
    }
  } catch (_) {
    /* ignore */
  }
  try {
    fs.unlinkSync(TUNNEL_PID_FILE);
  } catch (_) {
    /* ignore */
  }
  // Clear the cached publicUrl so consumers don't show a dead URL — but only
  // for quick tunnels. Permanent URLs survive across restarts and must stay
  // in config so that a fresh `wendy start` re-binds to the same domain.
  try {
    const cfg = readConfig();
    if (cfg.urlType !== 'permanent' && cfg.publicUrl) {
      delete cfg.publicUrl;
      writeConfig(cfg);
    }
  } catch (_) {
    /* ignore */
  }
  return stopped;
}

// ── stop ─────────────────────────────────────────────────────────────────────
async function cmdStop() {
  const initial = await checkHealth();
  if (!initial.ok) {
    process.stdout.write('Companion is not running\n');
    clearPidFile();
    stopTunnel();
    return 0;
  }

  const pid = readPidFile();
  if (pid && isProcessAlive(pid)) {
    try {
      process.kill(pid, 'SIGTERM');
    } catch (err) {
      process.stderr.write(
        '[wendy] failed to send SIGTERM to PID ' + pid + ': ' + String(err) + '\n',
      );
      return 1;
    }
    // Wait up to 5s for the process to exit and /health to go silent.
    for (let i = 0; i < 25; i++) {
      await sleep(200);
      const probe = await checkHealth();
      if (!probe.ok && !isProcessAlive(pid)) {
        clearPidFile();
        stopTunnel();
        process.stdout.write('Companion stopped\n');
        return 0;
      }
    }
    process.stderr.write(
      '[wendy] companion did not exit within 5s — you may need to kill PID ' +
        pid +
        ' manually.\n',
    );
    return 1;
  }

  // No PID file (or stale) but /health responded. Tell the user where to look.
  process.stderr.write(
    '[wendy] companion appears to be running but no PID file is recorded at ' +
      PID_FILE +
      '. It may have been started outside of `wendy start` — stop it manually.\n',
  );
  return 1;
}

// ── status ───────────────────────────────────────────────────────────────────
async function cmdStatus() {
  const probe = await checkHealth();
  if (!probe.ok) {
    process.stdout.write('Not running\n');
    return 0;
  }
  let version = 'unknown';
  if (probe.body && typeof probe.body.version === 'string') {
    version = probe.body.version;
  }
  process.stdout.write(
    'Running at ' + COMPANION_URL + ' (version ' + version + ')\n',
  );
  const cfg = readConfig();
  if (typeof cfg.publicUrl === 'string' && cfg.publicUrl.length > 0) {
    const suffix = cfg.urlType === 'permanent' ? ' (permanent)' : '';
    process.stdout.write('Public URL: ' + cfg.publicUrl + suffix + '\n');
  }

  // Licence status — best-effort. If the call fails, stay silent: the
  // companion just answered /health, so the licence line is informational.
  try {
    const res = await httpRequest({ method: 'GET', path: '/api/license/status' });
    if (res.statusCode === 200 && res.body && typeof res.body.status === 'string') {
      const status = res.body.status;
      if (status === 'active' || status === 'bypass') {
        const email = typeof res.body.email === 'string' ? res.body.email : '';
        if (email) {
          process.stdout.write('Licence : active (' + email + ')\n');
        } else {
          process.stdout.write('Licence : active\n');
        }
      } else if (status === 'expired') {
        process.stdout.write('Licence : expirée\n');
      } else {
        process.stdout.write('Licence : inactive\n');
      }
    }
  } catch (_) {
    /* best-effort — already printed companion status */
  }
  return 0;
}

// ── activate ─────────────────────────────────────────────────────────────────
async function cmdActivate(args) {
  const licenseKey = (args && args[0] ? String(args[0]) : '').trim();
  if (!licenseKey) {
    process.stderr.write('Usage: wendy activate <licence-key>\n');
    return 1;
  }
  let res;
  try {
    res = await httpRequest(
      { method: 'POST', path: '/api/license/activate' },
      { licenseKey: licenseKey },
    );
  } catch (err) {
    if (err && err.code === 'COMPANION_DOWN') {
      process.stderr.write(
        "Le companion n'est pas démarré. Lance `wendy start` d'abord.\n",
      );
      return 1;
    }
    process.stderr.write('Erreur: ' + (err && err.message ? err.message : String(err)) + '\n');
    return 1;
  }

  const status = res && res.body && typeof res.body.status === 'string' ? res.body.status : '';

  if (res.statusCode === 200 && (status === 'active' || status === 'bypass')) {
    const email = res.body && typeof res.body.email === 'string' ? res.body.email : '';
    if (email) {
      process.stdout.write('Licence activée — ' + email + '\n');
    } else {
      process.stdout.write('Licence activée\n');
    }
    return 0;
  }
  if (res.statusCode === 409 || (res.statusCode === 200 && status === 'active')) {
    process.stdout.write(
      "Licence déjà active. Contactez hello@palmthree.studio si quelque chose n'est pas normal.\n",
    );
    return 0;
  }
  if (res.statusCode === 400 || res.statusCode === 422) {
    process.stderr.write('Clé de licence invalide.\n');
    return 1;
  }
  const detail = res && res.body && typeof res.body.detail === 'string' ? res.body.detail : '';
  process.stderr.write(
    "Échec de l'activation (HTTP " +
      res.statusCode +
      ')' +
      (detail ? ' — ' + detail : '') +
      '\n',
  );
  return 1;
}

// ── deactivate ───────────────────────────────────────────────────────────────
async function cmdDeactivate() {
  let res;
  try {
    res = await httpRequest({ method: 'POST', path: '/api/license/deactivate' }, {});
  } catch (err) {
    if (err && err.code === 'COMPANION_DOWN') {
      process.stderr.write(
        "Le companion n'est pas démarré. Lance `wendy start` d'abord.\n",
      );
      return 1;
    }
    process.stderr.write('Erreur: ' + (err && err.message ? err.message : String(err)) + '\n');
    return 1;
  }
  if (res.statusCode === 200) {
    process.stdout.write('Licence désactivée.\n');
    return 0;
  }
  const detail = res && res.body && typeof res.body.detail === 'string' ? res.body.detail : '';
  process.stderr.write(
    'Échec de la désactivation (HTTP ' +
      res.statusCode +
      ')' +
      (detail ? ' — ' + detail : '') +
      '\n',
  );
  return 1;
}

// ── update ───────────────────────────────────────────────────────────────────
function downloadFile(url, destPath, redirects) {
  if (redirects === undefined) redirects = 0;
  return new Promise(function (resolve, reject) {
    if (redirects > 5) {
      reject(new Error('too many redirects'));
      return;
    }
    const tmpPath = destPath + '.partial';
    const out = fs.createWriteStream(tmpPath);
    const req = https.get(url, function (res) {
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
        resolve(downloadFile(res.headers.location, destPath, redirects + 1));
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

async function cmdUpdate() {
  const artifact = artifactName();
  if (!artifact) {
    process.stderr.write(
      '[wendy] platform ' +
        process.platform +
        '/' +
        process.arch +
        ' is not supported.\n',
    );
    return 1;
  }

  process.stdout.write('Checking for updates...\n');
  process.stdout.write('Downloading ' + artifact + '...\n');

  const target = companionBinaryPath();
  try {
    fs.mkdirSync(AGENT_DIR, { recursive: true });
  } catch (err) {
    process.stderr.write(
      '[wendy] failed to create ' + AGENT_DIR + ': ' + String(err) + '\n',
    );
    return 1;
  }

  const url = RELEASE_BASE + '/' + artifact;
  try {
    await downloadFile(url, target);
  } catch (err) {
    process.stderr.write('[wendy] download failed: ' + String(err) + '\n');
    return 1;
  }

  if (process.platform !== 'win32') {
    try {
      fs.chmodSync(target, 0o755);
    } catch (chmodErr) {
      process.stderr.write(
        '[wendy] chmod failed on ' + target + ': ' + String(chmodErr) + '\n',
      );
    }
  }

  process.stdout.write('Updated to latest version\n');
  process.stdout.write('Binary: ' + target + '\n');
  return 0;
}

// ── configure-tunnel (PRO) ───────────────────────────────────────────────────
/**
 * Parse `wendy configure-tunnel --token <jwt> --url <url>` from argv. Accepts
 * both `--key value` and `--key=value` forms.
 */
function parseConfigureTunnelArgs(argv) {
  const out = { token: '', url: '' };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--token' && i + 1 < argv.length) {
      out.token = argv[i + 1];
      i++;
    } else if (a.startsWith('--token=')) {
      out.token = a.slice('--token='.length);
    } else if (a === '--url' && i + 1 < argv.length) {
      out.url = argv[i + 1];
      i++;
    } else if (a.startsWith('--url=')) {
      out.url = a.slice('--url='.length);
    }
  }
  return out;
}

async function cmdConfigureTunnel(argv) {
  const args = parseConfigureTunnelArgs(argv);
  if (!args.token || !args.url) {
    process.stderr.write(
      'Usage: wendy configure-tunnel --token <tunnel-token> --url <public-url>\n',
    );
    return 1;
  }

  // 1. Companion must be running so we can verify the licence.
  const health = await checkHealth();
  if (!health.ok) {
    process.stderr.write(
      'Companion is not running. Start it first: `wendy start`.\n',
    );
    return 1;
  }

  // 2. Licence gate. PRO-only feature.
  const licenseResp = await httpRequest({ method: 'GET', path: '/api/license/status' }).catch(() => null);
  const license = licenseResp ? licenseResp.body : null;
  const status = license && typeof license.status === 'string' ? license.status : '';
  const isActive = status === 'active' || status === 'bypass';
  if (!isActive) {
    process.stderr.write(
      'Cette fonctionnalité nécessite une licence PRO. https://whiteboard-agent.com/pro\n',
    );
    return 1;
  }

  // 3. Sanity-check the URL — warn but never block.
  const reachable = await probeUrl(args.url);
  if (!reachable) {
    process.stderr.write(
      "Attention : l'URL n'est pas joignable. Vérifiez que le tunnel Cloudflare est actif et que le DNS est propagé.\n",
    );
  }

  // 4. Persist atomically (mode 0600 enforced by writeConfig).
  const cfg = readConfig();
  cfg.urlType = 'permanent';
  cfg.tunnelToken = args.token;
  cfg.publicUrl = args.url;
  writeConfig(cfg);

  // 5. Confirm.
  process.stdout.write('Tunnel configuré. URL permanente : ' + args.url + '.\n');
  process.stdout.write(
    'Redémarre le companion avec `wendy stop && wendy start`.\n',
  );
  return 0;
}

// ── help ─────────────────────────────────────────────────────────────────────
function cmdHelp() {
  process.stdout.write(
    [
      'wendy — companion CLI for Whiteboard',
      '',
      'Usage:',
      '  wendy <command>',
      '',
      'Commands:',
      '  start                  Start the companion in the background',
      '  stop                   Stop the companion',
      '  status                 Show companion status, URL and licence',
      '  activate <licence>     Register a LemonSqueezy licence key',
      '  deactivate             Release the registered licence key',
      '  update                 Download the latest companion binary',
      '  configure-tunnel       Bind a Cloudflare named tunnel (PRO)',
      '  help                   Show this help',
      '',
      'The companion runs at ' + COMPANION_URL + '.',
      '',
    ].join('\n'),
  );
  return 0;
}

// ── main ─────────────────────────────────────────────────────────────────────
async function main() {
  const argv = process.argv.slice(2);
  const cmd = argv[0];

  if (!cmd || cmd === 'help' || cmd === '--help' || cmd === '-h') {
    return cmdHelp();
  }
  if (cmd === 'start') return await cmdStart();
  if (cmd === 'stop') return await cmdStop();
  if (cmd === 'status') return await cmdStatus();
  if (cmd === 'activate') return await cmdActivate(argv.slice(1));
  if (cmd === 'deactivate') return await cmdDeactivate();
  if (cmd === 'update') return await cmdUpdate();
  if (cmd === 'configure-tunnel') return await cmdConfigureTunnel(argv.slice(1));

  process.stderr.write('Unknown command: ' + cmd + '\n\n');
  cmdHelp();
  return 1;
}

main()
  .then(function (code) {
    process.exit(typeof code === 'number' ? code : 0);
  })
  .catch(function (err) {
    process.stderr.write('[wendy] unexpected error: ' + String(err) + '\n');
    process.exit(1);
  });
