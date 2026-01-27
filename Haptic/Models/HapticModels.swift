import Foundation
import SwiftUI

// MARK: - Metronome Preset

/// A saved metronome configuration for quick recall
struct MetronomePreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var bpm: Int
    var timeSignature: TimeSignature
    var accentPattern: [Bool]
    var subdivisionEnabled: Bool
    var subdivisionType: SubdivisionType
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        bpm: Int,
        timeSignature: TimeSignature,
        accentPattern: [Bool],
        subdivisionEnabled: Bool = false,
        subdivisionType: SubdivisionType = .eighth
    ) {
        self.id = id
        self.name = name
        self.bpm = bpm
        self.timeSignature = timeSignature
        self.accentPattern = accentPattern
        self.subdivisionEnabled = subdivisionEnabled
        self.subdivisionType = subdivisionType
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Factory presets
    static let progMetal = MetronomePreset(
        name: "Prog Metal 7/8",
        bpm: 140,
        timeSignature: .sevenEight,
        accentPattern: [true, false, false, true, false, true, false]
    )

    static let djent = MetronomePreset(
        name: "Djent",
        bpm: 130,
        timeSignature: .common,
        accentPattern: [true, false, false, true],
        subdivisionEnabled: true,
        subdivisionType: .sixteenth
    )

    static let waltz = MetronomePreset(
        name: "Waltz",
        bpm: 96,
        timeSignature: .waltz,
        accentPattern: [true, false, false]
    )
}

// MARK: - Practice Session

/// Tracks a practice session for analytics
struct PracticeSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var bpmHistory: [BPMChange]
    var totalBeats: Int

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    struct BPMChange: Codable {
        let bpm: Int
        let timestamp: Date
    }

    init() {
        self.id = UUID()
        self.startTime = Date()
        self.bpmHistory = []
        self.totalBeats = 0
    }
}

// MARK: - Design System

/// RiffForge-inspired color palette - MONOCHROMATIC CYAN
/// Single accent color family for visual consistency
enum HapticColors {
    // Primary backgrounds
    static let deepBlack = Color(hex: "0A0A0F")      // Slight blue undertone
    static let charcoal = Color(hex: "14141A")       // Card backgrounds
    static let darkGray = Color(hex: "1E1E26")       // Elevated surfaces

    // Accent colors - CYAN FAMILY ONLY
    static let electricBlue = Color(hex: "00D4FF")   // Primary accent
    static let cyanBright = Color(hex: "5CFFFF")     // Current beat (bright cyan)
    static let cyanMuted = Color(hex: "0099B8")      // Slider mid-range
    static let cyanDark = Color(hex: "006680")       // Inactive/dim states

    // Legacy (keeping for compatibility but avoid using)
    static let neonGreen = cyanBright               // Remapped to cyan
    static let accentPurple = Color(hex: "0088AA")  // Remapped to dark cyan
    static let warningRed = Color(hex: "FF6B6B")    // Softer red for errors

    // Text colors
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "7A8A99")  // Cooler gray
    static let tertiaryText = Color(hex: "3A4550")   // Darker cool gray

    // Beat indicator colors - MONOCHROMATIC
    static let accentBeat = electricBlue            // Accented beat marker
    static let normalBeat = Color(hex: "3A4550")    // Normal beat (dark)
    static let currentBeat = cyanBright             // Current beat (WHITE-CYAN)
    static let currentBeatAccent = Color.white      // Current + Accent = WHITE
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Beat Grid Configuration

/// Configuration for the beat sequencer grid
struct BeatGridConfig {
    let columns: Int
    let rows: Int
    let beatSpacing: CGFloat
    let beatSize: CGFloat

    static func forTimeSignature(_ ts: TimeSignature, in width: CGFloat) -> BeatGridConfig {
        let beats = ts.beatsPerBar
        let columns = min(beats, 8) // Max 8 per row
        let rows = Int(ceil(Double(beats) / Double(columns)))
        let spacing: CGFloat = 8
        let availableWidth = width - (CGFloat(columns + 1) * spacing)
        let beatSize = availableWidth / CGFloat(columns)

        return BeatGridConfig(
            columns: columns,
            rows: rows,
            beatSpacing: spacing,
            beatSize: min(beatSize, 60) // Max 60pt
        )
    }
}

// MARK: - Haptic Feedback Patterns

enum HapticFeedbackPattern: String, CaseIterable {
    case sharp = "Sharp"
    case soft = "Soft"
    case double = "Double Tap"
    case heavy = "Heavy"

    var description: String {
        switch self {
        case .sharp: return "Crisp, percussive click"
        case .soft: return "Gentle, rounded tap"
        case .double: return "Quick double tap for emphasis"
        case .heavy: return "Strong thud for accent beats"
        }
    }
}

// MARK: - App Settings

struct HapticSettings: Codable {
    var accentHapticPattern: String
    var normalHapticPattern: String
    var visualFeedbackEnabled: Bool
    var soundEnabled: Bool
    var keepScreenOn: Bool
    var autoStartWorkoutSession: Bool

    static let `default` = HapticSettings(
        accentHapticPattern: HapticFeedbackPattern.heavy.rawValue,
        normalHapticPattern: HapticFeedbackPattern.sharp.rawValue,
        visualFeedbackEnabled: true,
        soundEnabled: false, // Haptic-first approach
        keepScreenOn: true,
        autoStartWorkoutSession: true
    )
}
