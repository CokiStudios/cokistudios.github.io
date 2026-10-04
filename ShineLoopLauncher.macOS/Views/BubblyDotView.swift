import SwiftUI

// MARK: - Bubbly Dot Dynamic Island / Notch
public struct BubblyDotView: View {
    @ObservedObject var vm: LauncherViewModel
    @State private var isHovering: Bool = false

    public var body: some View {
        HStack(spacing: 8) {
            // Pulsing activity indicator dot
            ZStack {
                Circle()
                    .fill(Color(hex: "00f5d4"))
                    .frame(width: 8, height: 8)

                Circle()
                    .stroke(Color(hex: "00f5d4").opacity(0.5), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .scaleEffect(vm.processRunner.state != .idle ? 1.4 : 1.0)
                    .opacity(vm.processRunner.state != .idle ? 0.8 : 0.3)
                    .animation(
                        vm.processRunner.state != .idle
                            ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .default,
                        value: vm.processRunner.state != .idle
                    )
            }

            // Status Icon
            Image(systemName: vm.bubblyDotIcon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "38bdf8"))

            // Dynamic Context Text
            VStack(alignment: .leading, spacing: 1) {
                Text(vm.bubblyDotTitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if vm.isBubblyDotExpanded {
                    Text(vm.bubblyDotSubtext)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "00f5d4"))
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Interactive expand arrow / hint
            Image(systemName: vm.isBubblyDotExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, vm.isBubblyDotExpanded ? 8 : 5)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00f5d4").opacity(isHovering ? 0.8 : 0.3),
                                    Color(hex: "6366f1").opacity(isHovering ? 0.6 : 0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color(hex: "00f5d4").opacity(isHovering ? 0.35 : 0.1),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                vm.toggleBubblyDot()
            }
        }
    }
}
