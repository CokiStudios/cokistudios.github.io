import SwiftUI

// MARK: - 3D Gaming Console Carousel View
public struct AppCarouselView: View {
    @ObservedObject var vm: LauncherViewModel

    public var body: some View {
        VStack(spacing: 24) {
            // Horizontal Carousel Strip
            HStack(spacing: 20) {
                // Prev button
                Button {
                    vm.selectPrevious()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 44, height: 80)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                // Cards Scroll / Stack
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(Array(vm.filteredApps.enumerated()), id: \.element.id) { index, app in
                                let isSelected = (index == vm.selectedIndex)

                                GameCardView(
                                    app: app,
                                    isSelected: isSelected,
                                    isHero: isSelected,
                                    onSelect: {
                                        vm.selectApp(at: index)
                                    },
                                    onLaunch: {
                                        vm.launchApp(app)
                                    }
                                )
                                .id(index)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: vm.selectedIndex) { _, newIndex in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

                // Next button
                Button {
                    vm.selectNext()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 44, height: 80)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .frame(height: 250)

            // Selected App Hero Detail Panel
            if let app = vm.selectedApp {
                HStack(alignment: .top, spacing: 24) {
                    // Left Column: Description & Launch Action
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            Text(app.title)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)

                            Text(app.badgeText)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: app.primaryColorHex))
                                .clipShape(Capsule())
                        }

                        Text(app.summary)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 16) {
                            // Primary Launch Button
                            Button {
                                vm.launchApp(app)
                            } label: {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 24, height: 24)
                                        Text("A")
                                            .font(.system(size: 13, weight: .black, design: .rounded))
                                            .foregroundColor(Color(hex: "00f5d4"))
                                    }

                                    Text(app.target == .systemSettings ? "CONFIGURAR CONSOLA" : "INICIAR JUEGO")
                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)

                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "00f5d4"), Color(hex: "38bdf8")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color(hex: "00f5d4").opacity(0.4), radius: 10, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)

                            // Quick Info Badge
                            HStack(spacing: 6) {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))

                                Text(String(format: "%.1f MB en NVMe", app.sizeMb))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right Column: Technical Specifications Grid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ESPECIFICACIONES TÉCNICAS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "00f5d4"))

                        VStack(spacing: 6) {
                            ForEach(app.techSpecs, id: \.key) { spec in
                                HStack {
                                    Text(spec.key)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.55))

                                    Spacer()

                                    Text(spec.value)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .frame(width: 290)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "0b1120").opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
    }
}
