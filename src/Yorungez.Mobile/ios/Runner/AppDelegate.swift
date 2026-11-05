import Flutter
import UIKit
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pose: YorungezPose?
  private var screenAwake: YorungezScreenAwake?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    FlutterMethodChannel(name: "yorungez/time", binaryMessenger: engineBridge.applicationRegistrar.messenger())
      .setMethodCallHandler { call, result in
        if call.method == "zone" { result(TimeZone.current.identifier) }
        else { result(FlutterMethodNotImplemented) }
      }
    let stream = YorungezPose()
    pose = stream
    FlutterEventChannel(name: "yorungez/pose",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()).setStreamHandler(stream)
    screenAwake = YorungezScreenAwake(messenger: engineBridge.applicationRegistrar.messenger())
  }
}

final class YorungezScreenAwake {
  private let channel: FlutterMethodChannel
  private var requested = false
  private var observers: [NSObjectProtocol] = []

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "yorungez/screen", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setEnabled" else { result(FlutterMethodNotImplemented); return }
      guard let enabled = call.arguments as? Bool else {
        result(FlutterError(code: "invalid_screen_state", message: "Expected a boolean", details: nil)); return
      }
      self?.requested = enabled
      self?.apply()
      result(nil)
    }
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification,
      object: nil, queue: .main) { _ in UIApplication.shared.isIdleTimerDisabled = false })
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
      object: nil, queue: .main) { [weak self] _ in self?.apply() })
  }

  private func apply() {
    UIApplication.shared.isIdleTimerDisabled = requested && UIApplication.shared.applicationState == .active
  }

  deinit {
    channel.setMethodCallHandler(nil)
    for observer in observers { NotificationCenter.default.removeObserver(observer) }
    UIApplication.shared.isIdleTimerDisabled = false
  }
}

final class YorungezPose: NSObject, FlutterStreamHandler {
  private let motion = CMMotionManager()
  private var sink: FlutterEventSink?
  private var observer: NSObjectProtocol?

  override init() {
    super.init()
    observer = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification,
      object: nil, queue: .main) { [weak self] _ in self?.stop() }
  }
  deinit {
    motion.stopDeviceMotionUpdates()
    if let observer = observer { NotificationCenter.default.removeObserver(observer) }
  }
  private func stop() { motion.stopDeviceMotionUpdates(); sink = nil }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    stop()
    guard motion.isDeviceMotionAvailable else {
      return FlutterError(code: "pose_unavailable", message: "Device motion unavailable", details: nil)
    }
    let frames = CMMotionManager.availableAttitudeReferenceFrames()
    let trueNorth = frames.contains(.xTrueNorthZVertical)
    guard trueNorth || frames.contains(.xMagneticNorthZVertical) else {
      return FlutterError(code: "pose_unavailable", message: "North reference unavailable", details: nil)
    }
    sink = events
    motion.deviceMotionUpdateInterval = 1.0 / 50.0
    motion.showsDeviceMovementDisplay = true
    motion.startDeviceMotionUpdates(using: trueNorth ? .xTrueNorthZVertical : .xMagneticNorthZVertical,
      to: .main) { [weak self] data, error in
      guard let self = self, let sink = self.sink else { return }
      guard error == nil, let data = data else {
        sink(FlutterError(code: "pose_unavailable", message: "Orientation unavailable", details: nil))
        self.stop(); return
      }
      let r = data.attitude.rotationMatrix
      // Core Motion NWU reference-to-device matrix, transposed then NWU->ENU.
      let enu = [-r.m12, -r.m22, -r.m32, r.m11, r.m21, r.m31, r.m13, r.m23, r.m33]
      let interface = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.interfaceOrientation
      let rotation: Int
      switch interface {
      case .landscapeLeft: rotation = 90
      case .landscapeRight: rotation = 270
      case .portraitUpsideDown: rotation = 180
      default: rotation = 0
      }
      let age = ProcessInfo.processInfo.systemUptime - data.timestamp
      guard age >= 0 && age < 2 else { return }
      sink(["matrix": enu, "rotation": rotation, "reference": trueNorth ? "true" : "magnetic",
        "quality": data.magneticField.accuracy.rawValue + 1,
        "timestampMs": Date().timeIntervalSince1970 * 1000 - age * 1000])
    }
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { stop(); return nil }
}
