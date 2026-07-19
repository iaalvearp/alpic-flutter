import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

enum LocationAccessStatus {
  checking,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  granted,
  error,
}

class LocationAccessResult {
  const LocationAccessResult(this.status, {this.position});

  final LocationAccessStatus status;
  final Position? position;
}

abstract interface class LocationService {
  Future<LocationAccessResult> checkAndRequestAccess({
    bool obtainPosition = true,
  });

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

class DeviceLocationService implements LocationService {
  @override
  Future<LocationAccessResult> checkAndRequestAccess({
    bool obtainPosition = true,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationAccessResult(
          LocationAccessStatus.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationAccessResult(
          LocationAccessStatus.permissionPermanentlyDenied,
        );
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationAccessResult(LocationAccessStatus.serviceDisabled);
      }
      if (!obtainPosition) {
        return const LocationAccessResult(LocationAccessStatus.granted);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationAccessResult(
        LocationAccessStatus.granted,
        position: position,
      );
    } catch (error) {
      debugPrint('No se pudo comprobar la ubicación: $error');
      return const LocationAccessResult(LocationAccessStatus.error);
    }
  }

  @override
  Future<bool> openAppSettings() => permission_handler.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
