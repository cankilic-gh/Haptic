import Foundation
import Combine
import CoreHaptics
import AVFoundation

/// HapticEngine - CoreHaptics Implementation for Sharp, Percussive Metronome Taps
/// Designed for professional musicians who need precise tactile feedback.
///
/// Key Features:
/// - Transient haptic patterns (sharp, percussive feel)
/// - Different intensities for accented vs normal beats
/// - Subdivision support for complex patterns
/// - Automatic engine recovery on interruption

final class HapticEngine: ObservableObject {

    // MARK: - Published State
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isRunning: Bool = false

    // MARK: - CoreHaptics
    private var engine: CHHapticEngine?
    private var accentedBeatPlayer: CHHapticPatternPlayer?
    private var normalBeatPlayer: CHHapticPatternPlayer?
    private var subdivisionPlayer: CHHapticPatternPlayer?
    private var ghostNotePlayer: CHHapticPatternPlayer?

    // MARK: - Haptic Pattern Definitions

    /// Beat intensity levels for different haptic weights
    enum BeatIntensity: Float {
        case accent = 1.0        // Full power - downbeat/accent
        case normal = 0.7        // Standard beat
        case subdivision = 0.4   // Eighth notes, sixteenths
        case ghost = 0.2         // Ghost notes, very subtle
    }

    /// Sharpness levels (higher = more "click", lower = more "thud")
    enum BeatSharpness: Float {
        case sharp = 1.0         // Crisp, percussive click
        case medium = 0.7        // Balanced feel
        case soft = 0.4          // Rounded, softer tap
    }

    // MARK: - Initialization

    init() {
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            isAvailable = false
            return
        }

