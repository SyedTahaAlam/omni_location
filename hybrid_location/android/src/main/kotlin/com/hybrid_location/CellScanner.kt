package com.hybrid_location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.telephony.*
import androidx.core.content.ContextCompat

/**
 * Scans for nearby cell towers using [TelephonyManager.getAllCellInfo].
 *
 * Handles [CellInfoLte], [CellInfoGsm], and [CellInfoWcdma] record types.
 * Returns an empty list on [SecurityException] (permission not granted).
 */
class CellScanner(private val context: Context) {

    private val telephonyManager: TelephonyManager? by lazy {
        context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
    }

    /**
     * Returns whether cellular data is available on this device.
     */
    fun isCellAvailable(): Boolean {
        val tm = telephonyManager ?: return false
        return tm.simState == TelephonyManager.SIM_STATE_READY
    }

    /**
     * Returns cell information for all visible cells.
     *
     * Each result is a [Map] with keys:
     * - `cid`  — cell identifier
     * - `lac`  — location area code
     * - `mcc`  — mobile country code
     * - `mnc`  — mobile network code
     * - `rssi` — signal strength in dBm (may be [Int.MIN_VALUE] if unavailable)
     */
    fun scan(): List<Map<String, Any>> {
        val tm = telephonyManager ?: return emptyList()

        // READ_PHONE_STATE is required to call getAllCellInfo.
        if (ContextCompat.checkSelfPermission(
                context, Manifest.permission.READ_PHONE_STATE
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return emptyList()
        }

        return try {
            val cells: List<CellInfo> = tm.allCellInfo ?: return emptyList()
            cells.mapNotNull { cellInfo ->
                when (cellInfo) {
                    is CellInfoLte -> {
                        val id = cellInfo.cellIdentity as CellIdentityLte
                        val signal = cellInfo.cellSignalStrength as CellSignalStrengthLte
                        mapOf(
                            "cid" to id.ci,
                            "lac" to id.tac,
                            "mcc" to (id.mccString?.toIntOrNull() ?: 0),
                            "mnc" to (id.mncString?.toIntOrNull() ?: 0),
                            "rssi" to signal.dbm,
                        )
                    }
                    is CellInfoGsm -> {
                        val id = cellInfo.cellIdentity as CellIdentityGsm
                        val signal = cellInfo.cellSignalStrength as CellSignalStrengthGsm
                        mapOf(
                            "cid" to id.cid,
                            "lac" to id.lac,
                            "mcc" to (id.mccString?.toIntOrNull() ?: 0),
                            "mnc" to (id.mncString?.toIntOrNull() ?: 0),
                            "rssi" to signal.dbm,
                        )
                    }
                    is CellInfoWcdma -> {
                        val id = cellInfo.cellIdentity as CellIdentityWcdma
                        val signal = cellInfo.cellSignalStrength as CellSignalStrengthWcdma
                        mapOf(
                            "cid" to id.cid,
                            "lac" to id.lac,
                            "mcc" to (id.mccString?.toIntOrNull() ?: 0),
                            "mnc" to (id.mncString?.toIntOrNull() ?: 0),
                            "rssi" to signal.dbm,
                        )
                    }
                    else -> null
                }
            }
        } catch (e: SecurityException) {
            emptyList()
        }
    }
}
