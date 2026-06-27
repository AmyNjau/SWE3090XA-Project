'use strict';

/** 404 handler for unknown routes. */
function notFound(req, res) {
  res.status(404).json({ error: `Not found: ${req.method} ${req.originalUrl}` });
}

/** Central error handler so failures degrade to a clean JSON response. */
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  // Avoid leaking internals on 500s.
  const message = status >= 500 ? 'Internal server error' : err.message;
  if (status >= 500) console.error(err);
  res.status(status).json({ error: message });
}

module.exports = { notFound, errorHandler };
