import SwiftUI

/// MetronomeView - Channel Strip design: rack-mounted studio gear aesthetic
/// Features: Arc slider, 7-segment BPM display, recessed panel wells, unified button style

struct MetronomeView: View {
    @StateObject private var metronome = MetronomeManager()
    @StateObject private var watchSync = WatchSyncManager.shared

    @State private var showingSettings = false
    @State private var showingTuner = false
    @State private var pulseIntensity: Double = 0

    /// Compact vertical height == landscape on iPhone. Drives the two-column layout.
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        ZStack {
            // Cyberpunk Background
            CyberpunkBackground(
                showScanLines: true,
                showCircuitPattern: true,
                pulseIntensity: metronome.isPlaying ? pulseIntensity : 0
            )

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
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

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Header (fixed at top)
            headerView
                .padding(.top, 8)
                .padding(.bottom, 4)

            // BPM panel (fixed after header)
            bpmDisplayPanel
                .padding(.horizontal, 20)
                .padding(.top, 8)

            // Knob (centered in remaining space)
            Spacer()
            dialKnob(size: 260)
                .padding(.horizontal, 20)
            Spacer()

            // Bottom controls (fixed height)
            bottomControls
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
        }
    }

    // MARK: - Landscape Layout (two columns to fit the short height)

    private var landscapeLayout: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.top, 6)
                .padding(.bottom, 2)

            HStack(alignment: .top, spacing: 16) {
                // Left column: BPM display + dial
                VStack(spacing: 10) {
                    bpmDisplayPanel
                    Spacer(minLength: 0)
                    dialKnob(size: 190)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)

                // Right column: sequencer + time signature + transport
                bottomControls
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Bottom Controls (shared by both layouts)

    private var bottomControls: some View {
        VStack(spacing: 0) {
            // BEAT PATTERN
            sectionLabel("BEAT PATTERN")
            recessedPanel {
                beatSequencerContent
            }

            Spacer().frame(height: 8)

            // TIME SIGNATURE
            sectionLabel("TIME SIGNATURE")
            recessedPanel {
                timeSignatureContent
            }

            Spacer().frame(height: 8)

            // TRANSPORT
            sectionLabel("TRANSPORT")
            recessedPanel {
                playButtonContent
            }
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

    private var bpmDisplayPanel: some View {
        recessedPanel {
            HStack(alignment: .center) {
                precisionButton(delta: -1)

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    ZStack {
                        Text("888")
                            .font(.custom("DSEG7Classic-Bold", size: 72))
                            .foregroundColor(HapticColors.electricBlue.opacity(0.07))

                        Text("\(metronome.bpm)")
                            .font(.custom("DSEG7Classic-Bold", size: 72))
                            .foregroundColor(HapticColors.electricBlue)
                            .shadow(color: HapticColors.electricBlue.opacity(0.9), radius: 1)
                            .shadow(color: HapticColors.electricBlue.opacity(0.6), radius: 6)
                            .shadow(color: HapticColors.electricBlue.opacity(0.3), radius: 16)
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.linear(duration: 0.05), value: metronome.bpm)
                            .scaleEffect(metronome.isPlaying ? 1.0 + pulseIntensity * 0.03 : 1.0)
                            .animation(.easeOut(duration: 0.1), value: pulseIntensity)
                    }

                    Text("BPM")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(HapticColors.electricBlue.opacity(0.5))
                        .shadow(color: HapticColors.electricBlue.opacity(0.3), radius: 4)
                }
                .onTapGesture { metronome.tap() }

                Spacer()

                precisionButton(delta: 1)
            }
        }
    }

    private func dialKnob(size: CGFloat) -> some View {
        ArcSlider(
            value: $metronome.bpm,
            range: 40...300,
            onDragStarted: {
                metronome.isDraggingDial = true
            },
            onDragEnded: {
                metronome.commitBPMChange()
            }
        )
        .frame(width: size, height: size)
    }

    private func precisionButton(delta: Int) -> some View {
        Button(action: { metronome.bpm += delta }) {
            Text(delta > 0 ? "+" : "\u{2212}")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.electricBlue)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "141419"))
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "222230"), lineWidth: 1)
                )
                .padding(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(ChannelStripButtonStyle())
    }

    // MARK: - Beat Sequencer

    private var beatSequencerContent: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 8),
                count: min(metronome.timeSignature.beatsPerBar, 8)
            ),
            spacing: 8
        ) {
            ForEach(0..<metronome.accentPattern.count, id: \.self) { index in
                ChannelStripBeatCell(
                    index: index,
                    isAccented: metronome.accentPattern[index],
                    isCurrent: metronome.isPlaying && metronome.currentBeat == index
                ) {
                    metronome.accentPattern[index].toggle()
                }
            }
        }
    }

    // MARK: - Time Signature Row

    private let standardSignatures: [TimeSignature] = [.common, .waltz, .cut, .sixEight]

    private var timeSignatureContent: some View {
        HStack(spacing: 8) {
            ForEach(standardSignatures, id: \.displayString) { ts in
                let isSelected = ts == metronome.timeSignature
                Button(action: { metronome.timeSignature = ts }) {
                    Text(ts.displayString)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(isSelected ? Color(hex: "00D4FF") : Color(hex: "4A4A5A"))
                        .shadow(
                            color: isSelected ? Color(hex: "00D4FF").opacity(0.4) : .clear,
                            radius: 4
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color(hex: "1C1C28") : Color(hex: "141419"))
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isSelected
                                        ? Color(hex: "00D4FF").opacity(0.4)
                                        : Color(hex: "222230"),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(ChannelStripButtonStyle())
                .animation(.easeOut(duration: 0.1), value: isSelected)
            }
        }
    }

    // MARK: - Play Button

    private var playButtonContent: some View {
        Button(action: { metronome.toggle() }) {
            HStack(spacing: 10) {
                Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace.downUp))

                Text(metronome.isPlaying ? "STOP" : "PLAY")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .tracking(4)
            }
            .foregroundColor(
                metronome.isPlaying
                    ? Color(hex: "00D4FF")
                    : Color(hex: "4A4A5A")
            )
            .shadow(
                color: metronome.isPlaying ? Color(hex: "00D4FF").opacity(0.5) : .clear,
                radius: 8
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "141419"))
                    if metronome.isPlaying {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "00F0FF").opacity(0.08))
                    }
                }
                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        metronome.isPlaying
                            ? Color(hex: "00D4FF").opacity(0.5)
                            : Color(hex: "222230"),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ChannelStripButtonStyle())
        .animation(.easeOut(duration: 0.08), value: metronome.isPlaying)
    }

    // MARK: - Recessed Panel

    private func recessedPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "06060A"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
            )
            .overlay(
                // Inner shadow: top highlight + bottom shadow
                ZStack {
                    // Top highlight
                    VStack {
                        LinearGradient(
                            colors: [Color.white.opacity(0.04), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 6)
                        Spacer()
                    }
                    // Bottom shadow
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 6)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "33334A"))
                .tracking(3)
            Spacer()
        }
        .padding(.bottom, 4)
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

