import AVFoundation
import Accelerate

/// Decodes a few fixed-length windows of an audio file to mono float PCM at a
/// target sample rate, for on-device mood classification (YAMNet wants 16 kHz).
///
/// Mirrors `spikes/clap/audio.py`, so the model sees what the spike evaluated:
/// - windows are centred on fractions of the duration and clamped to the file;
/// - a file shorter than one window comes back whole, as a single window;
/// - mono is the mean of the channels (what librosa does).
///
/// Only the windows are read from disk, never the whole file. Pure
/// AVFoundation with no Flutter dependency, so it also builds on macOS for the
/// librosa parity check in `spikes/clap/swift_parity`.
struct AudioWindowDecoder {
  struct Decoded {
    let windows: [[Float]]
    let startSeconds: [Double]
    let durationSeconds: Double
    let sourceSampleRate: Double
    let channelCount: Int
  }

  enum DecodeError: Error {
    /// The file is missing or in a format this OS version can't open. (macOS
    /// 26.6 decodes all five upload formats, Ogg Vorbis included; older iOS
    /// versions may not.)
    case unreadable(String)
    case empty
    case conversionFailed(String)
    case badArgs(String)

    var code: String {
      switch self {
      case .unreadable: return "unreadable"
      case .empty: return "empty"
      case .conversionFailed: return "decode_failed"
      case .badArgs: return "bad_args"
      }
    }

    var message: String {
      switch self {
      case .unreadable(let detail): return "Can't open audio file: \(detail)"
      case .empty: return "Audio file has no samples"
      case .conversionFailed(let detail): return "Couldn't convert audio: \(detail)"
      case .badArgs(let detail): return "Invalid decode arguments: \(detail)"
      }
    }
  }

  /// Highest common PCM rate; also keeps `resample`'s output count in range.
  static let maxSampleRate: Double = 384_000

  let targetSampleRate: Double

  func decode(url: URL, positions: [Double], windowSeconds: Double) throws -> Decoded {
    // Checked before any frame-count conversion: Int64/UInt32 initialisers
    // trap on NaN, infinity, negatives and overflow, which would kill the app.
    guard targetSampleRate.isFinite, targetSampleRate > 0, targetSampleRate <= Self.maxSampleRate else {
      throw DecodeError.badArgs("sampleRate must be in (0, \(Int(Self.maxSampleRate))], got \(targetSampleRate)")
    }
    guard windowSeconds.isFinite, windowSeconds > 0 else {
      throw DecodeError.badArgs("windowSeconds must be positive and finite, got \(windowSeconds)")
    }
    guard !positions.isEmpty, positions.allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
      throw DecodeError.badArgs("positions must be fractions in [0, 1], got \(positions)")
    }

    let file: AVAudioFile
    do {
      file = try AVAudioFile(forReading: url)
    } catch {
      throw DecodeError.unreadable(error.localizedDescription)
    }

    let format = file.processingFormat
    let sourceRate = format.sampleRate
    let length = file.length
    guard length > 0 else { throw DecodeError.empty }

    // Capped at the file length before converting so a huge window can't
    // overflow Int64; anything that long is the whole file anyway.
    let windowFrames = AVAudioFramePosition(min(windowSeconds * sourceRate, Double(length)))
    guard windowFrames > 0,
          windowFrames <= AVAudioFramePosition(AVAudioFrameCount.max)
    else {
      throw DecodeError.badArgs("windowSeconds \(windowSeconds) cannot fit in one audio buffer")
    }
    let ranges = Self.windowRanges(length: length, windowFrames: windowFrames, positions: positions)

    var windows: [[Float]] = []
    for range in ranges {
      let mono = try readMono(file, start: range.start, frames: range.frames)
      windows.append(try resample(mono, from: sourceRate, expectedFrames: range.frames))
    }

