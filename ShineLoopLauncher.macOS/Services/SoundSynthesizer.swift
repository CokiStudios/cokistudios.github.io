import Foundation
import AVFoundation

// MARK: - Native Handheld Audio Synthesizer
public final class SoundSynthesizer: @unchecked Sendable {
    public static let shared = SoundSynthesizer()

    public var volume: Float = 0.8
    public var isMuted: Bool = false

    private var activePlayers: [AVAudioPlayer] = []
    private let lock = NSLock()

    public enum Waveform {
        case sine
        case square
        case triangle
    }

    private init() {}

    /// Generates pure PCM 16-bit Mono WAV in memory for instant playback with zero disk I/O.
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

        // Sample generation with smooth anti-click envelope
        let attackSamples = min(Int(sampleRate * 0.005), numSamples / 4)
        let decaySamples = min(Int(sampleRate * 0.010), numSamples / 2)

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

            // Envelope to avoid audio clicks
            var env = 1.0
            if i < attackSamples {
                env = Double(i) / Double(attackSamples)
            } else if i > (numSamples - decaySamples) {
                env = Double(numSamples - i) / Double(decaySamples)
            }

            let sample = rawSample * env * 0.6
            let intSample = Int16(clamping: Int(sample * 32767.0))
            withUnsafeBytes(of: intSample.littleEndian) { data.append(contentsOf: $0) }
        }

        return data
    }

    /// Plays a custom frequency for duration in seconds (Matches Looping "play tone at N Hz for M ms")
    public func playTone(frequency: Double, duration: Double, waveform: Waveform = .sine) {
        guard !isMuted, volume > 0.001 else { return }

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            let wavData = self.generateWavData(frequency: frequency, duration: duration, waveform: waveform)
            do {
                let player = try AVAudioPlayer(data: wavData)
                player.volume = self.volume
                player.prepareToPlay()
                player.play()

                self.lock.lock()
                self.activePlayers.append(player)
                self.activePlayers.removeAll { !$0.isPlaying }
                self.lock.unlock()
            } catch {
                // Ignore audio failure
            }
        }
    }

    // MARK: - Official System Chimes

    /// Official Shine Loop Boot Chime from shine_launcher.loop (587 Hz 70ms -> 880 Hz 90ms)
    public func playBootChime() {
        playTone(frequency: 587.0, duration: 0.08, waveform: .sine)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) {
            self.playTone(frequency: 880.0, duration: 0.11, waveform: .sine)
        }
    }

    /// Crisp navigation tick when navigating cards or menus
    public func playNavTick() {
        playTone(frequency: 720.0, duration: 0.025, waveform: .sine)
    }

    /// Game / App Launch Confirmation Chime
    public func playLaunchChime() {
        playTone(frequency: 523.25, duration: 0.06, waveform: .sine)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.playTone(frequency: 659.25, duration: 0.06, waveform: .sine)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.playTone(frequency: 1046.50, duration: 0.14, waveform: .sine)
            }
        }
    }

    /// Back / Cancel soft click
    public func playBackTick() {
        playTone(frequency: 440.0, duration: 0.04, waveform: .triangle)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            self.playTone(frequency: 330.0, duration: 0.05, waveform: .triangle)
        }
    }

    /// Mode switch or action feedback
    public func playActionBlip() {
        playTone(frequency: 980.0, duration: 0.04, waveform: .sine)
    }
}
