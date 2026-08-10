'use strict';

const config = require('../config');
const { verifyIdToken } = require('../services/authService');

/**
 * Reads a bearer token from the Authorization header.
 * @returns {string|null}
 */
function bearerToken(req) {
  const header = req.get('authorization') || '';
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  return match ? match[1].trim() : null;
}

/**
 * Attaches the caller's identity to `req.user`, or rejects.
 *
 * The two rules that matter:
 *
 *   - A token that is supplied is ALWAYS verified, whether or not
 *     `AUTH_REQUIRED` is set. Skipping verification for optional auth would
 *     mean a forged token is accepted in the default configuration, which is
 *     the mistake this middleware exists to avoid.
 *   - A token that is absent is only tolerated when `AUTH_REQUIRED` is off, in
 *     which case `req.user` is null and the request proceeds anonymously.
 */
async function authenticate(req, res, next) {
  const token = bearerToken(req);

  if (!token) {
    if (config.auth.required) {
      const err = new Error('Authentication required. Sign in and retry.');
      err.status = 401;
      return next(err);
    }
    req.user = null;
    return next();
  }

  try {
    req.user = await verifyIdToken(token);
    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = { authenticate, bearerToken };
