import SwiftUI

/// TunerView - Main chromatic tuner interface
/// Cyberpunk aesthetic matching the app's design language
/// Full-screen tuner with gauge, note display, and frequency info

struct TunerView: View {
    @StateObject private var tuner = TunerEngine()
    @Environment(\.dismiss) private var dismiss

    @State private var showingPresetPicker = false
    @State private var showingReferencePitchPicker = false
    @State private var selectedPreset: TunerPreset = .chromatic
    @State private var hasMicPermission = false
    @State private var showingPermissionAlert = false

    var body: some View {
        ZStack {
            // Cyberpunk Background with pulse based on accuracy
            CyberpunkBackground(
                showScanLines: true,
                showCircuitPattern: true,
                pulseIntensity: tuner.state == .inTune ? 0.5 : 0
            )

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 8)

                Spacer()

                // Main content
                if hasMicPermission {
                    tunerContent
                } else {
                    permissionRequestView
                }

                Spacer()

                // Controls
                controlsSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            hasMicPermission = TunerEngine.hasMicrophonePermission
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Haptic needs microphone access to detect pitch. Please enable it in Settings.")
        }
        .sheet(isPresented: $showingPresetPicker) {
            PresetPickerView(selectedPreset: $selectedPreset)
        }
        .sheet(isPresented: $showingReferencePitchPicker) {
            ReferencePitchPickerView(referencePitch: $tuner.referencePitch)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                tuner.stop()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("METRONOME")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(1)
                }
                .foregroundColor(HapticColors.secondaryText)
            }

            Spacer()

            // Title
            Text("TUNER")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(HapticColors.electricBlue)
                .tracking(4)

            Spacer()

            // Preset selector
            Button(action: { showingPresetPicker = true }) {
                Image(systemName: selectedPreset.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HapticColors.secondaryText)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tuner Content

    private var tunerContent: some View {
        VStack(spacing: 24) {
            // Note Display with hexagonal frame
            noteDisplaySection

            // Gauge
            TunerGauge(
                centOffset: tuner.centOffset,
                accuracy: tuner.accuracy,
                isActive: tuner.state.isActive && tuner.detectedNote != nil
            )
            .padding(.horizontal, 20)

            // Frequency and cent display
            frequencySection

            // Signal strength indicator
            signalStrengthIndicator
        }
    }

    // MARK: - Note Display

    private var noteDisplaySection: some View {
        ZStack {
            // Hexagonal frame with accuracy-based glow
            HexagonalFrame(
                strokeColor: frameColor,
                glowColor: tuner.state == .inTune ? HapticColors.cyanBright : frameColor
            )
            .frame(width: 200, height: 200)
            .scaleEffect(tuner.state == .inTune ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.2), value: tuner.state == .inTune)

            VStack(spacing: 4) {
                // Note name
                if let note = tuner.detectedNote {
                    Text(note.displayName)
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundColor(tuner.accuracy.color)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.15), value: note.name)
                        .neonGlow(color: tuner.accuracy.color, radius: tuner.accuracy.glowRadius)

                    // Octave
                    Text("Octave \(note.octave)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(HapticColors.secondaryText)
                        .tracking(2)
                } else {
                    // No note detected
                    Text("--")
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundColor(HapticColors.tertiaryText)

                    Text(tuner.state.isActive ? "LISTENING" : "TAP TO START")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(HapticColors.secondaryText)
                        .tracking(2)
                }
            }
        }
        .onTapGesture {
            tuner.toggle()
        }
    }

    private var frameColor: Color {
        guard tuner.state.isActive else {
            return HapticColors.darkGray
        }

        if tuner.detectedNote != nil {
            return tuner.accuracy.color
        }

        return HapticColors.electricBlue.opacity(0.5)
    }

    // MARK: - Frequency Section

    private var frequencySection: some View {
        HStack(spacing: 30) {
            // Frequency display
            VStack(spacing: 4) {
                Text(frequencyString)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(HapticColors.primaryText)
                    .contentTransition(.numericText())

                Text("Hz")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)
                    .tracking(2)
            }

            // Cent offset display
            if tuner.detectedNote != nil {
                CentOffsetDisplay(
                    centOffset: tuner.centOffset,
                    accuracy: tuner.accuracy
                )
            }
        }
    }

    private var frequencyString: String {
        if tuner.detectedFrequency > 0 {
            return String(format: "%.1f", tuner.detectedFrequency)
        }
        return "---"
    }

    // MARK: - Signal Strength

    private var signalStrengthIndicator: some View {
        VStack(spacing: 6) {
            // Signal bars
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(signalBarColor(for: index))
                        .frame(width: 8, height: CGFloat(8 + index * 4))
                }
            }

            Text("SIGNAL")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.tertiaryText)
                .tracking(2)
        }
    }

    private func signalBarColor(for index: Int) -> Color {
        let normalizedStrength = min(tuner.signalStrength * 10, 1.0)  // Normalize to 0-1
        let threshold = Double(index + 1) / 5.0

        if normalizedStrength >= threshold && tuner.state.isActive {
            return HapticColors.electricBlue
        }
        return HapticColors.charcoal
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Reference pitch control
            HStack(spacing: 16) {
                ControlCard(
                    title: "REFERENCE",
                    value: "A4=\(Int(tuner.referencePitch))",
                    isActive: true
                ) {
                    showingReferencePitchPicker = true
                }

                ControlCard(
                    title: "PRESET",
                    value: selectedPreset.name.uppercased().prefix(8).description,
                    isActive: true
                ) {
                    showingPresetPicker = true
                }
            }

            // Start/Stop button
            tunerButton
        }
    }

    private var tunerButton: some View {
        Button(action: {
            if hasMicPermission {
                tuner.toggle()
            } else {
                requestMicrophonePermission()
            }
        }) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        tuner.state.isActive ? tuner.accuracy.color : HapticColors.darkGray,
                        lineWidth: 3
                    )
                    .frame(width: 90, height: 90)
                    .neonGlow(
                        color: tuner.state.isActive ? tuner.accuracy.color : .clear,
                        radius: tuner.state.isActive ? 12 : 0
                    )

                // Inner button
                Circle()
                    .fill(
                        tuner.state.isActive
                            ? tuner.accuracy.color
                            : HapticColors.charcoal
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(HapticColors.electricBlue.opacity(0.5), lineWidth: 1)
                    )

                // Icon
                Image(systemName: tuner.state.isActive ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(
                        tuner.state.isActive
                            ? HapticColors.deepBlack
                            : HapticColors.electricBlue
                    )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Permission Request

    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(HapticColors.warningRed)

            VStack(spacing: 8) {
                Text("Microphone Access Required")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(HapticColors.primaryText)

                Text("The tuner needs microphone access to detect pitch from your instrument.")
                    .font(.system(size: 14))
                    .foregroundColor(HapticColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: requestMicrophonePermission) {
                Text("ENABLE MICROPHONE")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(HapticColors.deepBlack)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(HapticColors.electricBlue)
                    .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func requestMicrophonePermission() {
        Task {
            let granted = await TunerEngine.requestMicrophonePermission()
            await MainActor.run {
                hasMicPermission = granted
                if !granted {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

// MARK: - Preset Picker View

struct PresetPickerView: View {
    @Binding var selectedPreset: TunerPreset
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                CyberpunkBackground(showCircuitPattern: false)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(TunerPreset.allPresets) { preset in
                            Button(action: {
                                selectedPreset = preset
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: preset.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(
                                            preset == selectedPreset
                                                ? HapticColors.deepBlack
                                                : HapticColors.electricBlue
                                        )
                                        .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(preset.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(
                                                preset == selectedPreset
                                                    ? HapticColors.deepBlack
                                                    : HapticColors.primaryText
                                            )

                                        if !preset.notes.isEmpty {
                                            Text(preset.notes.joined(separator: " - "))
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(
                                                    preset == selectedPreset
                                                        ? HapticColors.deepBlack.opacity(0.7)
                                                        : HapticColors.secondaryText
                                                )
                                        }
                                    }

                                    Spacer()

                                    if preset == selectedPreset {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(HapticColors.deepBlack)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            preset == selectedPreset
                                                ? HapticColors.electricBlue
                                                : HapticColors.charcoal
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    preset == selectedPreset
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
                    .padding(20)
                }
            }
            .navigationTitle("Tuning Preset")
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
}

// MARK: - Reference Pitch Picker View

struct ReferencePitchPickerView: View {
    @Binding var referencePitch: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                CyberpunkBackground(showCircuitPattern: false)

                VStack(spacing: 30) {
                    // Current value display
                    VStack(spacing: 8) {
                        Text("A4 = \(Int(referencePitch)) Hz")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(HapticColors.electricBlue)
                            .neonGlow(radius: 8)

                        Text("Reference Pitch")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(HapticColors.secondaryText)
                            .tracking(2)
                    }
                    .padding(.top, 30)

                    // Slider
                    VStack(spacing: 8) {
                        Slider(value: $referencePitch, in: ReferencePitch.extendedRange, step: 1)
                            .tint(HapticColors.electricBlue)
                            .padding(.horizontal, 30)

                        HStack {
                            Text("415")
                            Spacer()
                            Text("466")
                        }
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(HapticColors.tertiaryText)
                        .padding(.horizontal, 30)
                    }

                    // Quick presets
                    VStack(spacing: 12) {
                        Text("QUICK PRESETS")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(HapticColors.secondaryText)
                            .tracking(3)

                        HStack(spacing: 12) {
                            presetButton(pitch: 432, label: "432 Hz")
                            presetButton(pitch: 440, label: "440 Hz")
                            presetButton(pitch: 442, label: "442 Hz")
                        }

                        HStack(spacing: 12) {
                            presetButton(pitch: 415, label: "Baroque")
                            presetButton(pitch: 444, label: "444 Hz")
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Reference Pitch")
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

    private func presetButton(pitch: Double, label: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                referencePitch = pitch
            }
        }) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(
                    referencePitch == pitch ? HapticColors.deepBlack : HapticColors.primaryText
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            referencePitch == pitch
                                ? HapticColors.electricBlue
                                : HapticColors.charcoal
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    referencePitch == pitch ? .clear : HapticColors.darkGray,
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    TunerView()
}
