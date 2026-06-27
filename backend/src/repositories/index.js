'use strict';

const config = require('../config');
const LocalDataStore = require('./localDataStore');
const FirestoreDataStore = require('./firestoreDataStore');

/**
 * Factory that returns the configured data-store singleton. The rest of the
 * application depends only on this interface, never on a concrete store.
 */
let instance = null;

function getDataStore() {
  if (instance) return instance;

  switch (config.dataStore) {
    case 'firestore':
      instance = new FirestoreDataStore();
      break;
    case 'local':
    default:
      instance = new LocalDataStore();
      break;
  }
  return instance;
}

module.exports = { getDataStore };
