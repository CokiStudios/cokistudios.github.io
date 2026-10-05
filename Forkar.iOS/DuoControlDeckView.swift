//
//  DuoControlDeckView.swift
//  Forkar
//
//  iPhone Duo Adaptive Control Deck for Laptop & Folded Postures
//  Complies with Apple developer.apple.com/iphone-duo guidelines.
//

import SwiftUI

public struct DuoControlDeckView: View {
    @Binding var selectedItem: NavigationItem?
    @Binding var selectedTab: Int
    @ObservedObject var authManager: SupabaseManager
    @ObservedObject var duoManager = ForkarDuoManager.shared
    
    @State private var showPostComposer = false
    @State private var showEcoScanner = false
    @State private var showSimulatedHingeSheet = false
    
    public init(
        selectedItem: Binding<NavigationItem?>,
        selectedTab: Binding<Int>,
        authManager: SupabaseManager
    ) {
        self._selectedItem = selectedItem
        self._selectedTab = selectedTab
        self.authManager = authManager
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // MARK: - Posture & Hardware Security Status Strip
            HStack(spacing: 10) {
                // Posture Chip
                HStack(spacing: 5) {
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ForkarTheme.accent)
                    
                    Text("iPhone Duo • Modo Laptop")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ForkarTheme.accent.opacity(0.12))
                .cornerRadius(8)
                
                Spacer()
                
                // Hardware E2EE Security Badge (SEP / T2 Indicator)
                HStack(spacing: 5) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.emerald)
                    
                    #if os(macOS)
                    Text("T2/SEP E2EE Hardware")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.emerald)
                    #else
                    Text("Secure Enclave E2EE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.emerald)
                    #endif
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.emerald.opacity(0.15))
                .cornerRadius(6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // MARK: - Contextual Quick Action Pad
            HStack(spacing: 12) {
                switch selectedItem ?? .home {
                case .home:
                    Button(action: {
                        showPostComposer = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14, weight: .bold))
                            Text("Escribir Publicación")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ForkarTheme.primaryGradient)
                        .cornerRadius(12)
                        .shadow(color: ForkarTheme.accent.opacity(0.3), radius: 6, y: 2)
                    }
                    .sheet(isPresented: $showPostComposer) {
                        CreatePostView()
                            .environmentObject(authManager)
                    }
                    
                case .eco:
                    HStack(spacing: 10) {
                        Button(action: {
                            NotificationCenter.default.post(name: NSNotification.Name("OpenEcoQRScanner"), object: nil)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Escanear Eco QR")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.emerald)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            let co2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
                            let pts = UserDefaults.standard.integer(forKey: "forkar_eco_points")
                            DynamicIslandEcoManager.shared.startEcoLiveActivity(
                                co2: co2,
                                pts: pts,
                                userName: authManager.currentUser?.resolvedName ?? "CS Member"
                            )
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Live Activity")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(ForkarTheme.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(ForkarTheme.card)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                        }
                    }
                    
                case .chats:
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.emerald)
                            Text("CSMS AES-256-GCM")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(ForkarTheme.card.opacity(0.6))
                        .cornerRadius(10)
                        
                        Spacer()
                        
                        Text("Toca una sala arriba para abrir")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    
                case .profile:
                    HStack {
                        if let user = authManager.currentUser {
                            Text("Sesión activa como \(user.resolvedName)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ForkarTheme.text)
                        } else {
                            Text("Modo invitado")
                                .font(.system(size: 12))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Divider().background(ForkarTheme.border.opacity(0.4))
            
            // MARK: - Dual Screen Navigation Dock
            HStack(spacing: 12) {
                ForEach(NavigationItem.allCases) { item in
                    let isSelected = (selectedItem == item)
                    Button(action: {
                        selectedItem = item
                        selectedTab = item.tag
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? ForkarTheme.accent : ForkarTheme.textSub)
                            
                            Text(item.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? ForkarTheme.text : ForkarTheme.textSub)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? ForkarTheme.card : Color.clear)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? ForkarTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(ForkarTheme.bg)
    }
}
