import SwiftUI

// MARK: - Shine UI Position Enum
public enum ShineCorner {
    case topLeft, topRight, bottomLeft, bottomRight
}

// MARK: - Shine UI Corner Button Model
public struct ShineCornerButtonData: Identifiable {
    public let id = UUID()
    public let corner: ShineCorner
    public let label: String
    public let action: () -> Void
    
    public init(corner: ShineCorner, label: String, action: @escaping () -> Void) {
        self.corner = corner
        self.label = label
        self.action = action
    }
}

// MARK: - Shine UI Corner Button View (The 'Mickey Ears' attached directly to the thick border)
public struct ShineCornerButton: View {
    public let label: String
    public let action: () -> Void
    
    public init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 6)
                )
        }
        .buttonStyle(ShineCornerButtonStyle())
    }
}

struct ShineCornerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Shine Color Action Button View (conic-gradient circular buttons with green/red icons)
public struct ShineColorButton: View {
    public let iconSystemName: String
    public let iconColor: Color
    public let action: () -> Void
    
    public init(iconSystemName: String, iconColor: Color, action: @escaping () -> Void) {
        self.iconSystemName = iconSystemName
        self.iconColor = iconColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: iconSystemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    AngularGradient(
                        colors: [.blue, .yellow, .red, .green, .blue],
                        center: .center
                    )
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 6)
                )
                .shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: 2)
        }
        .buttonStyle(ShineCornerButtonStyle())
    }
}

// MARK: - Shine Card Container View Modifier (Thick border, flat offset shadow, corner attachment)
public struct ShineCardModifier: ViewModifier {
    public let cornerButtons: [ShineCornerButtonData]
    public let shadowOffset: CGFloat
    
    public init(cornerButtons: [ShineCornerButtonData] = [], shadowOffset: CGFloat = 10) {
        self.cornerButtons = cornerButtons
        self.shadowOffset = shadowOffset
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(40)
            .background(Color.white)
            .foregroundColor(.black)
            .overlay(
                Rectangle()
                    .stroke(Color.black, lineWidth: 6)
            )
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .offset(x: shadowOffset, y: shadowOffset)
            )
            .overlay(
                GeometryReader { geometry in
                    ZStack {
                        ForEach(cornerButtons) { btn in
                            ShineCornerButton(label: btn.label, action: btn.action)
                                .position(
                                    x: xPosition(for: btn.corner, in: geometry.size),
                                    y: yPosition(for: btn.corner, in: geometry.size)
                                )
                        }
                    }
                }
            )
    }
    
    private func xPosition(for corner: ShineCorner, in size: CGSize) -> CGFloat {
        switch corner {
        case .topLeft, .bottomLeft:
            return 0
        case .topRight, .bottomRight:
            return size.width
        }
    }
    
    private func yPosition(for corner: ShineCorner, in size: CGSize) -> CGFloat {
        switch corner {
        case .topLeft, .topRight:
            return 0
        case .bottomLeft, .bottomRight:
            return size.height
        }
    }
}

public extension View {
    func shineCard(cornerButtons: [ShineCornerButtonData] = [], shadowOffset: CGFloat = 10) -> some View {
        self.modifier(ShineCardModifier(cornerButtons: cornerButtons, shadowOffset: shadowOffset))
    }
}

// MARK: - Shine Alert Popup Overlay Component
public struct ShineAlertView<Content: View>: View {
    @Binding public var isPresented: Bool
    public let cornerButtons: [ShineCornerButtonData]
    public let content: () -> Content
    
    public init(
        isPresented: Binding<Bool>,
        cornerButtons: [ShineCornerButtonData] = [],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.cornerButtons = cornerButtons
        self.content = content
    }
    
    public var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                VStack(spacing: 20) {
                    content()
                }
                .shineCard(cornerButtons: [
                    ShineCornerButtonData(corner: .topLeft, label: "X") {
                        isPresented = false
                    }
                ] + cornerButtons)
                .padding(24)
                .frame(maxWidth: 400)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}
