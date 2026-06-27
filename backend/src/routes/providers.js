'use strict';

const express = require('express');
const { validateProvidersBody } = require('../middleware/validate');
const { findNearbyProviders } = require('../services/providerService');

const router = express.Router();

/**
 * POST /api/providers
 * Body: { "specialist": "General Physician", "latitude": -1.286, "longitude": 36.817, "radius": 5000 }
 * Returns nearby providers for the specialist, ranked by distance (mock) or rating (google).
 */
router.post('/', validateProvidersBody, async (req, res, next) => {
  try {
    const { specialist, latitude, longitude, radius, limit } = req.body;
    const providers = await findNearbyProviders(specialist, latitude, longitude, {
      radius,
      limit,
    });
    res.json({ specialist, count: providers.length, providers });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
