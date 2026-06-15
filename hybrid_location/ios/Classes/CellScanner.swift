import Foundation
import CoreTelephony

/**
 * Utility for checking cellular availability on iOS.
 *
 * Note: CoreTelephony does not provide a public API for enumerating
 * neighbour cells. Only the serving cell's radio technology is available
 * via `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology`.
 */
class CellScanner {

    /// Returns `true` when the device has at least one active cellular radio.
    static func isCellAvailable() -> Bool {
        let info = CTTelephonyNetworkInfo()
        if let serviceMap = info.serviceCurrentRadioAccessTechnology {
            return !serviceMap.isEmpty
        }
        return false
    }
}
