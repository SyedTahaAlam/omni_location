package com.hybrid_location

import android.content.Context
import android.net.wifi.WifiManager

/**
 * Scans for nearby Wi-Fi access points using [WifiManager].
 *
 * On Android 10+ the legacy [WifiManager.startScan] is deprecated and may
 * be throttled; this implementation falls back gracefully by returning the
 * last cached scan results when a fresh scan cannot be started.
 */
class WifiScanner(private val context: Context) {

    private val wifiManager: WifiManager? by lazy {
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
    }

    /**
     * Returns whether Wi-Fi is currently enabled on the device.
     */
    fun isWifiEnabled(): Boolean = wifiManager?.isWifiEnabled ?: false

    /**
     * Triggers a Wi-Fi scan and returns the results.
     *
     * Each result is a [Map] with keys:
     * - `bssid`  — MAC address of the access point
     * - `ssid`   — network name (may be empty on Android 10+)
     * - `level`  — signal strength in dBm
     *
     * Returns an empty list when Wi-Fi is disabled or the scan fails.
     */
    fun scan(): List<Map<String, Any>> {
        val mgr = wifiManager ?: return emptyList()
        if (!mgr.isWifiEnabled) return emptyList()

        // startScan() is deprecated but there is no synchronous replacement.
        // Results may be from the last cached scan — still useful for
        // geolocation purposes.
        @Suppress("DEPRECATION")
        mgr.startScan()

        return mgr.scanResults?.map { result ->
            mapOf(
                "bssid" to result.BSSID,
                "ssid" to result.SSID,
                "level" to result.level,
            )
        } ?: emptyList()
    }
}
