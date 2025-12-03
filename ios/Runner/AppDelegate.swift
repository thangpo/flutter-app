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

  // MARK: - Properties
  private var pushRegistry: PKPushRegistry?

  // MARK: - App lifecycle
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

    // PushKit (VoIP)
    initPushKit()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - PushKit setup
  private func initPushKit() {
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    self.pushRegistry = registry
    print("[PUSHKIT] init done (desiredPushTypes=.voIP, iOS \(UIDevice.current.systemVersion))")
  }

  // MARK: - PKPushRegistryDelegate

  /// VoIP token cập nhật (app cài lần đầu / token rotate)
  public func pushRegistry(_ registry: PKPushRegistry,
                           didUpdate pushCredentials: PKPushCredentials,
                           for type: PKPushType) {
    let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
    guard deviceToken.range(of: "^[0-9a-f]+$", options: .regularExpression) != nil else {
      print("[PUSHKIT] invalid hex token: \(deviceToken)")
      return
    }

    // (1) Đưa token cho plugin (flutter_callkit_incoming)
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)

    // Log token để kiểm tra
    print("[PUSHKIT] deviceToken=\(deviceToken)")

    // (2) Đọc access token do Flutter lưu (shared_preferences prefix "flutter.")
    let storedAccessToken = UserDefaults.standard.string(forKey: "flutter.social_access_token")
    print("[PUSHKIT] flutter.social_access_token=\(storedAccessToken ?? "nil")")

    // (3) Upload token lên server nếu có access token
    guard
      let accessToken = storedAccessToken, !accessToken.isEmpty,
      let url = URL(string: "https://social.vnshop247.com/api/pushkit")
    else {
      // Chưa đăng nhập hoặc chưa có token → chỉ log
      return
    }

    // Build body x-www-form-urlencoded với percent-encode an toàn
    var comps = URLComponents()
    // server_key đọc từ Info.plist (SOCIAL_SERVER_KEY) để tránh hardcode trong mã
    let serverKey = (Bundle.main.object(forInfoDictionaryKey: "SOCIAL_SERVER_KEY") as? String) ?? ""
    if serverKey.isEmpty {
      print("[PUSHKIT] missing SOCIAL_SERVER_KEY in Info.plist")
      return
    }

    var items: [URLQueryItem] = [
      URLQueryItem(name: "server_key", value: serverKey),
      URLQueryItem(name: "access_token", value: accessToken),
      URLQueryItem(name: "pushkit_token", value: deviceToken),
    ]
#if DEBUG
    items.append(URLQueryItem(name: "apns_env", value: "sandbox"))
#else
    items.append(URLQueryItem(name: "apns_env", value: "prod"))
#endif
    comps.queryItems = items
    let bodyData = comps.percentEncodedQuery?.data(using: .utf8)

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.httpBody = bodyData
    req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: req) { data, resp, err in
      if let err = err {
        print("[PUSHKIT] upload error: \(err)")
        return
      }
      if let http = resp as? HTTPURLResponse {
        print("[PUSHKIT] upload status=\(http.statusCode)")
        if http.statusCode == 403 {
          print("[PUSHKIT] access_token invalid/expired -> skip, wait app refresh token")
        }
      }
      if let data = data, let s = String(data: data, encoding: .utf8) {
        print("[PUSHKIT] upload response=\(s)")
      }
    }.resume()
  }

  /// Token VoIP bị vô hiệu (hiếm khi gặp)
  public func pushRegistry(_ registry: PKPushRegistry,
                           didInvalidatePushTokenFor type: PKPushType) {
    print("[PUSHKIT] token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  /// Nhận VoIP push (kể cả khi app bị kill)
  public func pushRegistry(_ registry: PKPushRegistry,
                           didReceiveIncomingPushWith payload: PKPushPayload,
                           for type: PKPushType,
                           completion: @escaping () -> Void) {

    // Một số backend gửi data ở key "data", một số gửi thẳng ở root
    let raw = payload.dictionaryPayload["data"] as? [AnyHashable: Any] ?? payload.dictionaryPayload

    // Convert về [String: Any] cho chắc
    var dataDict: [String: Any] = [:]
    raw.forEach { key, value in dataDict["\(key)"] = value }

    print("[PUSHKIT] incoming payload=\(dataDict)")

    // Map sang model Data của plugin flutter_callkit_incoming
    let rawCallId  = (dataDict["call_id"] as? String) ?? UUID().uuidString
    let callId     = normalizeUuid(rawCallId)
    let callerName = (dataDict["caller_name"] as? String) ?? "Incoming call"
    let handle     = (dataDict["caller_handle"] as? String) ?? callerName
    let isVideo    = ((dataDict["media"] as? String) == "video")

    let callData = flutter_callkit_incoming.Data(
      id: callId,
      nameCaller: callerName,
      handle: handle,
      type: isVideo ? 1 : 0 // 0=audio, 1=video (theo plugin)
    )
    callData.avatar = dataDict["caller_avatar"] as? String ?? ""
    callData.extra  = dataDict as NSDictionary

    print("[CALLKIT] showCallkitIncoming id=\(callId) video=\(isVideo)")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)

    // Gọi completion hơi trễ để đảm bảo showCallkitIncoming đã dispatch xong
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      completion()
    }
  }
}

// MARK: - Helpers
/// Tạo UUID hợp lệ từ chuỗi bất kỳ (ổn định, không phụ thuộc hash ngẫu nhiên).
private func normalizeUuid(_ raw: String) -> String {
  if let u = UUID(uuidString: raw) {
    return u.uuidString.lowercased()
  }
  var bytes = [UInt8](repeating: 0, count: 16)
  let scalars = raw.isEmpty ? Array("callkit-empty".utf8) : Array(raw.utf8)
  for (idx, v) in scalars.enumerated() {
    let pos = idx % 16
    bytes[pos] = UInt8((Int(bytes[pos]) + Int(v) + idx) & 0xff)
  }
  let hex = bytes.map { String(format: "%02x", $0) }.joined()
  let parts = [
    String(hex.prefix(8)),
    String(hex.dropFirst(8).prefix(4)),
    String(hex.dropFirst(12).prefix(4)),
    String(hex.dropFirst(16).prefix(4)),
    String(hex.dropFirst(20).prefix(12))
  ]
  return parts.joined(separator: "-")
}

// MARK: - FlutterDownloader plugin registrant (yêu cầu bởi flutter_downloader)
private func registerPlugins(registry: FlutterPluginRegistry) {
  if !registry.hasPlugin("FlutterDownloaderPlugin") {
    FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
  }
}
