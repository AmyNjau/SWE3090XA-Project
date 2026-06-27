'use strict';

const { test } = require('node:test');
const assert = require('node:assert');
const { createApp } = require('../src/app');

const app = createApp();

/** Start the app on an ephemeral port and return { baseUrl, close }. */
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

test('GET /api/health reports ok', async () => {
  const srv = await startServer();
  try {
    const res = await fetch(`${srv.baseUrl}/api/health`);
    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.status, 'ok');
  } finally {
    await srv.close();
  }
});

test('POST /api/diagnose returns ranked conditions + specialist + disclaimer', async () => {
  const srv = await startServer();
  try {
    const res = await fetch(`${srv.baseUrl}/api/diagnose`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ symptoms: ['fever', 'chills', 'headache', 'sweating'] }),
    });
    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.ok(Array.isArray(body.results) && body.results.length > 0);
    assert.strictEqual(body.results[0].id, 'malaria');
    assert.strictEqual(body.recommendedSpecialist, 'General Physician');
    assert.ok(typeof body.disclaimer === 'string' && body.disclaimer.length > 0);
    assert.ok(Array.isArray(body.results[0].matchedSymptoms));
  } finally {
    await srv.close();
  }
});

test('POST /api/diagnose rejects empty symptoms with 400', async () => {
  const srv = await startServer();
  try {
    const res = await fetch(`${srv.baseUrl}/api/diagnose`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ symptoms: [] }),
    });
    const body = await res.json();
    assert.strictEqual(res.status, 400);
    assert.ok(body.error);
  } finally {
    await srv.close();
  }
});

test('POST /api/providers returns nearby providers ranked by distance', async () => {
  const srv = await startServer();
  try {
    const res = await fetch(`${srv.baseUrl}/api/providers`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        specialist: 'General Physician',
        latitude: -1.2641,
        longitude: 36.8028,
      }),
    });
    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.ok(body.providers.length > 0);
    // Closest provider should be first.
    for (let i = 1; i < body.providers.length; i += 1) {
      assert.ok(body.providers[i].distanceMetres >= body.providers[i - 1].distanceMetres);
    }
  } finally {
    await srv.close();
  }
});

test('POST /api/providers rejects missing coordinates with 400', async () => {
  const srv = await startServer();
  try {
    const res = await fetch(`${srv.baseUrl}/api/providers`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ specialist: 'General Physician' }),
    });
    assert.strictEqual(res.status, 400);
  } finally {
    await srv.close();
  }
});

test('GET /api/symptoms returns the catalogue', async () => {
  const srv = await startServer();
  try {
    const res = await fetch(`${srv.baseUrl}/api/symptoms`);
    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.ok(body.count > 0 && Array.isArray(body.symptoms));
  } finally {
    await srv.close();
  }
});
