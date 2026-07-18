import SwiftUI

struct XtrapsBackground: View {
    let strokeColor: Color
    @State private var phase: CGFloat = 0.0
    
    init(strokeColor: Color = Color.indigo.opacity(0.12)) {
        self.strokeColor = strokeColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    
                    let offsetY = sin(phase) * 12
                    
                    path.move(to: CGPoint(x: 0, y: h * 0.15 + offsetY))
                    path.addCurve(
                        to: CGPoint(x: w * 0.5, y: h * 0.7 - offsetY),
                        control1: CGPoint(x: w * 0.15, y: h * 0.15 + offsetY),
                        control2: CGPoint(x: w * 0.3, y: h * 0.7 - offsetY)
                    )
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.6 + offsetY),
                        control1: CGPoint(x: w * 0.7, y: h * 0.7 - offsetY),
                        control2: CGPoint(x: w * 0.85, y: h * 0.6 + offsetY)
                    )
                }
                .stroke(strokeColor, lineWidth: 1.5)
                
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    
                    let offsetY = cos(phase) * 12
                    
                    path.move(to: CGPoint(x: 0, y: h * 0.5 + offsetY))
                    path.addCurve(
                        to: CGPoint(x: w * 0.25, y: h * 0.25 - offsetY),
                        control1: CGPoint(x: w * 0.1, y: h * 0.4 + offsetY),
                        control2: CGPoint(x: w * 0.15, y: h * 0.25 - offsetY)
                    )
                    path.addCurve(
                        to: CGPoint(x: w * 0.65, y: h * 0.65 + offsetY),
                        control1: CGPoint(x: w * 0.4, y: h * 0.25 - offsetY),
                        control2: CGPoint(x: w * 0.55, y: h * 0.65 + offsetY)
                    )
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.1 - offsetY),
                        control1: CGPoint(x: w * 0.8, y: h * 0.65 + offsetY),
                        control2: CGPoint(x: w * 0.9, y: h * 0.1 - offsetY)
                    )
                }
                .stroke(strokeColor, lineWidth: 1.5)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}
