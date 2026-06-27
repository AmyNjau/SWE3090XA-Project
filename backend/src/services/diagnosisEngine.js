'use strict';

/**
 * Rule-based diagnostic engine.
 *
 * For each candidate condition the engine sums the weights of the symptoms the
 * user reported and divides by the maximum possible weight for that condition,
 * producing a normalised confidence score in the range 0..1. Because every
 * score traces directly back to specific weighted symptoms, the reasoning is
 * fully explainable -- a deliberate design choice for a safety-sensitive domain.
 *
 * This module is pure (no I/O), which keeps it trivially unit-testable.
 */

/**
 * Score a single condition against the user's reported symptoms.
 * @param {object} condition  A condition from the knowledge base.
 * @param {string[]} userSymptoms  Symptom ids the user reported.
 * @returns {{ score: number, matched: string[] }}
 *   score   normalised confidence 0..1
 *   matched the symptom ids that contributed to the score (explainability)
 */
function scoreCondition(condition, userSymptoms) {
  const weights = condition.symptoms || {};
  const maxScore = Object.values(weights).reduce((a, b) => a + b, 0);
  if (maxScore <= 0) return { score: 0, matched: [] };

  let matchedWeight = 0;
  const matched = [];
  for (const symptom of userSymptoms) {
    if (Object.prototype.hasOwnProperty.call(weights, symptom)) {
      matchedWeight += weights[symptom];
      matched.push(symptom);
    }
  }
  return { score: matchedWeight / maxScore, matched };
}

/**
 * Produce a ranked list of probable conditions.
 * @param {string[]} userSymptoms  Symptom ids the user reported.
 * @param {object[]} conditions    The knowledge base conditions.
 * @param {object} [options]
 * @param {number} [options.threshold=0.2]  Minimum normalised score to include.
 * @param {number} [options.maxResults]     Cap on the number of results.
 * @returns {object[]} ranked conditions with confidence and matched symptoms
 */
function diagnose(userSymptoms, conditions, options = {}) {
  const threshold = options.threshold ?? 0.2;
  const maxResults = options.maxResults ?? Infinity;

  // De-duplicate and normalise input defensively.
  const symptomSet = [...new Set((userSymptoms || []).map((s) => String(s).trim()))];

  return conditions
    .map((condition) => {
      const { score, matched } = scoreCondition(condition, symptomSet);
      return {
        id: condition.id,
        name: condition.name,
        specialist: condition.specialist,
        severity: condition.severity,
        description: condition.description,
        confidence: +(score * 100).toFixed(1), // 0..100, one decimal
        matchedSymptoms: matched, // explainability: why this ranked here
      };
    })
    .filter((r) => r.confidence >= threshold * 100 && r.matchedSymptoms.length > 0)
    .sort((a, b) => b.confidence - a.confidence)
    .slice(0, maxResults);
}

module.exports = { scoreCondition, diagnose };
