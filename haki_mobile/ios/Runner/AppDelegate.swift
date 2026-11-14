import Flutter
import NaturalLanguage
import PushKit
import Speech
import flutter_callkit_incoming
import Translation
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PKPushRegistryDelegate {
  private var pushChannel: FlutterMethodChannel?
  private var voipRegistry: PKPushRegistry?
  /// Chat from a tapped notification, kept until Dart asks (it may not be listening yet on a cold start).
  private var pendingChat: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    // VoIP pushes ring through CallKit even when Haki is closed
    let voip = PKPushRegistry(queue: .main)
    voip.delegate = self
    voip.desiredPushTypes = [.voIP]
    voipRegistry = voip
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(credentials.token.map { String(format: "%02x", $0) }.joined())
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  /// iOS requires every VoIP push to show a call right away. The push has no names (like all
  /// Haki pushes); the app fills in who is calling once it connects and gets the offer.
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    let chat = payload.dictionaryPayload["chat"] as? [String: Any] ?? [:]
    let data = flutter_callkit_incoming.Data(id: UUID().uuidString, nameCaller: "Haki", handle: "Incoming call", type: 0)
    data.appName = "Haki"
    data.extra = chat as NSDictionary
    data.supportsVideo = true
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { completion() }
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Foundation.Data) {
    pushChannel?.invokeMethod("token", arguments: deviceToken.map { String(format: "%02x", $0) }.joined())
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    pushChannel?.invokeMethod("error", arguments: error.localizedDescription)
  }

  // Haki is on screen: the live connection already shows the message, so no banner
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let chat = response.notification.request.content.userInfo["chat"] as? [String: Any] ?? [:]
    pendingChat = chat
    pushChannel?.invokeMethod("open", arguments: chat)
    completionHandler()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HakiTranscriber") else { return }
    let push = FlutterMethodChannel(name: "haki/push", binaryMessenger: registrar.messenger())
    pushChannel = push
    push.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "register":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
          DispatchQueue.main.async {
            if granted { UIApplication.shared.registerForRemoteNotifications() }
            result(granted)
          }
        }
      case "takePendingChat":
        result(self?.pendingChat)
        self?.pendingChat = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    let channel = FlutterMethodChannel(name: "haki/transcribe", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "transcribe",
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else { return result(FlutterMethodNotImplemented) }
      HakiTranscriber.shared.transcribe(path: path, result: result)
    }
    let translate = FlutterMethodChannel(name: "haki/translate", binaryMessenger: registrar.messenger())
    translate.setMethodCallHandler { call, result in
      guard call.method == "translate", let text = (call.arguments as? [String: Any])?["text"] as? String
      else { return result(FlutterMethodNotImplemented) }
      HakiTranslator.translate(text, result: result)
    }
  }
}

/// Message → your language with Apple's on-device Translation models. Text never leaves the phone.
enum HakiTranslator {
  static func translate(_ text: String, result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *) else {
      return result(FlutterError(code: "unavailable", message: "Translation needs iOS 26 or later.", details: nil))
    }
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    guard let detected = recognizer.dominantLanguage, detected != .undetermined else {
      return result(FlutterError(code: "unknown", message: "Couldn’t tell which language this is.", details: nil))
    }
    let source = Locale.Language(identifier: detected.rawValue)
    let target = Locale.current.language
    let fromName = Locale.current.localizedString(forLanguageCode: detected.rawValue) ?? detected.rawValue
    if source.languageCode == target.languageCode {
      return result(FlutterError(code: "same", message: "This is already in your language.", details: nil))
    }
    Task { @MainActor in
      switch await LanguageAvailability().status(from: source, to: target) {
      case .installed:
        do {
          let session = TranslationSession(installedSource: source, target: target)
          let response = try await session.translate(text)
          result(["text": response.targetText, "from": fromName])
        } catch {
          result(FlutterError(code: "failed", message: "Couldn’t translate this on the phone.", details: error.localizedDescription))
        }
      case .supported:
        result(FlutterError(code: "download", message: "Download \(fromName) in Settings → Apps → Translate → Languages, then try again. Translation runs on this phone only.", details: nil))
      default:
        result(FlutterError(code: "unsupported", message: "\(fromName) can’t be translated on this phone yet.", details: nil))
      }
    }
  }
}

/// Voice note → text entirely on the phone. Refuses rather than sending audio to a server.
final class HakiTranscriber {
  static let shared = HakiTranscriber()
  private var task: SFSpeechRecognitionTask?

  func transcribe(path: String, result: @escaping FlutterResult) {
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        guard status == .authorized else {
          return result(FlutterError(code: "denied", message: "Allow speech recognition in Settings to transcribe.", details: nil))
        }
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
          return result(FlutterError(code: "unavailable", message: "On-device transcription isn’t available for this language on this phone.", details: nil))
        }
        let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: path))
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        var answered = false
        self.task = recognizer.recognitionTask(with: request) { res, error in
          DispatchQueue.main.async {
            guard !answered else { return }
            if let res = res, res.isFinal {
              answered = true
              result(res.bestTranscription.formattedString)
            } else if let error = error {
              answered = true
              result(FlutterError(code: "failed", message: "Couldn’t turn this voice message into text on this phone.", details: error.localizedDescription))
            }
          }
        }
      }
    }
  }
}
