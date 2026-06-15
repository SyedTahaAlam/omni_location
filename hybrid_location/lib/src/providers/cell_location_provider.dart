import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../models/hybrid_location_result.dart';
import '../models/location_config.dart';
import '../models/location_source.dart';
import '../utils/constants.dart';
import '../utils/geo_api_client.dart';
import 'base_location_provider.dart';

/// Location provider that uses cell tower data.
///
/// Collects the serving cell and neighbour cells via the native platform
/// channel, then POSTs to the Google Geolocation API.
///
/// Only available on Android. Returns `null` on iOS gracefully.
///
/// Expected accuracy: 100 m – 5 km.
class CellLocationProvider extends BaseLocationProvider {
  /// Creates a [CellLocationProvider].
  ///
  /// [config] must include a non-null [LocationConfig.googleApiKey].
  CellLocationProvider({
    required LocationConfig config,
    GeoApiClient? apiClient,
    MethodChannel? channel,
  })  : _config = config,
        _apiClient = apiClient ??
            GeoApiClient(httpTimeoutMs: config.httpTimeoutMs),
        _channel = channel ??
            const MethodChannel(kChannelName);

  final LocationConfig _config;
  final GeoApiClient _apiClient;
  final MethodChannel _channel;

  @override
  LocationSource get source => LocationSource.cellTower;

  @override
  Future<bool> isAvailable() async {
    // Cell scanning is not available via public iOS APIs.
    if (Platform.isIOS) return false;
    if (_config.googleApiKey == null || _config.googleApiKey!.isEmpty) {
      return false;
    }
    try {
      final result = await _channel
          .invokeMethod<bool>(kMethodIsCellAvailable);
      return result ?? false;
    } catch (e) {
      developer.log('CellLocationProvider.isAvailable error: $e',
          name: kLogName);
      return false;
    }
  }

  @override
  Future<HybridLocationResult?> getLocation() async {
    if (Platform.isIOS) return null;
    try {
      final rawCells = await _channel.invokeMethod<List<dynamic>>(
        kMethodScanCells,
      );
      if (rawCells == null || rawCells.isEmpty) {
        developer.log('CellLocationProvider: no cells found', name: kLogName);
        return null;
      }

      final cellTowers = rawCells
          .whereType<Map>()
          .map(
            (c) => {
              'cellId': c['cid'],
              'locationAreaCode': c['lac'],
              'mobileCountryCode': c['mcc'],
              'mobileNetworkCode': c['mnc'],
              'signalStrength': c['rssi'],
            },
          )
          .toList();

      if (cellTowers.isEmpty) return null;

      final body = {'cellTowers': cellTowers};
      final url = '$kGoogleGeoApiUrl?key=${_config.googleApiKey}';
      final response = await _apiClient.post(url, body);

      if (response == null) {
        developer.log('CellLocationProvider: Google API returned null',
            name: kLogName);
        return null;
      }

      final location = response['location'] as Map<String, dynamic>?;
      if (location == null) {
        developer.log('CellLocationProvider: missing location in response',
            name: kLogName);
        return null;
      }

      return HybridLocationResult(
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
        accuracyMeters: (response['accuracy'] as num?)?.toDouble() ?? 2000.0,
        source: LocationSource.cellTower,
        timestamp: DateTime.now(),
        raw: response,
      );
    } on PlatformException catch (e) {
      developer.log('CellLocationProvider PlatformException: $e',
          name: kLogName);
      return null;
    } catch (e) {
      developer.log('CellLocationProvider.getLocation error: $e',
          name: kLogName);
      return null;
    }
  }
}
