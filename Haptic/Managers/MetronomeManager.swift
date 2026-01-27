import Foundation
import Combine

/// MetronomeManager - High-Precision Timing Engine
/// Uses DispatchSourceTimer for microsecond accuracy, preventing drift
/// during long practice sessions and complex time signatures.
///
/// Design Philosophy:
/// - Absolute timing (not relative intervals) to prevent cumulative drift
/// - Separation of timing and feedback (haptic/audio/visual can be swapped)
/// - Support for prog-metal complexity (7/8, 13/16, polyrhythms)

final class MetronomeManager: ObservableObject {

    // MARK: - Published State
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentBeat: Int = 0
    @Published private(set) var currentSubdivision: Int = 0
    @Published private(set) var currentBar: Int = 0

    @Published var bpm: Int = 120 {
        didSet {
            // Clamp to valid range without causing infinite loop
            let clampedValue = max(20, min(300, bpm))
            if bpm != clampedValue {
                bpm = clampedValue
                return // Exit to avoid double processing
            }
            if isPlaying {
                restartTimer()
            }
        }
    }

    @Published var timeSignature: TimeSignature = .common {
        didSet {
            if isPlaying {
                stop()
                start()
            }
        }
    }

    @Published var accentPattern: [Bool] = [true, false, false, false] {
        didSet {
            // Ensure pattern length matches time signature
            adjustAccentPattern()
        }
    }

    @Published var subdivisionEnabled: Bool = false
    @Published var subdivisionType: SubdivisionType = .eighth

    // MARK: - Timing Engine
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(
        label: "com.haptic.metronome.timer",
        qos: .userInteractive // Highest priority for timing accuracy
    )

    // MARK: - Absolute Timing
    private var startTime: UInt64 = 0
    private var tickCount: UInt64 = 0
    private var machTimebaseInfo = mach_timebase_info_data_t()

    // MARK: - Haptic Integration
    private let hapticEngine: HapticEngine

    // MARK: - Callbacks
    var onBeat: ((Int, Bool) -> Void)?
    var onSubdivision: ((Int) -> Void)?
    var onBarChange: ((Int) -> Void)?

    // MARK: - Computed Properties

    /// Interval between beats in nanoseconds
    private var beatIntervalNanos: UInt64 {
        UInt64((60.0 / Double(bpm)) * 1_000_000_000)
    }

    /// Interval between subdivisions in nanoseconds
    private var subdivisionIntervalNanos: UInt64 {
        beatIntervalNanos / UInt64(subdivisionType.divisor)
    }

    /// Number of ticks per beat (including subdivisions)
    private var ticksPerBeat: Int {
        subdivisionEnabled ? subdivisionType.divisor : 1
    }

    // MARK: - Initialization

    init(hapticEngine: HapticEngine = HapticEngine()) {
        self.hapticEngine = hapticEngine

        // Get mach timebase for nanosecond conversion
        mach_timebase_info(&machTimebaseInfo)

        adjustAccentPattern()
    }

    deinit {
        stop()
    }

    // MARK: - Control Methods

    func start() {
        guard !isPlaying else { return }

        // Prepare haptic engine
        do {
            try hapticEngine.start()
        } catch {
            print("MetronomeManager: Failed to start haptic engine: \(error)")
        }

        // Reset state
        currentBeat = 0
        currentSubdivision = 0
        currentBar = 0
        tickCount = 0

        // Record start time using mach_absolute_time for highest precision
        startTime = mach_absolute_time()

        // Create high-precision timer
        createTimer()

        isPlaying = true
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isPlaying = false
        hapticEngine.stop()
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    // MARK: - Timer Management

    private func createTimer() {
        timer?.cancel()

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: timerQueue)

        // Calculate interval based on subdivision
        let intervalNanos = subdivisionEnabled ? subdivisionIntervalNanos : beatIntervalNanos

        // Use strict timer with tight leeway for precision
        timer.schedule(
            deadline: .now(),
            repeating: .nanoseconds(Int(intervalNanos)),
            leeway: .nanoseconds(100_000) // 0.1ms leeway - very tight
        )

        timer.setEventHandler { [weak self] in
            self?.timerFired()
        }

        timer.resume()
        self.timer = timer
    }

