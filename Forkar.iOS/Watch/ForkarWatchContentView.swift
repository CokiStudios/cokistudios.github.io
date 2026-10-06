//
//  ForkarWatchContentView.swift
//  ForkarWatch
//
//  Native watchOS interface for Forkar
//  Optimized for Apple Watch Series 8-12 and Apple Watch Ultra 1-4
//

import SwiftUI

public struct ForkarWatchContentView: View {
    @StateObject private var watchBridge = ForkarWatchConnectivity.shared
    @State private var selectedTab = 0
    @State private var showCheckInSuccess = false
    @State private var customReplyText = ""
    @State private var isReplying = false
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Tab 1: Eco Dashboard
            ecoDashboardPage
                .tag(0)
            
            // MARK: - Tab 2: CSMS Wrist Chat
            csmsChatPage
                .tag(1)
            
            // MARK: - Tab 3: Estado & Llave Criptográfica
            hardwareStatusPage
                .tag(2)
        }
        .tabViewStyle(.page)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(watchBridge.isReachable ? Color.green : Color.orange.opacity(0.8))
                .frame(width: 6, height: 6)
                .padding(6)
        }
    }
    
    // MARK: - Eco Dashboard
    private var ecoDashboardPage: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Eco Ring Gauge
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 8)
                        .frame(width: 82, height: 82)
                    
                    Circle()
                        .trim(from: 0, to: min(CGFloat(watchBridge.co2Saved / 20.0), 1.0))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.green, .mint, .teal]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 82, height: 82)
                    
                    VStack(spacing: 1) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text("\(watchBridge.co2Saved, specifier: "%.1f")")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("kg CO₂")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                
                // Puntos Eco Badge
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    
                    Text("\(watchBridge.ecoPoints) pts")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(12)
                
                // Acción Rápida: Validar Check-In en Muñeca
                Button(action: {
                    watchBridge.sendWristCheckIn()
                    showCheckInSuccess = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 13))
                        Text("Validar Eco")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 4)
                .alert("¡Acción Registrada!", isPresented: $showCheckInSuccess) {
                    Button("Listo", role: .cancel) { }
                } message: {
                    Text("+20 Puntos Eco y 0.8 kg CO₂ ahorrados sincronizados con iPhone.")
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - CSMS Wrist Chat
    private var csmsChatPage: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("CSMS E2EE")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.green)
                        .tracking(1.0)
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                // Respuestas Rápidas Pre-configuradas
                VStack(spacing: 5) {
                    quickReplyButton("En camino 🚗")
                    quickReplyButton("Punto Verde validado 🌱")
                    quickReplyButton("Confirmado ✅")
                    quickReplyButton("Nos vemos pronto 👋")
                }
                
                // Botón de Dictado por Voz
                TextField("Escribir mensaje...", text: $customReplyText)
                    .onSubmit {
                        if !customReplyText.isEmpty {
                            watchBridge.sendQuickReply(text: customReplyText)
                            customReplyText = ""
                        }
                    }
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func quickReplyButton(_ text: String) -> some View {
        Button(action: {
            watchBridge.sendQuickReply(text: text)
        }) {
            HStack {
                Text(text)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.mint)
            }
        }
        .buttonStyle(.bordered)
        .tint(.gray.opacity(0.3))
    }
    
    // MARK: - Estado de Hardware y Llaves Criptográficas
    private var hardwareStatusPage: some View {
        ScrollView {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.indigo.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(watchBridge.userInitials)
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.indigo)
                    )
                
                Text(watchBridge.userName)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 4) {
                    statusRow(
                        title: "Cifrado",
                        value: "AES-256-GCM",
                        icon: "lock.fill",
                        color: .green
                    )
                    statusRow(
                        title: "Secure Enclave",
                        value: "Hardware SEP",
                        icon: "cpu.fill",
                        color: .mint
                    )
                    statusRow(
                        title: "Enlace iPhone",
                        value: watchBridge.isReachable ? "Conectado" : "En espera",
                        icon: "iphone.gen3",
                        color: watchBridge.isReachable ? .green : .orange
                    )
                }
                .padding(8)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func statusRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
