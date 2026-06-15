import 'package:flutter/foundation.dart';
import 'location_source.dart';

/// Configuration options passed to [HybridLocation.configure].
///
/// All fields have sensible defaults so the package works out-of-the-box
/// for IP-based resolution; a [googleApiKey] is only required when
/// Wi-Fi or cell-tower providers are enabled.
@immutable
class LocationConfig {
  /// Google Geolocation API key.
  ///
  /// Required for [LocationSource.wifi] and [LocationSource.cellTower]
  /// providers which POST to the Google Geolocation API.
  final String? googleApiKey;

  /// Base URL for the IP geolocation service.
  ///
  /// Defaults to `http://ip-api.com/json`.
  final String? ipApiUrl;

  /// How long a cached location result remains valid.
  ///
  /// Defaults to 2 minutes.
  final Duration cacheExpiry;

  /// Ordered list of providers to try during fallback resolution.
  ///
  /// Providers are tried in order; the first successful result is returned.
  /// Defaults to `[wifi, cellTower, ip]`.
  final List<LocationSource> providerOrder;

  /// Whether to enable the Bluetooth BLE beacon provider.
  ///
  /// Requires pre-placed beacons with known positions. Defaults to `false`.
  final bool enableBluetooth;

  /// Whether to request background location permission on startup.
  ///
  /// Defaults to `false`.
  final bool requestBackgroundPermission;

  /// Timeout in milliseconds for Wi-Fi scanning.
  ///
  /// Defaults to `5000` ms.
  final int wifiScanTimeoutMs;

  /// Timeout in milliseconds for HTTP requests to external APIs.
  ///
  /// Defaults to `8000` ms.
  final int httpTimeoutMs;

  /// Known Bluetooth beacon positions keyed by device UUID / MAC address.
  ///
  /// Required when [enableBluetooth] is `true`.  Each entry maps a beacon
  /// identifier to a `{'lat': double, 'lng': double}` map.
  final Map<String, Map<String, double>> knownBeacons;

  /// Creates a [LocationConfig] with the given options.
  const LocationConfig({
    this.googleApiKey,
    this.ipApiUrl,
    this.cacheExpiry = const Duration(minutes: 2),
    this.providerOrder = const [
      LocationSource.wifi,
      LocationSource.cellTower,
      LocationSource.ip,
    ],
    this.enableBluetooth = false,
    this.requestBackgroundPermission = false,
    this.wifiScanTimeoutMs = 5000,
    this.httpTimeoutMs = 8000,
    this.knownBeacons = const {},
  });

  /// Returns a copy of this config with the given fields replaced.
  LocationConfig copyWith({
    String? googleApiKey,
    String? ipApiUrl,
    Duration? cacheExpiry,
    List<LocationSource>? providerOrder,
    bool? enableBluetooth,
    bool? requestBackgroundPermission,
    int? wifiScanTimeoutMs,
    int? httpTimeoutMs,
    Map<String, Map<String, double>>? knownBeacons,
  }) {
    return LocationConfig(
      googleApiKey: googleApiKey ?? this.googleApiKey,
      ipApiUrl: ipApiUrl ?? this.ipApiUrl,
      cacheExpiry: cacheExpiry ?? this.cacheExpiry,
      providerOrder: providerOrder ?? this.providerOrder,
      enableBluetooth: enableBluetooth ?? this.enableBluetooth,
      requestBackgroundPermission:
          requestBackgroundPermission ?? this.requestBackgroundPermission,
      wifiScanTimeoutMs: wifiScanTimeoutMs ?? this.wifiScanTimeoutMs,
      httpTimeoutMs: httpTimeoutMs ?? this.httpTimeoutMs,
      knownBeacons: knownBeacons ?? this.knownBeacons,
    );
  }

  /// Serialises this config to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'googleApiKey': googleApiKey,
        'ipApiUrl': ipApiUrl,
        'cacheExpiryMs': cacheExpiry.inMilliseconds,
        'providerOrder': providerOrder.map((e) => e.name).toList(),
        'enableBluetooth': enableBluetooth,
        'requestBackgroundPermission': requestBackgroundPermission,
        'wifiScanTimeoutMs': wifiScanTimeoutMs,
        'httpTimeoutMs': httpTimeoutMs,
      };

  /// Deserialises a [LocationConfig] from a JSON map.
  factory LocationConfig.fromJson(Map<String, dynamic> json) {
    return LocationConfig(
      googleApiKey: json['googleApiKey'] as String?,
      ipApiUrl: json['ipApiUrl'] as String?,
      cacheExpiry: Duration(
        milliseconds: json['cacheExpiryMs'] as int? ?? 120000,
      ),
      providerOrder: (json['providerOrder'] as List<dynamic>?)
              ?.map(
                (e) => LocationSource.values.firstWhere(
                  (s) => s.name == e,
                  orElse: () => LocationSource.unknown,
                ),
              )
              .toList() ??
          const [LocationSource.wifi, LocationSource.cellTower, LocationSource.ip],
      enableBluetooth: json['enableBluetooth'] as bool? ?? false,
      requestBackgroundPermission:
          json['requestBackgroundPermission'] as bool? ?? false,
      wifiScanTimeoutMs: json['wifiScanTimeoutMs'] as int? ?? 5000,
      httpTimeoutMs: json['httpTimeoutMs'] as int? ?? 8000,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationConfig &&
        other.googleApiKey == googleApiKey &&
        other.ipApiUrl == ipApiUrl &&
        other.cacheExpiry == cacheExpiry &&
        other.enableBluetooth == enableBluetooth &&
        other.requestBackgroundPermission == requestBackgroundPermission &&
        other.wifiScanTimeoutMs == wifiScanTimeoutMs &&
        other.httpTimeoutMs == httpTimeoutMs;
  }

  @override
  int get hashCode => Object.hash(
        googleApiKey,
        ipApiUrl,
        cacheExpiry,
        enableBluetooth,
        requestBackgroundPermission,
        wifiScanTimeoutMs,
        httpTimeoutMs,
      );
}
