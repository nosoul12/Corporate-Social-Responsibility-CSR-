import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animal_rescue_app/core/theme/primary_gradient_button.dart';

/// Service for handling runtime permissions with user-friendly dialogs
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request location permission with proper user flow
  Future<PermissionStatus> requestLocationPermission(
      BuildContext context) async {
    var status = await Permission.location.status;

    if (status.isGranted) {
      return status;
    }

    if (status.isDenied) {
      // Show rationale before requesting
      final shouldRequest = await _showPermissionRationale(
        context,
        'Location Access Required',
        'Pet Buddy needs your location to show nearby cases and help animals in need.',
      );

      if (!shouldRequest) {
        return status;
      }

      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      // Show dialog to go to settings
      await _showOpenSettingsDialog(
        context,
        'Location Permission Required',
        'Please enable location access in Settings to use location features.',
      );
    }

    return status;
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Handle location permission with comprehensive flow
  Future<bool> handleLocationPermission(BuildContext context) async {
    // Check if service is enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      final enableService = await _showLocationServiceDialog(context);
      if (!enableService) {
        return false;
      }
      // User chose to enable, but we can't programmatically do it
      // They need to go to settings
      await Geolocator.openLocationSettings();
      return false;
    }

    // Check permission
    final status = await requestLocationPermission(context);
    return status.isGranted;
  }

  /// Show permission rationale dialog
  Future<bool> _showPermissionRationale(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Now'),
              ),
              PrimaryGradientButton(
                onPressed: () => Navigator.pop(context, true),
                expand: false,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show dialog to open app settings
  Future<void> _showOpenSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PrimaryGradientButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            expand: false,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show location service dialog
  Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text(
              'Please enable location services in your device settings to use location features.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              PrimaryGradientButton(
                onPressed: () => Navigator.pop(context, true),
                expand: false,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: const Text('Enable'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
