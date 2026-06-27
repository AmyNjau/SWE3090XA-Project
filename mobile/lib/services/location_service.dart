import 'package:geolocator/geolocator.dart';

import '../config.dart';

/// Result of a location request, including whether the device's real position
/// was used or the app fell back to a default location.
class UserLocation {
  final double latitude;
  final double longitude;
  final bool isFallback;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.isFallback = false,
  });

  static const UserLocation fallback = UserLocation(
    latitude: AppConfig.fallbackLatitude,
    longitude: AppConfig.fallbackLongitude,
    isFallback: true,
  );
}

/// Wraps geolocation with graceful degradation: if the service is disabled or
/// permission is denied, it returns a fallback location instead of failing, so
/// the user still receives nearby-provider suggestions (FR-15).
class LocationService {
  Future<UserLocation> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return UserLocation.fallback;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return UserLocation.fallback;
      }

      // A last-known fix returns instantly when available.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return UserLocation(latitude: last.latitude, longitude: last.longitude);
      }

      // Otherwise request a fresh fix, but bound the wait so the UI never hangs
      // (important on low-connectivity devices and emulators without a fix).
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      return UserLocation(latitude: pos.latitude, longitude: pos.longitude);
    } catch (_) {
      // Any failure (including timeout) degrades gracefully to the fallback.
      return UserLocation.fallback;
    }
  }
}
