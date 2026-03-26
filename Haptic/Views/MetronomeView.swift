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

                // BPM Knob (combined display + control)
                bpmKnobSection
                    .padding(.horizontal, 20)

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

    // MARK: - BPM Knob (Combined Display + Control)

    private var bpmKnobSection: some View {
        ZStack {
            // Rotary knob with LED ring
            ArcSlider(value: $metronome.bpm, range: 40...300)
                .frame(width: 260, height: 260)

            // BPM display overlay (centered on knob)
            VStack(spacing: 2) {
                Text("\(metronome.bpm)")
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: metronome.bpm)
                    .scaleEffect(metronome.isPlaying ? 1.0 + pulseIntensity * 0.03 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: pulseIntensity)

                Text("BPM")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(6)

                // Precision steppers
                HStack(spacing: 24) {
                    precisionButton(delta: -1)

                    Text("TAP")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(HapticColors.tertiaryText)
                        .tracking(2)
                        .onTapGesture { metronome.tap() }

                    precisionButton(delta: 1)
                }
                .padding(.top, 6)
            }
            .allowsHitTesting(true)
        }
    }

    private func precisionButton(delta: Int) -> some View {
        Button(action: { metronome.bpm += delta }) {
            Text(delta > 0 ? "+" : "−")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.electricBlue)
                .frame(width: 32, height: 32)
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
        VStack(spacing: 6) {
            // LED bar above transport button
            RoundedRectangle(cornerRadius: 2)
                .fill(metronome.isPlaying ? HapticColors.electricBlue : Color(hex: "1a1a1a"))
                .frame(width: 160, height: 3)
                .shadow(color: metronome.isPlaying ? HapticColors.electricBlue.opacity(0.7) : .clear, radius: 4)
                .shadow(color: metronome.isPlaying ? HapticColors.electricBlue.opacity(0.3) : .clear, radius: 8)

            Button(action: { metronome.toggle() }) {
                ZStack {
                    // Button well (recessed slot)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "06060a"))
                        .overlay(
                            LinearGradient(
                                colors: [Color.black.opacity(0.7), Color.clear],
                                startPoint: .top, endPoint: .center
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .frame(width: 160, height: 56)

                    // Button face
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: metronome.isPlaying
                                    ? [Color(hex: "141420"), Color(hex: "1a1a26")]
                                    : [Color(hex: "2a2a36"), Color(hex: "1e1e28")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    metronome.isPlaying
                                        ? Color.black.opacity(0.4)
                                        : Color.white.opacity(0.08),
                                    lineWidth: 0.5
                                )
                        )
                        // Inner shadow for pushed state
                        .overlay(
                            metronome.isPlaying
                                ? RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.black.opacity(0.6), lineWidth: 2)
                                    .blur(radius: 2)
                                    .mask(RoundedRectangle(cornerRadius: 6))
                                : nil
                        )
                        .shadow(
                            color: metronome.isPlaying ? .clear : .black.opacity(0.6),
                            radius: metronome.isPlaying ? 0 : 4,
                            y: metronome.isPlaying ? 0 : 3
                        )
                        .frame(width: 154, height: 50)
                        .offset(y: metronome.isPlaying ? 2 : 0)

                    // Icon centered
                    Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: metronome.isPlaying ? 20 : 22, weight: .semibold))
                        .foregroundColor(
                            metronome.isPlaying
                                ? HapticColors.electricBlue
                                : Color(hex: "6a6a7a")
                        )
                        .shadow(color: metronome.isPlaying ? HapticColors.electricBlue.opacity(0.5) : .clear,
                                radius: 8)
                        .contentTransition(.symbolEffect(.replace.downUp))
                        .offset(y: metronome.isPlaying ? 2 : 0)
                }
            }
            .buttonStyle(.plain)
            .animation(.easeOut(duration: 0.1), value: metronome.isPlaying)

            // Silk-screened label
            Text("PLAY / STOP")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.tertiaryText)
                .tracking(3)
        }
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
            VStack(spacing: 4) {
                // LED bar above button
                RoundedRectangle(cornerRadius: 2)
                    .fill(ledBarColor)
                    .frame(height: 3)
                    .shadow(color: ledBarGlow, radius: isCurrent || isAccented ? 4 : 0)
                    .shadow(color: ledBarGlow.opacity(0.5), radius: isCurrent || isAccented ? 8 : 0)
                    .padding(.horizontal, 4)

                ZStack {
                    // Chassis slot
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "0d0d14"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black.opacity(0.6), lineWidth: 1)
                        )

                    // Button face
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: isAccented
                                    ? [Color(hex: "16161d"), Color(hex: "1a1a24")]
                                    : [Color(hex: "282832"), Color(hex: "1e1e28")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(buttonStroke, lineWidth: 0.5)
                        )
                        .shadow(
                            color: isAccented ? .clear : .black.opacity(0.5),
                            radius: isAccented ? 0 : 3,
                            y: isAccented ? 0 : 2
                        )
                        .overlay(
                            isAccented
                                ? RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black.opacity(0.6), lineWidth: 2)
                                    .blur(radius: 2)
                                    .mask(RoundedRectangle(cornerRadius: 4))
                                : nil
                        )
                        .padding(.horizontal, isAccented ? 3 : 2)
                        .offset(y: isAccented ? 1.5 : 0)

                    // Beat number
                    Text("\(index + 1)")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(labelColor)
                        .shadow(color: isAccented ? HapticColors.electricBlue.opacity(0.4) : .clear, radius: 4)
                        .offset(y: isAccented ? 1.5 : 0)
                }
                .frame(height: 48)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.08), value: isCurrent)
        .animation(.easeOut(duration: 0.12), value: isAccented)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(isAccented ? .isSelected : [])
    }

    private var buttonStroke: Color {
        if isCurrent {
            return HapticColors.electricBlue.opacity(isAccented ? 0.4 : 0.25)
        }
        return isAccented
            ? Color.black.opacity(0.2)
            : Color.white.opacity(0.07)
    }

    private var labelColor: Color {
        // Accented (pushed in) = label lit
        // Current beat playing = only LED bar lights, not the label
        if isAccented { return HapticColors.electricBlue }
        return Color(hex: "555566")
    }

    private var ledBarColor: Color {
        if isCurrent && isAccented { return .white }
        if isCurrent { return HapticColors.electricBlue }
        if isAccented { return HapticColors.electricBlue.opacity(0.8) }
        return Color(hex: "1a1a1a")
    }

    private var ledBarGlow: Color {
        if isCurrent && isAccented { return .white }
        if isCurrent { return HapticColors.electricBlue }
        if isAccented { return HapticColors.electricBlue.opacity(0.5) }
        return .clear
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
                // LCD panel
                ZStack {
                    // Recessed bezel
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "08080c"))
                        .overlay(
                            LinearGradient(
                                colors: [Color.black.opacity(0.6), Color.clear],
                                startPoint: .top, endPoint: .center
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black.opacity(0.7), lineWidth: 1)
                        )

                    // LCD glass
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0a120a"), Color(hex: "080e08")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .padding(2)

                    // Ghost segments
                    Text(ghostText)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "0d1a1a"))

                    // Active value
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? HapticColors.electricBlue : Color(hex: "1a3333"))
                        .shadow(color: isActive ? HapticColors.electricBlue.opacity(0.5) : .clear, radius: 6)
                        .shadow(color: isActive ? HapticColors.electricBlue.opacity(0.2) : .clear, radius: 12)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)

                // Silk-screened label
                Text(title)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(2)
            }
        }
        .buttonStyle(.plain)
    }

    private var ghostText: String {
        if title == "TIME SIG" { return "8/8" }
        return "888"
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
