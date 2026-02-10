import Foundation
import AVFoundation
import Accelerate
import Combine

/// TunerEngine - Real-time pitch detection using YIN algorithm
/// Designed for high accuracy instrument tuning with low latency
///
/// Key Features:
/// - YIN pitch detection algorithm (highly accurate for monophonic signals)
/// - AVAudioEngine with installTap for real-time audio capture
/// - Accelerate framework for optimized DSP operations
/// - Works alongside metronome (shared audio session)

final class TunerEngine: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state: TunerState = .idle
    @Published private(set) var detectedFrequency: Double = 0.0
    @Published private(set) var detectedNote: MusicalNote?
    @Published private(set) var centOffset: Double = 0.0
    @Published private(set) var accuracy: TuningAccuracy = .far
    @Published private(set) var signalStrength: Double = 0.0

    @Published var referencePitch: Double = 440.0 {
        didSet {
            updateDetectedNote()
        }
    }

    @Published var configuration: TunerConfiguration = .default

    // MARK: - Audio Engine

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private let bufferSize: AVAudioFrameCount = 4096
    private var sampleRate: Double = 44100.0

    // MARK: - YIN Algorithm Parameters

    private let yinThreshold: Float = 0.15  // Confidence threshold
    private let minFrequency: Double = 27.5  // A0
    private let maxFrequency: Double = 4186.0  // C8

    // MARK: - Haptic Integration

    private let hapticEngine: HapticEngine
    private var lastInTuneHapticTime: Date = .distantPast
    private let hapticCooldown: TimeInterval = 0.5

    // MARK: - Smoothing

    private var frequencyHistory: [Double] = []
    private let smoothingWindowSize = 5

    // MARK: - Initialization

    init(hapticEngine: HapticEngine = HapticEngine()) {
        self.hapticEngine = hapticEngine
    }

    deinit {
        stop()
    }

    // MARK: - Public Control

    func start() {
        guard state == .idle else { return }

        do {
            try setupAudioSession()
            try setupAudioEngine()
            try audioEngine?.start()

            state = .listening

            // Start haptic engine for feedback
            try? hapticEngine.start()

        } catch {
            print("TunerEngine: Failed to start - \(error)")
            state = .idle
        }
    }

    func stop() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil

        state = .idle
        detectedFrequency = 0.0
        detectedNote = nil
        centOffset = 0.0
        accuracy = .far
        signalStrength = 0.0
        frequencyHistory.removeAll()

        hapticEngine.stop()
    }

    func toggle() {
        if state == .idle {
            start()
        } else {
            stop()
        }
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        // Configure for recording with playback (allows metronome to work)
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setPreferredSampleRate(44100)
        try session.setPreferredIOBufferDuration(0.005) // Low latency
        try session.setActive(true)

        sampleRate = session.sampleRate
    }

    // MARK: - Audio Engine Setup

    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()

        guard let audioEngine = audioEngine else {
            throw TunerError.engineSetupFailed
        }

        inputNode = audioEngine.inputNode
        let inputFormat = inputNode!.inputFormat(forBus: 0)
        sampleRate = inputFormat.sampleRate

        // Install tap on input node to capture audio
        inputNode?.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
    }

    // MARK: - Audio Processing

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        // Calculate signal strength (RMS)
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameCount))

        let amplitude = Double(rms)

        // Skip if signal is too weak
        guard amplitude > 0.01 else {
            DispatchQueue.main.async { [weak self] in
                self?.signalStrength = amplitude
                if self?.state != .idle {
                    self?.state = .listening
                }
            }
            return
        }

        // Perform YIN pitch detection
        if let frequency = detectPitchYIN(data: channelData, frameCount: frameCount) {
            // Smooth the frequency reading
            let smoothedFrequency = smoothFrequency(frequency)

            DispatchQueue.main.async { [weak self] in
                self?.signalStrength = amplitude
                self?.updateWithFrequency(smoothedFrequency)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.signalStrength = amplitude
            }
        }
    }

    // MARK: - YIN Pitch Detection Algorithm

    /// YIN algorithm for pitch detection
    /// Based on: "YIN, a fundamental frequency estimator for speech and music"
    /// by Alain de Cheveigne and Hideki Kawahara
    private func detectPitchYIN(data: UnsafePointer<Float>, frameCount: Int) -> Double? {
        let tauMax = Int(sampleRate / minFrequency)
        let tauMin = Int(sampleRate / maxFrequency)

        guard frameCount >= tauMax else { return nil }

        // Step 1: Calculate the difference function
        var diffFunction = [Float](repeating: 0, count: tauMax)

        for tau in tauMin..<tauMax {
            var sum: Float = 0
            for j in 0..<(frameCount - tauMax) {
                let diff = data[j] - data[j + tau]
                sum += diff * diff
            }
            diffFunction[tau] = sum
        }

        // Step 2: Calculate cumulative mean normalized difference function
        var cmndf = [Float](repeating: 0, count: tauMax)
        cmndf[0] = 1
        var runningSum: Float = 0

        for tau in 1..<tauMax {
            runningSum += diffFunction[tau]
            if runningSum > 0 {
                cmndf[tau] = diffFunction[tau] * Float(tau) / runningSum
            } else {
                cmndf[tau] = 1
            }
        }

        // Step 3: Find the first dip below threshold
        var tau = tauMin
        while tau < tauMax - 1 {
            if cmndf[tau] < yinThreshold {
                // Found a dip, now find the local minimum
                while tau + 1 < tauMax && cmndf[tau + 1] < cmndf[tau] {
                    tau += 1
                }
                break
            }
            tau += 1
        }

        // No valid pitch found
        if tau >= tauMax - 1 || cmndf[tau] >= yinThreshold {
            return nil
        }

        // Step 4: Parabolic interpolation for better accuracy
        let betterTau = parabolicInterpolation(cmndf: cmndf, tau: tau)

        // Convert tau to frequency
        let frequency = sampleRate / Double(betterTau)

        // Validate frequency range
        guard frequency >= minFrequency && frequency <= maxFrequency else {
            return nil
        }

        return frequency
    }

    /// Parabolic interpolation for sub-sample accuracy
    private func parabolicInterpolation(cmndf: [Float], tau: Int) -> Double {
        guard tau > 0 && tau < cmndf.count - 1 else {
            return Double(tau)
        }

        let s0 = cmndf[tau - 1]
        let s1 = cmndf[tau]
        let s2 = cmndf[tau + 1]

        let adjustment = (s2 - s0) / (2 * (2 * s1 - s2 - s0))

        return Double(tau) + Double(adjustment)
    }

    // MARK: - Frequency Smoothing

    private func smoothFrequency(_ frequency: Double) -> Double {
        frequencyHistory.append(frequency)

        // Keep only recent readings
        if frequencyHistory.count > smoothingWindowSize {
            frequencyHistory.removeFirst()
        }

        // Use median filter for robustness against outliers
        let sorted = frequencyHistory.sorted()
        let mid = sorted.count / 2

        if sorted.count % 2 == 0 && sorted.count >= 2 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        } else {
            return sorted[mid]
        }
    }

    // MARK: - State Update

    private func updateWithFrequency(_ frequency: Double) {
        detectedFrequency = frequency

        // Find closest note
        if let result = MusicalNote.closest(to: frequency, referencePitch: referencePitch) {
            detectedNote = result.note
            centOffset = result.centOffset
            accuracy = TuningAccuracy(centOffset: centOffset)

            // Update state
            if accuracy == .inTune {
                state = .inTune
                triggerInTuneHaptic()
            } else {
                state = .detecting(frequency: frequency)
            }
        }
    }

    private func updateDetectedNote() {
        guard detectedFrequency > 0 else { return }

        if let result = MusicalNote.closest(to: detectedFrequency, referencePitch: referencePitch) {
            detectedNote = result.note
            centOffset = result.centOffset
            accuracy = TuningAccuracy(centOffset: centOffset)
        }
    }

    // MARK: - Haptic Feedback

    private func triggerInTuneHaptic() {
        guard configuration.hapticFeedbackEnabled else { return }

        // Prevent rapid-fire haptics
        let now = Date()
        guard now.timeIntervalSince(lastInTuneHapticTime) >= hapticCooldown else { return }

        lastInTuneHapticTime = now
        hapticEngine.playAccentedBeat()  // Satisfying "in tune" feedback
    }

    // MARK: - Error Types

    enum TunerError: LocalizedError {
        case engineSetupFailed
        case permissionDenied
        case audioSessionFailed

        var errorDescription: String? {
            switch self {
            case .engineSetupFailed:
                return "Failed to setup audio engine"
            case .permissionDenied:
                return "Microphone permission denied"
            case .audioSessionFailed:
                return "Failed to configure audio session"
            }
        }
    }
}

// MARK: - Microphone Permission

extension TunerEngine {

    static func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    static var hasMicrophonePermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }
}
