import '../models/hybrid_location_result.dart';
import '../models/location_source.dart';

/// Abstract base class that every location provider must implement.
///
/// Providers follow a simple contract:
/// 1. Report whether they can be used right now via [isAvailable].
/// 2. Attempt to resolve a location via [getLocation], returning `null`
///    on failure instead of throwing.
abstract class BaseLocationProvider {
  /// Returns `true` if this provider's underlying sensor or API is
  /// accessible on the current device and platform.
  Future<bool> isAvailable();

  /// Attempts to obtain a location fix.
  ///
  /// Returns `null` when the provider cannot produce a result (e.g.
  /// insufficient data, API error, timeout).  Must never throw.
  Future<HybridLocationResult?> getLocation();

  /// The [LocationSource] this provider represents.
  LocationSource get source;
}
