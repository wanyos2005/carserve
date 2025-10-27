import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

/// Unified permission service that handles all permission types
/// Follows DRY principles by centralizing permission logic
class UnifiedPermissionService {
  
  /// Generic permission request method
  static Future<bool> _requestPermission(
    Permission permission, {
    String? title,
    String? message,
    BuildContext? context,
  }) async {
    var status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      status = await permission.request();
      return status.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      if (context != null && title != null && message != null) {
        await _showPermissionDialog(context, title, message);
      }
      return false;
    }
    
    return false;
  }
  
  /// Location permission with Geolocator integration
  static Future<bool> requestLocationPermission({
    BuildContext? context,
    bool showDialog = true,
  }) async {
    // Use Geolocator for location-specific permission handling
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showDialog && context != null) {
          _showLocationServiceDialog(context);
        }
        return false;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showDialog && context != null) {
            _showPermissionDeniedDialog(context);
          }
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (showDialog && context != null) {
          _showPermissionPermanentlyDeniedDialog(context);
        }
        return false;
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }
  
  /// Camera permission
  static Future<bool> requestCameraPermission({BuildContext? context}) async {
    return await _requestPermission(
      Permission.camera,
      title: 'Camera Permission Required',
      message: 'DriveOn needs camera access to let you take photos of your vehicle for service documentation.',
      context: context,
    );
  }
  
  /// Storage permission
  static Future<bool> requestStoragePermission({BuildContext? context}) async {
    return await _requestPermission(
      Permission.storage,
      title: 'Storage Permission Required',
      message: 'DriveOn needs storage access to save service receipts and vehicle documentation.',
      context: context,
    );
  }
  
  /// Phone permission
  static Future<bool> requestPhonePermission({BuildContext? context}) async {
    return await _requestPermission(
      Permission.phone,
      title: 'Phone Permission Required',
      message: 'DriveOn needs phone access to enable direct calling to service providers.',
      context: context,
    );
  }
  
  /// SMS permission
  static Future<bool> requestSMSPermission({BuildContext? context}) async {
    return await _requestPermission(
      Permission.sms,
      title: 'SMS Permission Required',
      message: 'DriveOn needs SMS access to send you service confirmations and appointment reminders.',
      context: context,
    );
  }
  
  /// Check permission status
  static Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.isGranted;
  }
  
  /// Get all permission statuses
  static Future<Map<String, bool>> getAllPermissionStatus() async {
    return {
      'location': await isLocationPermissionGranted(),
      'camera': await isPermissionGranted(Permission.camera),
      'storage': await isPermissionGranted(Permission.storage),
      'phone': await isPermissionGranted(Permission.phone),
      'sms': await isPermissionGranted(Permission.sms),
    };
  }
  
  /// Check location permission (using Geolocator)
  static Future<bool> isLocationPermissionGranted() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }
  
  /// Show permission dialog
  static Future<void> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
  
  /// Show location service dialog
  static void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled. Please enable them in your device settings to use location-based features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Show permission denied dialog
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to find nearby service providers and calculate distances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Show permission permanently denied dialog
  static void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission has been permanently denied. Please enable it in app settings to use location features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
