'use strict';

/**
 * Firestore implementation of the data-store interface.
 *
 * STUB: this is deliberately left as a documented stub so the app can swap the
 * data tier to Firebase Firestore (DATA_STORE=firestore) without touching any
 * service or route code. To activate it:
 *
 *   1. npm install firebase-admin
 *   2. Provide credentials (GOOGLE_APPLICATION_CREDENTIALS or default creds)
 *   3. Seed Firestore collections that mirror src/data/*.json:
 *        conditions, symptoms, specialists, providers, queries
 *   4. Implement each method below using the Firestore SDK.
 *
 * The method signatures match LocalDataStore exactly.
 */
class FirestoreDataStore {
  constructor() {
    // const admin = require('firebase-admin');
    // admin.initializeApp({ ... });
    // this.db = admin.firestore();
    throw new Error(
      'FirestoreDataStore is not implemented yet. ' +
        'Set DATA_STORE=local to use the file-backed store, or implement this class. ' +
        'See the comments in src/repositories/firestoreDataStore.js.'
    );
  }

  async getConditions() {
    // const snap = await this.db.collection('conditions').get();
    // return snap.docs.map((d) => d.data());
    throw new Error('Not implemented');
  }

  async getSymptoms() {
    throw new Error('Not implemented');
  }

  async getSpecialists() {
    throw new Error('Not implemented');
  }

  async getSpecialistByType(/* type */) {
    throw new Error('Not implemented');
  }

  async getProvidersBySpecialty(/* specialty */) {
    throw new Error('Not implemented');
  }

  async logQuery(/* record */) {
    throw new Error('Not implemented');
  }

  async getQueryLog() {
    throw new Error('Not implemented');
  }
}

module.exports = FirestoreDataStore;
