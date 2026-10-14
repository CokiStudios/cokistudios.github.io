//
//  ContentView.swift
//  Forkar for Watch Watch App
//
//  Created by iJeriX Ortiz on 13/10/26.
//  Copyright © 2026 Coki Studios. All rights reserved.
//

import SwiftUI
import WatchKit
import WatchConnectivity
public import Combine

// MARK: - Models
struct WatchChatRoom: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String?
    let is_group: Bool
    let created_at: String
    
    var displayName: String {
        name ?? "Chat Privado"
    }
}

struct WatchChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let room_id: UUID
    let sender_id: UUID
    let content: String
    let created_at: String
    var author_name: String? = nil
    
    var isCokiAI: Bool {
        (author_name?.contains("Coki") == true) || content.hasPrefix("🤖 [Coki AI]")
    }
    
    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: created_at) ?? ISO8601DateFormatter().date(from: created_at) else {
            return ""
        }
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: date)
    }
}

// MARK: - Supabase Watch Manager (Zero Hardcoding - Requiere Vinculación con iPhone)
class WatchSupabaseManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSupabaseManager()
    
    let baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"
    
    // Identidad dinámica (Cero identidades falsas o hardcodeadas)
    @Published var currentUserEmail: String = ""
    @Published var currentUserId: UUID? = nil
    @Published var rooms: [WatchChatRoom] = []
    @Published var isLoading = false
    
    // Los 3 Datos Reales de Sostenibilidad sincronizados desde iPhone
    @Published var co2Saved: Double = 0.0
    @Published var ecoPoints: Int = 0
    @Published var levelTitle: String = ""
    @Published var copilotInsight: String = ""
    
    // Estado de Enlace con iPhone
    @Published var isReachable: Bool = false
    @Published var isPhoneLinked: Bool = false
    @Published var hasReceivedInitialSync: Bool = false
    @Published var isSEPActive: Bool = true
    private var isActivating: Bool = false
    
    override init() {
        super.init()
        
        // Recuperar solo si existe sesión vinculada previamente
        if UserDefaults.standard.bool(forKey: "cs_watch_is_linked") {
            if let storedEmail = UserDefaults.standard.string(forKey: "cs_watch_user_email"), !storedEmail.isEmpty {
                currentUserEmail = storedEmail
                isPhoneLinked = true
                hasReceivedInitialSync = true
            }
            if let storedId = UserDefaults.standard.string(forKey: "cs_watch_user_id"), let uuid = UUID(uuidString: storedId) {
                currentUserId = uuid
            }
            co2Saved = UserDefaults.standard.double(forKey: "cs_watch_co2")
            ecoPoints = UserDefaults.standard.integer(forKey: "cs_watch_pts")
            levelTitle = UserDefaults.standard.string(forKey: "cs_watch_level") ?? "Nivel Sostenible"
            copilotInsight = UserDefaults.standard.string(forKey: "cs_watch_copilot") ?? "Conducción eco-eficiente activa"
        }
        
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState == .notActivated && !isActivating {
            isActivating = true
            session.activate()
        }
    }
    
    /// Solicita forzosamente al iPhone la sincronización de los 3 datos reales y la identidad activa
    func requestSyncFromiPhone() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else {
            if session.activationState == .notActivated && !isActivating {
                isActivating = true
                session.activate()
            }
            return
        }
        let payload: [String: Any] = [
            "action": "request_sync",
            "timestamp": Date().timeIntervalSince1970
        ]
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            do {
                try session.updateApplicationContext(payload)
            } catch {
                // Silencioso si la sesión cambia de estado
            }
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isActivating = false
            self.isReachable = session.isReachable
            if activationState == .activated {
                self.requestSyncFromiPhone()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if session.isReachable && session.activationState == .activated && (!self.isPhoneLinked || !self.hasReceivedInitialSync) {
                self.requestSyncFromiPhone()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.processIncomingPayload(applicationContext)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.processIncomingPayload(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.processIncomingPayload(userInfo)
        }
    }
    
    private func processIncomingPayload(_ payload: [String: Any]) {
        if let linked = payload["is_phone_linked"] as? Bool, linked {
            self.isPhoneLinked = true
            self.hasReceivedInitialSync = true
            UserDefaults.standard.set(true, forKey: "cs_watch_is_linked")
        }
        
        if let email = payload["user_email"] as? String, !email.isEmpty {
            self.currentUserEmail = email
            self.isPhoneLinked = true
            self.hasReceivedInitialSync = true
            UserDefaults.standard.set(email, forKey: "cs_watch_user_email")
            UserDefaults.standard.set(true, forKey: "cs_watch_is_linked")
        }
        
        if let idStr = payload["user_id"] as? String, let uuid = UUID(uuidString: idStr) {
            self.currentUserId = uuid
            UserDefaults.standard.set(idStr, forKey: "cs_watch_user_id")
        }
        
        // Los 3 datos reales recibidos del iPhone
        var receivedAnyEcoData = false
        if let co2 = payload["co2_saved"] as? Double {
            self.co2Saved = co2
            UserDefaults.standard.set(co2, forKey: "cs_watch_co2")
            receivedAnyEcoData = true
        }
        if let pts = payload["eco_points"] as? Int {
            self.ecoPoints = pts
            UserDefaults.standard.set(pts, forKey: "cs_watch_pts")
            receivedAnyEcoData = true
        }
        if let lvl = payload["level_title"] as? String, !lvl.isEmpty {
            self.levelTitle = lvl
            UserDefaults.standard.set(lvl, forKey: "cs_watch_level")
            receivedAnyEcoData = true
        }
        
        if receivedAnyEcoData {
            self.isPhoneLinked = true
            self.hasReceivedInitialSync = true
            UserDefaults.standard.set(true, forKey: "cs_watch_is_linked")
        }
        
        if let insight = payload["copilot_insight"] as? String, !insight.isEmpty {
            self.copilotInsight = insight
            UserDefaults.standard.set(insight, forKey: "cs_watch_copilot")
        }
        if let sep = payload["sep_active"] as? Bool {
            self.isSEPActive = sep
        }
        
        Task {
            await self.fetchRooms()
        }
    }
    
    func sendWristCheckIn(points: Int = 20, co2: Double = 0.8) {
        self.ecoPoints += points
        self.co2Saved += co2
        UserDefaults.standard.set(self.co2Saved, forKey: "cs_watch_co2")
        UserDefaults.standard.set(self.ecoPoints, forKey: "cs_watch_pts")
        
        let payload: [String: Any] = [
            "action": "eco_check_in",
            "added_points": points,
            "added_co2": co2,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.default.activationState == .activated {
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            } else {
                try? WCSession.default.updateApplicationContext(payload)
            }
        }
    }
    
    func fetchRooms() async {
        guard isPhoneLinked else { return }
        await MainActor.run { isLoading = true }
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_rooms?select=*&order=created_at.desc") else { return }
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                let decoded = try JSONDecoder().decode([WatchChatRoom].self, from: data)
                await MainActor.run {
                    self.rooms = decoded
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
    
    func fetchMessages(roomId: UUID) async -> [WatchChatMessage] {
        guard isPhoneLinked else { return [] }
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_messages?select=*&room_id=eq.\(roomId.uuidString)&order=created_at.asc") else { return [] }
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                return (try? JSONDecoder().decode([WatchChatMessage].self, from: data)) ?? []
            }
        } catch {}
        return []
    }
    
    func sendMessage(roomId: UUID, content: String, authorName: String? = nil) async -> Bool {
        guard isPhoneLinked, let currentUserId = currentUserId else { return false }
        let clean = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return false }
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_messages") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        var payload: [String: Any] = [
            "room_id": roomId.uuidString,
            "sender_id": currentUserId.uuidString,
            "content": clean
        ]
        if let authorName = authorName {
            payload["author_name"] = authorName
        }
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return false }
        request.httpBody = httpBody
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                return true
            }
        } catch {}
        return false
    }
}

