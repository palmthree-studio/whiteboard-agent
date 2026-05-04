'use strict';
/**
 * Shared cloudflared helpers used by both `agent/bin/cli.js` (`wendy start`)
 * and `agent/scripts/postinstall.js` (agentique install). Centralising the
 * spawn / argument resolution logic keeps the two entry points in sync and
 * makes it easier to add modes (quick tunnel, named tunnel) without
 * duplicating logic.
 *
 * Constraints
 *  - CommonJS only (Node.js stdlib + optional `cloudflared` npm dep).
 *  - Pure functions: nothing here writes to disk or to global state. Callers
 *    own PID files, config persistence and logging.
 *  - Never throws: errors during spawn are surfaced via the returned promise
 *    (rejection or `{ url: null }`) so callers can degrade gracefully.
 */

const fs = require('fs');

const DEFAULT_QUICK_TUNNEL_TIMEOUT_MS = 20000;
const TRYCLOUDFLARE_REGEX = /https:\/\/[a-z0-9-]+\.trycloudflare\.com/;

/**
 * Resolve the cloudflared binary path. Prefers the npm `cloudflared` package
 * (installed as a runtime dep of `whiteboard-agent`); falls back to `npx -y
 * cloudflared` so dev linkage and broken postinstalls still work.
 *
 * @returns {{ bin: string, prefix: string[] }} `prefix` is the args that
 *   must be prepended to the cloudflared invocation (empty for the binary,
 *   `['-y', 'cloudflared']` for the npx fallback).
 */
function resolveCloudflared() {
  try {
    // eslint-disable-next-line global-require
    const cf = require('cloudflared');
    if (cf && typeof cf.bin === 'string' && fs.existsSync(cf.bin)) {
      return { bin: cf.bin, prefix: [] };
    }
  } catch (_) {
    /* package not installed — fall through to npx */
  }
  return {
    bin: process.platform === 'win32' ? 'npx.cmd' : 'npx',
    prefix: ['-y', 'cloudflared'],
  };
}

/**
 * Build the full `{ bin, args }` tuple for `child_process.spawn`. Internal.
 */
function buildSpawnArgs(tunnelArgs) {
  const cmd = resolveCloudflared();
  return { bin: cmd.bin, args: [...cmd.prefix, ...tunnelArgs] };
}

/**
 * Spawn a Cloudflare quick tunnel pointing at the local companion. Resolves
 * with `{ process, url }` once cloudflared announces a `*.trycloudflare.com`
 * URL (within `timeoutMs`). On timeout, resolves with `{ process, url: null }`
 * — the caller decides whether to keep the tunnel running or kill it.
 *
 * Importantly, the child is detached + `unref()`d once we have a URL, so the
 * parent script can exit while the tunnel keeps running in the background.
 *
 * @param {string} targetUrl   The local URL the tunnel should expose, e.g.
 *                             `http://localhost:3001`.
 * @param {object} [opts]
 * @param {number} [opts.timeoutMs=20000] How long to wait for the URL.
 * @param {(line: string) => void} [opts.onLog] Optional logger for stdout/stderr.
 *
 * @returns {Promise<{ process: import('child_process').ChildProcess, url: string|null }>}
 */
function startQuickTunnel(targetUrl, opts) {
  const options = opts || {};
  const timeoutMs =
    typeof options.timeoutMs === 'number' && options.timeoutMs > 0
      ? options.timeoutMs
      : DEFAULT_QUICK_TUNNEL_TIMEOUT_MS;
  const onLog = typeof options.onLog === 'function' ? options.onLog : null;

  // Lazy-require to avoid pulling child_process when the helper is imported
  // for type-checking only.
  // eslint-disable-next-line global-require
  const { spawn } = require('child_process');

  return new Promise(function (resolve, reject) {
    let child;
    try {
      const { bin, args } = buildSpawnArgs([
        'tunnel',
        '--url',
        targetUrl,
        '--no-autoupdate',
      ]);
      child = spawn(bin, args, {
        detached: true,
        stdio: ['ignore', 'pipe', 'pipe'],
      });
    } catch (err) {
      reject(err);
      return;
    }

    let resolved = false;
    let urlFound = null;

    const finish = function (url) {
      if (resolved) return;
      resolved = true;
      clearTimeout(timer);
      try {
        child.unref();
      } catch (_) {
        /* ignore */
      }
      resolve({ process: child, url: url });
    };

    const timer = setTimeout(function () {
      finish(urlFound);
    }, timeoutMs);

    const onData = function (chunk) {
      const text = String(chunk);
      if (onLog) {
        for (const line of text.split(/\r?\n/)) {
          if (line.length > 0) onLog(line);
        }
      }
      const match = text.match(TRYCLOUDFLARE_REGEX);
      if (match) {
        urlFound = match[0];
        finish(urlFound);
      }
    };

    if (child.stdout) child.stdout.on('data', onData);
    if (child.stderr) child.stderr.on('data', onData);
    child.on('error', function (err) {
      if (!resolved) {
        clearTimeout(timer);
        resolved = true;
        reject(err);
      }
    });
    child.on('exit', function () {
      finish(urlFound);
    });
  });
}

/**
 * Spawn a Cloudflare *named* tunnel using a pre-issued connector token. The
 * URL is known in advance (configured via the Cloudflare dashboard), so we
 * don't parse stdout — we just spawn, persist the PID via the caller, and
 * trust cloudflared to maintain the connection.
 *
 * @param {string} token  Connector token (the JWT base64 emitted by
 *                        `cloudflared tunnel token <name>`).
 * @param {object} [opts]
 * @param {(line: string) => void} [opts.onLog] Optional logger for stdout/stderr.
 *
 * @returns {Promise<{ process: import('child_process').ChildProcess }>}
 */
function startNamedTunnel(token, opts) {
  const options = opts || {};
  const onLog = typeof options.onLog === 'function' ? options.onLog : null;

  if (typeof token !== 'string' || token.length === 0) {
    return Promise.reject(new Error('startNamedTunnel: token is required'));
  }

  // eslint-disable-next-line global-require
  const { spawn } = require('child_process');

  return new Promise(function (resolve, reject) {
    let child;
    try {
      const { bin, args } = buildSpawnArgs([
        'tunnel',
        '--no-autoupdate',
        'run',
        '--token',
        token,
      ]);
      child = spawn(bin, args, {
        detached: true,
        stdio: ['ignore', 'pipe', 'pipe'],
      });
    } catch (err) {
      reject(err);
      return;
    }

    if (onLog) {
      const onData = function (chunk) {
        const text = String(chunk);
        for (const line of text.split(/\r?\n/)) {
          if (line.length > 0) onLog(line);
        }
      };
      if (child.stdout) child.stdout.on('data', onData);
      if (child.stderr) child.stderr.on('data', onData);
    }

    child.on('error', function (err) {
      // Surface spawn errors that happen after the synchronous phase via the
      // logger; we still resolve because the caller already has the handle.
      if (onLog) onLog('[cloudflared] error: ' + String(err));
    });

    try {
      child.unref();
    } catch (_) {
      /* ignore */
    }

    resolve({ process: child });
  });
}

module.exports = {
  resolveCloudflared,
  startQuickTunnel,
  startNamedTunnel,
};
