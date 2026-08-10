'use strict';

const { test, afterEach } = require('node:test');
const assert = require('node:assert');

const config = require('../src/config');
const authService = require('../src/services/authService');
const { createApp } = require('../src/app');

const app = createApp();

function startServer() {
  return new Promise((resolve) => {
    const server = app.listen(0, () => {
      const { port } = server.address();
      resolve({
        baseUrl: `http://127.0.0.1:${port}`,
        close: () => new Promise((r) => server.close(r)),
      });
    });
  });
}

function diagnose(baseUrl, headers = {}) {
  return fetch(`${baseUrl}/api/diagnose`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: JSON.stringify({ symptoms: ['fever', 'chills'] }),
  });
}

/** Stands in for Firebase: accepts exactly one token, rejects everything else. */
function fakeVerifier(good = 'good-token') {
  return async (token) => {
    if (token !== good) throw new Error('nope');
    return { uid: 'user-123', email: 'amy@example.com', email_verified: true };
  };
}

afterEach(() => {
  authService.reset();
  config.auth.required = false;
});

test('a valid ID token authenticates the request', async () => {
  authService.setVerifier(fakeVerifier());
  const srv = await startServer();
  try {
    const res = await diagnose(srv.baseUrl, { Authorization: 'Bearer good-token' });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok(Array.isArray(body.results));
  } finally {
    await srv.close();
  }
});

test('an invalid ID token is rejected with 401', async () => {
  authService.setVerifier(fakeVerifier());
  const srv = await startServer();
  try {
    const res = await diagnose(srv.baseUrl, { Authorization: 'Bearer forged-token' });
    assert.strictEqual(res.status, 401);
  } finally {
    await srv.close();
  }
});

test('a supplied token is verified even when auth is optional', async () => {
  // The important one: with AUTH_REQUIRED off it would be tempting to skip
  // verification entirely, which would accept a forged token by default.
  config.auth.required = false;
  authService.setVerifier(fakeVerifier());
  const srv = await startServer();
  try {
    const res = await diagnose(srv.baseUrl, { Authorization: 'Bearer forged-token' });
    assert.strictEqual(res.status, 401);
  } finally {
    await srv.close();
  }
});

test('anonymous requests are allowed when auth is not required', async () => {
  config.auth.required = false;
  const srv = await startServer();
  try {
    const res = await diagnose(srv.baseUrl);
    assert.strictEqual(res.status, 200);
  } finally {
    await srv.close();
  }
});

test('anonymous requests are rejected when auth is required', async () => {
  config.auth.required = true;
  const srv = await startServer();
  try {
    const res = await diagnose(srv.baseUrl);
    assert.strictEqual(res.status, 401);
    const body = await res.json();
    assert.match(body.error, /Authentication required/i);
  } finally {
    await srv.close();
  }
});

test('the catalogue stays public so the app can load before sign-in', async () => {
  config.auth.required = true;
  const srv = await startServer();
  try {
    const res = await fetch(`${srv.baseUrl}/api/symptoms`);
    assert.strictEqual(res.status, 200);
  } finally {
    await srv.close();
  }
});

test('a malformed Authorization header is treated as no token', async () => {
  config.auth.required = true;
  const srv = await startServer();
  try {
    const res = await diagnose(srv.baseUrl, { Authorization: 'Basic abc123' });
    assert.strictEqual(res.status, 401);
  } finally {
    await srv.close();
  }
});

test('an authenticated diagnosis is logged against the caller uid', async () => {
  authService.setVerifier(fakeVerifier());
  const { getDataStore } = require('../src/repositories');
  const srv = await startServer();
  try {
    await diagnose(srv.baseUrl, { Authorization: 'Bearer good-token' });
    const log = await getDataStore().getQueryLog();
    const latest = log[log.length - 1];
    assert.strictEqual(latest.uid, 'user-123');
  } finally {
    await srv.close();
  }
});

test('an anonymous diagnosis is logged with a null uid', async () => {
  const { getDataStore } = require('../src/repositories');
  const srv = await startServer();
  try {
    await diagnose(srv.baseUrl);
    const log = await getDataStore().getQueryLog();
    const latest = log[log.length - 1];
    assert.strictEqual(latest.uid, null);
  } finally {
    await srv.close();
  }
});

test('the error message never leaks why a token failed', async () => {
  authService.setVerifier(async () => {
    throw new Error('Firebase ID token has expired at 1234567890; signature mismatch');
  });
  const srv = await startServer();
  try {
    const res = await diagnose(srv.baseUrl, { Authorization: 'Bearer whatever' });
    assert.strictEqual(res.status, 401);
    const body = await res.json();
    assert.doesNotMatch(body.error, /signature|1234567890/i);
  } finally {
    await srv.close();
  }
});
