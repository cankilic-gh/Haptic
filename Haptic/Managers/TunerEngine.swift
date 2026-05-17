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
/// - Input gain boost for improved mic sensitivity
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
    private let bufferSize: AVAudioFrameCount = 2048
    private var sampleRate: Double = 44100.0

    // MARK: - YIN Algorithm Parameters

    private let yinThreshold: Float = 0.15
    private let minFrequency: Double = 27.5   // A0
    private let maxFrequency: Double = 4186.0  // C8

    // MARK: - Haptic Integration

    private let hapticEngine: HapticEngine
    private var lastInTuneHapticTime: Date = .distantPast
    private let hapticCooldown: TimeInterval = 0.5

    // MARK: - Smoothing

    private var frequencyHistory: [Double] = []
    private let smoothingWindowSize = 3

    // MARK: - Input Gain

    private let targetInputGain: Float = 0.85

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
            #if DEBUG
            print("TunerEngine: Failed to start - \(error)")
            #endif
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

        // Use .default mode instead of .measurement to enable hardware AGC
        // and signal processing that improves sensitivity for instrument detection.
        // .measurement disables all system audio processing which hurts weak signals.
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setPreferredSampleRate(44100)
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)

        // Boost input gain to improve mic sensitivity for quiet instruments
        if session.isInputGainSettable {
            try session.setInputGain(targetInputGain)
        }

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

        // Lower noise gate to pick up quieter signals.
        // Hardware AGC + input gain boost compensate for noise floor.
        guard amplitude > 0.0005 else {
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
    ///
    /// Optimized with Accelerate framework for the difference function computation.
    private func detectPitchYIN(data: UnsafePointer<Float>, frameCount: Int) -> Double? {
        let tauMax = Int(sampleRate / minFrequency)
        let tauMin = Int(sampleRate / maxFrequency)

        guard frameCount >= tauMax else { return nil }

        let windowLength = frameCount - tauMax

        // Step 1: Calculate the difference function using Accelerate
        var diffFunction = [Float](repeating: 0, count: tauMax)

        for tau in tauMin..<tauMax {
            // d(tau) = sum of (x[j] - x[j+tau])^2
            // Expand: sum(x[j]^2) + sum(x[j+tau]^2) - 2*sum(x[j]*x[j+tau])
            // Use vDSP for the cross-correlation term

            var crossCorr: Float = 0
            vDSP_dotpr(data, 1, data.advanced(by: tau), 1, &crossCorr, vDSP_Length(windowLength))

            var sumSq1: Float = 0
            vDSP_dotpr(data, 1, data, 1, &sumSq1, vDSP_Length(windowLength))

            var sumSq2: Float = 0
            let shifted = data.advanced(by: tau)
            vDSP_dotpr(shifted, 1, shifted, 1, &sumSq2, vDSP_Length(windowLength))

            diffFunction[tau] = sumSq1 + sumSq2 - 2.0 * crossCorr
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

        // Keep only recent readings (reduced window for faster response)
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
