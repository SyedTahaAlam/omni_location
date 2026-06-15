import 'package:flutter/foundation.dart';
import 'location_source.dart';

/// The result object returned by [HybridLocation.getLocation].
///
/// Contains the resolved coordinates along with metadata about
/// how the location was obtained.
@immutable
class HybridLocationResult {
  /// Geographic latitude in decimal degrees.
  final double latitude;

  /// Geographic longitude in decimal degrees.
  final double longitude;

  /// Estimated accuracy radius in meters.
  final double accuracyMeters;

  /// The provider that produced this result.
  final LocationSource source;

  /// When this result was obtained.
  final DateTime timestamp;

  /// Whether this result was served from the in-memory cache.
  final bool isCached;

  /// Raw response payload from the underlying provider or API.
  final Map<String, dynamic> raw;

  /// Creates a [HybridLocationResult].
  const HybridLocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.source,
    required this.timestamp,
    this.isCached = false,
    this.raw = const {},
  });

  /// Returns a copy of this result with the given fields replaced.
  HybridLocationResult copyWith({
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    LocationSource? source,
    DateTime? timestamp,
    bool? isCached,
    Map<String, dynamic>? raw,
  }) {
    return HybridLocationResult(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      isCached: isCached ?? this.isCached,
      raw: raw ?? this.raw,
    );
  }

  /// Serialises this result to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'source': source.name,
        'timestamp': timestamp.toIso8601String(),
        'isCached': isCached,
        'raw': raw,
      };

  /// Deserialises a [HybridLocationResult] from a JSON map.
  factory HybridLocationResult.fromJson(Map<String, dynamic> json) {
    return HybridLocationResult(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
      source: LocationSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => LocationSource.unknown,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isCached: json['isCached'] as bool? ?? false,
      raw: Map<String, dynamic>.from(json['raw'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HybridLocationResult &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracyMeters == accuracyMeters &&
        other.source == source &&
        other.timestamp == timestamp &&
        other.isCached == isCached;
  }

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        accuracyMeters,
        source,
        timestamp,
        isCached,
      );

  @override
  String toString() =>
      'HybridLocationResult(lat=$latitude, lng=$longitude, '
      'accuracy=${accuracyMeters}m, source=$source, cached=$isCached)';
}
