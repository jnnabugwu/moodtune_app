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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AudioDecode") {
      AudioDecodeChannel.register(with: registrar.messenger())
    }
  }
}

/// Bridges Dart's `moodtune/audio_decode` channel to [AudioWindowDecoder].
/// Decoding runs off the main thread; windows go back as Float32List.
enum AudioDecodeChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "moodtune/audio_decode", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "decodeWindows" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String,
        let positions = (args["positions"] as? [NSNumber])?.map(\.doubleValue),
        let windowSeconds = (args["windowSeconds"] as? NSNumber)?.doubleValue,
        let sampleRate = (args["sampleRate"] as? NSNumber)?.doubleValue
      else {
        result(FlutterError(
          code: "bad_args",
          message: "Expected path, positions, windowSeconds and sampleRate",
          details: nil
        ))
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        let reply: Any
        do {
          let decoded = try AudioWindowDecoder(targetSampleRate: sampleRate).decode(
            url: URL(fileURLWithPath: path),
            positions: positions,
            windowSeconds: windowSeconds
          )
          reply = [
            "windows": decoded.windows.map { window in
              FlutterStandardTypedData(float32: window.withUnsafeBufferPointer { Data(buffer: $0) })
            },
            "startSeconds": decoded.startSeconds,
            "durationSeconds": decoded.durationSeconds,
            "sourceSampleRate": decoded.sourceSampleRate,
            "channelCount": decoded.channelCount,
          ] as [String: Any]
        } catch let error as AudioWindowDecoder.DecodeError {
          reply = FlutterError(code: error.code, message: error.message, details: nil)
        } catch {
          reply = FlutterError(code: "decode_failed", message: error.localizedDescription, details: nil)
        }
        DispatchQueue.main.async { result(reply) }
      }
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

  /// Close to the first instructions that generated on device. Used when the
  /// full instructions are rejected with `unsupportedLanguageOrLocale`.
  static let minimalInstructions = """
    You explain in plain language why a song has a certain mood. \
    Write one or two sentences, under 60 words, about the song itself. \
    Use only the facts provided and name the mood. \
    Do not mention lyrics, genre, the artist, or anything not in the facts.
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

  /// Used when Dart sends no `timeoutMs`; matches `MoodNarrator.timeout`.
  static let defaultTimeoutMs = 5000

  static func narrate(_ args: [String: Any], result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      let prompt = prompt(from: args)
      let timeout = Duration.milliseconds(args["timeoutMs"] as? Int ?? defaultTimeoutMs)
      Task {
        do {
          let narration = try await withDeadline(timeout) { try await generate(prompt) }
          await MainActor.run { result(narration) }
        } catch {
          await MainActor.run {
            result(FlutterError(
              code: error is DeadlineExceeded ? "timeout" : "generation_failed",
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

  struct DeadlineExceeded: LocalizedError {
    var errorDescription: String? { "Narration deadline exceeded" }
  }

  #if canImport(FoundationModels)
  /// Runs `operation`, cancelling it once `timeout` elapses. Dart stops
  /// waiting at the same deadline and shows template copy, so cancelling
  /// keeps the on-device model from generating text nobody will read.
  /// Covers the `minimalInstructions` retry too, since it runs inside
  /// `operation`.
  @available(iOS 26.0, *)
  static func withDeadline<T: Sendable>(
    _ timeout: Duration,
    operation: @escaping @Sendable () async throws -> T
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask(operation: operation)
      group.addTask {
        try await Task.sleep(for: timeout)
        throw DeadlineExceeded()
      }
      // Whichever child finishes first wins; cancel the other. On timeout
      // this cancels the in-flight `LanguageModelSession.respond`.
      defer { group.cancelAll() }
      guard let first = try await group.next() else { throw DeadlineExceeded() }
      return first
    }
  }

  /// Returns `text` plus which `instructions` set produced it, so Dart can
  /// log whether the fallback was needed.
  @available(iOS 26.0, *)
  static func generate(_ prompt: String) async throws -> [String: String] {
    do {
      let text = try await respond(to: prompt, instructions: instructions)
      return ["text": text, "instructions": "full"]
    } catch let error as LanguageModelSession.GenerationError {
      guard case .unsupportedLanguageOrLocale = error else { throw error }
      let text = try await respond(to: prompt, instructions: minimalInstructions)
      return ["text": text, "instructions": "minimal"]
    }
  }

  @available(iOS 26.0, *)
  static func respond(to prompt: String, instructions: String) async throws -> String {
    let session = LanguageModelSession(instructions: instructions)
    let response = try await session.respond(
      to: prompt,
      options: GenerationOptions(temperature: 0.4)
    )
    return response.content
  }

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
