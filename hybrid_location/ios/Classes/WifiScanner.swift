import Foundation
import Network

/**
 * Utility for checking Wi-Fi connectivity on iOS.
 *
 * Full AP scanning (BSSID enumeration) requires the "Access WiFi Information"
 * entitlement from Apple. Without that entitlement this class can only report
 * whether a Wi-Fi path exists — it cannot return a list of access points.
 */
class WifiScanner {

    /// Returns `true` when an active Wi-Fi network interface is available.
    ///
    /// Uses `NWPathMonitor` with a `.wifi` interface constraint to perform
    /// a synchronous check.
    static func isWifiEnabled() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isWifi = false

        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor.pathUpdateHandler = { path in
            isWifi = path.status == .satisfied
            semaphore.signal()
        }
        let queue = DispatchQueue(label: "com.hybrid_location.wifi_check")
        monitor.start(queue: queue)

        // Wait up to 1 second for the path status to be delivered.
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()

        return isWifi
    }
}
