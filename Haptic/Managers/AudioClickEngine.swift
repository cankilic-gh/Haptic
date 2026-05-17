import Foundation
import AVFoundation

/// AudioClickEngine - Synthesized click sounds for the metronome
/// Generates short percussive clicks at different pitches/volumes
/// No external audio files needed - pure programmatic synthesis
///
/// Click types:
/// - Accent: 880 Hz, full volume (bright, prominent)
/// - Normal: 660 Hz, 70% volume
/// - Subdivision: 440 Hz, 40% volume
/// - Ghost: 330 Hz, 20% volume

final class AudioClickEngine {

    // MARK: - Audio Engine

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var mixerNode: AVAudioMixerNode?

    // MARK: - Pre-rendered Buffers

    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?
    private var subdivisionBuffer: AVAudioPCMBuffer?
    private var ghostBuffer: AVAudioPCMBuffer?

    // MARK: - Configuration

    private let sampleRate: Double = 44100.0
    private let clickDuration: Double = 0.025  // 25ms - short, percussive

    private(set) var isRunning: Bool = false

    // MARK: - Initialization

    init() {
        setupAudioEngine()
        generateClickBuffers()
    }

    // MARK: - Setup

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixerNode = AVAudioMixerNode()

        guard let audioEngine = audioEngine,
              let playerNode = playerNode,
              let mixerNode = mixerNode else { return }

        audioEngine.attach(playerNode)
        audioEngine.attach(mixerNode)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        audioEngine.connect(playerNode, to: mixerNode, format: format)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: format)
    }

    private func generateClickBuffers() {
        // Accent: high pitch, full volume, slightly longer
        accentBuffer = generateClick(frequency: 880, amplitude: 0.9, duration: 0.03)

        // Normal: medium pitch, moderate volume
        normalBuffer = generateClick(frequency: 660, amplitude: 0.6, duration: clickDuration)

        // Subdivision: lower pitch, quiet
        subdivisionBuffer = generateClick(frequency: 440, amplitude: 0.3, duration: 0.02)

        // Ghost: lowest, very quiet
        ghostBuffer = generateClick(frequency: 330, amplitude: 0.15, duration: 0.015)
    }

    /// Generate a short click waveform with exponential decay
    private func generateClick(frequency: Double, amplitude: Float, duration: Double) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        let angularFrequency = 2.0 * Double.pi * frequency / sampleRate

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let normalizedTime = time / duration

            // Sine wave with exponential decay envelope
            let envelope = Float(exp(-normalizedTime * 8.0))  // Fast decay
            let sine = Float(sin(angularFrequency * Double(frame)))

            // Add a click transient at the very start (first 1ms)
            let transient: Float
            if normalizedTime < 0.04 {
                transient = Float(1.0 - normalizedTime / 0.04) * 0.5
            } else {
                transient = 0
            }

            channelData[frame] = (sine * envelope + transient) * amplitude
        }

        return buffer
    }

    // MARK: - Control

    func start() {
        guard let audioEngine = audioEngine else { return }

        do {
            // Configure audio session for playback
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            #endif

            try audioEngine.start()
            isRunning = true
        } catch {
            #if DEBUG
            print("AudioClickEngine: Failed to start: \(error)")
            #endif
        }
    }

    func stop() {
        playerNode?.stop()
        audioEngine?.stop()
        isRunning = false
    }

    // MARK: - Playback

    func playAccent() {
        playBuffer(accentBuffer)
    }

    func playNormal() {
        playBuffer(normalBuffer)
    }

    func playSubdivision() {
        playBuffer(subdivisionBuffer)
    }

    func playGhost() {
        playBuffer(ghostBuffer)
    }

    func playBeat(isAccented: Bool, isSubdivision: Bool = false) {
        if isSubdivision {
            playSubdivision()
        } else if isAccented {
            playAccent()
        } else {
            playNormal()
        }
    }

    private func playBuffer(_ buffer: AVAudioPCMBuffer?) {
        guard isRunning,
              let playerNode = playerNode,
              let buffer = buffer else { return }

        // Schedule and play immediately
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)

        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}