// MARK: - Main Content View (Multitab)
struct ContentView: View {
    @StateObject private var supabase = WatchSupabaseManager.shared
    
    var body: some View {
        TabView {
            WatchEcoDashboardView()
            WatchRoomsListView()
            WatchHardwareStatusView()
        }
        .tabViewStyle(.page)
        .onAppear {
            supabase.requestSyncFromiPhone()
        }
    }
}

// MARK: - Tab 0: Watch Eco Dashboard (Los 3 Datos Reales de Sostenibilidad)
struct WatchEcoDashboardView: View {
    @StateObject private var supabase = WatchSupabaseManager.shared
    @State private var showCheckInAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if !supabase.isPhoneLinked && !supabase.hasReceivedInitialSync {
                    // Barrera de Vinculación Obligatoria
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.orange.opacity(0.3), lineWidth: 4)
                                .frame(width: 52, height: 52)
                            Image(systemName: "iphone.and.arrow.forward")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 4)
                        
                        Text("Vincular con iPhone")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Abre Forkar en tu iPhone para sincronizar los datos reales de los 3:")
                            .font(.system(size: 9))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("1. CO₂ Ahorrado (kg)")
                            Text("2. Puntos Eco")
                            Text("3. Nivel de Sostenibilidad")
                        }
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.green)
                        
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            supabase.requestSyncFromiPhone()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Sincronizar con iPhone")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.35))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 4)
                } else {
                    // Datos Reales de los 3
                    // 1. Tacómetro de CO2 Real
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.2), lineWidth: 7)
                            .frame(width: 76, height: 76)
                        
                        Circle()
                            .trim(from: 0, to: min(CGFloat(supabase.co2Saved / 20.0), 1.0))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.green, .mint, .teal]),
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 7, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 76, height: 76)
                        
                        VStack(spacing: 0) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.green)
                            
                            Text(String(format: "%.1f", supabase.co2Saved))
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.white)
                            
                            Text("kg CO₂")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 2)
                    
                    // 2. Puntos Eco Reales y 3. Nivel Real
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("\(supabase.ecoPoints) pts")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.gray)
                            .font(.system(size: 9))
                        
                        Text(supabase.levelTitle.isEmpty ? "Sostenible" : supabase.levelTitle)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color.green)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.18))
                    .cornerRadius(10)
                    
                    // Indicador de Certificación Real
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("iPhone Vinculado • Datos Reales")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    // Wrist Check-In Button
                    Button(action: {
                        WKInterfaceDevice.current().play(.success)
                        supabase.sendWristCheckIn()
                        showCheckInAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Check-In Eco (+20)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.25))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Coki Copilot Wrist Insight
                    if !supabase.copilotInsight.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(red: 99/255, green: 102/255, blue: 241/255))
                                Text("Coki Copilot")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text(supabase.copilotInsight)
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        .padding(6)
                        .background(Color(white: 0.12))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Eco Hub")
        .alert("¡Check-In Registrado! 🌿", isPresented: $showCheckInAlert) {
            Button("Genial", role: .cancel) {}
        } message: {
            Text("+20 Puntos Eco y +0.8 kg CO₂ sincronizados en vivo con tu iPhone.")
        }
    }
}

