# hybrid_location

A Flutter package that determines device location **without GPS** by using a
priority-based fallback chain across multiple sensor and network sources.

## Features

| Provider | Accuracy | Permissions needed |
|---|---|---|
| Wi-Fi (via Google Geolocation API) | 10–40 m | Location (+ Google API key) |
| Cell tower (via Google Geolocation API) | 100 m – 5 km | Location, Phone State (Android only) |
| IP geolocation | City-level (1–50 km) | None |
| Bluetooth BLE beacons | 1–3 m | Bluetooth scan (+ known beacon map) |

## Getting started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  hybrid_location: ^0.1.0
```

## Usage

### Configure once (e.g. in `main()`)

```dart
await HybridLocation.configure(LocationConfig(
  googleApiKey: 'YOUR_GOOGLE_API_KEY',
  providerOrder: [LocationSource.wifi, LocationSource.cellTower, LocationSource.ip],
  cacheExpiry: Duration(minutes: 3),
));
```

### One-shot fetch

```dart
try {
  final result = await HybridLocation.getLocation();
  print('${result.latitude}, ${result.longitude} via ${result.source}');
} on HybridLocationException catch (e) {
  print('All providers failed: ${e.failedSources}');
}
```

### Continuous tracking

```dart
HybridLocation.locationStream.listen((loc) {
  print('Update: ${loc.latitude}, ${loc.longitude} [${loc.source}]');
});
await HybridLocation.startTracking(interval: Duration(minutes: 5));
// ...
await HybridLocation.stopTracking();
```

## Android setup

The required permissions are declared in the plugin's `AndroidManifest.xml`.
Your app still needs to request runtime permissions — the package handles this
via `PermissionHandler.requestRequiredPermissions(config)`.

## iOS setup

Add to your app's `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to determine location via Wi-Fi.</string>
<!-- Only needed when enableBluetooth: true -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Used to scan BLE beacons for location.</string>
```

> **Note:** Wi-Fi AP scanning on iOS requires the *Access WiFi Information*
> entitlement from Apple. Without it, the package falls back to IP geolocation
> automatically.

## Fallback chain

1. **Cache** — returns immediately if the cached result is still within `cacheExpiry`.
2. Providers are tried in `providerOrder` order.
3. First non-null result is cached and returned.
4. If all providers fail, `HybridLocationException` is thrown.

## Additional information

- No GPS is used at any point.
- `developer.log` is used throughout (no `print` statements).
- All models are immutable and support `copyWith`, `toJson`, `fromJson`.
