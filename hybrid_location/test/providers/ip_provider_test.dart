import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hybrid_location/src/models/location_config.dart';
import 'package:hybrid_location/src/models/location_source.dart';
import 'package:hybrid_location/src/providers/ip_location_provider.dart';
import 'package:hybrid_location/src/utils/geo_api_client.dart';

import 'ip_provider_test.mocks.dart';

@GenerateMocks([GeoApiClient])
void main() {
  const config = LocationConfig(httpTimeoutMs: 3000);

  late MockGeoApiClient mockClient;
  late IpLocationProvider provider;

  setUp(() {
    mockClient = MockGeoApiClient();
    provider = IpLocationProvider(config: config, apiClient: mockClient);
  });

  group('IpLocationProvider', () {
    test('returns null when ip-api status is "fail"', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => {'status': 'fail', 'message': 'reserved range'},
      );

      final result = await provider.getLocation();
      expect(result, isNull);
    });

    test('parses valid response correctly', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => {
          'status': 'success',
          'lat': 37.4219983,
          'lon': -122.084,
          'city': 'Mountain View',
          'regionName': 'California',
          'country': 'United States',
        },
      );

      final result = await provider.getLocation();
      expect(result, isNotNull);
      expect(result!.source, LocationSource.ip);
      expect(result.latitude, 37.4219983);
      expect(result.longitude, -122.084);
      expect(result.accuracyMeters, greaterThan(0));
    });

    test('handles network error gracefully (returns null, does not throw)',
        () async {
      when(mockClient.get(any)).thenAnswer((_) async => null);

      final result = await provider.getLocation();
      expect(result, isNull);
    });

    test('isAvailable() always returns true', () async {
      expect(await provider.isAvailable(), isTrue);
    });

    test('uses ipApiUrl from config when set', () async {
      const customConfig = LocationConfig(
        ipApiUrl: 'http://custom-ip-api.example/json',
        httpTimeoutMs: 3000,
      );
      final customProvider =
          IpLocationProvider(config: customConfig, apiClient: mockClient);

      when(mockClient.get('http://custom-ip-api.example/json'))
          .thenAnswer(
        (_) async => {
          'status': 'success',
          'lat': 1.0,
          'lon': 2.0,
        },
      );

      final result = await customProvider.getLocation();
      expect(result?.latitude, 1.0);
      verify(mockClient.get('http://custom-ip-api.example/json')).called(1);
    });
  });
}