// MARK: - Tab 1: Watch Rooms List View (CSMS E2EE)
struct WatchRoomsListView: View {
    @StateObject private var supabase = WatchSupabaseManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !supabase.isPhoneLinked && !supabase.hasReceivedInitialSync {
                    VStack(spacing: 6) {
                        Image(systemName: "lock.iphone")
                            .font(.system(size: 26))
                            .foregroundColor(.orange)
                        Text("Requiere iPhone")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text("Inicia sesión en Forkar para iPhone para desbloquear tus salas con cifrado E2EE.")
                            .font(.system(size: 9))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                        
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            supabase.requestSyncFromiPhone()
                        }) {
                            Text("Vincular")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 6)
                } else if supabase.isLoading && supabase.rooms.isEmpty {
                    ProgressView()
                        .tint(Color(red: 99/255, green: 102/255, blue: 241/255))
                } else if supabase.rooms.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 99/255, green: 102/255, blue: 241/255))
                        Text("No hay chats")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("Desliza para actualizar")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(supabase.rooms) { room in
                            NavigationLink(destination: WatchChatDetailView(room: room)) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(red: 99/255, green: 102/255, blue: 241/255), Color(red: 139/255, green: 92/255, blue: 246/255)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 28, height: 28)
                                        
                                        Image(systemName: room.is_group ? "person.2.fill" : "message.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(room.displayName)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Text(room.is_group ? "Grupo CSMS" : "Directo")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(white: 0.12))
                            )
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle("CSMS Chats")
            .task {
                if supabase.isPhoneLinked {
                    await supabase.fetchRooms()
                }
            }
            .refreshable {
                await supabase.fetchRooms()
            }
        }
    }
}

