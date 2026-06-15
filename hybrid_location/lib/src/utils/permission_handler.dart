import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';
import '../models/location_config.dart';
import 'constants.dart';

/// Result of a permission request performed by [PermissionHandler].
enum PermissionStatus {
  /// All required permissions were granted.
  granted,

  /// Some permissions were granted but others were denied.
  partiallyGranted,

  /// All requested permissions were denied by the user.
  denied,

  /// At least one permission was permanently denied (requires settings).
  permanentlyDenied,
}

/// Handles runtime permission requests required by the location providers.
class PermissionHandler {
  /// Requests all permissions needed based on [config].
  ///
  /// Permission request order:
  /// 1. Internet — always, no prompt needed.
  /// 2. Location (whenInUse) — required for Wi-Fi scan on both platforms.
  /// 3. Phone state — Android only, for cell-tower data.
  /// 4. Bluetooth scan — only when [LocationConfig.enableBluetooth] is `true`.
  ///
  /// Returns a [PermissionStatus] summarising the outcome.
  static Future<PermissionStatus> requestRequiredPermissions(
    LocationConfig config,
  ) async {
    final requested = <Permission>[];
    final denied = <Permission>[];
    final permanentlyDenied = <Permission>[];

    // Location permission is always required (Wi-Fi scan on Android 9+
    // and CoreLocation on iOS).
    requested.add(Permission.locationWhenInUse);

    if (config.enableBluetooth) {
      requested.add(Permission.bluetoothScan);
    }

    for (final permission in requested) {
      try {
        final status = await permission.request();
        if (status.isPermanentlyDenied) {
          permanentlyDenied.add(permission);
          developer.log(
            'Permission permanently denied: $permission',
            name: kLogName,
          );
        } else if (!status.isGranted) {
          denied.add(permission);
          developer.log(
            'Permission denied: $permission',
            name: kLogName,
          );
        }
      } catch (e) {
        developer.log(
          'Error requesting permission $permission: $e',
          name: kLogName,
        );
        denied.add(permission);
      }
    }

    if (permanentlyDenied.isNotEmpty) {
      return PermissionStatus.permanentlyDenied;
    }
    if (denied.isEmpty) {
      return PermissionStatus.granted;
    }
    if (denied.length < requested.length) {
      return PermissionStatus.partiallyGranted;
    }
    return PermissionStatus.denied;
  }
}
