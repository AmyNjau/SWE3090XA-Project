'use strict';

const { test } = require('node:test');
const assert = require('node:assert');
const { scoreCondition, diagnose } = require('../src/services/diagnosisEngine');

const malaria = {
  id: 'malaria',
  name: 'Malaria',
  specialist: 'General Physician',
  severity: 'high',
  symptoms: { fever: 0.9, chills: 0.8, headache: 0.5 }, // maxScore = 2.2
};

const cold = {
  id: 'common_cold',
  name: 'Common Cold',
  specialist: 'General Physician',
  severity: 'low',
  symptoms: { runny_nose: 0.9, sore_throat: 0.7 }, // maxScore = 1.6
};

test('scoreCondition returns 1.0 when all symptoms match', () => {
  const { score, matched } = scoreCondition(malaria, ['fever', 'chills', 'headache']);
  assert.strictEqual(+score.toFixed(3), 1);
  assert.deepStrictEqual(matched.sort(), ['chills', 'fever', 'headache']);
});

test('scoreCondition normalises a partial match', () => {
  // fever (0.9) + chills (0.8) = 1.7 of 2.2
  const { score } = scoreCondition(malaria, ['fever', 'chills']);
  assert.strictEqual(+score.toFixed(4), +(1.7 / 2.2).toFixed(4));
});

test('scoreCondition ignores unknown symptoms', () => {
  const { score, matched } = scoreCondition(malaria, ['fever', 'banana']);
  assert.strictEqual(+score.toFixed(4), +(0.9 / 2.2).toFixed(4));
  assert.deepStrictEqual(matched, ['fever']);
});

test('diagnose ranks conditions by confidence descending', () => {
  const ranked = diagnose(['fever', 'chills', 'headache', 'runny_nose'], [malaria, cold]);
  assert.strictEqual(ranked[0].id, 'malaria');
  assert.ok(ranked[0].confidence > (ranked[1]?.confidence ?? 0));
});

test('diagnose drops conditions below the threshold', () => {
  // Only runny_nose -> cold scores 0.9/1.6 = 56%; malaria has no match.
  const ranked = diagnose(['runny_nose'], [malaria, cold], { threshold: 0.2 });
  assert.strictEqual(ranked.length, 1);
  assert.strictEqual(ranked[0].id, 'common_cold');
});

test('diagnose returns explainable matched symptoms', () => {
  const ranked = diagnose(['fever', 'chills'], [malaria]);
  assert.deepStrictEqual(ranked[0].matchedSymptoms.sort(), ['chills', 'fever']);
});

test('diagnose is deterministic for the same input (reliability requirement)', () => {
  const input = ['fever', 'chills', 'headache'];
  const a = diagnose(input, [malaria, cold]);
  const b = diagnose(input, [malaria, cold]);
  assert.deepStrictEqual(a, b);
});

test('diagnose de-duplicates repeated symptoms', () => {
  const once = diagnose(['fever'], [malaria]);
  const twice = diagnose(['fever', 'fever'], [malaria]);
  assert.deepStrictEqual(once, twice);
});

test('diagnose respects maxResults', () => {
  const ranked = diagnose(['fever', 'chills', 'headache', 'runny_nose', 'sore_throat'], [malaria, cold], {
    maxResults: 1,
  });
  assert.strictEqual(ranked.length, 1);
});
