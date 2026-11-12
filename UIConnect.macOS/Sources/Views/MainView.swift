import SwiftUI

// MARK: - Main Application Window View
public struct MainView: View {
    @StateObject private var vm = UIConnectViewModel()

    public init() {}

    public var body: some View {
        ZStack {
            // Background
            UITheme.bg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar
                HeaderView(vm: vm)

                // Segmented Tab Selector Bar
                HStack(spacing: 8) {
                    ForEach(UIConnectViewModel.Tab.allCases) { tab in
                        Button(action: {
                            vm.selectedTab = tab
                            SoundSynthesizer.shared.playTone(frequency: 600, duration: 0.04)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 12, weight: .bold))
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(vm.selectedTab == tab ? UITheme.primary.opacity(0.18) : Color.clear)
                            .foregroundColor(vm.selectedTab == tab ? UITheme.primary : UITheme.textSecondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(vm.selectedTab == tab ? UITheme.primary.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Quick status pill
                    if vm.isBusy {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Procesando...")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(UITheme.accent)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(UITheme.cardBg)
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(UITheme.bg)
                .overlay(Rectangle().frame(height: 1).foregroundColor(UITheme.cardBorder), alignment: .bottom)

                // Main Content Area
                ZStack {
                    switch vm.selectedTab {
                    case .devices:
                        DevicesTabView(vm: vm)
                    case .modules:
                        ModulesTabView(vm: vm)
                    case .controls:
                        ControlsTabView(vm: vm)
                    case .looping:
                        LoopingTabView(vm: vm)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Log Drawer
                LogDrawerView()
            }
        }
        .frame(minWidth: 920, idealWidth: 1080, minHeight: 640, idealHeight: 760)
        .preferredColorScheme(.dark)
    }
}
