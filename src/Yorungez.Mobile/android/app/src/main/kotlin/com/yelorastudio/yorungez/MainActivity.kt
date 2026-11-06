package com.yelorastudio.yorungez

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.SystemClock
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), SensorEventListener, EventChannel.StreamHandler {
    private lateinit var sensors: SensorManager
    private var sink: EventChannel.EventSink? = null
    private var accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
    private var lastTimestamp = 0L
    private var keepScreenRequested = false
    private var activityResumed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yorungez/time")
            .setMethodCallHandler { call, result ->
                if (call.method == "zone") result.success(java.util.TimeZone.getDefault().id)
                else result.notImplemented()
            }
        sensors = getSystemService(SENSOR_SERVICE) as SensorManager
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yorungez/pose-capabilities")
            .setMethodCallHandler { call, result ->
                if (call.method == "get") result.success(mapOf("supported" to (orientationSensor() != null)))
                else result.notImplemented()
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "yorungez/pose")
            .setStreamHandler(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yorungez/screen")
            .setMethodCallHandler { call, result ->
                if (call.method != "setEnabled") {
                    result.notImplemented()
                } else if (call.arguments !is Boolean) {
                    result.error("invalid_screen_state", "Expected a boolean", null)
                } else {
                    keepScreenRequested = call.arguments as Boolean
                    applyScreenAwake()
                    result.success(null)
                }
            }
    }

    private fun applyScreenAwake() {
        if (activityResumed && keepScreenRequested) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    override fun onResume() {
        super.onResume()
        activityResumed = true
        applyScreenAwake()
    }

    private fun orientationSensor(): Sensor? =
        sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
            ?: sensors.getDefaultSensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sensors.unregisterListener(this)
        sink = events
        lastTimestamp = 0L
        accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
        val sensor = orientationSensor()
        if (sensor == null) {
            sink = null
            events.error("pose_unsupported", "North-referenced orientation unsupported", null)
        } else if (!sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)) {
            sink = null
            events.error("pose_unavailable", "North-referenced orientation unavailable", null)
        }
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        sink = null
    }

    override fun onAccuracyChanged(sensor: Sensor?, value: Int) { accuracy = value }

    override fun onSensorChanged(event: SensorEvent) {
        val target = sink ?: return
        if (event.timestamp <= lastTimestamp) return
        val age = (SystemClock.elapsedRealtimeNanos() - event.timestamp) / 1000000.0
        if (age < 0 || age > 2000) return
        val rotation = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(rotation, event.values)
        if (rotation.any { !it.isFinite() }) return
        lastTimestamp = event.timestamp
        @Suppress("DEPRECATION")
        val displayRotation = windowManager.defaultDisplay.rotation * 90
        // Android rotation-vector world axes are East / magnetic North / Up.
        // Do not silently apply an expired/unknown platform geomagnetic model.
        target.success(mapOf(
            "matrix" to rotation.map { it.toDouble() },
            "rotation" to displayRotation,
            "reference" to "magnetic",
            "quality" to accuracy,
            "timestampMs" to (System.currentTimeMillis() - age),
            "headingAccuracyDegrees" to if (event.values.size > 4 && event.values[4] >= 0)
                Math.toDegrees(event.values[4].toDouble()) else null
        ))
    }

    override fun onPause() {
        activityResumed = false
        applyScreenAwake()
        if (::sensors.isInitialized) sensors.unregisterListener(this)
        sink = null
        super.onPause()
    }
}
