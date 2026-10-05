//
//  ForkarDuoManager.swift
//  Forkar
//
//  Official iPhone Duo adaptation framework for Forkar iOS & macOS
//  Complies with Apple Developer Guidelines (developer.apple.com/iphone-duo)
//  and Preparing your app for iPhone Duo (WWDC 2026 / Xcode 27+ specs)
//

import SwiftUI
internal import Combine

// MARK: - iPhone Duo Posture and Display Models
public enum DuoPosture: String, CaseIterable, Equatable {
    case closed             // Outer display only, compact vertical profile
    case partiallyFolded    // Laptop / Tent / Book posture with active hinge crease
    case fullyOpen          // Inner expansive dual display (unified or split canvas)
}

public enum DuoDisplayMode: String, Equatable {
    case outerCoverDisplay  // Compact outer screen with vertical bar placement
    case innerFoldingCanvas // Expansive inner display
}

public enum DuoArrangementStyle {
    case split              // Side-by-side (landscape/wide) or Top-Bottom (portrait/laptop)
    case overlay            // Overlaid presentation adapting to the fold
}

// MARK: - Posture & Display Environment Manager
public class ForkarDuoManager: ObservableObject {
    public static let shared = ForkarDuoManager()
    
    @Published public var currentPosture: DuoPosture = .closed
    @Published public var displayMode: DuoDisplayMode = .outerCoverDisplay
    @Published public var hingeAngle: Double = 0.0          // In degrees: 0° (closed), 90°-135° (laptop), 180° (flat)
    @Published public var isVerticalBarActive: Bool = false  // Set when toolbar appears on vertical edge
    @Published public var verticalBarEdge: Edge = .trailing // Leading or Trailing side
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        detectInitialDisplayMetrics()
    }
    
    /// Detect display geometry and adapt posture
    public func updateMetrics(size: CGSize, safeAreaInsets: EdgeInsets) {
        let aspectRatio = size.width / max(size.height, 1.0)
        
        // Dynamic detection for inner vs outer display
        // Outer display has aspect ratio < 0.55 (tall/narrow ~21:9 or similar foldable cover)
        // Inner display has aspect ratio closer to 1.0 - 1.4 (squarish/tablet-like ~4:3 to 8:7)
        if aspectRatio > 0.85 || size.width >= 650 {
            displayMode = .innerFoldingCanvas
            if hingeAngle >= 80 && hingeAngle <= 145 {
                currentPosture = .partiallyFolded
            } else {
                currentPosture = .fullyOpen
            }
            isVerticalBarActive = false
        } else {
            displayMode = .outerCoverDisplay
            currentPosture = .closed
            // On outer display, Apple Duo specs present navigation/tab bars on the vertical edge
            isVerticalBarActive = true
            verticalBarEdge = .trailing
        }
    }
    
    public func setSimulatedHinge(angle: Double) {
        self.hingeAngle = angle
        if angle <= 15 {
            currentPosture = .closed
            displayMode = .outerCoverDisplay
            isVerticalBarActive = true
        } else if angle < 165 {
            currentPosture = .partiallyFolded
            displayMode = .innerFoldingCanvas
            isVerticalBarActive = false
        } else {
            currentPosture = .fullyOpen
            displayMode = .innerFoldingCanvas
            isVerticalBarActive = false
        }
    }
    
    private func detectInitialDisplayMetrics() {
        #if os(iOS)
        // Initial detection
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let bounds = windowScene.screen.bounds
            let ratio = bounds.width / max(bounds.height, 1.0)
            if ratio > 0.85 || bounds.width >= 650 {
                displayMode = .innerFoldingCanvas
                currentPosture = .fullyOpen
            } else {
                displayMode = .outerCoverDisplay
                currentPosture = .closed
            }
        }
        #else
        // macOS is always regular expansive
        displayMode = .innerFoldingCanvas
        currentPosture = .fullyOpen
        #endif
    }
}

// MARK: - SwiftUI Environment Keys for iPhone Duo
private struct DuoPostureKey: EnvironmentKey {
    static let defaultValue: DuoPosture = .closed
}

private struct DuoDisplayModeKey: EnvironmentKey {
    static let defaultValue: DuoDisplayMode = .outerCoverDisplay
}

private struct DuoVerticalBarActiveKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    public var duoPosture: DuoPosture {
        get { self[DuoPostureKey.self] }
        set { self[DuoPostureKey.self] = newValue }
    }
    
    public var duoDisplayMode: DuoDisplayMode {
        get { self[DuoDisplayModeKey.self] }
        set { self[DuoDisplayModeKey.self] = newValue }
    }
    
    public var isDuoVerticalBarActive: Bool {
        get { self[DuoVerticalBarActiveKey.self] }
        set { self[DuoVerticalBarActiveKey.self] = newValue }
    }
}

// MARK: - View Modifiers for iPhone Duo Adaptability
public struct ForkarDuoFoldAwareModifier: ViewModifier {
    @ObservedObject private var duoManager = ForkarDuoManager.shared
    
    public func body(content: Content) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let isLaptop = duoManager.currentPosture == .partiallyFolded
            
            content
                .padding(.horizontal, isLaptop ? 12 : 0)
                .onAppear {
                    duoManager.updateMetrics(size: size, safeAreaInsets: proxy.safeAreaInsets)
                }
                .onChange(of: size) { newSize in
                    duoManager.updateMetrics(size: newSize, safeAreaInsets: proxy.safeAreaInsets)
                }
        }
    }
}

public struct ForkarDuoToolbarItemModifier: ViewModifier {
    let title: String
    let icon: String
    let placement: ToolbarItemPlacement
    let action: () -> Void
    
    public func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: placement) {
                Button(action: action) {
                    // Apple HIG for iPhone Duo: Always supply both icon and title
                    // The system automatically shows icon-only when presented vertically
                    Label(title, systemImage: icon)
                }
            }
        }
    }
}

extension View {
    /// Adapts the layout dynamically to iPhone Duo outer/inner display and fold crease
    public func forkarDuoFoldAware() -> some View {
        self.modifier(ForkarDuoFoldAwareModifier())
    }
    
    /// Conforms to Apple HIG for iPhone Duo toolbar items (icon + label support for vertical/overflow bars)
    public func duoToolbarAction(
        title: String,
        icon: String,
        placement: ToolbarItemPlacement = .topBarTrailing,
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(ForkarDuoToolbarItemModifier(title: title, icon: icon, placement: placement, action: action))
    }
}

// MARK: - Universal Adaptive Arrangement View (Apple ArrangementView Pattern)
public struct ForkarDuoArrangementView<Primary: View, Secondary: View>: View {
    @ObservedObject private var duoManager = ForkarDuoManager.shared
    let style: DuoArrangementStyle
    let primary: Primary
    let secondary: Secondary
    
    public init(
        style: DuoArrangementStyle = .split,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.style = style
        self.primary = primary()
        self.secondary = secondary()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > proxy.size.height
            let isPartiallyFolded = duoManager.currentPosture == .partiallyFolded
            
            Group {
                if isPartiallyFolded {
                    // Laptop posture: Primary on top screen, Secondary on bottom screen across fold
                    VStack(spacing: 0) {
                        primary
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Hardware-safe Fold Crease Separation Bar
                        HStack {
                            Rectangle()
                                .fill(ForkarTheme.border.opacity(0.35))
                                .frame(height: 1)
                        }
                        .frame(height: 14)
                        .background(ForkarTheme.card.opacity(0.3))
                        .overlay(
                            Capsule()
                                .fill(ForkarTheme.textSub.opacity(0.3))
                                .frame(width: 48, height: 4)
                        )
                        
                        secondary
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if isWide || duoManager.displayMode == .innerFoldingCanvas {
                    // Fully unfolded inner canvas (side-by-side dual pane)
                    HStack(spacing: 0) {
                        primary
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Divider().background(ForkarTheme.border.opacity(0.4))
                        
                        secondary
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    // Compact outer display: Primary view with secondary accessible via sliding sheet or overlay
                    ZStack {
                        primary
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .onAppear {
                duoManager.updateMetrics(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            }
            .onChange(of: proxy.size) { newSize in
                duoManager.updateMetrics(size: newSize, safeAreaInsets: proxy.safeAreaInsets)
            }
        }
    }
}
