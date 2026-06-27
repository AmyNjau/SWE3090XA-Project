'use strict';

const express = require('express');
const cors = require('cors');

const config = require('./config');
const diagnoseRoutes = require('./routes/diagnose');
const providerRoutes = require('./routes/providers');
const catalogRoutes = require('./routes/catalog');
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
    });
  });

  app.use('/api/diagnose', diagnoseRoutes);
  app.use('/api/providers', providerRoutes);
  app.use('/api', catalogRoutes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
