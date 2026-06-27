'use strict';

const path = require('path');
const fs = require('fs');

/**
 * Local, file-backed implementation of the data-store interface.
 * Reads the curated JSON knowledge base, symptom catalogue, specialist
 * mappings and sample providers from src/data, and keeps query logs in memory.
 *
 * This implementation is intentionally swappable: firestoreDataStore.js exposes
 * the same async interface so the rest of the app never changes when the data
 * tier moves to Firebase Firestore.
 */
const DATA_DIR = path.join(__dirname, '..', 'data');

function loadJson(file) {
  const raw = fs.readFileSync(path.join(DATA_DIR, file), 'utf8');
  return JSON.parse(raw);
}

class LocalDataStore {
  constructor() {
    this._conditions = loadJson('knowledge_base.json').conditions;
    this._symptoms = loadJson('symptoms.json').symptoms;
    this._specialists = loadJson('specialists.json').specialists;
    this._providers = loadJson('providers.json').providers;
    this._queryLog = [];
  }

  async getConditions() {
    return this._conditions;
  }

  async getSymptoms() {
    return this._symptoms;
  }

  async getSpecialists() {
    return this._specialists;
  }

  async getSpecialistByType(type) {
    return this._specialists.find((s) => s.type === type) || null;
  }

  async getProvidersBySpecialty(specialty) {
    return this._providers.filter((p) => p.specialty === specialty);
  }

  /** Persist an anonymised query record (in memory for the local store). */
  async logQuery(record) {
    this._queryLog.push(record);
    return record;
  }

  async getQueryLog() {
    return this._queryLog;
  }
}

module.exports = LocalDataStore;
