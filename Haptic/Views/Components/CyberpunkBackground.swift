import SwiftUI

/// CyberpunkBackground - Layered background with scan lines and circuit traces
/// Creates the RiffForge aesthetic without being distracting

struct CyberpunkBackground: View {
    var showScanLines: Bool = true
    var showCircuitPattern: Bool = true
    var pulseIntensity: Double = 0

    var body: some View {
        ZStack {
            // Base gradient - deep space black with subtle blue
            LinearGradient(
                colors: [
                    Color(hex: "0a0a0f"),
                    Color(hex: "0d0d14"),
                    Color(hex: "0a0a0f")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Circuit pattern layer
            if showCircuitPattern {
                CircuitPatternView()
                    .opacity(0.03)
            }

            // Scan lines overlay
            if showScanLines {
                ScanLinesView()
                    .opacity(0.04)
            }

            // Vignette effect
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )

            // Beat pulse overlay
            if pulseIntensity > 0 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                HapticColors.electricBlue.opacity(pulseIntensity * 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .scaleEffect(1.0 + pulseIntensity * 0.2)
                    .animation(.easeOut(duration: 0.15), value: pulseIntensity)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Scan Lines

struct ScanLinesView: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let lineHeight: CGFloat = 2
                let gap: CGFloat = 3
                var y: CGFloat = 0

                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: lineHeight)
                    context.fill(Path(rect), with: .color(.white))
                    y += lineHeight + gap
                }
            }
        }
    }
}

// MARK: - Circuit Pattern

struct CircuitPatternView: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let gridSize: CGFloat = 40
                let lineWidth: CGFloat = 1

                // Horizontal lines
                for y in stride(from: 0, to: size.height, by: gridSize) {
                    let path = Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(.white), lineWidth: lineWidth)
                }

                // Vertical lines with breaks
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    let path = Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(path, with: .color(.white), lineWidth: lineWidth)
                }

                // Circuit nodes at intersections
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    for y in stride(from: 0, to: size.height, by: gridSize) {
                        // Random node visibility for organic feel
                        if Int.random(in: 0...3) == 0 {
                            let rect = CGRect(
                                x: x - 2,
                                y: y - 2,
                                width: 4,
                                height: 4
                            )
                            context.fill(Path(ellipseIn: rect), with: .color(.white))
                        }
                    }
                }

                // Random circuit traces
                for _ in 0..<15 {
                    let startX = CGFloat.random(in: 0...size.width)
                    let startY = CGFloat.random(in: 0...size.height)
                    let endX = startX + CGFloat.random(in: -80...80)
                    let endY = startY + CGFloat.random(in: -80...80)

                    let path = Path { p in
                        p.move(to: CGPoint(x: startX, y: startY))
                        // Right-angle trace
                        if Bool.random() {
                            p.addLine(to: CGPoint(x: endX, y: startY))
                            p.addLine(to: CGPoint(x: endX, y: endY))
                        } else {
                            p.addLine(to: CGPoint(x: startX, y: endY))
                            p.addLine(to: CGPoint(x: endX, y: endY))
                        }
                    }
                    context.stroke(path, with: .color(.white), lineWidth: lineWidth)
                }
            }
        }
    }
}

// MARK: - Pulse Ring

struct PulseRing: View {
    let isActive: Bool
    let bpm: Int

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6

    var body: some View {
        Circle()
            .stroke(HapticColors.electricBlue.opacity(opacity), lineWidth: 2)
            .scaleEffect(scale)
            .animation(.easeOut(duration: beatDuration * 0.4), value: scale)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startPulsing()
                }
            }
    }

    private var beatDuration: Double {
        60.0 / Double(bpm)
    }

    private func startPulsing() {
        // This would be triggered by the metronome beat callback
        withAnimation(.easeOut(duration: beatDuration * 0.2)) {
            scale = 1.15
            opacity = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + beatDuration * 0.2) {
            withAnimation(.easeIn(duration: beatDuration * 0.3)) {
                scale = 1.0
                opacity = 0.3
            }
        }
    }
}

// MARK: - Hexagonal Frame

struct HexagonalFrame: View {
    var strokeColor: Color = HapticColors.electricBlue
    var glowColor: Color = HapticColors.electricBlue
    var lineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            // Glow layer
            HexagonShape()
                .stroke(glowColor.opacity(0.5), lineWidth: lineWidth + 4)
                .blur(radius: 8)

            // Main stroke
            HexagonShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            strokeColor.opacity(0.6),
                            strokeColor,
                            strokeColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
        }
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let corners = 6
        let adjustment: CGFloat = .pi / 2 // Rotate to point up

        var path = Path()

        for i in 0..<corners {
            let angle = (CGFloat(i) * (2 * .pi / CGFloat(corners))) - adjustment
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Neon Glow Modifier

struct NeonGlow: ViewModifier {
    var color: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius / 2)
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 1.5)
    }
}

extension View {
    func neonGlow(color: Color = HapticColors.electricBlue, radius: CGFloat = 8) -> some View {
        modifier(NeonGlow(color: color, radius: radius))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        CyberpunkBackground(pulseIntensity: 0.5)

        VStack(spacing: 30) {
            ZStack {
                HexagonalFrame()
                    .frame(width: 200, height: 200)

                Text("120")
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .neonGlow()
            }

            Text("HAPTIC")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(HapticColors.electricBlue)
                .neonGlow(radius: 12)
        }
    }
}
