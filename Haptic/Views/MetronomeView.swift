import SwiftUI

/// MetronomeView - Main iPhone interface with RiffForge Cyberpunk aesthetic
/// Features: Arc slider, hexagonal BPM display, beat sequencer, pulse animations

struct MetronomeView: View {
    @StateObject private var metronome = MetronomeManager()
    @StateObject private var watchSync = WatchSyncManager.shared

    @State private var showingTimeSignaturePicker = false
    @State private var showingPresets = false
    @State private var showingSettings = false
    @State private var showingTuner = false
    @State private var pulseIntensity: Double = 0

    var body: some View {
        ZStack {
            // Cyberpunk Background
            CyberpunkBackground(
                showScanLines: true,
                showCircuitPattern: true,
                pulseIntensity: metronome.isPlaying ? pulseIntensity : 0
            )

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 8)

                Spacer()

                // BPM Display with Hexagonal Frame
                bpmDisplaySection

                // Arc Slider
                arcSliderSection
                    .padding(.horizontal, 30)

                Spacer()

                // Beat Sequencer
                beatSequencerSection
                    .padding(.horizontal, 20)

                Spacer()

                // Time Signature & Subdivisions
                controlsRow
                    .padding(.horizontal, 20)

                Spacer()

                // Play Button
                playButtonSection
                    .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(metronome.$currentBeat) { _ in
            if metronome.isPlaying {
                triggerPulse()
            }
        }
        .onChange(of: metronome.bpm) { _, _ in
            syncToWatch()
        }
        .onChange(of: metronome.isPlaying) { _, _ in
            syncToWatch()
        }
        .fullScreenCover(isPresented: $showingTuner) {
            TunerView()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Watch connection indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(watchSync.isReachable ? HapticColors.electricBlue : HapticColors.warningRed)
                    .frame(width: 8, height: 8)
                    .neonGlow(color: watchSync.isReachable ? HapticColors.electricBlue : HapticColors.warningRed, radius: 4)

                Text(watchSync.isReachable ? "WATCH LINKED" : "WATCH OFFLINE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(1)
            }

            Spacer()

            // App title
            Text("HAPTIC")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(HapticColors.electricBlue)
                .tracking(4)

            Spacer()

            // Tuner & Settings buttons
            HStack(spacing: 16) {
                Button(action: { showingTuner = true }) {
                    Image(systemName: "tuningfork")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HapticColors.electricBlue)
                }

                Button(action: { showingSettings = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HapticColors.secondaryText)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - BPM Display

    private var bpmDisplaySection: some View {
        ZStack {
            // Hexagonal frame with pulse
            HexagonalFrame(
                strokeColor: metronome.isPlaying ? HapticColors.electricBlue : HapticColors.darkGray,
                glowColor: metronome.isPlaying ? HapticColors.electricBlue : .clear
            )
            .frame(width: 220, height: 220)
            .scaleEffect(metronome.isPlaying ? 1.0 + pulseIntensity * 0.03 : 1.0)
            .animation(.easeOut(duration: 0.1), value: pulseIntensity)

            VStack(spacing: 4) {
                // BPM Value
                Text("\(metronome.bpm)")
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: metronome.bpm)
                    .onTapGesture {
                        metronome.tap()
                    }

                Text("BPM")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(6)

                // Precision steppers
                HStack(spacing: 30) {
                    precisionButton(delta: -1)

                    Text("TAP")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(HapticColors.tertiaryText)
                        .tracking(2)

                    precisionButton(delta: 1)
                }
                .padding(.top, 8)
            }
        }
    }

    private func precisionButton(delta: Int) -> some View {
        Button(action: { metronome.bpm += delta }) {
            Text(delta > 0 ? "+" : "−")
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.electricBlue)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(HapticColors.charcoal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(HapticColors.electricBlue.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Arc Slider

    private var arcSliderSection: some View {
        ArcSlider(value: $metronome.bpm, range: 40...300)
            .frame(height: 120)
    }

    // MARK: - Beat Sequencer

    private var beatSequencerSection: some View {
        VStack(spacing: 12) {
            // Section label
            HStack {
                Rectangle()
                    .fill(HapticColors.electricBlue.opacity(0.3))
                    .frame(height: 1)

                Text("PATTERN")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(3)

                Rectangle()
                    .fill(HapticColors.electricBlue.opacity(0.3))
                    .frame(height: 1)
            }

            // Beat grid
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 8),
                    count: min(metronome.timeSignature.beatsPerBar, 8)
                ),
                spacing: 8
            ) {
                ForEach(0..<metronome.accentPattern.count, id: \.self) { index in
                    CyberpunkBeatCell(
                        index: index,
                        isAccented: metronome.accentPattern[index],
                        isCurrent: metronome.isPlaying && metronome.currentBeat == index
                    ) {
                        metronome.accentPattern[index].toggle()
                    }
                }
            }

            // Preset patterns
            HStack(spacing: 8) {
                ForEach(MetronomeManager.AccentPreset.allCases, id: \.rawValue) { preset in
                    PresetButton(
                        title: preset.rawValue.uppercased(),
                        isActive: false
                    ) {
                        metronome.applyPreset(preset)
                    }
                }
            }
        }
    }

    // MARK: - Controls Row

    private var controlsRow: some View {
        HStack(spacing: 16) {
            // Time Signature
            ControlCard(
                title: "TIME SIG",
                value: metronome.timeSignature.displayString,
                isActive: true
            ) {
                showingTimeSignaturePicker = true
            }
            .sheet(isPresented: $showingTimeSignaturePicker) {
                TimeSignaturePickerView(selectedTimeSignature: $metronome.timeSignature)
            }

            // Subdivisions
            ControlCard(
                title: "SUBDIVIDE",
                value: metronome.subdivisionEnabled ? metronome.subdivisionType.displayName.uppercased() : "OFF",
                isActive: metronome.subdivisionEnabled
            ) {
                metronome.subdivisionEnabled.toggle()
            }
        }
    }

    // MARK: - Play Button

    private var playButtonSection: some View {
        Button(action: { metronome.toggle() }) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        metronome.isPlaying ? HapticColors.electricBlue : HapticColors.darkGray,
                        lineWidth: 3
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(metronome.isPlaying ? 1.0 + pulseIntensity * 0.1 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: pulseIntensity)
                    .neonGlow(
                        color: metronome.isPlaying ? HapticColors.electricBlue : .clear,
                        radius: metronome.isPlaying ? 12 : 0
                    )

                // Inner button
                Circle()
                    .fill(
                        metronome.isPlaying
                            ? HapticColors.electricBlue
                            : HapticColors.charcoal
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(HapticColors.electricBlue.opacity(0.5), lineWidth: 1)
                    )

                // Icon
                Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(
                        metronome.isPlaying
                            ? HapticColors.deepBlack
                            : HapticColors.electricBlue
                    )
                    .offset(x: metronome.isPlaying ? 0 : 3)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Helpers

    private func triggerPulse() {
        pulseIntensity = 1.0
        withAnimation(.easeOut(duration: 0.15)) {
            pulseIntensity = 0
        }
    }

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

// MARK: - Supporting Components

struct CyberpunkBeatCell: View {
    let index: Int
    let isAccented: Bool
    let isCurrent: Bool
    let onTap: () -> Void

    // Accessibility label describing the beat state
    private var accessibilityLabelText: String {
        var label = "Beat \(index + 1)"
        if isAccented {
            label += ", accented"
        }
        if isCurrent {
            label += ", currently playing"
        }
        return label
    }

    private var accessibilityHintText: String {
        isAccented ? "Double tap to remove accent" : "Double tap to add accent"
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .frame(height: 60)

                // Beat number
                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(textColor)

                // Accent indicator
                if isAccented && !isCurrent {
                    VStack {
                        Circle()
                            .fill(HapticColors.electricBlue)
                            .frame(width: 6, height: 6)
                            .neonGlow(color: HapticColors.electricBlue, radius: 4)
                        Spacer()
                    }
                    .padding(.top, 6)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(isCurrent ? 1.08 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isCurrent)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(isAccented ? .isSelected : [])
    }

    private var backgroundColor: Color {
        if isCurrent {
            // Monochromatic: accented current = white, normal current = bright cyan
            return isAccented ? HapticColors.currentBeatAccent : HapticColors.currentBeat
        }
        return HapticColors.charcoal
    }

    private var borderColor: Color {
        if isCurrent {
            return .clear
        }
        return isAccented ? HapticColors.electricBlue.opacity(0.5) : HapticColors.darkGray
    }

    private var textColor: Color {
        if isCurrent {
            return HapticColors.deepBlack
        }
        return isAccented ? HapticColors.primaryText : HapticColors.secondaryText
    }
}

struct PresetButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(isActive ? HapticColors.deepBlack : HapticColors.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isActive ? HapticColors.electricBlue : HapticColors.charcoal)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ControlCard: View {
    let title: String
    let value: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(isActive ? HapticColors.electricBlue : HapticColors.tertiaryText)

                Text(title)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(HapticColors.charcoal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isActive ? HapticColors.electricBlue.opacity(0.3) : HapticColors.darkGray,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Time Signature Picker

struct TimeSignaturePickerView: View {
    @Binding var selectedTimeSignature: TimeSignature
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                CyberpunkBackground(showCircuitPattern: false)

                ScrollView {
                    VStack(spacing: 24) {
                        sectionView(
                            title: "STANDARD",
                            signatures: [.common, .waltz, .cut, .sixEight]
                        )

                        sectionView(
                            title: "PROG / COMPLEX",
                            signatures: [.fiveFour, .sevenEight, .elevenEight, .thirteenSixteen, .fifteenSixteen]
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Time Signature")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(HapticColors.electricBlue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionView(title: String, signatures: [TimeSignature]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Rectangle()
                    .fill(HapticColors.electricBlue.opacity(0.3))
                    .frame(height: 1)

                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(3)

                Rectangle()
                    .fill(HapticColors.electricBlue.opacity(0.3))
                    .frame(height: 1)
            }

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
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        ts == selectedTimeSignature
                                            ? HapticColors.electricBlue
                                            : HapticColors.charcoal
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                ts == selectedTimeSignature
                                                    ? .clear
                                                    : HapticColors.darkGray,
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MetronomeView()
}
