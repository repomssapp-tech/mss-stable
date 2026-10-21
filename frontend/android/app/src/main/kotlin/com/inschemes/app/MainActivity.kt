package com.inschemes.app

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.view.accessibility.AccessibilityManager
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var voiceAccessibility: MethodChannel? = null
    private var automaticSpeechBridge: AutomaticSpeechBridge? = null
    private var speechOutputBridge: SpeechOutputBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        voiceAccessibility = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.inschemes.app/voice_accessibility",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "screenReaderEnabled") {
                    result.notImplemented()
                } else {
                    val manager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
                    result.success(manager.isEnabled && (
                        manager.isTouchExplorationEnabled || manager.getEnabledAccessibilityServiceList(
                            AccessibilityServiceInfo.FEEDBACK_SPOKEN,
                        ).isNotEmpty()
                    ))
                }
            }
        }
        automaticSpeechBridge = AutomaticSpeechBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
        speechOutputBridge = SpeechOutputBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        voiceAccessibility?.setMethodCallHandler(null)
        voiceAccessibility = null
        automaticSpeechBridge?.dispose()
        automaticSpeechBridge = null
        speechOutputBridge?.dispose()
        speechOutputBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
