import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'models/hybrid_location_result.dart';
import 'models/location_config.dart';
import 'models/location_source.dart';
import 'providers/base_location_provider.dart';
import 'providers/bluetooth_location_provider.dart';
import 'providers/cell_location_provider.dart';
import 'providers/ip_location_provider.dart';
import 'providers/wifi_location_provider.dart';
import 'utils/constants.dart';

/// Exception thrown when all location providers fail.
class HybridLocationException implements Exception {
  /// Human-readable description of the failure.
  final String message;

  /// The providers that were attempted but did not return a result.
  final List<LocationSource> failedSources;

  /// Underlying errors captured during each provider attempt.
  final List<Object> underlyingErrors;

  /// Creates a [HybridLocationException].
  const HybridLocationException({
    required this.message,
    this.failedSources = const [],
    this.underlyingErrors = const [],
  });

  @override
  String toString() =>
      'HybridLocationException: $message '
      '(tried: ${failedSources.map((s) => s.name).join(', ')})';
}

/// Main entry point for the hybrid_location package.
///
/// All members are static — configure once, then call [getLocation] from
/// anywhere in the app.
///
/// ```dart
/// await HybridLocation.configure(LocationConfig(
///   googleApiKey: 'YOUR_KEY',
/// ));
/// final result = await HybridLocation.getLocation();
/// ```
class HybridLocation {
  HybridLocation._();

  static LocationConfig _config = const LocationConfig();
  static List<BaseLocationProvider> _providers = [];

  // ---------------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------------
  static HybridLocationResult? _cachedResult;
  static DateTime? _cacheTime;

  // ---------------------------------------------------------------------------
  // Tracking
  // ---------------------------------------------------------------------------
  static StreamController<HybridLocationResult>? _streamController;
  static Timer? _trackingTimer;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Configures the plugin with the given [config].
  ///
  /// Must be called before [getLocation] or [startTracking].
  /// Calling [configure] again replaces the previous configuration and
  /// clears the cache.
  static Future<void> configure(LocationConfig config) async {
    _config = config;
    _providers = _buildProviders(config);
    await clearCache();
    developer.log('Configured with providers: '
        '${_providers.map((p) => p.source.name).join(', ')}',
        name: kLogName);
  }

  /// Returns the most recently obtained location result, or `null` if none.
  static HybridLocationResult? get lastKnownLocation => _cachedResult;

  /// Obtains a location fix using the configured fallback chain.
  ///
  /// 1. Returns the cached result immediately if it has not expired.
  /// 2. Tries each provider in [LocationConfig.providerOrder].
  /// 3. Throws [HybridLocationException] if all providers fail.
  static Future<HybridLocationResult> getLocation() async {
    // 1. Check cache.
    if (_cachedResult != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _config.cacheExpiry) {
        developer.log('Returning cached result (age: ${age.inSeconds}s)',
            name: kLogName);
        return _cachedResult!.copyWith(isCached: true);
      }
    }

    // 2. Try providers in order.
    final failedSources = <LocationSource>[];
    final errors = <Object>[];

    for (final provider in _providers) {
      try {
        final available = await provider.isAvailable();
        if (!available) {
          developer.log(
              '${provider.source.name} provider not available — skipping',
              name: kLogName);
          continue;
        }

        final result = await provider.getLocation();
        if (result != null) {
          _cachedResult = result;
          _cacheTime = DateTime.now();
          developer.log(
              'Location obtained via ${result.source.name}: '
              '${result.latitude}, ${result.longitude}',
              name: kLogName);
          return result;
        }
        failedSources.add(provider.source);
        developer.log('${provider.source.name} provider returned null',
            name: kLogName);
      } catch (e) {
        failedSources.add(provider.source);
        errors.add(e);
        developer.log('${provider.source.name} provider threw: $e',
            name: kLogName);
      }
    }

    // 3. All providers failed.
    throw HybridLocationException(
      message: 'All location providers failed.',
      failedSources: failedSources,
      underlyingErrors: errors,
    );
  }

  /// A broadcast stream that emits location updates when tracking is active.
  ///
  /// Subscribe before calling [startTracking].
  static Stream<HybridLocationResult> get locationStream {
    _streamController ??=
        StreamController<HybridLocationResult>.broadcast();
    return _streamController!.stream;
  }

  /// Starts periodic location updates at the given [interval].
  ///
  /// Each tick calls [getLocation] and emits the result on [locationStream].
  /// Errors are logged but do not stop the timer.
  static Future<void> startTracking({
    Duration interval = const Duration(minutes: 2),
  }) async {
    _trackingTimer?.cancel();
    _streamController ??=
        StreamController<HybridLocationResult>.broadcast();

    developer.log(
        'startTracking: interval=${interval.inSeconds}s', name: kLogName);

    _trackingTimer = Timer.periodic(interval, (_) async {
      try {
        final result = await getLocation();
        if (!(_streamController?.isClosed ?? true)) {
          _streamController!.add(result);
        }
      } on HybridLocationException catch (e) {
        developer.log('Tracking tick failed: $e', name: kLogName);
      } catch (e) {
        developer.log('Tracking tick unexpected error: $e', name: kLogName);
      }
    });
  }

  /// Stops periodic location updates and closes the stream if there are no
  /// remaining listeners.
  static Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    developer.log('stopTracking', name: kLogName);

    if (_streamController != null &&
        !_streamController!.hasListener &&
        !_streamController!.isClosed) {
      await _streamController!.close();
      _streamController = null;
    }
  }

  /// Clears the in-memory location cache.
  ///
  /// The next call to [getLocation] will re-fetch from providers.
  static Future<void> clearCache() async {
    _cachedResult = null;
    _cacheTime = null;
    developer.log('Cache cleared', name: kLogName);
  }

  // ---------------------------------------------------------------------------
  // Test helpers (visible for testing only)
  // ---------------------------------------------------------------------------

  /// Overrides the internal provider list.
  ///
  /// **For testing only.** Do not call in production code.
  @visibleForTesting
  static set testProviders(List<BaseLocationProvider> providers) {
    _providers = providers;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static List<BaseLocationProvider> _buildProviders(LocationConfig config) {
    final allProviders = <LocationSource, BaseLocationProvider>{
      LocationSource.wifi: WifiLocationProvider(config: config),
      LocationSource.cellTower: CellLocationProvider(config: config),
      LocationSource.ip: IpLocationProvider(config: config),
      LocationSource.bluetooth: BluetoothLocationProvider(config: config),
    };

    return config.providerOrder
        .where(allProviders.containsKey)
        .map((source) => allProviders[source]!)
        .toList();
  }
}