// MARK: - Channel Strip Beat Cell

struct ChannelStripBeatCell: View {
    let index: Int
    let isAccented: Bool
    let isCurrent: Bool
    let onTap: () -> Void

    private var accessibilityLabelText: String {
        var label = "Beat \(index + 1)"
        if isAccented { label += ", accented" }
        if isCurrent { label += ", currently playing" }
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

                // Unified button
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isAccented ? Color(hex: "1C1C28") : Color(hex: "141419"))
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)

                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isAccented
                                ? Color(hex: "00D4FF").opacity(0.4)
                                : Color(hex: "222230"),
                            lineWidth: 1
                        )

                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(isAccented ? Color(hex: "00D4FF") : Color(hex: "4A4A5A"))
                        .shadow(
                            color: isAccented ? Color(hex: "00D4FF").opacity(0.4) : .clear,
                            radius: 4
                        )
                }
                .frame(height: 48)
                .offset(y: isAccented ? 1 : 0)
            }
        }
        .buttonStyle(ChannelStripButtonStyle())
        .animation(.easeOut(duration: 0.08), value: isCurrent)
        .animation(.easeOut(duration: 0.1), value: isAccented)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(isAccented ? .isSelected : [])
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

// MARK: - Button Styles

struct ChannelStripButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 1 : 0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Time Signature Picker (kept for settings access)

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

// MARK: - Shared Components (used by TunerView etc.)

struct ControlCard: View {
    let title: String
    let value: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "2a2a34"), Color(hex: "1e1e28")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.12),
                                            Color.white.opacity(0.03),
                                            Color.clear
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 3)

                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? HapticColors.electricBlue : Color(hex: "555566"))
                        .shadow(color: isActive ? HapticColors.electricBlue.opacity(0.4) : .clear, radius: 6)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)

                Text(title)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(2)
            }
        }
        .buttonStyle(KeyCapButtonStyle())
    }
}

struct KeyCapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    MetronomeView()
}