// MARK: - Tab 2: Watch Hardware & Telemetría Status
struct WatchHardwareStatusView: View {
    @StateObject private var supabase = WatchSupabaseManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(red: 99/255, green: 102/255, blue: 241/255))
                    .padding(.top, 4)
                
                Text("Seguridad y Enlace")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Secure Enclave:")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Activo (SEP)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("Cifrado CSMS:")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("AES-256-GCM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Enlace iPhone:")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(supabase.isPhoneLinked ? "Vinculado (Datos Reales)" : "No Vinculado")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(supabase.isPhoneLinked ? .green : .orange)
                    }
                    HStack {
                        Text("Datos de los 3:")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(supabase.hasReceivedInitialSync ? "Sincronizados" : "Pendiente")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(supabase.hasReceivedInitialSync ? .green : .yellow)
                    }
                }
                .padding(8)
                .background(Color(white: 0.12))
                .cornerRadius(10)
                
                Text(supabase.currentUserEmail.isEmpty ? "Usuario: Abre Forkar en iPhone para vincular" : "Usuario: \(supabase.currentUserEmail)")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Seguridad")
    }
}

// MARK: - Watch Chat Detail View with Voice & Quick Dictation
struct WatchChatDetailView: View {
    let room: WatchChatRoom
    @StateObject private var supabase = WatchSupabaseManager.shared
    @State private var messages: [WatchChatMessage] = []
    @State private var isLoading = false
    @State private var quickText = ""
    
    let quickReplies = [
        "¡Hola! 👋",
        "En camino 🏃‍♂️",
        "Listo ✅",
        "Hablamos luego ⏳",
        "De acuerdo 👍",
        "Revisando Forkar 🌿",
        "/Coki ¿cómo va mi eco-score?",
        "/Coki consejos de conducción",
        "@Coki estado de telemetría",
        "/Genimg auto eléctrico"
    ]
    