        do {
            engine = try CHHapticEngine()
            configureEngine()
            try preparePatternPlayers()
            isAvailable = true
        } catch {
            print("HapticEngine: Failed to create engine: \(error)")
            isAvailable = false
        }
    }

    private func configureEngine() {
        guard let engine = engine else { return }

        // Handle engine reset (e.g., after app returns to foreground)
        engine.resetHandler = { [weak self] in
            do {
                try self?.engine?.start()
                try self?.preparePatternPlayers()
            } catch {
                print("HapticEngine: Failed to restart: \(error)")
            }
        }

        // Handle when engine stops (e.g., audio session interruption)
        engine.stoppedHandler = { [weak self] reason in
            print("HapticEngine stopped: \(reason.rawValue)")
            self?.isRunning = false
        }

        // Configure for background audio (allows haptics during background playback)
        engine.isAutoShutdownEnabled = false
        engine.playsHapticsOnly = true
    }

    // MARK: - Pattern Creation

    /// Create a transient haptic pattern with specified intensity and sharpness
    /// Transient = single, sharp tap (as opposed to continuous vibration)
    private func createTransientPattern(
        intensity: BeatIntensity,
        sharpness: BeatSharpness
    ) throws -> CHHapticPattern {

        // Transient event - the key to sharp, percussive feel
        let transientEvent = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: intensity.rawValue
                ),
                CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: sharpness.rawValue
                )
            ],
            relativeTime: 0,
            duration: 0.05 // Very short for percussive feel
        )

        return try CHHapticPattern(events: [transientEvent], parameters: [])
    }

    /// Create enhanced accent pattern with double-tap feel
    /// Gives extra emphasis to downbeats
    private func createAccentPattern() throws -> CHHapticPattern {
        // Primary strong tap
        let primaryTap = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0,
            duration: 0.05
        )

        // Subtle reinforcement tap (creates "thicker" feel)
        let reinforcementTap = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0.025, // 25ms after primary
            duration: 0.03
        )

        return try CHHapticPattern(events: [primaryTap, reinforcementTap], parameters: [])
    }

    // MARK: - Player Preparation

    private func preparePatternPlayers() throws {
        guard let engine = engine else { return }

        // Accented beat - strongest, sharpest, with reinforcement
        let accentPattern = try createAccentPattern()
        accentedBeatPlayer = try engine.makePlayer(with: accentPattern)

        // Normal beat - strong but not emphasized
        let normalPattern = try createTransientPattern(
            intensity: .normal,
            sharpness: .sharp
        )
        normalBeatPlayer = try engine.makePlayer(with: normalPattern)

        // Subdivision - lighter tap for eighth/sixteenth notes
        let subdivisionPattern = try createTransientPattern(
            intensity: .subdivision,
            sharpness: .medium
        )
        subdivisionPlayer = try engine.makePlayer(with: subdivisionPattern)

        // Ghost note - very subtle, almost felt rather than heard
        let ghostPattern = try createTransientPattern(
            intensity: .ghost,
            sharpness: .soft
        )
        ghostNotePlayer = try engine.makePlayer(with: ghostPattern)
    }

    // MARK: - Engine Control

    func start() throws {
        guard let engine = engine else {
            throw HapticError.engineNotAvailable
        }

        try engine.start()
        isRunning = true
    }

    func stop() {
        engine?.stop(completionHandler: nil)
        isRunning = false
    }

    // MARK: - Beat Triggering

    /// Play an accented beat (downbeats, emphasized beats)
    func playAccentedBeat() {
        guard isRunning else { return }

        do {
            try accentedBeatPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("HapticEngine: Failed to play accented beat: \(error)")
        }
    }

    /// Play a normal beat
    func playNormalBeat() {
        guard isRunning else { return }

        do {
            try normalBeatPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("HapticEngine: Failed to play normal beat: \(error)")
        }
    }

    /// Play a subdivision beat (eighth notes, sixteenths)
    func playSubdivision() {
        guard isRunning else { return }

        do {
            try subdivisionPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("HapticEngine: Failed to play subdivision: \(error)")
        }
    }

    /// Play a ghost note (very subtle)
    func playGhostNote() {
        guard isRunning else { return }

        do {
            try ghostNotePlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("HapticEngine: Failed to play ghost note: \(error)")
        }
    }

    /// Play beat based on accent pattern value
    func playBeat(isAccented: Bool, isSubdivision: Bool = false) {
        if isSubdivision {
            playSubdivision()
        } else if isAccented {
            playAccentedBeat()
        } else {
            playNormalBeat()
        }
    }

    // MARK: - Advanced Patterns

    /// Create and play a custom pattern for complex rhythms
    func playCustomPattern(events: [HapticBeatEvent]) {
        guard isRunning, let engine = engine else { return }

        do {
            var hapticEvents: [CHHapticEvent] = []

            for event in events {
                let intensity: Float
                let sharpness: Float

                switch event.type {
                case .accent:
                    intensity = BeatIntensity.accent.rawValue
                    sharpness = BeatSharpness.sharp.rawValue
                case .normal:
                    intensity = BeatIntensity.normal.rawValue
                    sharpness = BeatSharpness.sharp.rawValue
                case .subdivision:
                    intensity = BeatIntensity.subdivision.rawValue
                    sharpness = BeatSharpness.medium.rawValue
                case .ghost:
                    intensity = BeatIntensity.ghost.rawValue
                    sharpness = BeatSharpness.soft.rawValue
                case .rest:
                    continue // No haptic for rests
                }

                let hapticEvent = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: event.relativeTime,
                    duration: 0.05
                )

                hapticEvents.append(hapticEvent)
            }

            let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)

        } catch {
            print("HapticEngine: Failed to play custom pattern: \(error)")
        }
    }

    // MARK: - Error Types

    enum HapticError: LocalizedError {
        case engineNotAvailable
        case patternCreationFailed
        case playerNotReady

        var errorDescription: String? {
            switch self {
            case .engineNotAvailable:
                return "Haptic engine is not available"
            case .patternCreationFailed:
                return "Failed to create haptic pattern"
            case .playerNotReady:
                return "Haptic player is not ready"
            }
        }
    }
}

// MARK: - Supporting Types

/// Represents a single beat event in a custom haptic pattern
struct HapticBeatEvent {
    let type: BeatType
    let relativeTime: TimeInterval

    enum BeatType {
        case accent
        case normal
        case subdivision
        case ghost
        case rest
    }
}

// MARK: - Watch-Specific Implementation

#if os(watchOS)
import WatchKit

extension HapticEngine {

    /// Fallback to WatchKit haptics when CoreHaptics isn't available
    /// (older Apple Watch models)
    func playWatchKitFallback(isAccented: Bool) {
        if isAccented {
            WKInterfaceDevice.current().play(.notification)
        } else {
            WKInterfaceDevice.current().play(.click)
        }
    }
}
#endif
