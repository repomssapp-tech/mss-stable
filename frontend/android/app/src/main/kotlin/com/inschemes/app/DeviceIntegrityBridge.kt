package com.inschemes.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address
import java.net.Inet6Address

/**
 * Reports what the app's security gate needs to decide whether MSS may run:
 * Developer options / USB debugging, an active VPN (and whether it looks like
 * an allowed one: Tailscale or AdGuard), and whether Wi-Fi is open (no
 * password) or behind a sign-in page.
 *
 * Android does not tell an app which app owns a VPN, so the allowed VPNs are
 * recognised by fingerprint: Tailscale by its 100.64.0.0/10 (or fd7a:115c:a1e0::/48)
 * tunnel addresses, AdGuard by being installed while the VPN is not Tailscale.
 */
class DeviceIntegrityBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "com.inschemes.app/device_integrity")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "report" -> result.success(report())
                "openSettings" -> result.success(openSettings(call.argument<String>("kind")))
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private fun report(): Map<String, Any?> {
        val resolver = activity.contentResolver
        val devOptions = Settings.Global.getInt(
            resolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0,
        ) == 1
        val adb = Settings.Global.getInt(resolver, Settings.Global.ADB_ENABLED, 0) == 1

        val cm = activity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        var vpnActive = false
        var vpnTailscale = false
        var wifiConnected = false
        var wifiOpen: Boolean? = null
        var wifiCaptive = false

        @Suppress("DEPRECATION")
        for (network in cm.allNetworks) {
            val caps = cm.getNetworkCapabilities(network) ?: continue
            if (caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                vpnActive = true
                if (isTailscale(cm.getLinkProperties(network))) vpnTailscale = true
                continue
            }
            if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                wifiConnected = true
                if (caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_CAPTIVE_PORTAL)) {
                    wifiCaptive = true
                }
                val open = wifiIsOpen(caps)
                if (open != null) wifiOpen = (wifiOpen ?: false) || open
            }
        }

        val adguardInstalled = isInstalled("com.adguard.android")
        val vpnKind = when {
            !vpnActive -> "none"
            vpnTailscale -> "tailscale"
            adguardInstalled -> "adguard"
            else -> "other"
        }

        return mapOf(
            "developerOptions" to devOptions,
            "usbDebugging" to adb,
            "vpnActive" to vpnActive,
            "vpnKind" to vpnKind,
            "wifiConnected" to wifiConnected,
            "wifiOpen" to wifiOpen,
            "wifiCaptivePortal" to wifiCaptive,
            "sdk" to Build.VERSION.SDK_INT,
        )
    }

    /** Tailscale gives every device a 100.64.0.0/10 address (and fd7a:115c:a1e0::/48). */
    private fun isTailscale(lp: LinkProperties?): Boolean {
        if (lp == null) return false
        for (la in lp.linkAddresses) {
            val a = la.address
            if (a is Inet4Address) {
                val b = a.address
                val first = b[0].toInt() and 0xff
                val second = b[1].toInt() and 0xff
                if (first == 100 && second in 64..127) return true
            } else if (a is Inet6Address) {
                val b = a.address
                if ((b[0].toInt() and 0xff) == 0xfd && (b[1].toInt() and 0xff) == 0x7a &&
                    (b[2].toInt() and 0xff) == 0x11 && (b[3].toInt() and 0xff) == 0x5c &&
                    (b[4].toInt() and 0xff) == 0xa1 && (b[5].toInt() and 0xff) == 0xe0
                ) {
                    return true
                }
            }
        }
        return false
    }

    /**
     * True for Wi-Fi with no password (open, or "enhanced open" OWE), false for
     * a secured one, null when Android does not say (before Android 12).
     */
    private fun wifiIsOpen(caps: NetworkCapabilities): Boolean? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        val info = caps.transportInfo as? WifiInfo ?: return null
        return when (info.currentSecurityType) {
            WifiInfo.SECURITY_TYPE_OPEN, WifiInfo.SECURITY_TYPE_OWE -> true
            WifiInfo.SECURITY_TYPE_UNKNOWN -> null
            else -> false
        }
    }

    private fun isInstalled(pkg: String): Boolean = try {
        @Suppress("DEPRECATION")
        activity.packageManager.getPackageInfo(pkg, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    /** Opens the settings page that fixes the problem; false when none opened. */
    private fun openSettings(kind: String?): Boolean {
        val action = when (kind) {
            "developer" -> Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS
            "vpn" -> Settings.ACTION_VPN_SETTINGS
            "wifi" -> Settings.ACTION_WIFI_SETTINGS
            else -> Settings.ACTION_SETTINGS
        }
        return try {
            activity.startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: ActivityNotFoundException) {
            try {
                activity.startActivity(Intent(Settings.ACTION_SETTINGS))
                true
            } catch (e2: ActivityNotFoundException) {
                false
            }
        }
    }
}
