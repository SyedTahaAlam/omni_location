import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hybrid_location/hybrid_location.dart';
import 'package:hybrid_location/src/providers/base_location_provider.dart';

import 'hybrid_location_test.mocks.dart';

// Generate mocks:
// flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([BaseLocationProvider])
void main() {
  late MockBaseLocationProvider mockWifi;
  late MockBaseLocationProvider mockCell;
  late MockBaseLocationProvider mockIp;

  final wifiResult = HybridLocationResult(
    latitude: 37.4219983,
    longitude: -122.084,
    accuracyMeters: 20,
    source: LocationSource.wifi,
    timestamp: DateTime(2024),
  );

  final cellResult = HybridLocationResult(
    latitude: 37.42,
    longitude: -122.08,
    accuracyMeters: 500,
    source: LocationSource.cellTower,
    timestamp: DateTime(2024),
  );

  final ipResult = HybridLocationResult(
    latitude: 37.0,
    longitude: -122.0,
    accuracyMeters: 10000,
    source: LocationSource.ip,
    timestamp: DateTime(2024),
  );

  setUp(() async {
    mockWifi = MockBaseLocationProvider();
    mockCell = MockBaseLocationProvider();
    mockIp = MockBaseLocationProvider();

    when(mockWifi.source).thenReturn(LocationSource.wifi);
    when(mockCell.source).thenReturn(LocationSource.cellTower);
    when(mockIp.source).thenReturn(LocationSource.ip);

    await HybridLocation.clearCache();
  });

  // ---------------------------------------------------------------------------
  // Internal helper: configure with injected mocks
  // ---------------------------------------------------------------------------
  Future<void> configureWithMocks({
    required List<BaseLocationProvider> providers,
  }) async {
    // We call the internal setter via configure and replace providers.
    await HybridLocation.configure(
      const LocationConfig(
        cacheExpiry: Duration(minutes: 2),
        providerOrder: [
          LocationSource.wifi,
          LocationSource.cellTower,
          LocationSource.ip,
        ],
      ),
    );
    // Inject mocks by overriding providers through the test helper.
    HybridLocationTestHelper.setProviders(providers);
  }

  group('getLocation()', () {
    test('returns Wi-Fi result when Wi-Fi provider succeeds', () async {
      when(mockWifi.isAvailable()).thenAnswer((_) async => true);
      when(mockWifi.getLocation()).thenAnswer((_) async => wifiResult);

      await configureWithMocks(providers: [mockWifi, mockCell, mockIp]);

      final result = await HybridLocation.getLocation();
      expect(result.source, LocationSource.wifi);
      expect(result.latitude, wifiResult.latitude);
      verifyNever(mockCell.getLocation());
      verifyNever(mockIp.getLocation());
    });

    test('falls back to cell when Wi-Fi returns null', () async {
      when(mockWifi.isAvailable()).thenAnswer((_) async => true);
      when(mockWifi.getLocation()).thenAnswer((_) async => null);
      when(mockCell.isAvailable()).thenAnswer((_) async => true);
      when(mockCell.getLocation()).thenAnswer((_) async => cellResult);

      await configureWithMocks(providers: [mockWifi, mockCell, mockIp]);

      final result = await HybridLocation.getLocation();
      expect(result.source, LocationSource.cellTower);
    });

    test('falls back to IP when Wi-Fi and cell return null', () async {
      when(mockWifi.isAvailable()).thenAnswer((_) async => true);
      when(mockWifi.getLocation()).thenAnswer((_) async => null);
      when(mockCell.isAvailable()).thenAnswer((_) async => true);
      when(mockCell.getLocation()).thenAnswer((_) async => null);
      when(mockIp.isAvailable()).thenAnswer((_) async => true);
      when(mockIp.getLocation()).thenAnswer((_) async => ipResult);

      await configureWithMocks(providers: [mockWifi, mockCell, mockIp]);

      final result = await HybridLocation.getLocation();
      expect(result.source, LocationSource.ip);
    });

    test('throws HybridLocationException when all providers fail', () async {
      when(mockWifi.isAvailable()).thenAnswer((_) async => true);
      when(mockWifi.getLocation()).thenAnswer((_) async => null);
      when(mockCell.isAvailable()).thenAnswer((_) async => true);
      when(mockCell.getLocation()).thenAnswer((_) async => null);
      when(mockIp.isAvailable()).thenAnswer((_) async => true);
      when(mockIp.getLocation()).thenAnswer((_) async => null);

      await configureWithMocks(providers: [mockWifi, mockCell, mockIp]);

      expect(
        () => HybridLocation.getLocation(),
        throwsA(isA<HybridLocationException>()),
      );
    });

    test('returns cached result within cacheExpiry window', () async {
      when(mockWifi.isAvailable()).thenAnswer((_) async => true);
      when(mockWifi.getLocation()).thenAnswer((_) async => wifiResult);

      await configureWithMocks(providers: [mockWifi, mockCell, mockIp]);

      // First call — fetches fresh.
      await HybridLocation.getLocation();
      // Second call — should return cached without calling providers again.
      final cached = await HybridLocation.getLocation();

      expect(cached.isCached, isTrue);
      verify(mockWifi.getLocation()).called(1); // called only once
    });

    test('clearCache() causes next call to re-fetch', () async {
      when(mockWifi.isAvailable()).thenAnswer((_) async => true);
      when(mockWifi.getLocation()).thenAnswer((_) async => wifiResult);

      await configureWithMocks(providers: [mockWifi, mockCell, mockIp]);

      await HybridLocation.getLocation(); // first fetch
      await HybridLocation.clearCache();
      await HybridLocation.getLocation(); // should re-fetch

      verify(mockWifi.getLocation()).called(2);
    });
  });
}

/// Test-only helper that exposes package-private state for injection.
///
/// This class is intentionally placed in the test directory and is NOT
/// part of the public API.
class HybridLocationTestHelper {
  HybridLocationTestHelper._();

  /// Replaces the internal provider list used by [HybridLocation].
  static void setProviders(List<BaseLocationProvider> providers) {
    // ignore: invalid_use_of_visible_for_testing_member
    HybridLocation.testProviders = providers;
  }
}
