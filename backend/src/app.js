'use strict';

const express = require('express');
const cors = require('cors');

const config = require('./config');
const diagnoseRoutes = require('./routes/diagnose');
const providerRoutes = require('./routes/providers');
const catalogRoutes = require('./routes/catalog');
const { authenticate } = require('./middleware/auth');
const { notFound, errorHandler } = require('./middleware/errorHandler');

/**
 * Builds and returns the Express app. Kept separate from server.js so tests can
 * import the app without binding a network port.
 */
function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  // Health/liveness probe.
  app.get('/api/health', (req, res) => {
    res.json({
      status: 'ok',
      service: 'smart-health-backend',
      dataStore: config.dataStore,
      providerSource: config.providerSource,
      authRequired: config.auth.required,
    });
  });

  // The catalogue endpoints stay open: they return the symptom and specialist
  // lists the sign-in screen needs before anyone has a token, and they expose
  // no user data. Everything that reasons about a person's symptoms is behind
  // authentication.
  app.use('/api/diagnose', authenticate, diagnoseRoutes);
  app.use('/api/providers', authenticate, providerRoutes);
  app.use('/api', catalogRoutes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
