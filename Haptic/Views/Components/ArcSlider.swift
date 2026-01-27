import SwiftUI

/// ArcSlider - Cyberpunk-style circular tempo control
/// 270-degree arc for sweeping through BPM ranges
/// Haptic feedback at tempo landmarks

struct ArcSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    // Configuration
    let lineWidth: CGFloat = 8
    let glowRadius: CGFloat = 12

    // Evenly spaced tick marks
    private let tickCount = 9

    // Gesture state
    @State private var isDragging = false
    @GestureState private var dragLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = (size / 2) - lineWidth - glowRadius

            ZStack {
                // Background track
                arcPath(radius: radius)
                    .stroke(
                        HapticColors.charcoal,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )

                // Glow layer (behind the value arc)
                arcPath(radius: radius, progress: progress)
                    .stroke(
                        temperatureColor.opacity(0.5),
                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round)
                    )
                    .blur(radius: isDragging ? glowRadius : glowRadius / 2)

                // Value arc
                arcPath(radius: radius, progress: progress)
                    .stroke(
                        LinearGradient(
                            colors: [temperatureColor.opacity(0.8), temperatureColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )

                // Thumb indicator
                Circle()
                    .fill(temperatureColor)
                    .frame(width: lineWidth + 8, height: lineWidth + 8)
                    .shadow(color: temperatureColor, radius: isDragging ? 12 : 6)
                    .position(thumbPosition(radius: radius, center: center))

                // Evenly spaced tick marks
                ForEach(0..<tickCount, id: \.self) { index in
                    tickMark(at: Double(index) / Double(tickCount - 1), radius: radius, center: center)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        updateValue(from: gesture.location, center: center, radius: radius)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Computed Properties

    private var progress: Double {
        let normalized = Double(value - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        return min(max(normalized, 0), 1)
    }

    /// Vibrant cyan gradient - gets brighter/whiter as tempo increases
    private var temperatureColor: Color {
        let t = progress // 0.0 to 1.0

        // Vibrant cyan that approaches white at high tempo
        // Hue: 190° (cyan) - stays constant
        // Saturation: 100% → 70% (slightly desaturates toward white)
        // Brightness: 60% → 100% (much brighter range)

        let hue: Double = 190.0 / 360.0 // Cyan hue
        let saturation: Double = 1.0 - (t * 0.3) // 100% → 70%
        let brightness: Double = 0.6 + (t * 0.4) // 60% → 100%

        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    // MARK: - Path Helpers

    private func arcPath(radius: CGFloat, progress: Double = 1.0) -> Path {
        let startAngle = Angle(degrees: 135)  // Bottom-left
        let endAngle = Angle(degrees: 135 + (270 * progress))  // 270-degree sweep

        return Path { path in
            path.addArc(
                center: .zero,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        .offsetBy(dx: radius + lineWidth + glowRadius, dy: radius + lineWidth + glowRadius)
    }

    private func thumbPosition(radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = Angle(degrees: 135 + (270 * progress))
        let x = center.x + radius * cos(CGFloat(angle.radians))
        let y = center.y + radius * sin(CGFloat(angle.radians))
        return CGPoint(x: x, y: y)
    }

    private func tickMark(at tickProgress: Double, radius: CGFloat, center: CGPoint) -> some View {
        let angle = Angle(degrees: 135 + (270 * tickProgress))
        let innerRadius = radius - 15
        let x = center.x + innerRadius * cos(CGFloat(angle.radians))
        let y = center.y + innerRadius * sin(CGFloat(angle.radians))

        let isPassed = progress >= tickProgress
        let isNear = abs(progress - tickProgress) < 0.02

        return Circle()
            .fill(isPassed ? HapticColors.electricBlue : HapticColors.tertiaryText)
            .frame(width: isNear ? 6 : 4, height: isNear ? 6 : 4)
            .shadow(color: isPassed ? HapticColors.electricBlue.opacity(0.8) : .clear, radius: 4)
            .position(x: x, y: y)
            .animation(.easeOut(duration: 0.15), value: isPassed)
    }

    // MARK: - Gesture Handling

    private func updateValue(from location: CGPoint, center: CGPoint, radius: CGFloat) {
        let vector = CGPoint(x: location.x - center.x, y: location.y - center.y)
        var angle = atan2(vector.y, vector.x)

        // Convert to degrees and adjust for our arc orientation
        var degrees = angle * 180 / .pi

        // Normalize to our arc range (135 to 405 degrees)
        if degrees < 0 { degrees += 360 }
        if degrees < 135 { degrees += 360 }

        // Clamp to arc range
        degrees = max(135, min(405, degrees))

        // Convert to progress (0-1)
        let progress = (degrees - 135) / 270

        // Convert to BPM value
        let newValue = Int(Double(range.lowerBound) + progress * Double(range.upperBound - range.lowerBound))
        let clampedValue = max(range.lowerBound, min(range.upperBound, newValue))

        // Haptic feedback at landmarks
        if clampedValue != value {
            if landmarks.contains(clampedValue) {
                // Strong haptic at landmarks
                #if os(iOS)
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                #endif
            } else if clampedValue % 5 == 0 {
                // Light haptic every 5 BPM
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
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            ArcSlider(value: .constant(120), range: 40...300)
                .frame(width: 280, height: 280)

            Text("120 BPM")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
