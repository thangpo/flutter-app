import UIKit
import Flutter
import Firebase
import GoogleMaps
import flutter_downloader
import FBSDKCoreKit
import FBSDKLoginKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {

    // Firebase
    FirebaseApp.configure()

    // Google Maps (bật nếu bạn có API key)
    // GMSServices.provideAPIKey("YOUR_MAP_KEY_HERE")

    // Flutter plugin auto-registrant
    GeneratedPluginRegistrant.register(with: self)

    // Flutter Downloader
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - FlutterDownloader plugin registrant (yêu cầu bởi flutter_downloader)
private func registerPlugins(registry: FlutterPluginRegistry) {
  if !registry.hasPlugin("FlutterDownloaderPlugin") {
    FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
  }
}