    private func restartTimer() {
        if isPlaying {
            // Calculate where we should be in the current beat
            let currentMachTime = mach_absolute_time()
            let elapsedNanos = machTimeToNanos(currentMachTime - startTime)
            let elapsedBeats = elapsedNanos / beatIntervalNanos

            // Adjust start time to maintain sync
            startTime = currentMachTime - nanosToMachTime(elapsedBeats * beatIntervalNanos)

            createTimer()
        }
    }

    // MARK: - Timer Event Handler

    private func timerFired() {
        // Calculate expected beat based on elapsed time (not tick count)
        // This prevents drift accumulation
        let currentMachTime = mach_absolute_time()
        let elapsedNanos = machTimeToNanos(currentMachTime - startTime)

        let totalTicks: Int
        let tickInterval: UInt64

        if subdivisionEnabled {
            tickInterval = subdivisionIntervalNanos
            totalTicks = Int(elapsedNanos / tickInterval)
        } else {
            tickInterval = beatIntervalNanos
            totalTicks = Int(elapsedNanos / tickInterval)
        }

        // Determine current position
        let tickInBeat = subdivisionEnabled ? (totalTicks % ticksPerBeat) : 0
        let beatInBar = (totalTicks / ticksPerBeat) % timeSignature.beatsPerBar
        let bar = (totalTicks / ticksPerBeat) / timeSignature.beatsPerBar

        // Check for beat change
        let newBeat = beatInBar
        let newBar = bar
        let isNewBeat = tickInBeat == 0

        // Update state on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.currentSubdivision = tickInBeat

            if isNewBeat {
                self.currentBeat = newBeat

                if newBar != self.currentBar {
                    self.currentBar = newBar
                    self.onBarChange?(newBar)
                }

                // Trigger haptic and callback
                let isAccented = self.isAccentedBeat(newBeat)
                self.hapticEngine.playBeat(isAccented: isAccented, isSubdivision: false)
                self.onBeat?(newBeat, isAccented)

            } else if self.subdivisionEnabled {
                // Subdivision tick (not on beat)
                self.hapticEngine.playSubdivision()
                self.onSubdivision?(tickInBeat)
            }
        }

        tickCount = UInt64(totalTicks)
    }

    // MARK: - Accent Pattern

    private func isAccentedBeat(_ beat: Int) -> Bool {
        guard beat < accentPattern.count else { return false }
        return accentPattern[beat]
    }

    private func adjustAccentPattern() {
        let requiredLength = timeSignature.beatsPerBar

        if accentPattern.count < requiredLength {
            // Extend pattern
            accentPattern.append(contentsOf: Array(repeating: false, count: requiredLength - accentPattern.count))
        } else if accentPattern.count > requiredLength {
            // Trim pattern
            accentPattern = Array(accentPattern.prefix(requiredLength))
        }

        // Ensure first beat is accented by default
        if !accentPattern.isEmpty && !accentPattern.contains(true) {
            accentPattern[0] = true
        }
    }

    // MARK: - Mach Time Conversion

    private func machTimeToNanos(_ machTime: UInt64) -> UInt64 {
        return machTime * UInt64(machTimebaseInfo.numer) / UInt64(machTimebaseInfo.denom)
    }

    private func nanosToMachTime(_ nanos: UInt64) -> UInt64 {
        return nanos * UInt64(machTimebaseInfo.denom) / UInt64(machTimebaseInfo.numer)
    }

    // MARK: - Tap Tempo

    private var tapTimes: [Date] = []
    private let maxTapSamples = 4

    func tap() {
        let now = Date()

        // Clear old taps (more than 2 seconds ago)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 2.0 }

        tapTimes.append(now)

        // Need at least 2 taps to calculate tempo
        guard tapTimes.count >= 2 else { return }

        // Calculate average interval
        var intervals: [TimeInterval] = []
        for i in 1..<tapTimes.count {
            intervals.append(tapTimes[i].timeIntervalSince(tapTimes[i-1]))
        }

        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let calculatedBPM = Int(60.0 / averageInterval)

        bpm = max(20, min(300, calculatedBPM))
    }

    func clearTapTempo() {
        tapTimes.removeAll()
    }
}

