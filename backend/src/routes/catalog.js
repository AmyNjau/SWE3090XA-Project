'use strict';

const express = require('express');
const { getDataStore } = require('../repositories');

const router = express.Router();

/** GET /api/symptoms - the symptom catalogue used to populate the input screen. */
router.get('/symptoms', async (req, res, next) => {
  try {
    const symptoms = await getDataStore().getSymptoms();
    res.json({ count: symptoms.length, symptoms });
  } catch (err) {
    next(err);
  }
});

/** GET /api/specialists - the specialist directory. */
router.get('/specialists', async (req, res, next) => {
  try {
    const specialists = await getDataStore().getSpecialists();
    res.json({ count: specialists.length, specialists });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
