import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../models/hybrid_location_result.dart';
import '../models/location_config.dart';
import '../models/location_source.dart';
import '../utils/constants.dart';
import '../utils/geo_api_client.dart';
import 'base_location_provider.dart';

/// Location provider that uses nearby Wi-Fi access points.
///
/// Scans for visible APs, collects BSSID and signal strength, then
/// POSTs to the Google Geolocation API to resolve lat/lng.
///
/// Expected accuracy: 10–40 metres.
class WifiLocationProvider extends BaseLocationProvider {
  /// Creates a [WifiLocationProvider].
  ///
  /// [config] must include a non-null [LocationConfig.googleApiKey].
  WifiLocationProvider({
    required LocationConfig config,
    GeoApiClient? apiClient,
  })  : _config = config,
        _apiClient = apiClient ??
            GeoApiClient(httpTimeoutMs: config.httpTimeoutMs);

  final LocationConfig _config;
  final GeoApiClient _apiClient;

  @override
  LocationSource get source => LocationSource.wifi;

  @override
  Future<bool> isAvailable() async {
    if (_config.googleApiKey == null || _config.googleApiKey!.isEmpty) {
      developer.log(
        'WifiLocationProvider: googleApiKey is not configured',
        name: kLogName,
      );
      return false;
    }
    try {
      final canScan = await WiFiScan.instance
          .canStartScan(askPermissions: false);
      return canScan == CanStartScan.yes;
    } catch (e) {
      developer.log('WifiLocationProvider.isAvailable error: $e',
          name: kLogName);
      return false;
    }
  }

  @override
  Future<HybridLocationResult?> getLocation() async {
    try {
      // Trigger a fresh scan with timeout.
      final canScan = await WiFiScan.instance
          .canStartScan(askPermissions: true)
          .timeout(Duration(milliseconds: _config.wifiScanTimeoutMs));
      if (canScan != CanStartScan.yes) {
        developer.log('WifiLocationProvider: cannot start scan ($canScan)',
            name: kLogName);
        return null;
      }

      final started = await WiFiScan.instance
          .startScan()
          .timeout(Duration(milliseconds: _config.wifiScanTimeoutMs));
      if (!started) {
        developer.log('WifiLocationProvider: startScan returned false',
            name: kLogName);
        return null;
      }

      final canRead =
          await WiFiScan.instance.canGetScannedResults(askPermissions: false);
      if (canRead != CanGetScannedResults.yes) {
        developer.log(
            'WifiLocationProvider: cannot read scan results ($canRead)',
            name: kLogName);
        return null;
      }

      final results = await WiFiScan.instance.getScannedResults();
      if (results.length < kMinWifiAccessPoints) {
        developer.log(
          'WifiLocationProvider: insufficient APs (${results.length} < $kMinWifiAccessPoints)',
          name: kLogName,
        );
        return null;
      }

      final accessPoints = results
          .map((ap) => {
                'macAddress': ap.bssid,
                'signalStrength': ap.level,
              })
          .toList();

      final body = {'wifiAccessPoints': accessPoints};
      final url =
          '$kGoogleGeoApiUrl?key=${_config.googleApiKey}';
      final response = await _apiClient.post(url, body);

      if (response == null) {
        developer.log('WifiLocationProvider: Google API returned null',
            name: kLogName);
        return null;
      }

      final location = response['location'] as Map<String, dynamic>?;
      if (location == null) {
        developer.log('WifiLocationProvider: missing location in response',
            name: kLogName);
        return null;
      }

      return HybridLocationResult(
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
        accuracyMeters: (response['accuracy'] as num?)?.toDouble() ?? 50.0,
        source: LocationSource.wifi,
        timestamp: DateTime.now(),
        raw: response,
      );
    } on PlatformException catch (e) {
      developer.log('WifiLocationProvider PlatformException: $e',
          name: kLogName);
      return null;
    } catch (e) {
      developer.log('WifiLocationProvider.getLocation error: $e',
          name: kLogName);
      return null;
    }
  }
}
