import SwiftUI

/// ArcSlider - Cyberpunk potentiometer knob with LED tick ring
/// Rotary knob control with 270-degree sweep and haptic feedback

struct ArcSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    // LED tick ring configuration
    private let tickCount = 31
    private let sweepDegrees: Double = 270
    private let startAngle: Double = 135

    // Landmark tempos for stronger haptic feedback
    private let landmarks: Set<Int> = [40, 60, 80, 100, 120, 140, 160, 180, 200, 240, 300]

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: size / 2)
            let tickRingRadius = (size / 2) - 4
            let knobRadius = tickRingRadius - 22

            ZStack {
                // LED tick ring (outer)
                ledTickRing(center: center, radius: tickRingRadius)

                // Knob body
                knobBody(center: center, radius: knobRadius)

                // Position indicator on knob edge
                knobIndicator(center: center, knobRadius: knobRadius)
            }
            .frame(width: geometry.size.width, height: size)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        updateValue(from: gesture.location, center: center)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Progress

    private var progress: Double {
        let normalized = Double(value - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        return min(max(normalized, 0), 1)
    }

    // MARK: - LED Tick Ring

    private func ledTickRing(center: CGPoint, radius: CGFloat) -> some View {
        ForEach(0..<tickCount, id: \.self) { index in
            let tickProgress = Double(index) / Double(tickCount - 1)
            let isActive = progress >= tickProgress
            let landmark = isLandmark(tickProgress)
            let tickLen: CGFloat = landmark ? 11 : 7
            let tickWidth: CGFloat = landmark ? 3 : 2

            ledTick(
                center: center,
                radius: radius,
                tickProgress: tickProgress,
                length: tickLen,
                width: tickWidth,
                isActive: isActive
            )
        }
    }

    private func ledTick(center: CGPoint, radius: CGFloat, tickProgress: Double,
                         length: CGFloat, width: CGFloat, isActive: Bool) -> some View {
        let angle = Angle(degrees: startAngle + (sweepDegrees * tickProgress))
        let midR = radius - length / 2
        let x = center.x + midR * cos(CGFloat(angle.radians))
        let y = center.y + midR * sin(CGFloat(angle.radians))
        let color = isActive ? tickColor(at: tickProgress) : Color(hex: "1A1A22")

        return Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .rotationEffect(angle + .degrees(90))
            .shadow(color: isActive ? color : .clear, radius: isActive ? 2 : 0)
            .shadow(color: isActive ? color.opacity(0.8) : .clear, radius: isActive ? 5 : 0)
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: isActive ? 10 : 0)
            .position(x: x, y: y)
    }

    private func isLandmark(_ tickProgress: Double) -> Bool {
        let landmarkProgress = landmarks.map { Double($0 - range.lowerBound) / Double(range.upperBound - range.lowerBound) }
        return landmarkProgress.contains(where: { abs($0 - tickProgress) < 0.02 })
    }

    private func tickColor(at tickProgress: Double) -> Color {
        // VU meter: green (0-33%) → yellow (33-66%) → red (66-100%)
        // Each zone gets brighter toward its end

        if tickProgress < 0.33 {
            // Green zone - dim to bright green
            let local = tickProgress / 0.33
            let brightness = 0.4 + (local * 0.5)
            return Color(hue: 130.0 / 360.0, saturation: 0.9 - (local * 0.15), brightness: brightness)
        } else if tickProgress < 0.66 {
            // Yellow/amber zone
            let local = (tickProgress - 0.33) / 0.33
            let hue = (60.0 - local * 20.0) / 360.0 // 60° yellow → 40° amber
            let brightness = 0.5 + (local * 0.45)
            return Color(hue: hue, saturation: 0.95 - (local * 0.1), brightness: brightness)
        } else {
            // Red zone - amber-red to hot white-red
            let local = (tickProgress - 0.66) / 0.34
            let hue = (40.0 - local * 30.0) / 360.0 // 40° amber → 10° hot red
            let saturation = 0.9 - (local * 0.35) // desaturate toward white-hot
            let brightness = 0.55 + (local * 0.45)
            return Color(hue: hue, saturation: saturation, brightness: brightness)
        }
    }

    // MARK: - Knob Body

    private func knobBody(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            // Outer bevel ring (raised edge feel)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.02),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.15)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: radius * 2, height: radius * 2)
                .position(center)

            // Knob face - conical gradient for brushed metal feel
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hex: "1C1C24"),
                            Color(hex: "242430"),
                            Color(hex: "1A1A22"),
                            Color(hex: "202028"),
                            Color(hex: "18181F"),
                            Color(hex: "222230"),
                            Color(hex: "1C1C24")
                        ],
                        center: .center
                    )
                )
                .frame(width: radius * 2 - 4, height: radius * 2 - 4)
                .position(center)

            // Top-left highlight (light source reflection)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.07),
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: radius * 0.8
                    )
                )
                .frame(width: radius * 2 - 4, height: radius * 2 - 4)
                .position(center)

            // Concentric brushed texture rings
            ForEach(0..<5, id: \.self) { ring in
                let ringRadius = radius * (0.25 + Double(ring) * 0.15)
                Circle()
                    .stroke(Color.white.opacity(0.025), lineWidth: 0.5)
                    .frame(width: ringRadius * 2, height: ringRadius * 2)
                    .position(center)
            }

            // Center dimple
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "0E0E14"),
                            Color(hex: "161620"),
                            Color.white.opacity(0.03)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
                .position(center)

            // Drag glow
            if isDragging {
                Circle()
                    .stroke(HapticColors.electricBlue.opacity(0.1), lineWidth: 2)
                    .frame(width: radius * 2 + 4, height: radius * 2 + 4)
                    .blur(radius: 4)
                    .position(center)
            }
        }
        .animation(.easeOut(duration: 0.2), value: isDragging)
    }

    // MARK: - Knob Indicator (edge-mounted, rotates with value)

    private func knobIndicator(center: CGPoint, knobRadius: CGFloat) -> some View {
        let angle = Angle(degrees: startAngle + (sweepDegrees * progress))
        let dotDist = knobRadius - 10
        let x = center.x + dotDist * cos(CGFloat(angle.radians))
        let y = center.y + dotDist * sin(CGFloat(angle.radians))

        return ZStack {
            // Glow
            Circle()
                .fill(HapticColors.electricBlue.opacity(0.5))
                .frame(width: 12, height: 12)
                .blur(radius: 6)
                .position(x: x, y: y)

            // Dot
            Circle()
                .fill(HapticColors.electricBlue)
                .frame(width: isDragging ? 6 : 5, height: isDragging ? 6 : 5)
                .shadow(color: HapticColors.electricBlue, radius: 4)
                .position(x: x, y: y)
        }
        .animation(.easeOut(duration: 0.08), value: progress)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
    }

    // MARK: - Gesture Handling

    private func updateValue(from location: CGPoint, center: CGPoint) {
        let vector = CGPoint(x: location.x - center.x, y: location.y - center.y)
        let angle = atan2(vector.y, vector.x)

        var degrees = angle * 180 / .pi
        if degrees < 0 { degrees += 360 }
        if degrees < startAngle { degrees += 360 }

        degrees = max(startAngle, min(startAngle + sweepDegrees, degrees))

        let newProgress = (degrees - startAngle) / sweepDegrees
        let newValue = Int(Double(range.lowerBound) + newProgress * Double(range.upperBound - range.lowerBound))
        let clampedValue = max(range.lowerBound, min(range.upperBound, newValue))

        if clampedValue != value {
            if landmarks.contains(clampedValue) {
                #if os(iOS)
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                #endif
            } else if clampedValue % 5 == 0 {
                #if os(iOS)
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                #endif
            }
            value = clampedValue
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0a0a0f").ignoresSafeArea()

        VStack(spacing: 20) {
            ArcSlider(value: .constant(180), range: 40...300)
                .frame(width: 260, height: 260)

            Text("180 BPM")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