// MARK: - Time Signature

struct TimeSignature: Equatable, Codable {
    let beatsPerBar: Int
    let beatUnit: Int // 4 = quarter note, 8 = eighth note, etc.

    var displayString: String {
        "\(beatsPerBar)/\(beatUnit)"
    }

    // Common time signatures
    static let common = TimeSignature(beatsPerBar: 4, beatUnit: 4)      // 4/4
    static let waltz = TimeSignature(beatsPerBar: 3, beatUnit: 4)       // 3/4
    static let cut = TimeSignature(beatsPerBar: 2, beatUnit: 2)         // 2/2
    static let sixEight = TimeSignature(beatsPerBar: 6, beatUnit: 8)    // 6/8

    // Prog-metal signatures
    static let sevenEight = TimeSignature(beatsPerBar: 7, beatUnit: 8)      // 7/8
    static let fiveFour = TimeSignature(beatsPerBar: 5, beatUnit: 4)        // 5/4
    static let elevenEight = TimeSignature(beatsPerBar: 11, beatUnit: 8)    // 11/8
    static let thirteenSixteen = TimeSignature(beatsPerBar: 13, beatUnit: 16) // 13/16
    static let fifteenSixteen = TimeSignature(beatsPerBar: 15, beatUnit: 16)  // 15/16

    // All presets
    static let presets: [TimeSignature] = [
        .common, .waltz, .cut, .sixEight,
        .fiveFour, .sevenEight, .elevenEight,
        .thirteenSixteen, .fifteenSixteen
    ]
}

// MARK: - Subdivision Type

enum SubdivisionType: Int, CaseIterable, Codable {
    case eighth = 2       // 1/8 notes
    case triplet = 3      // Triplets
    case sixteenth = 4    // 1/16 notes

    var divisor: Int {
        rawValue
    }

    var displayName: String {
        switch self {
        case .eighth: return "8ths"
        case .triplet: return "Triplets"
        case .sixteenth: return "16ths"
        }
    }
}

// MARK: - Preset Patterns

extension MetronomeManager {

    /// Common accent pattern presets for prog-metal
    enum AccentPreset: String, CaseIterable {
        case standard      // First beat only
        case backbeat      // 2 and 4
        case allAccent     // Every beat
        case djent         // Syncopated prog pattern

        func pattern(for timeSignature: TimeSignature) -> [Bool] {
            let beats = timeSignature.beatsPerBar

            switch self {
            case .standard:
                return [true] + Array(repeating: false, count: beats - 1)

            case .backbeat:
                return (0..<beats).map { ($0 + 1) % 2 == 0 } // 2, 4, 6...

            case .allAccent:
                return Array(repeating: true, count: beats)

            case .djent:
                // Meshuggah-style: accent on 1, then irregular pattern
                if beats == 4 {
                    return [true, false, false, true]
                } else if beats == 7 {
                    return [true, false, false, true, false, true, false]
                } else if beats == 8 {
                    return [true, false, false, true, false, false, true, false]
                } else {
                    // Default: first and middle-ish
                    var pattern = Array(repeating: false, count: beats)
                    pattern[0] = true
                    if beats > 3 {
                        pattern[beats / 2] = true
                    }
                    return pattern
                }
            }
        }
    }

    func applyPreset(_ preset: AccentPreset) {
        accentPattern = preset.pattern(for: timeSignature)
    }
}
