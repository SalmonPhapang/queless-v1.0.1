import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // We don't automatically request anymore, we use the PermissionRequestScreen
      // But we need to distinguish between "denied once" and "never asked"
      debugPrint('⚠️ Location permissions are denied');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    final hasPerm = await _handlePermission();
    if (!hasPerm) {
      return null;
    }

    try {
      // Using 'best' accuracy to get the most precise location possible.
      // We also add a timeLimit to prevent indefinite waiting.
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      // If the accuracy is worse than 15 meters, we try to get a more accurate fix.
      if (_currentPosition != null && _currentPosition!.accuracy > 15) {
        debugPrint(
            '⚠️ Location accuracy was ${_currentPosition!.accuracy}m. Attempting a more precise fix...');
        try {
          final improvedPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 10),
          );
          if (improvedPosition.accuracy < _currentPosition!.accuracy) {
            _currentPosition = improvedPosition;
          }
        } catch (retryError) {
          debugPrint(
              'ℹ️ Accuracy retry failed, using first position: $retryError');
        }
      }

      debugPrint(
          '📍 Location obtained: ${_currentPosition?.latitude}, ${_currentPosition?.longitude} (Accuracy: ${_currentPosition?.accuracy}m)');
      return _currentPosition;
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      // Fallback to last known position if current fails (e.g., timeout)
      _currentPosition = await Geolocator.getLastKnownPosition();
      if (_currentPosition != null) {
        debugPrint(
            'ℹ️ Using last known location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      }
      return _currentPosition;
    }
  }

  double calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Log all placemarks for debugging (optional, but helpful for development)
        debugPrint('📍 Placemark found: ${p.toString()}');

        // Construct a more robust address string
        // Often 'street' contains both house number and street name.
        // If 'street' is just a number or empty, we try to use other fields.
        String street = p.street ?? '';
        String subLocality = p.subLocality ?? '';
        String locality = p.locality ?? '';

        List<String> parts = [];
        if (street.isNotEmpty) parts.add(street);
        if (subLocality.isNotEmpty && subLocality != locality) {
          parts.add(subLocality);
        }
        if (locality.isNotEmpty) parts.add(locality);

        return parts.isNotEmpty ? parts.join(', ') : 'Unknown Address';
      }
      return 'Address not found';
    } catch (e) {
      debugPrint('❌ Error getting address: $e');
      return 'Error getting address';
    }
  }
}
