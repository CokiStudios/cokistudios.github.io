import Foundation
import AVFoundation

// MARK: - Native APU Audio Synthesizer (Zero Disk I/O)
public final class SoundSynthesizer: ObservableObject, @unchecked Sendable {
    public static let shared = SoundSynthesizer()

    public var volume: Float = 0.85
    @Published public var isMuted: Bool = false

    private var activePlayers: [AVAudioPlayer] = []
    private let lock = NSLock()

    public enum Waveform {
        case sine
        case square
        case triangle
    }

    private init() {}

    /// Synthesizes pure PCM 16-bit Mono WAV in memory for zero-latency playback.
    private func generateWavData(frequency: Double, duration: Double, waveform: Waveform = .sine, sampleRate: Double = 44100.0) -> Data {
        let numSamples = max(1, Int(sampleRate * duration))
        var data = Data()
        data.reserveCapacity(44 + numSamples * 2)

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        let fileSize = UInt32(36 + numSamples * 2)
        withUnsafeBytes(of: fileSize.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: "WAVEfmt ".utf8)

        let subchunk1Size: UInt32 = 16
        withUnsafeBytes(of: subchunk1Size.littleEndian) { data.append(contentsOf: $0) }
        let audioFormat: UInt16 = 1 // PCM
        withUnsafeBytes(of: audioFormat.littleEndian) { data.append(contentsOf: $0) }
        let numChannels: UInt16 = 1 // Mono
        withUnsafeBytes(of: numChannels.littleEndian) { data.append(contentsOf: $0) }
        let sampleRateU32 = UInt32(sampleRate)
        withUnsafeBytes(of: sampleRateU32.littleEndian) { data.append(contentsOf: $0) }
        let byteRate = UInt32(sampleRate * 2)
        withUnsafeBytes(of: byteRate.littleEndian) { data.append(contentsOf: $0) }
        let blockAlign: UInt16 = 2
        withUnsafeBytes(of: blockAlign.littleEndian) { data.append(contentsOf: $0) }
        let bitsPerSample: UInt16 = 16
        withUnsafeBytes(of: bitsPerSample.littleEndian) { data.append(contentsOf: $0) }

        // Data chunk
        data.append(contentsOf: "data".utf8)
        let subchunk2Size = UInt32(numSamples * 2)
        withUnsafeBytes(of: subchunk2Size.littleEndian) { data.append(contentsOf: $0) }

        // Envelope: soft attack and decay to eliminate audio clicking
        let attackSamples = min(Int(sampleRate * 0.005), numSamples / 4)
        let decaySamples = min(Int(sampleRate * 0.015), numSamples / 2)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let phase = 2.0 * .pi * frequency * t

            var rawSample: Double = 0.0
            switch waveform {
            case .sine:
                rawSample = sin(phase)
            case .square:
                rawSample = sin(phase) >= 0 ? 0.6 : -0.6
            case .triangle:
                rawSample = (2.0 / .pi) * asin(sin(phase))
            }

            var env = 1.0
            if i < attackSamples {
                env = Double(i) / Double(attackSamples)
            } else if i > numSamples - decaySamples {
                env = Double(numSamples - i) / Double(decaySamples)
            }

            let sample = Int16(max(-32768.0, min(32767.0, rawSample * env * 32767.0 * Double(volume))))
            withUnsafeBytes(of: sample.littleEndian) { data.append(contentsOf: $0) }
        }

        return data
    }

    public func playTone(frequency: Double, duration: Double = 0.09, waveform: Waveform = .sine) {
        guard !isMuted else { return }

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            let wavData = self.generateWavData(frequency: frequency, duration: duration, waveform: waveform)

            do {
                let player = try AVAudioPlayer(data: wavData)
                player.prepareToPlay()

                self.lock.lock()
                self.activePlayers.append(player)
                self.lock.unlock()

                player.play()

                DispatchQueue.global().asyncAfter(deadline: .now() + duration + 0.1) { [weak self, weak player] in
                    guard let self = self, let player = player else { return }
                    self.lock.lock()
                    self.activePlayers.removeAll { $0 === player }
                    self.lock.unlock()
                }
            } catch {
                // Ignore audio player errors
            }
        }
    }

    /// Coki Studios APU Signature Notification (880Hz -> 1174Hz)
    public func playApuChime() {
        playTone(frequency: 880.0, duration: 0.08, waveform: .sine)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.07) { [weak self] in
            self?.playTone(frequency: 1174.66, duration: 0.12, waveform: .triangle)
        }
    }

    /// Success action feedback
    public func playSuccess() {
        playTone(frequency: 587.33, duration: 0.06, waveform: .sine)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.playTone(frequency: 880.0, duration: 0.10, waveform: .sine)
        }
    }

    /// Alert feedback
    public func playWarning() {
        playTone(frequency: 329.63, duration: 0.12, waveform: .square)
    }
}
