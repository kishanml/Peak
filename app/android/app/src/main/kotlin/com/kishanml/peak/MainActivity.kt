package com.kishanml.peak

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.kishanml.peak/timer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "beep") {
                val toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 100)
                toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP, 180)
                result.success(null)
                return@setMethodCallHandler
            }

            result.notImplemented()
        }
    }
}
