import SwiftUI
import WatchKit

/// WatchMetronomeView - Minimalist "Focus Mode" interface for Apple Watch
/// Features: Large BPM display, Start/Stop, Digital Crown BPM adjustment
/// Designed for quick glances during practice sessions

struct WatchMetronomeView: View {
    @StateObject private var viewModel = WatchMetronomeViewModel()

    // Digital Crown state
    @State private var crownValue: Double = 120
    @State private var isCrownActive = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 4) {
                // Status indicator
                statusIndicator

                // BPM Display (main focus)
                bpmDisplay

                // Beat indicator
                beatIndicator

                // Play/Stop button
                playButton
            }
        }
        .focusable(true)
        .digitalCrownRotation(
            $crownValue,
            from: 20,
            through: 300,
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, newValue in
            viewModel.bpm = Int(newValue)
            isCrownActive = true

            // Auto-hide crown indicator after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isCrownActive = false
            }
        }
        .onAppear {
            crownValue = Double(viewModel.bpm)
        }
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            // iPhone connection status
            Circle()
                .fill(viewModel.isPhoneReachable ? Color.green : Color.red)
                .frame(width: 6, height: 6)

            // Workout session status
            if viewModel.isWorkoutActive {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }

            Spacer()

            // Time signature
            Text(viewModel.timeSignature.displayString)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - BPM Display

    private var bpmDisplay: some View {
        VStack(spacing: 0) {
            // Crown adjustment indicator
            if isCrownActive {
                Image(systemName: "digitalcrown.horizontal.arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(WatchColors.electricBlue)
                    .transition(.opacity)
            }

            // Large BPM number
            Text("\(viewModel.bpm)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.isPlaying ? WatchColors.electricBlue : .white)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: viewModel.bpm)

            Text("BPM")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
                .tracking(2)
        }
    }

    // MARK: - Beat Indicator

    private var beatIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.timeSignature.beatsPerBar, id: \.self) { beat in
                Circle()
                    .fill(beatColor(for: beat))
                    .frame(width: beatSize(for: beat), height: beatSize(for: beat))
                    .animation(.easeOut(duration: 0.1), value: viewModel.currentBeat)
            }
        }
        .frame(height: 20)
    }

    private func beatColor(for beat: Int) -> Color {
        if viewModel.currentBeat == beat && viewModel.isPlaying {
            return viewModel.accentPattern[safe: beat] == true
                ? WatchColors.electricBlue
                : WatchColors.neonGreen
        } else if viewModel.accentPattern[safe: beat] == true {
            return Color.gray
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private func beatSize(for beat: Int) -> CGFloat {
        let isCurrentBeat = viewModel.currentBeat == beat && viewModel.isPlaying
        let isAccent = viewModel.accentPattern[safe: beat] == true
        let baseSize: CGFloat = isAccent ? 12 : 8
        return isCurrentBeat ? baseSize * 1.3 : baseSize
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button(action: { viewModel.toggle() }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(viewModel.isPlaying ? WatchColors.electricBlue : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)

                // Icon
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(viewModel.isPlaying ? .black : WatchColors.electricBlue)
                    .offset(x: viewModel.isPlaying ? 0 : 2) // Optical centering
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Watch Colors

enum WatchColors {
    static let electricBlue = Color(red: 0, green: 0.83, blue: 1)
    static let neonGreen = Color(red: 0.22, green: 1, blue: 0.08)
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - View Model

@MainActor
class WatchMetronomeViewModel: ObservableObject {
    @Published var bpm: Int = 120 {
        didSet {
            metronome.bpm = bpm
            syncToPhone()
        }
    }

    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0
    @Published var timeSignature: TimeSignature = .common
    @Published var accentPattern: [Bool] = [true, false, false, false]
    @Published var isPhoneReachable: Bool = false
    @Published var isWorkoutActive: Bool = false

    private let metronome = MetronomeManager()
    private let workoutManager = WorkoutSessionManager()
    private let watchSync = WatchSyncManager.shared

    init() {
        setupBindings()
        setupWatchSync()
    }

    private func setupBindings() {
        metronome.onBeat = { [weak self] beat, _ in
            self?.currentBeat = beat
        }

        // Observe metronome state
        metronome.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)

        // Observe workout state
        workoutManager.$isSessionActive
            .receive(on: DispatchQueue.main)
            .assign(to: &$isWorkoutActive)
    }

    private func setupWatchSync() {
        watchSync.onStateReceived = { [weak self] state in
            self?.applyState(state)
        }

        watchSync.onCommandReceived = { [weak self] command in
            self?.handleCommand(command)
        }

        // Observe reachability
        watchSync.$isReachable
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPhoneReachable)
    }

    func toggle() {
        Task {
            if isPlaying {
                metronome.stop()
                try? await workoutManager.stopSession()
            } else {
                // Start workout session first for background execution
                try? await workoutManager.requestAuthorization()
                try? await workoutManager.startSession()

                metronome.start()
            }
            syncToPhone()
        }
    }

    private func applyState(_ state: MetronomeState) {
        bpm = state.bpm
        timeSignature = state.timeSignature
        accentPattern = state.accentPattern

        metronome.bpm = state.bpm
        metronome.timeSignature = state.timeSignature
        metronome.accentPattern = state.accentPattern

        if state.isPlaying && !isPlaying {
            toggle()
        } else if !state.isPlaying && isPlaying {
            toggle()
        }
    }

    private func handleCommand(_ command: MetronomeCommand) {
        switch command {
        case .play:
            if !isPlaying { toggle() }
        case .stop:
            if isPlaying { toggle() }
        case .toggle:
            toggle()
        case .incrementBPM:
            bpm += 1
        case .decrementBPM:
            bpm -= 1
        case .resetToDefaults:
            bpm = 120
            timeSignature = .common
            accentPattern = [true, false, false, false]
        }
    }

    private func syncToPhone() {
        let state = MetronomeState(
            bpm: bpm,
            isPlaying: isPlaying,
            timeSignature: timeSignature,
            accentPattern: accentPattern,
            subdivisionEnabled: false,
            subdivisionType: .eighth
        )
        watchSync.syncState(state)
    }
}

// MARK: - Preview

#Preview {
    WatchMetronomeView()
}
