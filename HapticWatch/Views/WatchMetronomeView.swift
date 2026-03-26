import SwiftUI

/// WatchMetronomeView - Retro hardware styled watch interface
/// Compact layout matching iOS cassette deck aesthetic

struct WatchMetronomeView: View {
    @StateObject private var metronome = MetronomeManager()
    @State private var pulseIntensity: Double = 0
    @State private var crownBPM: Double = 120

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Beat pulse overlay
            if metronome.isPlaying && pulseIntensity > 0 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                HapticColors.electricBlue.opacity(pulseIntensity * 0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .scaleEffect(1.0 + pulseIntensity * 0.1)
                    .animation(.easeOut(duration: 0.12), value: pulseIntensity)
            }

            VStack(spacing: 4) {
                // Title
                Text("HAPTIC")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(tempoColor.opacity(0.6))
                    .tracking(3)

                Spacer()

                // BPM LCD display
                bpmLCDDisplay

                // Tempo zone indicator
                tempoZoneBar
                    .padding(.horizontal, 16)

                Spacer()

                // Beat LED bars
                beatLEDBars
                    .padding(.horizontal, 6)

                Spacer()

                // Transport button
                transportButton
            }
            .padding(.vertical, 2)
        }
        .focusable()
        .digitalCrownRotation(
            $crownBPM,
            from: 20,
            through: 300,
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownBPM) { _, newValue in
            metronome.bpm = Int(newValue)
        }
        .onChange(of: metronome.bpm) { _, newValue in
            crownBPM = Double(newValue)
        }
        .onReceive(metronome.$currentBeat) { _ in
            if metronome.isPlaying {
                triggerPulse()
            }
        }
    }

    // MARK: - Tempo Color (VU meter style)

    private var tempoProgress: Double {
        let normalized = Double(metronome.bpm - 40) / Double(300 - 40)
        return min(max(normalized, 0), 1)
    }

    private var tempoColor: Color {
        let t = tempoProgress
        if t < 0.33 {
            let local = t / 0.33
            return Color(hue: 130.0 / 360.0, saturation: 0.85, brightness: 0.5 + local * 0.4)
        } else if t < 0.66 {
            let local = (t - 0.33) / 0.33
            let hue = (60.0 - local * 20.0) / 360.0
            return Color(hue: hue, saturation: 0.9, brightness: 0.6 + local * 0.35)
        } else {
            let local = (t - 0.66) / 0.34
            let hue = (40.0 - local * 30.0) / 360.0
            return Color(hue: hue, saturation: 0.85 - local * 0.3, brightness: 0.6 + local * 0.4)
        }
    }

    // MARK: - Tempo Zone Bar

    private var tempoZoneBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(hex: "1a1a1a"))
                    .frame(height: 3)

                // Fill
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(tempoColor)
                    .frame(width: geo.size.width * tempoProgress, height: 3)
                    .shadow(color: tempoColor.opacity(0.6), radius: 3)
                    .animation(.easeOut(duration: 0.15), value: metronome.bpm)
            }
        }
        .frame(height: 3)
    }

    // MARK: - BPM LCD Display

    private var bpmLCDDisplay: some View {
        ZStack {
            // LCD bezel
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "08080c"))
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), Color.clear],
                        startPoint: .top, endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                )

            // LCD glass
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0a120a"), Color(hex: "080e08")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .padding(2)

            VStack(spacing: 1) {
                // Ghost segments
                Text("888")
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "0d1a1a"))
                    .overlay(
                        Text("\(metronome.bpm)")
                            .font(.system(size: 42, weight: .bold, design: .monospaced))
                            .foregroundColor(tempoColor)
                            .shadow(color: tempoColor.opacity(0.4), radius: 6)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.15), value: metronome.bpm)
                    )

                HStack(spacing: 12) {
                    Text("BPM")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(HapticColors.secondaryText)
                        .tracking(3)

                    Text(metronome.timeSignature.displayString)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(HapticColors.secondaryText)
                }
            }
        }
        .frame(height: 72)
        .padding(.horizontal, 8)
        .onTapGesture {
            metronome.tap()
        }
    }

    // MARK: - Beat LED Bars

    private var beatLEDBars: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<metronome.timeSignature.beatsPerBar, id: \.self) { index in
                let isCurrent = metronome.isPlaying && metronome.currentBeat == index
                let isAccented = index < metronome.accentPattern.count && metronome.accentPattern[index]

                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(isCurrent: isCurrent, isAccented: isAccented))
                    .frame(height: 6)
                    .shadow(
                        color: barGlow(isCurrent: isCurrent, isAccented: isAccented),
                        radius: (isCurrent || isAccented) ? 4 : 0
                    )
                    .shadow(
                        color: barGlow(isCurrent: isCurrent, isAccented: isAccented).opacity(0.5),
                        radius: (isCurrent || isAccented) ? 8 : 0
                    )
                    .animation(.easeOut(duration: 0.08), value: metronome.currentBeat)
            }
        }
    }

    private var barSpacing: CGFloat {
        let beats = metronome.timeSignature.beatsPerBar
        if beats <= 4 { return 4 }
        if beats <= 7 { return 3 }
        return 2
    }

    private func barColor(isCurrent: Bool, isAccented: Bool) -> Color {
        if isCurrent && isAccented { return .white }
        if isCurrent { return tempoColor }
        if isAccented { return tempoColor.opacity(0.8) }
        return Color(hex: "1a1a1a")
    }

    private func barGlow(isCurrent: Bool, isAccented: Bool) -> Color {
        if isCurrent && isAccented { return .white }
        if isCurrent { return tempoColor }
        if isAccented { return tempoColor.opacity(0.5) }
        return .clear
    }

    // MARK: - Transport Button

    private var transportButton: some View {
        Button(action: { metronome.toggle() }) {
            ZStack {
                // Button well
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "06060a"))
                    .frame(width: 100, height: 36)

                // Button face
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: metronome.isPlaying
                                ? [Color(hex: "141420"), Color(hex: "1a1a26")]
                                : [Color(hex: "282832"), Color(hex: "1e1e28")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                metronome.isPlaying ? Color.black.opacity(0.4) : Color.white.opacity(0.08),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: metronome.isPlaying ? .clear : .black.opacity(0.5),
                        radius: metronome.isPlaying ? 0 : 3,
                        y: metronome.isPlaying ? 0 : 2
                    )
                    .frame(width: 96, height: 32)
                    .offset(y: metronome.isPlaying ? 1.5 : 0)

                // Icon
                Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(
                        metronome.isPlaying ? tempoColor : Color(hex: "6a6a7a")
                    )
                    .shadow(color: metronome.isPlaying ? tempoColor.opacity(0.5) : .clear, radius: 6)
                    .contentTransition(.symbolEffect(.replace.downUp))
                    .offset(y: metronome.isPlaying ? 1.5 : 0)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.1), value: metronome.isPlaying)
    }

    // MARK: - Pulse

    private func triggerPulse() {
        pulseIntensity = 1.0
        withAnimation(.easeOut(duration: 0.12)) {
            pulseIntensity = 0
        }
    }
}

#Preview {
    WatchMetronomeView()
}
