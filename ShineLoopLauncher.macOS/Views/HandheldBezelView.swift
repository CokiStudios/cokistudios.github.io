import SwiftUI

// MARK: - Handheld Physical Console Bezel (Shine Loop Console Body)
public struct HandheldBezelView<Content: View>: View {
    @ObservedObject var vm: LauncherViewModel
    let content: Content

    public init(vm: LauncherViewModel, @ViewBuilder content: () -> Content) {
        self.vm = vm
        self.content = content()
    }

    public var body: some View {
        if !vm.isHandheldBezelEnabled {
            content
        } else {
            // Render Screen inside Shine Loop Handheld Chassis
            ZStack {
                // Console Body Gradient & Texture
                RoundedRectangle(cornerRadius: 36)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "090d16"),
                                Color(hex: "02050b")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 36)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "00f5d4").opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.8), radius: 30, x: 0, y: 15)

                HStack(spacing: 0) {
                    // Left Controller Grip Area
                    leftGrip()
                        .frame(width: 90)

                    // Center OLED Screen Container
                    VStack(spacing: 0) {
                        content
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                            )
                            .shadow(color: Color(hex: "00f5d4").opacity(0.15), radius: 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 24)

                    // Right Controller Grip Area
                    rightGrip()
                        .frame(width: 90)
                }
            }
            .padding(12)
        }
    }

    // Left Grip: Left Stick, D-Pad, Select
    private func leftGrip() -> some View {
        VStack(spacing: 24) {
            // Shoulder bumper L1 indicator
            Text("L1")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 44, height: 16)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())

            Spacer()

            // Left Analog Stick
            analogStick()

            // D-Pad Cross
            dpadCross()

            Spacer()

            // Speaker Grille Left
            speakerGrille()
        }
        .padding(.vertical, 24)
    }

    // Right Grip: ABXY Buttons, Right Stick, Menu
    private func rightGrip() -> some View {
        VStack(spacing: 24) {
            // Shoulder bumper R1 indicator
            Text("R1")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 44, height: 16)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())

            Spacer()

            // ABXY Buttons Diamond
            abxyButtons()

            // Right Analog Stick
            analogStick()

            Spacer()

            // Speaker Grille Right
            speakerGrille()
        }
        .padding(.vertical, 24)
    }

    private func analogStick() -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: "111827"))
                .frame(width: 48, height: 48)
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "1f2937"), Color(hex: "0b0f19")],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Circle().stroke(Color(hex: "00f5d4").opacity(0.4), lineWidth: 1)
                )
        }
    }

    private func dpadCross() -> some View {
        VStack(spacing: 2) {
            Button { vm.selectUp() } label: {
                dpadBtn(sym: "arrowtriangle.up.fill")
            }.buttonStyle(.plain)

            HStack(spacing: 14) {
                Button { vm.selectPrevious() } label: {
                    dpadBtn(sym: "arrowtriangle.left.fill")
                }.buttonStyle(.plain)

                Button { vm.selectNext() } label: {
                    dpadBtn(sym: "arrowtriangle.right.fill")
                }.buttonStyle(.plain)
            }

            Button { vm.selectDown() } label: {
                dpadBtn(sym: "arrowtriangle.down.fill")
            }.buttonStyle(.plain)
        }
    }

    private func dpadBtn(sym: String) -> some View {
        Image(systemName: sym)
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.7))
            .frame(width: 22, height: 22)
            .background(Color(hex: "1e293b"))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func abxyButtons() -> some View {
        VStack(spacing: 4) {
            faceButton(label: "X", color: Color(hex: "38bdf8")) {
                vm.toggleViewMode()
            }

            HStack(spacing: 12) {
                faceButton(label: "Y", color: Color(hex: "eab308")) {
                    vm.toggleBubblyDot()
                }

                faceButton(label: "A", color: Color(hex: "00f5d4")) {
                    if let app = vm.selectedApp {
                        vm.launchApp(app)
                    }
                }
            }

            faceButton(label: "B", color: Color(hex: "f43f5e")) {
                vm.closeRunningApp()
            }
        }
    }

    private func faceButton(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(Color(hex: "1e293b"))
                .clipShape(Circle())
                .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func speakerGrille() -> some View {
        VStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { _ in
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 24, height: 3)
            }
        }
    }
}
