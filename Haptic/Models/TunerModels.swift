import Foundation
import SwiftUI

// MARK: - Musical Note

/// Represents a musical note with all relevant frequency information
struct MusicalNote: Identifiable, Equatable {
    let id = UUID()
    let name: String           // C, C#, D, etc.
    let octave: Int            // 0-8
    let midiNumber: Int        // MIDI note number (0-127)
    let frequency: Double      // Standard frequency in Hz (A4 = 440Hz)

    var fullName: String {
        "\(name)\(octave)"
    }

    var displayName: String {
        name.replacingOccurrences(of: "#", with: "#")
    }

    /// Calculate the expected frequency for this note at a given reference pitch
    func frequency(at referencePitch: Double) -> Double {
        // A4 is MIDI note 69
        let semitonesFromA4 = Double(midiNumber - 69)
        return referencePitch * pow(2.0, semitonesFromA4 / 12.0)
    }

    // Standard note frequencies based on A4 = 440Hz
    static let all: [MusicalNote] = {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        var notes: [MusicalNote] = []

        for midi in 0...127 {
            let octave = (midi / 12) - 1
            let noteIndex = midi % 12
            let semitoneFromA4 = Double(midi - 69)
            let frequency = 440.0 * pow(2.0, semitoneFromA4 / 12.0)

            notes.append(MusicalNote(
                name: noteNames[noteIndex],
                octave: octave,
                midiNumber: midi,
                frequency: frequency
            ))
        }

        return notes
    }()

    /// Find the closest note to a given frequency
    static func closest(to frequency: Double, referencePitch: Double = 440.0) -> (note: MusicalNote, centOffset: Double)? {
        guard frequency > 16.0 && frequency < 8000.0 else { return nil }

        // Calculate MIDI number from frequency
        let midiFloat = 69.0 + 12.0 * log2(frequency / referencePitch)
        let midiNumber = Int(round(midiFloat))

        guard midiNumber >= 0 && midiNumber <= 127 else { return nil }

        let note = all[midiNumber]
        let expectedFrequency = note.frequency(at: referencePitch)

        // Calculate cent offset: 1200 cents = 1 octave
        let centOffset = 1200.0 * log2(frequency / expectedFrequency)

        return (note, centOffset)
    }
}

// MARK: - Tuner State

/// Current state of the tuner
enum TunerState: Equatable {
    case idle                          // Not listening
    case listening                     // Listening but no signal
    case detecting(frequency: Double)  // Detected a pitch
    case inTune                        // Within acceptable range

    var isActive: Bool {
        switch self {
        case .idle: return false
        default: return true
        }
    }
}

// MARK: - Tuning Accuracy

/// Visual feedback based on how close the tuning is
enum TuningAccuracy {
    case far           // > 20 cents - red
    case close         // 5-20 cents - cyan muted
    case inTune        // < 5 cents - bright cyan

    init(centOffset: Double) {
        let absoluteOffset = abs(centOffset)
        if absoluteOffset < 5 {
            self = .inTune
        } else if absoluteOffset < 20 {
            self = .close
        } else {
            self = .far
        }
    }

    var color: Color {
        switch self {
        case .far: return HapticColors.warningRed
        case .close: return HapticColors.cyanMuted
        case .inTune: return HapticColors.cyanBright
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .far: return 4
        case .close: return 8
        case .inTune: return 16
        }
    }
}

// MARK: - Tuner Preset

/// Predefined tuning presets for different instruments
struct TunerPreset: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let notes: [String]  // Expected notes for the instrument
    let icon: String     // SF Symbol

    static let chromatic = TunerPreset(
        name: "Chromatic",
        notes: [],  // All notes
        icon: "waveform"
    )

    static let guitarStandard = TunerPreset(
        name: "Guitar Standard",
        notes: ["E2", "A2", "D3", "G3", "B3", "E4"],
        icon: "guitars"
    )

    static let guitarDropD = TunerPreset(
        name: "Guitar Drop D",
        notes: ["D2", "A2", "D3", "G3", "B3", "E4"],
        icon: "guitars"
    )

    static let bassStandard = TunerPreset(
        name: "Bass Standard",
        notes: ["E1", "A1", "D2", "G2"],
        icon: "guitars.fill"
    )

    static let bassDropD = TunerPreset(
        name: "Bass Drop D",
        notes: ["D1", "A1", "D2", "G2"],
        icon: "guitars.fill"
    )

    static let ukulele = TunerPreset(
        name: "Ukulele",
        notes: ["G4", "C4", "E4", "A4"],
        icon: "music.note"
    )

    static let allPresets: [TunerPreset] = [
        .chromatic,
        .guitarStandard,
        .guitarDropD,
        .bassStandard,
        .bassDropD,
        .ukulele
    ]
}

// MARK: - Reference Pitch

/// Common reference pitch options
struct ReferencePitch {
    let frequency: Double
    let displayName: String

    static let standard = ReferencePitch(frequency: 440.0, displayName: "A4 = 440 Hz")
    static let baroque = ReferencePitch(frequency: 415.0, displayName: "A4 = 415 Hz")
    static let concert = ReferencePitch(frequency: 442.0, displayName: "A4 = 442 Hz")
    static let scientific = ReferencePitch(frequency: 432.0, displayName: "A4 = 432 Hz")

    static let range: ClosedRange<Double> = 430...450
    static let extendedRange: ClosedRange<Double> = 415...466
}

// MARK: - Pitch Detection Result

/// Result from pitch detection algorithm
struct PitchDetectionResult {
    let frequency: Double
    let confidence: Double  // 0.0 to 1.0
    let amplitude: Double   // Signal strength
    let timestamp: Date

    var isValid: Bool {
        confidence > 0.85 && amplitude > 0.01
    }
}

// MARK: - Tuner Configuration

/// User-configurable tuner settings
struct TunerConfiguration: Codable {
    var referencePitch: Double = 440.0
    var inTuneThreshold: Double = 5.0  // cents
    var closeThreshold: Double = 20.0  // cents
    var hapticFeedbackEnabled: Bool = true
    var autoDetectEnabled: Bool = true

    static let `default` = TunerConfiguration()
}
