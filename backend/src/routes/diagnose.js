'use strict';

const express = require('express');
const { validateDiagnoseBody } = require('../middleware/validate');
const { runDiagnosis } = require('../services/diagnosisService');

const router = express.Router();

/**
 * POST /api/diagnose
 * Body: { "symptoms": ["fever", "chills", "headache"] }
 * Returns ranked conditions, the recommended specialist, and a disclaimer.
 */
router.post('/', validateDiagnoseBody, async (req, res, next) => {
  try {
    const { symptoms } = req.body;
    const payload = await runDiagnosis(symptoms);
    res.json(payload);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
