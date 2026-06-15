/// {@canonicalFor hybrid_location.HybridLocation}
/// A Flutter package for determining device location without GPS.
///
/// Uses a priority-based fallback chain across Wi-Fi, cell towers,
/// IP geolocation, and Bluetooth BLE beacons.
///
/// ## Quick Start
/// ```dart
/// await HybridLocation.configure(LocationConfig(
///   googleApiKey: 'YOUR_KEY',
///   providerOrder: [LocationSource.wifi, LocationSource.cellTower, LocationSource.ip],
/// ));
/// final result = await HybridLocation.getLocation();
/// ```
library hybrid_location;

export 'src/hybrid_location_plugin.dart';
export 'src/models/hybrid_location_result.dart';
export 'src/models/location_config.dart';
export 'src/models/location_source.dart';
export 'src/providers/base_location_provider.dart';
