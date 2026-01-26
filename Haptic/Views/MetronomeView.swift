import SwiftUI

/// MetronomeView - Main iPhone interface with RiffForge-inspired design
/// Features: BPM display, beat sequencer, time signature selection, play controls

struct MetronomeView: View {
    @StateObject private var metronome = MetronomeManager()
    @StateObject private var watchSync = WatchSyncManager.shared

    @State private var showingTimeSignaturePicker = false
    @State private var showingPresets = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            // Background
            HapticColors.deepBlack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Spacer()

                // BPM Display
                bpmDisplay

                Spacer()

                // Beat Sequencer
                beatSequencer
                    .padding(.horizontal, 20)

                Spacer()

                // Time Signature & Subdivisions
                controlsRow
                    .padding(.horizontal, 20)

                Spacer()

                // Play Button
                playButton
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: metronome.bpm) { _, newValue in
            syncToWatch()
        }
        .onChange(of: metronome.isPlaying) { _, newValue in
            syncToWatch()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Watch connection indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(watchSync.isReachable ? HapticColors.neonGreen : HapticColors.warningRed)
                    .frame(width: 8, height: 8)

                Text(watchSync.isReachable ? "Watch Connected" : "Watch Not Connected")
                    .font(.caption)
                    .foregroundColor(HapticColors.secondaryText)
            }

            Spacer()

            // Settings button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
                    .font(.title3)
                    .foregroundColor(HapticColors.secondaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - BPM Display

    private var bpmDisplay: some View {
        VStack(spacing: 8) {
            // BPM Value with tap gesture for tap tempo
            Text("\(metronome.bpm)")
                .font(.system(size: 120, weight: .bold, design: .monospaced))
                .foregroundColor(HapticColors.primaryText)
                .onTapGesture {
                    metronome.tap()
                }

            Text("BPM")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HapticColors.secondaryText)
                .tracking(4)

            // BPM Stepper
            HStack(spacing: 40) {
                // Decrement buttons
                HStack(spacing: 16) {
                    bpmButton(delta: -10)
                    bpmButton(delta: -1)
                }

                // Tap tempo hint
                Text("TAP FOR TEMPO")
                    .font(.caption2)
                    .foregroundColor(HapticColors.tertiaryText)

                // Increment buttons
                HStack(spacing: 16) {
                    bpmButton(delta: 1)
                    bpmButton(delta: 10)
                }
            }
            .padding(.top, 16)
        }
    }

    private func bpmButton(delta: Int) -> some View {
        Button(action: { metronome.bpm += delta }) {
            Text(delta > 0 ? "+\(delta)" : "\(delta)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(HapticColors.primaryText)
                .frame(width: 44, height: 36)
                .background(HapticColors.darkGray)
                .cornerRadius(8)
        }
    }

    // MARK: - Beat Sequencer

    private var beatSequencer: some View {
        VStack(spacing: 12) {
            Text("ACCENT PATTERN")
                .font(.caption)
                .foregroundColor(HapticColors.secondaryText)
                .tracking(2)

            // Beat grid
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 8),
                    count: min(metronome.timeSignature.beatsPerBar, 8)
                ),
                spacing: 8
            ) {
                ForEach(0..<metronome.accentPattern.count, id: \.self) { index in
                    BeatCell(
                        index: index,
                        isAccented: metronome.accentPattern[index],
                        isCurrent: metronome.isPlaying && metronome.currentBeat == index
                    ) {
                        // Toggle accent
                        metronome.accentPattern[index].toggle()
                    }
                }
            }

            // Preset patterns
            HStack(spacing: 12) {
                ForEach(MetronomeManager.AccentPreset.allCases, id: \.rawValue) { preset in
                    Button(action: { metronome.applyPreset(preset) }) {
                        Text(preset.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(HapticColors.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(HapticColors.charcoal)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Controls Row

    private var controlsRow: some View {
        HStack(spacing: 20) {
            // Time Signature
            Button(action: { showingTimeSignaturePicker = true }) {
                VStack(spacing: 4) {
                    Text(metronome.timeSignature.displayString)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(HapticColors.electricBlue)

                    Text("TIME SIG")
                        .font(.caption2)
                        .foregroundColor(HapticColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(HapticColors.charcoal)
                .cornerRadius(12)
            }
            .sheet(isPresented: $showingTimeSignaturePicker) {
                TimeSignaturePickerView(
                    selectedTimeSignature: $metronome.timeSignature
                )
            }

            // Subdivisions
            Button(action: { metronome.subdivisionEnabled.toggle() }) {
                VStack(spacing: 4) {
                    Text(metronome.subdivisionEnabled ? metronome.subdivisionType.displayName : "OFF")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(
                            metronome.subdivisionEnabled
                                ? HapticColors.neonGreen
                                : HapticColors.tertiaryText
                        )

                    Text("SUBDIVIDE")
                        .font(.caption2)
                        .foregroundColor(HapticColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(HapticColors.charcoal)
                .cornerRadius(12)
            }
            .simultaneousGesture(
                LongPressGesture().onEnded { _ in
                    // Cycle subdivision types on long press
                    let allTypes = SubdivisionType.allCases
                    if let currentIndex = allTypes.firstIndex(of: metronome.subdivisionType) {
                        let nextIndex = (currentIndex + 1) % allTypes.count
                        metronome.subdivisionType = allTypes[nextIndex]
                        metronome.subdivisionEnabled = true
                    }
                }
            )
        }
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button(action: { metronome.toggle() }) {
            ZStack {
                // Outer ring - pulses when playing
                Circle()
                    .stroke(
                        metronome.isPlaying ? HapticColors.electricBlue : HapticColors.darkGray,
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(metronome.isPlaying ? 1.1 : 1.0)
                    .animation(
                        metronome.isPlaying
                            ? .easeInOut(duration: 60.0 / Double(metronome.bpm)).repeatForever(autoreverses: true)
                            : .default,
                        value: metronome.isPlaying
                    )

                // Inner button
                Circle()
                    .fill(
                        metronome.isPlaying
                            ? HapticColors.electricBlue
                            : HapticColors.charcoal
                    )
                    .frame(width: 80, height: 80)

                // Icon
                Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(
                        metronome.isPlaying
                            ? HapticColors.deepBlack
                            : HapticColors.electricBlue
                    )
                    .offset(x: metronome.isPlaying ? 0 : 3) // Optical centering for play icon
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sync

    private func syncToWatch() {
        let state = MetronomeState(
            bpm: metronome.bpm,
            isPlaying: metronome.isPlaying,
            timeSignature: metronome.timeSignature,
            accentPattern: metronome.accentPattern,
            subdivisionEnabled: metronome.subdivisionEnabled,
            subdivisionType: metronome.subdivisionType
        )
        watchSync.syncState(state)
    }
}

// MARK: - Beat Cell

struct BeatCell: View {
    let index: Int
    let isAccented: Bool
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .frame(height: 56)

                // Beat number
                Text("\(index + 1)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(textColor)

                // Accent indicator
                if isAccented {
                    VStack {
                        Circle()
                            .fill(HapticColors.electricBlue)
                            .frame(width: 6, height: 6)
                        Spacer()
                    }
                    .padding(.top, 6)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isCurrent ? 1.1 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.5), value: isCurrent)
    }

    private var backgroundColor: Color {
        if isCurrent {
            return isAccented ? HapticColors.electricBlue : HapticColors.neonGreen
        } else if isAccented {
            return HapticColors.darkGray
        } else {
            return HapticColors.charcoal
        }
    }

    private var textColor: Color {
        if isCurrent {
            return HapticColors.deepBlack
        } else {
            return isAccented ? HapticColors.primaryText : HapticColors.secondaryText
        }
    }
}

// MARK: - Time Signature Picker

struct TimeSignaturePickerView: View {
    @Binding var selectedTimeSignature: TimeSignature
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                HapticColors.deepBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Standard
                        sectionView(
                            title: "STANDARD",
                            signatures: [.common, .waltz, .cut, .sixEight]
                        )

                        // Prog / Complex
                        sectionView(
                            title: "PROG / COMPLEX",
                            signatures: [.fiveFour, .sevenEight, .elevenEight, .thirteenSixteen, .fifteenSixteen]
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Time Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(HapticColors.electricBlue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionView(title: String, signatures: [TimeSignature]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundColor(HapticColors.secondaryText)
                .tracking(2)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ForEach(signatures, id: \.displayString) { ts in
                    Button(action: {
                        selectedTimeSignature = ts
                        dismiss()
                    }) {
                        Text(ts.displayString)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(
                                ts == selectedTimeSignature
                                    ? HapticColors.deepBlack
                                    : HapticColors.primaryText
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                ts == selectedTimeSignature
                                    ? HapticColors.electricBlue
                                    : HapticColors.charcoal
                            )
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MetronomeView()
}
