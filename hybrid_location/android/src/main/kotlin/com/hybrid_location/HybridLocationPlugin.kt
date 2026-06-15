package com.hybrid_location

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android implementation of the hybrid_location Flutter plugin.
 *
 * Exposes a [MethodChannel] named `hybrid_location` with the following
 * callable methods:
 *
 * | Method            | Return type        | Description                        |
 * |-------------------|--------------------|------------------------------------|
 * | scanWifi          | List<Map>          | Visible Wi-Fi APs (bssid/ssid/level)|
 * | scanCells         | List<Map>          | Visible cell towers (cid/lac/…)    |
 * | isWifiEnabled     | Boolean            | Whether Wi-Fi adapter is on        |
 * | isCellAvailable   | Boolean            | Whether a SIM card is ready        |
 */
class HybridLocationPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var wifiScanner: WifiScanner? = null
    private var cellScanner: CellScanner? = null

    // -------------------------------------------------------------------------
    // FlutterPlugin lifecycle
    // -------------------------------------------------------------------------

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        wifiScanner = WifiScanner(binding.applicationContext)
        cellScanner = CellScanner(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        wifiScanner = null
        cellScanner = null
    }

    // -------------------------------------------------------------------------
    // MethodCallHandler
    // -------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanWifi" -> {
                val aps = wifiScanner?.scan() ?: emptyList<Map<String, Any>>()
                result.success(aps)
            }
            "scanCells" -> {
                val cells = cellScanner?.scan() ?: emptyList<Map<String, Any>>()
                result.success(cells)
            }
            "isWifiEnabled" -> {
                result.success(wifiScanner?.isWifiEnabled() ?: false)
            }
            "isCellAvailable" -> {
                result.success(cellScanner?.isCellAvailable() ?: false)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        private const val CHANNEL_NAME = "hybrid_location"
    }
}
