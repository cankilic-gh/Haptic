import SwiftUI

/// TunerGauge - Animated needle gauge for pitch visualization
/// Shows -50 to +50 cents with smooth needle animation
/// Cyberpunk aesthetic matching the app's design language

struct TunerGauge: View {
    let centOffset: Double      // -50 to +50
    let accuracy: TuningAccuracy
    let isActive: Bool

    // Configuration
    private let gaugeWidth: CGFloat = 280
    private let gaugeHeight: CGFloat = 140
    private let needleLength: CGFloat = 100
    private let tickCount = 11  // -50, -40, ..., 0, ..., +40, +50

    var body: some View {
        ZStack {
            // Background arc
            GaugeArc()
                .stroke(
                    LinearGradient(
                        colors: [
                            HapticColors.charcoal,
                            HapticColors.darkGray,
                            HapticColors.charcoal
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: gaugeWidth, height: gaugeHeight)

            // Colored indicator arc (shows current position range)
            if isActive {
                GaugeArc(progress: centToProgress(centOffset))
                    .stroke(
                        accuracy.color.opacity(0.6),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: gaugeWidth, height: gaugeHeight)
                    .blur(radius: 4)

                GaugeArc(progress: centToProgress(centOffset))
                    .stroke(
                        accuracy.color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: gaugeWidth, height: gaugeHeight)
            }

            // Center zone indicator (in-tune zone)
            CenterZoneIndicator()
                .frame(width: gaugeWidth, height: gaugeHeight)

            // Tick marks
            ForEach(0..<tickCount, id: \.self) { index in
                TickMark(
                    index: index,
                    totalTicks: tickCount,
                    gaugeWidth: gaugeWidth,
                    isHighlighted: isTickHighlighted(index)
                )
            }

            // Tick labels
            TickLabels(gaugeWidth: gaugeWidth)

            // Needle
            NeedleView(
                angle: centToAngle(centOffset),
                color: isActive ? accuracy.color : HapticColors.tertiaryText,
                length: needleLength,
                isActive: isActive
            )

            // Center pivot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            HapticColors.electricBlue.opacity(0.8),
                            HapticColors.charcoal
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 20, height: 20)
                .shadow(color: isActive ? accuracy.color.opacity(0.5) : .clear, radius: 8)
                .offset(y: gaugeHeight / 2 - 10)
        }
        .frame(width: gaugeWidth, height: gaugeHeight + 20)
    }

    // MARK: - Helpers

    private func centToAngle(_ cents: Double) -> Angle {
        // Map -50 to +50 cents to -90 to +90 degrees
        let clampedCents = max(-50, min(50, cents))
        let degrees = (clampedCents / 50.0) * 90.0
        return Angle(degrees: degrees)
    }

    private func centToProgress(_ cents: Double) -> Double {
        // Map -50 to +50 to 0 to 1
        let clampedCents = max(-50, min(50, cents))
        return (clampedCents + 50) / 100.0
    }

    private func isTickHighlighted(_ index: Int) -> Bool {
        guard isActive else { return false }
        let tickCent = -50 + (index * 10)  // -50, -40, ..., +50
        return abs(centOffset - Double(tickCent)) < 8
    }
}

// MARK: - Gauge Arc Shape

struct GaugeArc: Shape {
    var progress: Double = 1.0

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2 - 10

        let startAngle = Angle(degrees: -180)
        let progressAngle = Angle(degrees: -180 + (progress * 180))

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: progress < 1.0 ? progressAngle : Angle(degrees: 0),
            clockwise: false
        )
        return path
    }

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
}

// MARK: - Center Zone Indicator

struct CenterZoneIndicator: View {
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height)
            let radius = min(geometry.size.width, geometry.size.height * 2) / 2 - 10

            // In-tune zone arc (-5 to +5 cents = -9 to +9 degrees)
            Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-99),  // -90 - 9
                    endAngle: .degrees(-81),    // -90 + 9
                    clockwise: false
                )
            }
            .stroke(HapticColors.cyanBright.opacity(0.3), lineWidth: 12)
            .blur(radius: 4)

            // Center line
            Path { path in
                path.move(to: CGPoint(x: center.x, y: center.y - radius + 5))
                path.addLine(to: CGPoint(x: center.x, y: center.y - radius - 15))
            }
            .stroke(HapticColors.cyanBright, lineWidth: 2)
            .shadow(color: HapticColors.cyanBright, radius: 4)
        }
    }
}

// MARK: - Tick Mark

struct TickMark: View {
    let index: Int
    let totalTicks: Int
    let gaugeWidth: CGFloat
    let isHighlighted: Bool

