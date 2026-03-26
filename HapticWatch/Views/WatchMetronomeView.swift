import SwiftUI

/// WatchMetronomeView - Main watch interface
/// Compact layout with BPM display, beat dots, and Digital Crown control

struct WatchMetronomeView: View {
    @StateObject private var metronome = MetronomeManager()
    @State private var pulseIntensity: Double = 0
    @State private var crownBPM: Double = 120

    var body: some View {
        ZStack {
            // Background with subtle pulse
            Color.black
                .ignoresSafeArea()

            // Beat pulse overlay
            if metronome.isPlaying && pulseIntensity > 0 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                HapticColors.electricBlue.opacity(pulseIntensity * 0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .scaleEffect(1.0 + pulseIntensity * 0.1)
                    .animation(.easeOut(duration: 0.12), value: pulseIntensity)
            }

            VStack(spacing: 6) {
                // Title
                Text("HAPTIC")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(HapticColors.electricBlue.opacity(0.6))
                    .tracking(3)

                Spacer()

                // BPM Display
                bpmDisplay

                // Time signature
                Text(metronome.timeSignature.displayString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(HapticColors.secondaryText)

                Spacer()

                // Beat dots
                beatDots
                    .padding(.horizontal, 8)

                Spacer()

                // Play/Stop button
                playButton
            }
            .padding(.vertical, 4)
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

    // MARK: - BPM Display

    private var bpmDisplay: some View {
        VStack(spacing: 2) {
            Text("\(metronome.bpm)")
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.15), value: metronome.bpm)
                .scaleEffect(metronome.isPlaying ? 1.0 + pulseIntensity * 0.03 : 1.0)

            Text("BPM")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.secondaryText)
                .tracking(4)
        }
        .onTapGesture {
            metronome.tap()
        }
    }

    // MARK: - Beat Dots

    private var beatDots: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<metronome.timeSignature.beatsPerBar, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(metronome.isPlaying && metronome.currentBeat == index ? 1.4 : 1.0)
                    .animation(.spring(response: 0.15, dampingFraction: 0.6), value: metronome.currentBeat)
                    .shadow(
                        color: (metronome.isPlaying && metronome.currentBeat == index)
                            ? dotColor(for: index).opacity(0.8) : .clear,
                        radius: 4
                    )
            }
        }
    }

    private var dotSize: CGFloat {
        let beats = metronome.timeSignature.beatsPerBar
        if beats <= 4 { return 12 }
        if beats <= 7 { return 9 }
        return 7
    }

    private var dotSpacing: CGFloat {
        let beats = metronome.timeSignature.beatsPerBar
        if beats <= 4 { return 10 }
        if beats <= 7 { return 6 }
        return 4
    }

    private func dotColor(for index: Int) -> Color {
        if metronome.isPlaying && metronome.currentBeat == index {
            return metronome.accentPattern[index] ? .white : HapticColors.cyanBright
        }
        if metronome.accentPattern[index] {
            return HapticColors.electricBlue
        }
        return HapticColors.charcoal
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button(action: { metronome.toggle() }) {
            ZStack {
                Circle()
                    .fill(
                        metronome.isPlaying
                            ? HapticColors.electricBlue
                            : HapticColors.charcoal
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(
                                metronome.isPlaying
                                    ? HapticColors.electricBlue.opacity(0.5)
                                    : HapticColors.electricBlue.opacity(0.3),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: metronome.isPlaying
                            ? HapticColors.electricBlue.opacity(0.5) : .clear,
                        radius: 8
                    )

                Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(
                        metronome.isPlaying ? .black : HapticColors.electricBlue
                    )
                    .offset(x: metronome.isPlaying ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace.downUp))
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: metronome.isPlaying)
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
