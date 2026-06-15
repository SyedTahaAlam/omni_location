/// Internal constants used throughout the hybrid_location package.
///
/// Centralises all hard-coded strings and default values to avoid
/// duplication and to make future changes easier.
library;

// ---------------------------------------------------------------------------
// Method channel
// ---------------------------------------------------------------------------

/// The Flutter platform channel name shared by all native method calls.
const String kChannelName = 'hybrid_location';

// ---------------------------------------------------------------------------
// Native method names
// ---------------------------------------------------------------------------

/// Platform channel method: scan visible Wi-Fi access points.
const String kMethodScanWifi = 'scanWifi';

/// Platform channel method: scan visible cell towers.
const String kMethodScanCells = 'scanCells';

/// Platform channel method: check whether Wi-Fi is enabled.
const String kMethodIsWifiEnabled = 'isWifiEnabled';

/// Platform channel method: check whether cellular data is available.
const String kMethodIsCellAvailable = 'isCellAvailable';

// ---------------------------------------------------------------------------
// API URLs
// ---------------------------------------------------------------------------

/// Default IP geolocation API endpoint.
const String kDefaultIpApiUrl = 'http://ip-api.com/json';

/// Google Geolocation API endpoint (requires API key).
const String kGoogleGeoApiUrl =
    'https://www.googleapis.com/geolocation/v1/geolocate';

// ---------------------------------------------------------------------------
// Default timeouts and limits
// ---------------------------------------------------------------------------

/// Default Wi-Fi scan timeout in milliseconds.
const int kDefaultWifiScanTimeoutMs = 5000;

/// Default HTTP request timeout in milliseconds.
const int kDefaultHttpTimeoutMs = 8000;

/// Default cache expiry in milliseconds (2 minutes).
const int kDefaultCacheExpiryMs = 120000;

/// Minimum number of Wi-Fi access points required to call the Geo API.
const int kMinWifiAccessPoints = 2;

/// Minimum number of Bluetooth beacons required for trilateration.
const int kMinBluetoothBeacons = 3;

/// Minimum RSSI (dBm) for a BLE device to be considered a valid beacon.
const int kBluetoothMinRssi = -80;

/// BLE scan duration in seconds.
const int kBleScanDurationSeconds = 5;

// ---------------------------------------------------------------------------
// Log tag
// ---------------------------------------------------------------------------

/// Tag used with `developer.log` throughout the package.
const String kLogName = 'HybridLocation';