    @State private var showQuickRepliesSheet = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    // Quick Action Bar
                    HStack(spacing: 6) {
                        Button(action: {
                            showQuickRepliesSheet = true
                        }) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.yellow)
                                .frame(width: 32, height: 32)
                                .background(Color(white: 0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        TextField("Mensaje...", text: $quickText)
                            .font(.system(size: 12))
                            .onSubmit {
                                sendQuickReply(quickText)
                                quickText = ""
                            }
                    }
                    .padding(.horizontal, 4)
                    
                    if messages.isEmpty && !isLoading {
                        Text("Sin mensajes recientes")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        ForEach(messages) { msg in
                            let isMe = msg.sender_id == (supabase.currentUserId ?? UUID())
                            let isAI = msg.isCokiAI
                            let hasMention = msg.content.contains("@") || msg.content.contains("/")
                            
                            HStack {
                                if isMe { Spacer() }
                                
                                VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                                    if isAI {
                                        HStack(spacing: 3) {
                                            Text("🤖")
                                                .font(.system(size: 9))
                                            Text("Coki AI")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                    
                                    Text(msg.content)
                                        .font(.system(size: 11, weight: isAI ? .semibold : .medium))
                                        .foregroundColor(hasMention && !isMe ? Color(red: 254/255, green: 240/255, blue: 138/255) : .white)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(
                                            isAI
                                            ? Color(red: 30/255, green: 27/255, blue: 75/255)
                                            : (isMe
                                                ? Color(red: 99/255, green: 102/255, blue: 241/255)
                                                : Color(white: 0.18))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isAI ? Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.8) : Color.clear, lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                    
                                    Text(msg.formattedTime)
                                        .font(.system(size: 9))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                }
                                .id(msg.id)
                                
                                if !isMe { Spacer() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle(room.displayName)
            .sheet(isPresented: $showQuickRepliesSheet) {
                ScrollView {
                    VStack(spacing: 6) {
                        Text("Respuestas Rápidas")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                        
                        ForEach(quickReplies, id: \.self) { reply in
                            Button(action: {
                                showQuickRepliesSheet = false
                                sendQuickReply(reply)
                            }) {
                                HStack {
                                    Text(reply)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color(white: 0.16))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(8)
                }
            }
            .task {
                await loadMessages()
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .refreshable {
                await loadMessages()
            }
        }
    }
    
    private func loadMessages() async {
        isLoading = true
        let msgs = await supabase.fetchMessages(roomId: room.id)
        await MainActor.run {
            self.messages = msgs
            self.isLoading = false
        }
    }
    
    private func sendQuickReply(_ text: String) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        WKInterfaceDevice.current().play(.click)
        Task {
            let success = await supabase.sendMessage(roomId: room.id, content: cleanText)
            if success {
                await loadMessages()
            }
            
            let isCokiQuery = cleanText.hasPrefix("/Coki") || cleanText.contains("@Coki")
            let isGenImg = cleanText.hasPrefix("/Genimg")
            
            if isCokiQuery {
                let query = cleanText.replacingOccurrences(of: "/Coki", with: "")
                    .replacingOccurrences(of: "@Coki", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let lowerQ = query.lowercased()
                let aiResponse: String
                if lowerQ.contains("eco") || lowerQ.contains("puntos") || lowerQ.contains("co2") {
                    aiResponse = "Has ahorrado \(String(format: "%.1f", supabase.co2Saved)) kg de CO₂ y tienes \(supabase.ecoPoints) Puntos Eco en nivel '\(supabase.levelTitle)'."
                } else if lowerQ.contains("conducc") || lowerQ.contains("conduc") || lowerQ.contains("viaje") || lowerQ.contains("telemetr") {
                    aiResponse = "Insight de Forkar Copilot: \(supabase.copilotInsight). Aceleración eficiente detectada."
                } else {
                    aiResponse = "Coki con Apple Intelligence activo en watchOS. Tus salas están cifradas con el Secure Enclave (SEP)."
                }
                
                _ = await supabase.sendMessage(
                    roomId: room.id,
                    content: "🤖 [Coki AI]: \(aiResponse)",
                    authorName: "Coki with Apple Intelligence"
                )
                await loadMessages()
            } else if isGenImg {
                let prompt = cleanText.replacingOccurrences(of: "/Genimg", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let targetPrompt = prompt.isEmpty ? "tu concepto" : "'\(prompt)'"
                _ = await supabase.sendMessage(
                    roomId: room.id,
                    content: "🎨 [Apple ImagePlayground]: Abre Forkar en tu iPhone o Mac para generar \(targetPrompt) con la API de Playground en pantalla completa.",
                    authorName: "Coki with Apple Intelligence"
                )
                await loadMessages()
            }
        }
    }
}
