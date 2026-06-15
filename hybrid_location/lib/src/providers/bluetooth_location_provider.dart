import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' show pow;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/hybrid_location_result.dart';
import '../models/location_config.dart';
import '../models/location_source.dart';
import '../utils/constants.dart';
import 'base_location_provider.dart';

/// Location provider that uses Bluetooth BLE beacons.
///
/// Scans for nearby BLE devices for [kBleScanDurationSeconds] seconds.
/// Only devices with RSSI > [kBluetoothMinRssi] dBm are considered.
///
/// Requires at least 3 beacons with known positions in
/// [LocationConfig.knownBeacons] for trilateration.
///
/// Expected accuracy: 1–3 metres (requires pre-placed beacons).
class BluetoothLocationProvider extends BaseLocationProvider {
  /// Creates a [BluetoothLocationProvider].
  BluetoothLocationProvider({required LocationConfig config})
      : _config = config;

  final LocationConfig _config;

  @override
  LocationSource get source => LocationSource.bluetooth;

  @override
  Future<bool> isAvailable() async {
    if (!_config.enableBluetooth) return false;
    if (_config.knownBeacons.isEmpty) {
      developer.log(
        'BluetoothLocationProvider: knownBeacons map is empty',
        name: kLogName,
      );
      return false;
    }
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      developer.log('BluetoothLocationProvider.isAvailable error: $e',
          name: kLogName);
      return false;
    }
  }

  @override
  Future<HybridLocationResult?> getLocation() async {
    if (!_config.enableBluetooth || _config.knownBeacons.isEmpty) {
      return null;
    }
    try {
      // Start scanning and collect results for the configured duration.
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: kBleScanDurationSeconds),
      );

      final detected = <String, int>{}; // deviceId → rssi

      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (r.rssi > kBluetoothMinRssi) {
            detected[r.device.remoteId.str] = r.rssi;
          }
        }
      });

      await Future<void>.delayed(
        const Duration(seconds: kBleScanDurationSeconds),
      );
      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      // Find beacons whose positions we know.
      final matchedBeacons = <String, Map<String, double>>{};
      final matchedRssi = <String, int>{};
      for (final entry in detected.entries) {
        if (_config.knownBeacons.containsKey(entry.key)) {
          matchedBeacons[entry.key] = _config.knownBeacons[entry.key]!;
          matchedRssi[entry.key] = entry.value;
        }
      }

      if (matchedBeacons.length < kMinBluetoothBeacons) {
        developer.log(
          'BluetoothLocationProvider: insufficient beacons '
          '(${matchedBeacons.length} < $kMinBluetoothBeacons)',
          name: kLogName,
        );
        return null;
      }

      final position = _trilaterate(matchedBeacons, matchedRssi);
      if (position == null) return null;

      return HybridLocationResult(
        latitude: position['lat']!,
        longitude: position['lng']!,
        accuracyMeters: 3.0,
        source: LocationSource.bluetooth,
        timestamp: DateTime.now(),
        raw: {
          'detectedBeacons': detected,
          'matchedBeacons': matchedBeacons,
        },
      );
    } catch (e) {
      developer.log('BluetoothLocationProvider.getLocation error: $e',
          name: kLogName);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Trilateration helpers
  // ---------------------------------------------------------------------------

  /// Converts RSSI to an estimated distance in metres using the log-distance
  /// path loss model.
  double _rssiToDistance(int rssi) {
    // Measured power at 1 m (-65 dBm) and path-loss exponent (2.0 for free space)
    const txPower = -65;
    const n = 2.0;
    if (rssi == 0) return -1.0;
    final ratio = rssi / txPower;
    if (ratio < 1.0) {
      return pow(ratio, 10).toDouble();
    }
    return 0.89976 * pow(ratio, 7.7095) + 0.111;
  }

  /// Performs a simple weighted centroid approximation of latitude/longitude
  /// from 3 or more beacon distances.
  Map<String, double>? _trilaterate(
    Map<String, Map<String, double>> beacons,
    Map<String, int> rssiMap,
  ) {
    if (beacons.length < kMinBluetoothBeacons) return null;

    double totalWeight = 0;
    double weightedLat = 0;
    double weightedLng = 0;

    for (final id in beacons.keys) {
      final pos = beacons[id]!;
      final rssi = rssiMap[id] ?? kBluetoothMinRssi;
      final distance = _rssiToDistance(rssi);
      // Weight is inverse of distance (closer beacon = higher weight).
      final weight = distance > 0 ? 1.0 / distance : 1.0;
      weightedLat += pos['lat']! * weight;
      weightedLng += pos['lng']! * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return null;

    return {
      'lat': weightedLat / totalWeight,
      'lng': weightedLng / totalWeight,
    };
  }

}
