'use strict';

/** Build a 400 error with a clear message. */
function badRequest(message) {
  const err = new Error(message);
  err.status = 400;
  return err;
}

/** Validate the body of POST /api/diagnose. */
function validateDiagnoseBody(req, res, next) {
  const { symptoms } = req.body || {};
  if (!Array.isArray(symptoms) || symptoms.length === 0) {
    return next(badRequest('No symptoms provided. Send a non-empty "symptoms" array.'));
  }
  if (!symptoms.every((s) => typeof s === 'string' && s.trim().length > 0)) {
    return next(badRequest('Every symptom must be a non-empty string.'));
  }
  next();
}

/** Validate the body of POST /api/providers. */
function validateProvidersBody(req, res, next) {
  const { specialist, latitude, longitude } = req.body || {};
  if (typeof specialist !== 'string' || specialist.trim().length === 0) {
    return next(badRequest('A "specialist" string is required.'));
  }
  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    return next(badRequest('Numeric "latitude" and "longitude" are required.'));
  }
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    return next(badRequest('latitude/longitude are out of range.'));
  }
  next();
}

module.exports = { validateDiagnoseBody, validateProvidersBody, badRequest };
