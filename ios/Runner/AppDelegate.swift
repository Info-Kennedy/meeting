import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register Twilio Video SDK plugin after Flutter engine is initialized
    // The plugin registration will handle platform view factory registration internally
    let controller = window?.rootViewController as? FlutterViewController
    if let registrar = controller?.engine?.registrar(forPlugin: "TwilioSdkPlugin") {
      TwilioSdkPlugin.register(with: registrar)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
