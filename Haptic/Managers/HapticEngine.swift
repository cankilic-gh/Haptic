import Foundation
import Combine
#if canImport(CoreHaptics)
import CoreHaptics
#endif
import AVFoundation
#if os(watchOS)
import WatchKit
#endif

/// HapticEngine - Cross-platform haptic feedback for metronome beats
/// iOS: CoreHaptics for precise transient patterns
/// watchOS: WKInterfaceDevice haptics as fallback

final class HapticEngine: ObservableObject {

    // MARK: - Published State
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isRunning: Bool = false
    @Published var soundEnabled: Bool = true

    #if canImport(CoreHaptics)
    // MARK: - CoreHaptics (iOS)
    private var engine: CHHapticEngine?
    private var accentedBeatPlayer: CHHapticPatternPlayer?
    private var normalBeatPlayer: CHHapticPatternPlayer?
    private var subdivisionPlayer: CHHapticPatternPlayer?
    private var ghostNotePlayer: CHHapticPatternPlayer?
    #endif

    // MARK: - Audio Click Engine
    private let audioClick = AudioClickEngine()

    // MARK: - Haptic Pattern Definitions

    enum BeatIntensity: Float {
        case accent = 1.0
        case normal = 0.7
        case subdivision = 0.4
        case ghost = 0.2
    }

    enum BeatSharpness: Float {
        case sharp = 1.0
        case medium = 0.7
        case soft = 0.4
    }

    // MARK: - Initialization

    init() {
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        #if canImport(CoreHaptics)
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
            #if DEBUG
            print("HapticEngine: Failed to create engine: \(error)")
            #endif
            isAvailable = false
        }
        #elseif os(watchOS)
        isAvailable = true
        #else
        isAvailable = false
        #endif
    }

    #if canImport(CoreHaptics)
    private func configureEngine() {
        guard let engine = engine else { return }

        engine.resetHandler = { [weak self] in
            do {
                try self?.engine?.start()
                try self?.preparePatternPlayers()
            } catch {
                #if DEBUG
                print("HapticEngine: Failed to restart: \(error)")
                #endif
            }
        }

        engine.stoppedHandler = { [weak self] reason in
            #if DEBUG
            print("HapticEngine stopped: \(reason.rawValue)")
            #endif
            self?.isRunning = false
        }

        engine.isAutoShutdownEnabled = false
        engine.playsHapticsOnly = true
    }

    // MARK: - Pattern Creation

    private func createTransientPattern(
        intensity: BeatIntensity,
        sharpness: BeatSharpness
    ) throws -> CHHapticPattern {
        let transientEvent = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity.rawValue),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness.rawValue)
            ],
            relativeTime: 0,
            duration: 0.05
        )
        return try CHHapticPattern(events: [transientEvent], parameters: [])
    }

    private func createAccentPattern() throws -> CHHapticPattern {
        let primaryTap = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0,
            duration: 0.05
        )

        let reinforcementTap = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0.025,
            duration: 0.03
        )

        return try CHHapticPattern(events: [primaryTap, reinforcementTap], parameters: [])
    }

    private func preparePatternPlayers() throws {
        guard let engine = engine else { return }

        accentedBeatPlayer = try engine.makePlayer(with: createAccentPattern())
        normalBeatPlayer = try engine.makePlayer(with: createTransientPattern(intensity: .normal, sharpness: .sharp))
        subdivisionPlayer = try engine.makePlayer(with: createTransientPattern(intensity: .subdivision, sharpness: .medium))
        ghostNotePlayer = try engine.makePlayer(with: createTransientPattern(intensity: .ghost, sharpness: .soft))
    }
    #endif

    // MARK: - Engine Control

    func start() throws {
        if soundEnabled {
            audioClick.start()
        }

        #if canImport(CoreHaptics)
        if let engine = engine {
            try engine.start()
        }
        #endif

        isRunning = true
    }

    func stop() {
        #if canImport(CoreHaptics)
        engine?.stop(completionHandler: nil)
        #endif
        audioClick.stop()
        isRunning = false
    }

    // MARK: - Beat Triggering

    func playAccentedBeat() {
        guard isRunning else { return }
        if soundEnabled { audioClick.playAccent() }

        #if canImport(CoreHaptics)
        do {
            try accentedBeatPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {}
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #endif
    }

    func playNormalBeat() {
        guard isRunning else { return }
        if soundEnabled { audioClick.playNormal() }

        #if canImport(CoreHaptics)
        do {
            try normalBeatPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {}
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    func playSubdivision() {
        guard isRunning else { return }
        if soundEnabled { audioClick.playSubdivision() }

        #if canImport(CoreHaptics)
        do {
            try subdivisionPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {}
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    func playGhostNote() {
        guard isRunning else { return }
        if soundEnabled { audioClick.playGhost() }

        #if canImport(CoreHaptics)
        do {
            try ghostNotePlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {}
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

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

    #if canImport(CoreHaptics)
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
                    continue
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
            #if DEBUG
            print("HapticEngine: Failed to play custom pattern: \(error)")
            #endif
        }
    }
    #endif

    // MARK: - Error Types

    enum HapticError: LocalizedError {
        case engineNotAvailable
        case patternCreationFailed
        case playerNotReady

        var errorDescription: String? {
            switch self {
            case .engineNotAvailable: return "Haptic engine is not available"
            case .patternCreationFailed: return "Failed to create haptic pattern"
            case .playerNotReady: return "Haptic player is not ready"
            }
        }
    }
}

// MARK: - Supporting Types

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
