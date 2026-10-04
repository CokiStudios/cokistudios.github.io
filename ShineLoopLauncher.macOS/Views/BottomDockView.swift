import SwiftUI

// MARK: - Bottom Controller Navigation Dock
public struct BottomDockView: View {
    @ObservedObject var vm: LauncherViewModel

    public var body: some View {
        HStack(spacing: 20) {
            // Controller Connection Badge
            HStack(spacing: 6) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "00f5d4"))

                Text(GameControllerManager.shared.isControllerConnected ? GameControllerManager.shared.connectedControllerName : "Mando / Teclado")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())

            Spacer()

            // Gamepad Navigation Hints Bar
            HStack(spacing: 16) {
                dockKeyHint(badge: "◀ ▶", action: "Navegar")
                dockKeyHint(badge: "A", action: "Iniciar", color: Color(hex: "00f5d4"))
                dockKeyHint(badge: "B", action: "Atrás", color: Color(hex: "f43f5e"))
                dockKeyHint(badge: "X", action: vm.viewMode == .carousel ? "Cuadrícula" : "Carrusel", color: Color(hex: "38bdf8"))
                dockKeyHint(badge: "Y", action: "Bubbly Dot", color: Color(hex: "eab308"))
                dockKeyHint(badge: "Tab", action: "Ajustes", color: Color(hex: "a855f7"))
            }

            Spacer()

            // View Mode Quick Switcher
            HStack(spacing: 4) {
                Button {
                    if vm.viewMode != .carousel {
                        vm.toggleViewMode()
                    }
                } label: {
                    Image(systemName: "rectangle.fill.on.rectangle.angled.fill")
                        .font(.system(size: 12))
                        .foregroundColor(vm.viewMode == .carousel ? Color(hex: "00f5d4") : .white.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .background(vm.viewMode == .carousel ? Color(hex: "00f5d4").opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button {
                    if vm.viewMode != .grid {
                        vm.toggleViewMode()
                    }
                } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(vm.viewMode == .grid ? Color(hex: "00f5d4") : .white.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .background(vm.viewMode == .grid ? Color(hex: "00f5d4").opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(2)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            Color(hex: "060913").opacity(0.9)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.08)),
            alignment: .top
        )
    }

    private func dockKeyHint(badge: String, action: String, color: Color = .white) -> some View {
        HStack(spacing: 5) {
            Text(badge)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(action)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
        }
    }
}