    private var angle: Angle {
        // Map tick index to angle: 0 -> -90, (totalTicks-1)/2 -> 0, totalTicks-1 -> 90
        let normalized = Double(index) / Double(totalTicks - 1)  // 0 to 1
        let degrees = -90 + (normalized * 180)  // -90 to 90
        return Angle(degrees: degrees)
    }

    private var isMajorTick: Bool {
        // Major ticks at -50, -25, 0, +25, +50
        index % 2 == 0 || index == totalTicks / 2
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height)
            let radius = min(geometry.size.width, geometry.size.height * 2) / 2 - 10
            let tickLength: CGFloat = isMajorTick ? 12 : 6

            let startRadius = radius - tickLength
            let endRadius = radius + 2

            let startPoint = pointOnCircle(center: center, radius: startRadius, angle: angle)
            let endPoint = pointOnCircle(center: center, radius: endRadius, angle: angle)

            Path { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(
                isHighlighted ? HapticColors.electricBlue : HapticColors.secondaryText,
                lineWidth: isMajorTick ? 2 : 1
            )
            .shadow(color: isHighlighted ? HapticColors.electricBlue : .clear, radius: 4)
        }
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        // Adjust angle: -90 degrees = top, 0 = right, 90 = left
        let adjustedAngle = angle.radians - .pi / 2
        return CGPoint(
            x: center.x + radius * cos(CGFloat(adjustedAngle)),
            y: center.y + radius * sin(CGFloat(adjustedAngle))
        )
    }
}

// MARK: - Tick Labels

struct TickLabels: View {
    let gaugeWidth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height)
            let labelRadius = min(geometry.size.width, geometry.size.height * 2) / 2 - 35

            // -50 label
            Text("-50")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.secondaryText)
                .position(labelPosition(center: center, radius: labelRadius, angle: .degrees(-90)))

            // 0 label
            Text("0")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(HapticColors.cyanBright)
                .position(labelPosition(center: center, radius: labelRadius, angle: .degrees(0)))

            // +50 label
            Text("+50")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.secondaryText)
                .position(labelPosition(center: center, radius: labelRadius, angle: .degrees(90)))
        }
    }

    private func labelPosition(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let adjustedAngle = angle.radians - .pi / 2
        return CGPoint(
            x: center.x + radius * cos(CGFloat(adjustedAngle)),
            y: center.y + radius * sin(CGFloat(adjustedAngle))
        )
    }
}

// MARK: - Needle View

struct NeedleView: View {
    let angle: Angle
    let color: Color
    let length: CGFloat
    let isActive: Bool

    var body: some View {
        GeometryReader { geometry in
            let pivot = CGPoint(x: geometry.size.width / 2, y: geometry.size.height - 10)

            ZStack {
                // Needle glow
                if isActive {
                    NeedleShape(length: length)
                        .fill(color.opacity(0.4))
                        .blur(radius: 6)
                        .rotationEffect(angle, anchor: UnitPoint(x: 0.5, y: 1.0))
                        .position(pivot)
                }

                // Needle body
                NeedleShape(length: length)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .rotationEffect(angle, anchor: UnitPoint(x: 0.5, y: 1.0))
                    .position(pivot)
                    .shadow(color: color.opacity(0.5), radius: isActive ? 8 : 2)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: angle.degrees)
    }
}

// MARK: - Needle Shape

struct NeedleShape: Shape {
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let baseWidth: CGFloat = 6
        let tipWidth: CGFloat = 2

        // Start from bottom center
        path.move(to: CGPoint(x: rect.midX - baseWidth / 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + baseWidth / 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + tipWidth / 2, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.midX - tipWidth / 2, y: rect.maxY - length))
        path.closeSubpath()

        return path
    }
}

// MARK: - Compact Cent Display

struct CentOffsetDisplay: View {
    let centOffset: Double
    let accuracy: TuningAccuracy

    var body: some View {
        HStack(spacing: 4) {
            // Direction arrow
            Image(systemName: centOffset > 0 ? "arrow.up" : centOffset < 0 ? "arrow.down" : "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accuracy.color)

            // Cent value
            Text(centString)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(accuracy.color)

            Text("cents")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(HapticColors.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(HapticColors.charcoal)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accuracy.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var centString: String {
        let rounded = Int(round(centOffset))
        if rounded > 0 {
            return "+\(rounded)"
        } else {
            return "\(rounded)"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        CyberpunkBackground()

        VStack(spacing: 40) {
            TunerGauge(centOffset: -15, accuracy: .close, isActive: true)

            TunerGauge(centOffset: 0, accuracy: .inTune, isActive: true)

            TunerGauge(centOffset: 35, accuracy: .far, isActive: true)

            CentOffsetDisplay(centOffset: -15, accuracy: .close)
        }
    }
}
