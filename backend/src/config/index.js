'use strict';

require('dotenv').config();

/**
 * Centralised configuration, read once from the environment with safe defaults
 * so the server runs out-of-the-box without any .env file.
 */
const config = {
  port: parseInt(process.env.PORT, 10) || 3000,

  // Which data-store implementation to use: 'local' | 'firestore'
  dataStore: process.env.DATA_STORE || 'local',

  // Where nearby-provider results come from: 'mock' | 'google'
  providerSource: process.env.PROVIDER_SOURCE || 'mock',

  // Google Maps Platform key (only required when providerSource === 'google')
  mapsApiKey: process.env.MAPS_API_KEY || '',

  // Firebase (only required when dataStore === 'firestore')
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID || '',

  // Engine tuning
  diagnosis: {
    // Conditions scoring below this normalised confidence are discarded.
    threshold: 0.2,
    // Maximum number of ranked conditions returned to the client.
    maxResults: 5,
  },

  providers: {
    // Default search radius in metres for nearby provider lookup.
    radiusMetres: 5000,
    // Maximum providers returned.
    limit: 10,
    // Time-to-live for cached provider lookups, in milliseconds.
    cacheTtlMs: 5 * 60 * 1000,
  },

  // Shown on every diagnosis response. Central so it is impossible to forget.
  disclaimer:
    'This is a guidance tool, not a substitute for professional medical advice. ' +
    'If your symptoms are severe or worsening, seek care from a qualified professional immediately.',
};

module.exports = config;
