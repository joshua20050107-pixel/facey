import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let hapticChannelName = "facey/haptics"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let hapticChannel = FlutterMethodChannel(
        name: hapticChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      hapticChannel.setMethodCallHandler { [weak self] call, result in
        self?.handleHapticMethodCall(call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func handleHapticMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "softImpact" else {
      result(FlutterMethodNotImplemented)
      return
    }

    DispatchQueue.main.async {
      if #available(iOS 13.0, *) {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
      } else {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
      }
      result(nil)
    }
  }
}
