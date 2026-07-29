import SwiftUI

// MARK: - Xtraps Precision Bezier Curve Shapes (Exact match to Coki Studios Brand Sketch)

public struct XtrapsWave1: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Starts horizontal top-left, dips into a smooth valley at 65% width, and rises steeply on the right
        path.move(to: CGPoint(x: 0, y: h * 0.16))
        path.addCurve(
            to: CGPoint(x: w * 0.45, y: h * 0.58),
            control1: CGPoint(x: w * 0.15, y: h * 0.16),
            control2: CGPoint(x: w * 0.30, y: h * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.82, y: h * 0.62),
            control1: CGPoint(x: w * 0.58, y: h * 0.76),
            control2: CGPoint(x: w * 0.70, y: h * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.13),
            control1: CGPoint(x: w * 0.90, y: h * 0.50),
            control2: CGPoint(x: w * 0.96, y: h * 0.28)
        )
        return path
    }
}

public struct XtrapsWave2: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Starts mid-left, arches gently up, stays relatively flat, and shoots UP steeply on the right edge
        path.move(to: CGPoint(x: 0, y: h * 0.43))
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.32),
            control1: CGPoint(x: w * 0.15, y: h * 0.37),
            control2: CGPoint(x: w * 0.35, y: h * 0.32)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.88, y: h * 0.34),
            control1: CGPoint(x: w * 0.72, y: h * 0.32),
            control2: CGPoint(x: w * 0.83, y: h * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: w, y: 0),
            control1: CGPoint(x: w * 0.93, y: h * 0.22),
            control2: CGPoint(x: w * 0.97, y: h * 0.08)
        )
        return path
    }
}

// MARK: - Xtraps Background (Vivid & Animated)

public struct XtrapsBackground: View {
    public let strokeColor: Color
    public let opacity: Double
    public let animated: Bool
    public let lineWidth: CGFloat
    @State private var phase: CGFloat = 0.0
    @State private var hue: Double = 0.0
    
    public init(
        strokeColor: Color = Color(red: 99/255, green: 102/255, blue: 241/255), // Vibrant Indigo
        opacity: Double = 0.55,
        animated: Bool = true,
        lineWidth: CGFloat = 2.2,
        rainbow: Bool = false
    ) {
        self.strokeColor = strokeColor
        self.opacity = opacity
        self.animated = animated
        self.lineWidth = lineWidth
        self.rainbow = rainbow
    }
    // New property for rainbow animation
    private let rainbow: Bool
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Determine current color based on rainbow flag
                let currentColor = rainbow ? Color(hue: hue, saturation: 0.8, brightness: 0.9) : strokeColor
                // Wave 1 Gradient Stroke
                XtrapsWave1()
                    .stroke(
                        LinearGradient(
                            colors: [
                                currentColor.opacity(opacity * 0.5),
                                currentColor.opacity(opacity * 1.0),
                                currentColor.opacity(opacity * 0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .offset(y: animated ? sin(phase) * 8 : 0)
                
                // Wave 2 Gradient Stroke
                XtrapsWave2()
                    .stroke(
                        LinearGradient(
                            colors: [
                                currentColor.opacity(opacity * 0.4),
                                currentColor.opacity(opacity * 0.85),
                                currentColor.opacity(opacity * 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .offset(y: animated ? cos(phase) * 8 : 0)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if animated {
                withAnimation(Animation.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                    phase = .pi * 2
                }
            }
            if rainbow {
                // Start hue animation loop
                withAnimation(Animation.linear(duration: 12.0).repeatForever(autoreverses: false)) {
                    hue = 1.0
                }
                // Periodic timer to update hue smoothly
                Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                    hue = (hue + 0.002).truncatingRemainder(dividingBy: 1.0)
                }
            }
        }
    }
}

// MARK: - Xtraps UI Divider Component

public struct XtrapsDivider: View {
    public let color: Color
    public let height: CGFloat
    
    public init(color: Color = Color(red: 99/255, green: 102/255, blue: 241/255), height: CGFloat = 40) {
        self.color = color
        self.height = height
    }
    
    public var body: some View {
        XtrapsBackground(strokeColor: color, opacity: 0.8, animated: false, lineWidth: 2.0)
            .frame(height: height)
            .padding(.vertical, 4)
    }
}
