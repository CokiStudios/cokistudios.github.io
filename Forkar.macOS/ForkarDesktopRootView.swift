import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 🖥️ FORKAR DESKTOP ROOT VIEW — FORKAR FOR PC (macOS)
// Layout principal tipo SplitView de 3 columnas con Extensión CSMS
// ══════════════════════════════════════════════════════════════════

enum NavigationTab: String, CaseIterable, Identifiable {
    case feed = "Muro"
    case csms = "Extensión CSMS"
    case eco = "Eco Hub"
    case profile = "Mi Perfil"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .feed: return "rectangle.stack.fill"
        case .csms: return "bubble.left.and.bubble.right.fill"
        case .eco: return "leaf.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct ForkarDesktopRootView: View {
    @EnvironmentObject var manager: SupabaseManager
    @State private var selectedTab: NavigationTab = .feed
    
    var body: some View {
        HSplitView {
            // ─── 1. BARRA LATERAL PRINCIPAL DE FORKAR ───
            VStack(alignment: .leading, spacing: 0) {
                // Cabecera de la Marca
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ForkarTheme.brandGradient)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "f.cursive")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Forkar")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(ForkarTheme.text)
                        Text("for PC • v2.0")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ForkarTheme.accent)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(ForkarTheme.bgSecondary)
                
                Divider().background(ForkarTheme.border)
                
                // Menú de Navegación
                VStack(spacing: 4) {
                    ForEach(NavigationTab.allCases) { tab in
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedTab == tab ? .white : (tab == .csms ? ForkarTheme.accent : ForkarTheme.textSub))
                                    .frame(width: 20)
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: selectedTab == tab ? .bold : .medium))
                                    .foregroundColor(selectedTab == tab ? .white : ForkarTheme.text)
                                
                                Spacer()
                                
                                // Insignia especial para la extensión CSMS
                                if tab == .csms {
                                    Text("EN VIVO")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(ForkarTheme.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(ForkarTheme.accent.opacity(0.15))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                selectedTab == tab
                                    ? RoundedRectangle(cornerRadius: 8).fill(ForkarTheme.cardActive)
                                    : RoundedRectangle(cornerRadius: 8).fill(Color.clear)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 14)
                
                Spacer()
                
                Divider().background(ForkarTheme.border)
                
                // Tarjeta de Usuario inferior
                HStack(spacing: 10) {
                    Circle()
                        .fill(ForkarTheme.accent.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(userInitials)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(ForkarTheme.accent)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(manager.currentUser?.fullName ?? "Usuario")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.text)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ForkarTheme.greenEco)
                                .frame(width: 6, height: 6)
                            Text("En línea")
                                .font(.system(size: 10))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(ForkarTheme.bgSecondary)
            }
            .frame(minWidth: 200, idealWidth: 230, maxWidth: 260)
            .background(ForkarTheme.bgTertiary)
            
            // ─── 2. CONTENIDO PRINCIPAL SEGÚN PESTAÑA ───
            ZStack {
                switch selectedTab {
                case .feed:
                    HomeFeedView(selectedTab: $selectedTab)
                        .environmentObject(manager)
                case .csms:
                    CSMSExtensionView()
                        .environmentObject(manager)
                case .eco:
                    ForkarEcoView(selectedTab: $selectedTab)
                        .environmentObject(manager)
                case .profile:
                    ProfileView()
                        .environmentObject(manager)
                }
            }
            .frame(minWidth: 640)
        }
        .frame(minWidth: 960, minHeight: 640)
        .background(ForkarTheme.bg)
    }
    
    private var userInitials: String {
        let name = manager.currentUser?.fullName ?? manager.currentUser?.email ?? "U"
        return String(name.prefix(2)).uppercased()
    }
}
