import SwiftUI

struct XtrapsBackground: View {
    let strokeColor: Color
    
    init(strokeColor: Color = Color.indigo.opacity(0.12)) {
        self.strokeColor = strokeColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: h * 0.15))
                    path.addCurve(
                        to: CGPoint(x: w * 0.5, y: h * 0.7),
                        control1: CGPoint(x: w * 0.15, y: h * 0.15),
                        control2: CGPoint(x: w * 0.3, y: h * 0.7)
                    )
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.6),
                        control1: CGPoint(x: w * 0.7, y: h * 0.7),
                        control2: CGPoint(x: w * 0.85, y: h * 0.6)
                    )
                }
                .stroke(strokeColor, lineWidth: 1.5)
                
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: h * 0.5))
                    path.addCurve(
                        to: CGPoint(x: w * 0.25, y: h * 0.25),
                        control1: CGPoint(x: w * 0.1, y: h * 0.4),
                        control2: CGPoint(x: w * 0.15, y: h * 0.25)
                    )
                    path.addCurve(
                        to: CGPoint(x: w * 0.65, y: h * 0.65),
                        control1: CGPoint(x: w * 0.4, y: h * 0.25),
                        control2: CGPoint(x: w * 0.55, y: h * 0.65)
                    )
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.1),
                        control1: CGPoint(x: w * 0.8, y: h * 0.65),
                        control2: CGPoint(x: w * 0.9, y: h * 0.1)
                    )
                }
                .stroke(strokeColor, lineWidth: 1.5)
            }
        }
        .allowsHitTesting(false)
    }
}
