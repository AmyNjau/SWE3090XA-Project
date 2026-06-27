'use strict';

const crypto = require('crypto');
const config = require('../config');
const { getDataStore } = require('../repositories');
const { diagnose } = require('./diagnosisEngine');

/**
 * Orchestrates a full diagnosis: runs the rule engine over the knowledge base,
 * derives the recommended specialist from the top condition, records an
 * anonymised query log, and attaches the safety disclaimer.
 */
async function runDiagnosis(symptoms) {
  const store = getDataStore();
  const conditions = await store.getConditions();

  const rawResults = diagnose(symptoms, conditions, {
    threshold: config.diagnosis.threshold,
    maxResults: config.diagnosis.maxResults,
  });

  // Build a symptom id -> display name map so the response can explain, in
  // plain language, which symptoms drove each condition's score. This makes the
  // rule-based reasoning visible to the user (the project's "explainable
  // inference" contribution) without leaking internal ids to the UI.
  const symptomCatalogue = await store.getSymptoms();
  const nameById = new Map(symptomCatalogue.map((s) => [s.id, s.name]));
  const results = rawResults.map((r) => ({
    ...r,
    matchedSymptomNames: r.matchedSymptoms.map((id) => nameById.get(id) || id),
  }));

  const recommendedSpecialist = results.length ? results[0].specialist : null;
  let specialistInfo = null;
  if (recommendedSpecialist) {
    specialistInfo = await store.getSpecialistByType(recommendedSpecialist);
  }

  // Anonymised query log: no user identifiers, just the inputs and outcome.
  await store.logQuery({
    query_id: crypto.randomUUID(),
    symptoms,
    topConditionId: results.length ? results[0].id : null,
    recommendedSpecialist,
    timestamp: new Date().toISOString(),
  });

  return {
    results,
    recommendedSpecialist,
    specialistInfo,
    disclaimer: config.disclaimer,
  };
}

module.exports = { runDiagnosis };
