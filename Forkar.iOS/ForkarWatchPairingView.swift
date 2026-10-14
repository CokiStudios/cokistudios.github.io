//
//  ForkarWatchPairingView.swift
//  Forkar
//
//  Created by Coki Studios on 28/09/2026.
//  Official Apple Watch Pairing & Synchronization Deck for Forkar iOS
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ForkarWatchPairingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: SupabaseManager
    @ObservedObject private var syncManager = ForkarWatchSyncManager.shared
    
    @State private var co2Saved: Double = UserDefaults.standard.double(forKey: "forkar_co2_saved")
    @State private var ecoPoints: Int = UserDefaults.standard.integer(forKey: "forkar_eco_points")
    @State private var isPulsing: Bool = false
    @State private var showSuccessBanner: Bool = false
    
    private var levelTitle: String {
        if ecoPoints >= 500 {
            return "Nivel Campeón Eco"
        } else if ecoPoints >= 200 {
            return "Nivel Avanzado"
        } else if ecoPoints >= 100 {
            return "Nivel Pro"
        } else {
            return "Nivel Sostenible"
        }
    }
    
    public init() {}
    
    public var body: some View {
        MultiplatformNavigationStack {
            ZStack {
                ForkarTheme.bg.ignoresSafeArea()
                XtrapsBackground(strokeColor: Color.emerald, opacity: 0.5, rainbow: true).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header con animación de enlace iPhone <-> Apple Watch
                        pairingHeaderView
                        
                        // Banner de estado general
                        statusBannerView
                        
                        // Tarjeta de Diagnóstico WCSession
                        diagnosticsCardView
                        
                        // Tarjeta de Los 3 Datos Reales de Sostenibilidad
                        threeMetricsCardView
                        
                        // Botones de Acción
                        actionsSectionView
                        
                        // Guía de Solución de Problemas
                        troubleshootingCardView
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Vincular Apple Watch")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.emerald)
                }
            }
            .onAppear {
                #if os(iOS)
                syncManager.activate()
                #endif
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
    
    // MARK: - Header Visual de Enlace
    private var pairingHeaderView: some View {
        VStack(spacing: 14) {
            HStack(spacing: 24) {
                // iPhone
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.emerald.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Image(systemName: "iphone")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.emerald)
                    }
                    Text("iPhone")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                }
                
                // Haz de Conexión / Ondas
                VStack(spacing: 4) {
                    HStack(spacing: 3) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(syncManager.isReachable ? Color.green : Color.yellow)
                                .frame(width: 5, height: 5)
                                .scaleEffect(isPulsing ? 1.3 : 0.8)
                                .opacity(isPulsing ? 1.0 : 0.4)
                                .animation(
                                    Animation.easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.15),
                                    value: isPulsing
                                )
                        }
                    }
                    
                    Image(systemName: syncManager.isReachable ? "bolt.horizontal.fill" : "wave.3.forward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(syncManager.isReachable ? .green : .yellow)
                    
                    Text(syncManager.isReachable ? "Enlace Activo" : "WCSession")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ForkarTheme.textSub)
                }
                .frame(width: 80)
                
                // Apple Watch
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(syncManager.isPaired ? Color.emerald.opacity(0.15) : Color.orange.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Image(systemName: "applewatch")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(syncManager.isPaired ? Color.emerald : .orange)
                    }
                    Text("Apple Watch")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                }
            }
            .padding(.top, 10)
            
            Text("Sincronización Universal de Ecosistema")
                .font(.system(size: 15, weight: .black))
                .foregroundColor(ForkarTheme.text)
            
            Text("Transmite en tiempo real los datos reales de CO₂, Puntos y Nivel con cifrado SEP respaldado por hardware.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(ForkarTheme.textSub)
                .padding(.horizontal, 10)
        }
        .padding(18)
        .background(ForkarTheme.card)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.emerald.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Banner de Estado
    private var statusBannerView: some View {
        HStack(spacing: 10) {
            Image(systemName: syncManager.isPaired ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(syncManager.isPaired ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(syncManager.syncStatusMessage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                
                Text(syncManager.isPaired ? "Los datos se envían sin hardcoding hacia la muñeca" : "Asegúrate de tener un Apple Watch emparejado")
                    .font(.system(size: 10))
                    .foregroundColor(ForkarTheme.textSub)
            }
            
            Spacer()
            
            if syncManager.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(syncManager.isPaired ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(syncManager.isPaired ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Diagnóstico de Conexión WCSession
    private var diagnosticsCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.emerald)
                Text("DIAGNÓSTICO DEL ENLACE")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.2)
                    .foregroundColor(Color.emerald)
                Spacer()
            }
            
            VStack(spacing: 10) {
                diagnosticRow(
                    title: "Sesión WCSession",
                    value: syncManager.activationStateName,
                    isPositive: syncManager.activationStateName == "Activo"
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                diagnosticRow(
                    title: "Apple Watch Emparejado",
                    value: syncManager.isPaired ? "Sí (Detectado)" : "No Detectado",
                    isPositive: syncManager.isPaired
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                diagnosticRow(
                    title: "App en Apple Watch",
                    value: syncManager.isWatchAppInstalled ? "Instalada" : "No instalada",
                    isPositive: syncManager.isWatchAppInstalled
                )
                
                Divider().background(Color.white.opacity(0.08))
                
                diagnosticRow(
                    title: "Canal Interactivo (Reachable)",
                    value: syncManager.isReachable ? "Conectado en Vivo" : "En Espera (Contexto)",
                    isPositive: syncManager.isReachable
                )
            }
        }
        .padding(16)
        .background(ForkarTheme.card)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func diagnosticRow(title: String, value: String, isPositive: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(ForkarTheme.textSub)
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(isPositive ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isPositive ? .green : .orange)
            }
        }
    }
    
    // MARK: - Tarjeta de Los 3 Datos Reales de Sostenibilidad
    private var threeMetricsCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.emerald)
                Text("LOS 3 DATOS REALES VINCULADOS")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.2)
                    .foregroundColor(Color.emerald)
                Spacer()
                Text("Sin Hardcoding")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.emerald)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.emerald.opacity(0.15))
                    .cornerRadius(6)
            }
            
            HStack(spacing: 12) {
                // 1. CO2
                VStack(spacing: 4) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.emerald)
                    Text(String(format: "%.1f", co2Saved))
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(ForkarTheme.text)
                    Text("kg CO₂")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ForkarTheme.textSub)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                
                // 2. Puntos
                VStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                    Text("\(ecoPoints)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(ForkarTheme.text)
                    Text("Puntos Eco")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ForkarTheme.textSub)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                
                // 3. Nivel
                VStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.emerald)
                    Text(levelTitle.replacingOccurrences(of: "Nivel ", with: ""))
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(ForkarTheme.text)
                        .lineLimit(1)
                    Text("Nivel")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ForkarTheme.textSub)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
            }
            
            if let user = authManager.currentUser {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.emerald)
                    Text("Usuario certificado: \(user.email ?? user.resolvedName)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ForkarTheme.textSub)
                        .lineLimit(1)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(ForkarTheme.card)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Botones de Acción
    private var actionsSectionView: some View {
        VStack(spacing: 12) {
            // Botón Principal: Sincronizar Ahora
            Button(action: {
                #if os(iOS)
                syncManager.pushFullEcosystemSync()
                #endif
                withAnimation {
                    showSuccessBanner = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showSuccessBanner = false
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 15, weight: .bold))
                    Text("Vincular y Sincronizar Ahora")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.emerald, Color.green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.emerald.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            if showSuccessBanner {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("¡Datos reales de los 3 transmitidos a tu Apple Watch!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.2))
                .cornerRadius(10)
                .transition(.opacity.combined(with: .scale))
            }
            
            // Botón Secundario: Abrir App Watch del Sistema
            #if os(iOS)
            if !syncManager.isPaired {
                Button(action: {
                    if let url = URL(string: "itms-watchs://"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Abrir App Apple Watch en iOS")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ForkarTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            #endif
        }
    }
    
    // MARK: - Guía Paso a Paso
    private var troubleshootingCardView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("¿CÓMO VINCULAR TU APPLE WATCH?")
                .font(.system(size: 10, weight: .black))
                .tracking(1.2)
                .foregroundColor(ForkarTheme.textSub)
            
            VStack(alignment: .leading, spacing: 6) {
                stepRow(number: "1", text: "Mantén abierta la app Forkar en tu iPhone con sesión iniciada.")
                stepRow(number: "2", text: "Abre 'Forkar for Watch' en tu Apple Watch.")
                stepRow(number: "3", text: "Toca 'Vincular y Sincronizar Ahora' para autorizar el traspaso de datos reales.")
                stepRow(number: "4", text: "Tu Apple Watch desbloqueará el Eco Hub, Puntos y Chats CSMS.")
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
    }
    
    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.black)
                .frame(width: 16, height: 16)
                .background(Color.emerald)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(ForkarTheme.textSub)
        }
    }
}