    return Decoded(
      windows: windows,
      startSeconds: ranges.map { Double($0.start) / sourceRate },
      durationSeconds: Double(length) / sourceRate,
      sourceSampleRate: sourceRate,
      channelCount: Int(format.channelCount)
    )
  }

  /// Same arithmetic as `load_windows_with_starts` in the spike.
  static func windowRanges(
    length: AVAudioFramePosition,
    windowFrames: AVAudioFramePosition,
    positions: [Double]
  ) -> [(start: AVAudioFramePosition, frames: AVAudioFramePosition)] {
    if length <= windowFrames { return [(0, length)] }
    return positions.map { position in
      let start = AVAudioFramePosition(position * Double(length)) - windowFrames / 2
      return (min(max(start, 0), length - windowFrames), windowFrames)
    }
  }

  private func readMono(
    _ file: AVAudioFile,
    start: AVAudioFramePosition,
    frames: AVAudioFramePosition
  ) throws -> [Float] {
    guard let buffer = AVAudioPCMBuffer(
      pcmFormat: file.processingFormat,
      frameCapacity: AVAudioFrameCount(frames)
    ) else {
      throw DecodeError.conversionFailed("couldn't allocate a \(frames)-frame buffer")
    }
    file.framePosition = start
    do {
      try file.read(into: buffer, frameCount: AVAudioFrameCount(frames))
    } catch {
      throw DecodeError.conversionFailed(error.localizedDescription)
    }

    let count = Int(buffer.frameLength)
    guard count > 0, let channels = buffer.floatChannelData else { throw DecodeError.empty }

    // Mean of the channels, as librosa's `mono=True` does.
    let channelCount = Int(buffer.format.channelCount)
    var mono = Array(UnsafeBufferPointer(start: channels[0], count: count))
    if channelCount > 1 {
      for c in 1..<channelCount {
        vDSP.add(mono, UnsafeBufferPointer(start: channels[c], count: count), result: &mono)
      }
      vDSP.multiply(1 / Float(channelCount), mono, result: &mono)
    }
    return mono
  }

  /// Resamples mono audio to `targetSampleRate`, then trims or zero-pads to
  /// the length librosa would produce, so every window is the same size.
  private func resample(
    _ mono: [Float],
    from sourceRate: Double,
    expectedFrames sourceFrames: AVAudioFramePosition
  ) throws -> [Float] {
    let outputCount = Int((Double(sourceFrames) * targetSampleRate / sourceRate).rounded(.up))
    if sourceRate == targetSampleRate { return fit(mono, to: outputCount) }

    guard
      let inFormat = AVAudioFormat(standardFormatWithSampleRate: sourceRate, channels: 1),
      let outFormat = AVAudioFormat(standardFormatWithSampleRate: targetSampleRate, channels: 1),
      let converter = AVAudioConverter(from: inFormat, to: outFormat),
      let input = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: AVAudioFrameCount(mono.count)),
      let output = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: AVAudioFrameCount(outputCount + 4096))
    else {
      throw DecodeError.conversionFailed("couldn't set up \(sourceRate) Hz → \(targetSampleRate) Hz")
    }
    converter.sampleRateConverterQuality = AVAudioQuality.max.rawValue
    converter.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Mastering

    input.frameLength = AVAudioFrameCount(mono.count)
    mono.withUnsafeBufferPointer { input.floatChannelData![0].update(from: $0.baseAddress!, count: mono.count) }

    var supplied = false
    var resampled: [Float] = []
    resampled.reserveCapacity(outputCount)
    while true {
      var error: NSError?
      let status = converter.convert(to: output, error: &error) { _, inputStatus in
        if supplied {
          inputStatus.pointee = .endOfStream
          return nil
        }
        supplied = true
        inputStatus.pointee = .haveData
        return input
      }
      if status == .error {
        throw DecodeError.conversionFailed(error?.localizedDescription ?? "unknown converter error")
      }
      resampled.append(
        contentsOf: UnsafeBufferPointer(start: output.floatChannelData![0], count: Int(output.frameLength))
      )
      if status == .endOfStream || output.frameLength == 0 { break }
    }
    return fit(resampled, to: outputCount)
  }

  private func fit(_ samples: [Float], to count: Int) -> [Float] {
    if samples.count >= count { return Array(samples.prefix(count)) }
    return samples + [Float](repeating: 0, count: count - samples.count)
  }
}
