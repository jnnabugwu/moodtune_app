import Flutter
import UIKit
#if canImport(FoundationModels)
import FoundationModels
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MoodNarration") {
      MoodNarrationChannel.register(with: registrar.messenger())
    }
  }
}

/// Bridges Dart's `moodtune/narration` channel to Apple's on-device
/// Foundation Models. The model only narrates a mood the classifier already
/// chose; Dart validates the output and falls back to template copy.
enum MoodNarrationChannel {
  static let instructions = """
    You tell a listener, in one or two sentences under 50 words, what a song \
    feels like and why. Speak about the song itself, starting with "This track". \
    Name the mood word you are given and explain it using only the sound facts. \
    Never mention an app, an analysis, a classification, confidence or scores. \
    Never mention lyrics, vocals, genre, the artist, or anything not in the facts. \
    Always answer in English.

    Example facts: The mood is upbeat, which means happy and energetic. The song \
    is fast, at 128 BPM. It has high energy, a bright tone and a smooth, flowing \
    sound. It can be described as danceable and lively.

    Example answer: This track feels upbeat: a fast 128 BPM pulse, high energy \
    and a bright, flowing sound make it lively and easy to dance to.
    """

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "moodtune/narration", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isAvailable":
        result(isAvailable())
      case "narrate":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "Expected a map", details: nil))
          return
        }
        narrate(args, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  static func isAvailable() -> Bool {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      if case .available = SystemLanguageModel.default.availability { return true }
    }
    #endif
    return false
  }

  static func narrate(_ args: [String: Any], result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      Task {
        do {
          let session = LanguageModelSession(instructions: instructions)
          let response = try await session.respond(
            to: prompt(from: args),
            options: GenerationOptions(temperature: 0.4)
          )
          await MainActor.run { result(response.content) }
        } catch {
          await MainActor.run {
            result(FlutterError(
              code: "generation_failed",
              message: error.localizedDescription,
              details: diagnostics(for: error)
            ))
          }
        }
      }
      return
    }
    #endif
    result(FlutterError(code: "unavailable", message: "On-device model unavailable", details: nil))
  }

  #if canImport(FoundationModels)
  /// Context for failures such as `unsupportedLanguageOrLocale`, logged by Dart.
  @available(iOS 26.0, *)
  static func diagnostics(for error: Error) -> String {
    let locale = Locale.current
    return [
      "error=\(String(describing: error))",
      "locale=\(locale.identifier)",
      "supportsLocale=\(SystemLanguageModel.default.supportsLocale(locale))",
      "preferredLanguages=\(Locale.preferredLanguages.prefix(3))",
      "appLocalization=\(Bundle.main.preferredLocalizations.first ?? "none")",
    ].joined(separator: " ")
  }
  #endif

  /// Only structured classifier output goes to the model: no title, artist,
  /// filename or other user-supplied text. Facts arrive pre-phrased from Dart
  /// (see `NarrationInput`) and are written as plain sentences; a terse
  /// key/value list once failed with `unsupportedLanguageOrLocale`.
  static func prompt(from args: [String: Any]) -> String {
    func text(_ key: String) -> String { args[key] as? String ?? "unknown" }
    let tempo = args["tempo"] as? Int ?? 0
    let descriptors = (args["descriptors"] as? [String] ?? []).joined(separator: ", ")
    return "The mood is \(text("mood")), which means \(text("moodSummary")). "
      + "The song is \(text("tempoFeel")), at \(tempo) BPM. "
      + "It has \(text("energy")), \(text("tone")) and \(text("texture")). "
      + "It can be described as \(descriptors)."
  }
}
