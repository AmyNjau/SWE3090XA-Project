'use strict';

const config = require('../config');

/**
 * Firebase ID-token verification.
 *
 * The Admin SDK is loaded lazily and only when a token actually needs checking,
 * for two reasons: the demo and the test suite run without any credentials, and
 * `firebase-admin` is a heavy dependency to pull in at require time for a
 * process that may never authenticate anybody.
 *
 * Verification is delegated to the Admin SDK rather than decoded here by hand.
 * Checking a JWT properly means validating the signature against Google's
 * rotating public keys as well as the issuer, audience and expiry, and hand-
 * rolling that is exactly how token verification gets silently weakened.
 */

let adminApp = null;
let verifier = null;

/** Reset cached state. Tests use this; nothing else should. */
function reset() {
  adminApp = null;
  verifier = null;
}

/** Override the verifier. Tests use this to avoid needing real credentials. */
function setVerifier(fn) {
  verifier = fn;
}

function initialiseAdmin() {
  let admin;
  try {
    // eslint-disable-next-line global-require
    admin = require('firebase-admin');
  } catch (err) {
    const error = new Error(
      'firebase-admin is not installed, so ID tokens cannot be verified. ' +
        'Run "npm run setup" in backend/, or leave AUTH_REQUIRED unset to run ' +
        'without authentication.'
    );
    error.status = 500;
    throw error;
  }

  if (!admin.apps.length) {
    const options = {};
    if (config.auth.projectId) {
      options.projectId = config.auth.projectId;
    }
    if (config.auth.credentialsPath) {
      // applicationDefault() reads GOOGLE_APPLICATION_CREDENTIALS itself.
      options.credential = admin.credential.applicationDefault();
    }
    adminApp = admin.initializeApp(options);
  } else {
    adminApp = admin.apps[0];
  }
  return admin;
}

/**
 * Verify a Firebase ID token.
 * @param {string} idToken
 * @returns {Promise<{uid: string, email: string|null, emailVerified: boolean}>}
 * @throws {Error} with status 401 when the token is missing, malformed or invalid.
 */
async function verifyIdToken(idToken) {
  if (!idToken || typeof idToken !== 'string') {
    const err = new Error('Authentication token missing.');
    err.status = 401;
    throw err;
  }

  if (!verifier) {
    const admin = initialiseAdmin();
    verifier = (token) => admin.auth(adminApp).verifyIdToken(token);
  }

  let decoded;
  try {
    decoded = await verifier(idToken);
  } catch (err) {
    // Never surface the SDK's message: it can describe why a token failed,
    // which is more than an unauthenticated caller needs to know.
    const error = new Error('Authentication token is invalid or has expired.');
    error.status = 401;
    throw error;
  }

  if (!decoded || !decoded.uid) {
    const error = new Error('Authentication token is invalid or has expired.');
    error.status = 401;
    throw error;
  }

  return {
    uid: decoded.uid,
    email: decoded.email || null,
    emailVerified: Boolean(decoded.email_verified),
  };
}

module.exports = { verifyIdToken, setVerifier, reset };
