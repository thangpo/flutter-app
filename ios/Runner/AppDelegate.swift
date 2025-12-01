import UIKit
import Flutter
import Firebase
import GoogleMaps
import flutter_downloader
import FBSDKCoreKit
import FBSDKLoginKit
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

  var pushRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    // GMSServices.provideAPIKey("YOUR_MAP_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)

    // PushKit (VoIP) init
    initPushKit()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
  if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
    FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
  }
}

// MARK: - PushKit
extension AppDelegate {
  func initPushKit() {
    pushRegistry = PKPushRegistry(queue: .main)
    pushRegistry?.delegate = self
    pushRegistry?.desiredPushTypes = [.voIP]
  }

  public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    let tokenData = pushCredentials.token
    let token = tokenData.map { String(format: "%02x", $0) }.joined()
    // Upload PushKit token
    if let accessToken = UserDefaults.standard.string(forKey: "socialAccessToken"),
       !accessToken.isEmpty,
       let url = URL(string: "https://social.vnshop247.com/api/v2/endpoints/pushkit.php") {
      var req = URLRequest(url: url)
      req.httpMethod = "POST"
      let body = "access_token=\(accessToken)&pushkit_token=\(token)"
      req.httpBody = body.data(using: .utf8)
      req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      URLSession.shared.dataTask(with: req) { _, resp, err in
        if let err = err {
          print("📞 pushkit upload error: \(err)")
          return
        }
        if let http = resp as? HTTPURLResponse {
          print("📞 pushkit upload status=\(http.statusCode)")
        }
      }.resume()
    } else {
      print("📞 PushKit token: \(token)")
    }
  }

  public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    print("📞 PushKit token invalidated")
  }

  public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    let raw = payload.dictionaryPayload["data"] as? [AnyHashable: Any] ?? payload.dictionaryPayload
    var data: [String: Any] = [:]
    raw.forEach { key, value in
      data["\(key)"] = value
    }
    let params: [String: Any] = [
      "id": "\(data["call_id"] ?? UUID().uuidString)",
      "nameCaller": (data["caller_name"] as? String) ?? "Incoming call",
      "avatar": data["caller_avatar"] ?? "",
      "handle": (data["caller_name"] as? String) ?? "Caller",
      "type": (data["media"] as? String) == "video" ? 1 : 0,
      "extra": data
    ]
    FlutterCallkitIncoming.showCallkitIncoming(params)
    completion()
  }
}
