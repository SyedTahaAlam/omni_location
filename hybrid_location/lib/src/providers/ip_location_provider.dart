import 'dart:developer' as developer;

import '../models/hybrid_location_result.dart';
import '../models/location_config.dart';
import '../models/location_source.dart';
import '../utils/constants.dart';
import '../utils/geo_api_client.dart';
import 'base_location_provider.dart';

/// Location provider that uses IP geolocation.
///
/// Sends a GET request to a configurable IP geolocation API
/// (default: `http://ip-api.com/json`) and parses the response.
///
/// Requires no device permissions. Use as last-resort fallback only.
///
/// Expected accuracy: city-level (~1–50 km).
class IpLocationProvider extends BaseLocationProvider {
  /// Creates an [IpLocationProvider].
  IpLocationProvider({
    required LocationConfig config,
    GeoApiClient? apiClient,
  })  : _config = config,
        _apiClient = apiClient ??
            GeoApiClient(httpTimeoutMs: config.httpTimeoutMs);

  final LocationConfig _config;
  final GeoApiClient _apiClient;

  String get _apiUrl => _config.ipApiUrl ?? kDefaultIpApiUrl;

  @override
  LocationSource get source => LocationSource.ip;

  @override
  Future<bool> isAvailable() async => true; // always try

  @override
  Future<HybridLocationResult?> getLocation() async {
    try {
      final response = await _apiClient.get(_apiUrl);
      if (response == null) {
        developer.log('IpLocationProvider: null response from $_apiUrl',
            name: kLogName);
        return null;
      }

      if (response['status'] != 'success') {
        developer.log(
          'IpLocationProvider: status=${response['status']} message=${response['message']}',
          name: kLogName,
        );
        return null;
      }

      final lat = response['lat'];
      final lon = response['lon'];
      if (lat == null || lon == null) {
        developer.log('IpLocationProvider: missing lat/lon in response',
            name: kLogName);
        return null;
      }

      return HybridLocationResult(
        latitude: (lat as num).toDouble(),
        longitude: (lon as num).toDouble(),
        accuracyMeters: 10000.0, // IP geolocation is city-level
        source: LocationSource.ip,
        timestamp: DateTime.now(),
        raw: response,
      );
    } catch (e) {
      developer.log('IpLocationProvider.getLocation error: $e',
          name: kLogName);
      return null;
    }
  }
}
