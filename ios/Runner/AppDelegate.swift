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

  public func pushRegistry(_ registry: PKPushRegistry,
                           didUpdate pushCredentials: PKPushCredentials,
                           for type: PKPushType) {
    let tokenData = pushCredentials.token
    let deviceToken = tokenData.map { String(format: "%02x", $0) }.joined()

    // (1) Báo token VoIP cho plugin như doc yêu cầu
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)

    // (2) Nếu có accessToken thì upload về server của bạn
    if let accessToken = UserDefaults.standard.string(forKey: "socialAccessToken"),
       !accessToken.isEmpty,
       let url = URL(string: "https://social.vnshop247.com/api/v2/endpoints/pushkit.php") {
      var req = URLRequest(url: url)
      req.httpMethod = "POST"
      let body = "access_token=\(accessToken)&pushkit_token=\(deviceToken)"
      req.httpBody = body.data(using: .utf8)
      req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      URLSession.shared.dataTask(with: req) { _, resp, err in
        if let err = err {
          print("pushkit upload error: \(err)")
          return
        }
        if let http = resp as? HTTPURLResponse {
          print("pushkit upload status=\(http.statusCode)")
        }
      }.resume()
    } else {
      print("PushKit token: \(deviceToken)")
    }
  }

  public func pushRegistry(_ registry: PKPushRegistry,
                           didInvalidatePushTokenFor type: PKPushType) {
    print("PushKit token invalidated")
    // clear token trong plugin
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  public func pushRegistry(_ registry: PKPushRegistry,
                           didReceiveIncomingPushWith payload: PKPushPayload,
                           for type: PKPushType,
                           completion: @escaping () -> Void) {

    // Lấy payload
    let raw = payload.dictionaryPayload["data"] as? [AnyHashable: Any] ?? payload.dictionaryPayload
    var dataDict: [String: Any] = [:]
    raw.forEach { key, value in dataDict["\(key)"] = value }

    // Map sang model Data của plugin
    let callId = (dataDict["call_id"] as? String) ?? UUID().uuidString
    let callerName = (dataDict["caller_name"] as? String) ?? "Incoming call"
    let handle = (dataDict["caller_name"] as? String) ?? "Caller"
    let isVideo = ((dataDict["media"] as? String) == "video")

    // Tạo đối tượng Data (đến từ module flutter_callkit_incoming)
    let callData = flutter_callkit_incoming.Data(
      id: callId,
      nameCaller: callerName,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    callData.avatar = dataDict["caller_avatar"] as? String ?? ""
    callData.extra = dataDict as NSDictionary

    // Gọi CallKit
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)

    // Hoàn tất
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      completion()
    }
  }
}
