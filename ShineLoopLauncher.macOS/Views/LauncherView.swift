import SwiftUI
import AppKit

// MARK: - Main Holo Loop OS Launcher View
public struct LauncherView: View {
    @StateObject private var vm = LauncherViewModel()
    @State private var eventMonitor: Any?

    public init() {}

    public var body: some View {
        HandheldBezelView(vm: vm) {
            ZStack {
                // Background Ambient Glow & Dark Cyber Canvas
                Color(hex: "02050e").ignoresSafeArea()

                // Radial ambient light reactive to current selected app
                if let app = vm.selectedApp {
                    RadialGradient(
                        colors: [
                            Color(hex: app.primaryColorHex).opacity(0.12),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.4), value: app.id)
                }

                VStack(spacing: 0) {
                    // 1. Top Telemetry & Status Bar
                    TopTelemetryBar(vm: vm)

                    // 2. Category Selector Navigation Pills
                    categoryBar()
                        .padding(.top, 14)
                        .padding(.bottom, 6)

                    // 3. Main Center Content (Carousel or Grid)
                    ZStack {
                        if vm.viewMode == .carousel {
                            AppCarouselView(vm: vm)
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        } else {
                            AppGridView(vm: vm)
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // 4. Bottom Gamepad Navigation Hints Dock
                    BottomDockView(vm: vm)
                }

                // 5. Settings Drawer (Slide-out from Right)
                if vm.isSettingsDrawerOpen {
                    SettingsDrawerView(vm: vm)
                }

                // 6. Running Looping App In-Game Overlay
                if vm.isRunningSheetPresented {
                    LoopingRunnerSheet(vm: vm)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                // 7. Looping Source Code Inspector (100% .loop Script)
                if vm.isSourceEditorOpen {
                    LoopSourceInspectorSheet(vm: vm)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleLoopSource"))) { _ in
            vm.isSourceEditorOpen.toggle()
        }
    }

    // MARK: - Category Filter Navigation Bar
    private func categoryBar() -> some View {
        HStack(spacing: 8) {
            ForEach(AppCategory.allCases, id: \.self) { cat in
                let isSelected = (vm.selectedCategory == cat)

                Button {
                    vm.selectedCategory = cat
                    vm.selectedIndex = 0
                    SoundSynthesizer.shared.playActionBlip()
                } label: {
                    HStack(spacing: 6) {
                        if isSelected {
                            Circle()
                                .fill(Color(hex: "00f5d4"))
                                .frame(width: 5, height: 5)
                        }

                        Text(cat.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .bold : .semibold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        isSelected
                            ? Color(hex: "00f5d4").opacity(0.18)
                            : Color.white.opacity(0.04)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? Color(hex: "00f5d4").opacity(0.6) : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Keyboard Handling via Local NSEvent Monitor
    private func setupKeyboardMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // When game execution modal is up
            if self.vm.isRunningSheetPresented {
                if event.keyCode == 53 { // ESC
                    self.vm.closeRunningApp()
                    return nil
                }
                return event
            }

            // When source inspector is up
            if self.vm.isSourceEditorOpen {
                if event.keyCode == 53 { // ESC
                    self.vm.isSourceEditorOpen = false
                    return nil
                }
                return event
            }

            // When settings drawer is up
            if self.vm.isSettingsDrawerOpen {
                if event.keyCode == 53 || event.keyCode == 48 { // ESC or TAB
                    self.vm.toggleSettings()
                    return nil
                }
                return event
            }

            switch event.keyCode {
            case 123, 0: // Left Arrow or 'A'
                self.vm.selectPrevious()
                return nil
            case 124, 2: // Right Arrow or 'D'
                self.vm.selectNext()
                return nil
            case 126, 13: // Up Arrow or 'W'
                self.vm.selectUp()
                return nil
            case 125, 1: // Down Arrow or 'S'
                self.vm.selectDown()
                return nil
            case 36, 49: // Enter or Spacebar (Button A)
                if let selected = self.vm.selectedApp {
                    self.vm.launchApp(selected)
                }
                return nil
            case 53: // Escape (Button B)
                SoundSynthesizer.shared.playBackTick()
                if self.vm.isBubblyDotExpanded {
                    self.vm.isBubblyDotExpanded = false
                }
                return nil
            case 7: // 'X' key (Switch View Mode)
                self.vm.toggleViewMode()
                return nil
            case 16: // 'Y' key (Bubbly Dot)
                self.vm.toggleBubblyDot()
                return nil
            case 48: // Tab key (Settings Drawer)
                self.vm.toggleSettings()
                return nil
            case 17: // 'T' key (Turbo Overclock toggle)
                self.vm.performanceProfile = (self.vm.performanceProfile == .turbo) ? .balanced : .turbo
                SoundSynthesizer.shared.playActionBlip()
                return nil
            case 37: // 'L' key (.loop code inspector)
                self.vm.isSourceEditorOpen.toggle()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyboardMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
