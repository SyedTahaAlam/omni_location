import Flutter
import UIKit
import CoreTelephony
import Network

/**
 * iOS implementation of the hybrid_location Flutter plugin.
 *
 * Implements the `hybrid_location` MethodChannel with the following methods:
 *
 * | Method           | Return type | Notes                                       |
 * |------------------|-------------|---------------------------------------------|
 * | scanWifi         | [[String: Any]] | Always returns [] — requires entitlement  |
 * | scanCells        | [[String: Any]] | Always returns [] — no public API         |
 * | isWifiEnabled    | Bool        | Checked via NWPathMonitor                   |
 * | isCellAvailable  | Bool        | Checked via CTTelephonyNetworkInfo          |
 *
 * - Wi-Fi scanning: Reading nearby access-point BSSIDs requires the
 *   "Access WiFi Information" entitlement granted by Apple. Without it,
 *   CNCopyCurrentNetworkInfo returns nil and startScan is unavailable.
 *   The IP fallback is used on iOS in most cases.
 *
 * - Cell neighbour scanning: There is no public CoreTelephony API for
 *   enumerating neighbour cells. Only the serving cell's radio technology
 *   is available. The IP fallback is used on iOS.
 */
@objc class HybridLocationPlugin: NSObject, FlutterPlugin {

    private static let channelName = "hybrid_location"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = HybridLocationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "scanWifi":
            // Wi-Fi scanning requires the "Access WiFi Information" entitlement.
            // Without the entitlement, CNCopyCurrentNetworkInfo returns nil and
            // no BSSID list is available. Return empty to trigger IP fallback.
            result([])

        case "scanCells":
            // CoreTelephony does not expose a public API for neighbour cell
            // information. Return empty to trigger IP fallback.
            result([])

        case "isWifiEnabled":
            result(WifiScanner.isWifiEnabled())

        case "isCellAvailable":
            result(CellScanner.isCellAvailable())

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
