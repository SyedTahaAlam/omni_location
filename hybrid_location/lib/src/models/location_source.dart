/// Enumerates the possible sources of a location fix.
enum LocationSource {
  /// Location determined from nearby Wi-Fi access points.
  wifi,

  /// Location determined from cellular tower data.
  cellTower,

  /// Location determined from the device's public IP address.
  ip,

  /// Location determined from Bluetooth BLE beacons.
  bluetooth,

  /// Source could not be determined.
  unknown,
}
