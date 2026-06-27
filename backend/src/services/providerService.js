'use strict';

const config = require('../config');
const { getDataStore } = require('../repositories');
const { haversineMetres } = require('../utils/geo');

/**
 * Provider service: finds nearby healthcare providers for a recommended
 * specialist type and the user's coordinates.
 *
 * Two sources, selected by config.providerSource:
 *   - 'mock'   : ranks the curated sample providers by real haversine distance.
 *   - 'google' : queries the Google Maps Platform Nearby Search API.
 *
 * Results are cached in-memory with a short TTL to control external API cost
 * and rate limits (a requirement called out in the design report).
 */

const cache = new Map(); // key -> { expires, value }

function cacheKey(specialist, lat, lng, radius) {
  // Round coordinates so nearby requests share a cache entry.
  const rLat = lat.toFixed(3);
  const rLng = lng.toFixed(3);
  return `${specialist}|${rLat}|${rLng}|${radius}`;
}

function getCached(key) {
  const hit = cache.get(key);
  if (!hit) return null;
  if (Date.now() > hit.expires) {
    cache.delete(key);
    return null;
  }
  return hit.value;
}

function setCached(key, value) {
  cache.set(key, { value, expires: Date.now() + config.providers.cacheTtlMs });
}

/** Rank curated sample providers by distance from the user. */
async function findFromMock(specialist, lat, lng, radius, limit) {
  const store = getDataStore();
  const providers = await store.getProvidersBySpecialty(specialist);
  return providers
    .map((p) => ({
      id: p.id,
      name: p.name,
      specialty: p.specialty,
      address: p.address,
      rating: p.rating,
      reviews: p.reviews,
      location: { latitude: p.latitude, longitude: p.longitude },
      distanceMetres: Math.round(haversineMetres(lat, lng, p.latitude, p.longitude)),
    }))
    .filter((p) => p.distanceMetres <= radius)
    .sort((a, b) => a.distanceMetres - b.distanceMetres)
    .slice(0, limit);
}

/** Query the Google Maps Platform Nearby Search API. */
async function findFromGoogle(specialist, lat, lng, radius, limit) {
  if (!config.mapsApiKey) {
    throw new Error('MAPS_API_KEY is not set but PROVIDER_SOURCE=google');
  }
  const store = getDataStore();
  const specialistRecord = await store.getSpecialistByType(specialist);
  const keyword = encodeURIComponent(
    specialistRecord ? specialistRecord.searchKeyword : `${specialist} doctor clinic`
  );
  const url =
    'https://maps.googleapis.com/maps/api/place/nearbysearch/json' +
    `?location=${lat},${lng}&radius=${radius}&keyword=${keyword}&key=${config.mapsApiKey}`;

  // Node 18+ provides a global fetch.
  const res = await fetch(url);
  const data = await res.json();
  const results = data.results || [];
  return results
    .map((p) => ({
      id: p.place_id,
      name: p.name,
      specialty: specialist,
      address: p.vicinity || null,
      rating: p.rating ?? null,
      reviews: p.user_ratings_total ?? null,
      location: p.geometry ? p.geometry.location : null,
      distanceMetres: p.geometry
        ? Math.round(
            haversineMetres(lat, lng, p.geometry.location.lat, p.geometry.location.lng)
          )
        : null,
    }))
    .sort((a, b) => (b.rating || 0) - (a.rating || 0))
    .slice(0, limit);
}

/**
 * Find nearby providers for a specialist type and user coordinates.
 * @returns {Promise<object[]>}
 */
async function findNearbyProviders(specialist, lat, lng, options = {}) {
  const radius = options.radius || config.providers.radiusMetres;
  const limit = options.limit || config.providers.limit;

  const key = cacheKey(specialist, lat, lng, radius);
  const cached = getCached(key);
  if (cached) return cached;

  const value =
    config.providerSource === 'google'
      ? await findFromGoogle(specialist, lat, lng, radius, limit)
      : await findFromMock(specialist, lat, lng, radius, limit);

  setCached(key, value);
  return value;
}

/** Exposed for tests. */
function _clearCache() {
  cache.clear();
}

module.exports = { findNearbyProviders, _clearCache };
