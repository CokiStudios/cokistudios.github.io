//
//  ForkarWatchSyncManager.swift
//  Forkar
//
//  Created by Coki Studios on 28/09/2026.
//  Bidirectional synchronization bridge uniting Forkar iOS & Apple Watch (watchOS)
//  Handles live Eco metrics, CSMS E2EE wrist interactions & Coki Copilot insights.
//

import Foundation
import SwiftUI
public import Combine

#if os(iOS)
import WatchConnectivity

public final class ForkarWatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = ForkarWatchSyncManager()
    
    @Published public var isPaired: Bool = false
    @Published public var isWatchAppInstalled: Bool = false
    @Published public var isReachable: Bool = false
    @Published public var lastSyncDate: Date? = nil
    @Published public var syncStatusMessage: String = "Listo para vincular"
    @Published public var isSyncing: Bool = false
    @Published public var activationStateName: String = "No activado"
    
    private var isActivating: Bool = false
    private var pendingEcoSync: Bool = false
    
    private override init() {
        super.init()
    }
    
    /// Activa de manera segura WCSession verificando que no esté ya en proceso de activación
    public func activate() {
        guard WCSession.isSupported() else {
            DispatchQueue.main.async {
                self.syncStatusMessage = "WatchConnectivity no soportado en este dispositivo"
                self.activationStateName = "No soportado"
            }
            return
        }
        
        let session = WCSession.default
        
        // Si ya está activada, solo actualizamos banderas y sincronizamos
        if session.activationState == .activated {
            DispatchQueue.main.async {
                self.isActivating = false
                self.activationStateName = "Activo"
                self.isPaired = session.isPaired
                self.isWatchAppInstalled = session.isWatchAppInstalled
                self.isReachable = session.isReachable
                self.syncStatusMessage = session.isPaired ? "Conectado al Apple Watch" : "Sin Apple Watch emparejado"
            }
            return
        }
        
        // Evitar activar si ya está en progreso para prevenir "already in progress or activated"
        guard session.activationState == .notActivated, !isActivating else {
            return
        }
        
        isActivating = true
        DispatchQueue.main.async {
            self.activationStateName = "Activando..."
            self.syncStatusMessage = "Conectando con Apple Watch..."
        }
        
        session.delegate = self
        session.activate()
    }
    
    // MARK: - Transmisiones Seguras al Apple Watch
    
    /// Sincroniza métricas reales de CO₂ y Puntos Eco garantizando que la sesión esté activada
    public func syncEcoImpact(co2: Double, points: Int, level: String = "Sostenible") {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        
        // Si la sesión no está activada, guardamos la intención y disparamos la activación
        guard session.activationState == .activated else {
            pendingEcoSync = true
            activate()
            return
        }
        
        guard session.isPaired else {
            DispatchQueue.main.async {
                self.syncStatusMessage = "No hay Apple Watch emparejado en iOS"
            }
            return
        }
        
        let payload: [String: Any] = [
            "co2_saved": co2,
            "eco_points": points,
            "level_title": level,
            "is_phone_linked": true,
            "sep_active": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 1. Envío interactivo inmediato si el reloj está al alcance
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
        
        // 2. Persistencia en el contexto de aplicación
        do {
            try session.updateApplicationContext(payload)
        } catch {
            print("WatchSync updateApplicationContext: \(error.localizedDescription)")
        }
        
        // 3. Complicaciones de esferas (solo si la app de reloj está instalada)
        #if canImport(ClockKit) || canImport(WidgetKit)
        if session.isWatchAppInstalled {
            session.transferCurrentComplicationUserInfo(payload)
        }
        #endif
        
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
            self.isSyncing = false
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.syncStatusMessage = "Sincronizado a las \(formatter.string(from: Date()))"
        }
    }
    
    /// Sincroniza credenciales de usuario verificadas
    public func syncUserProfile(name: String, email: String, userId: String) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired else { return }
        
        let payload: [String: Any] = [
            "user_name": name,
            "user_email": email,
            "user_id": userId,
            "is_phone_linked": true,
            "sep_active": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        try? session.updateApplicationContext(payload)
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }
    
    /// Despacha todos los 3 datos reales de sostenibilidad (CO2, Puntos, Nivel) y credenciales
    public func pushFullEcosystemSync() {
        DispatchQueue.main.async {
            self.isSyncing = true
            self.syncStatusMessage = "Transmitiendo datos reales..."
        }
        
        let currentCo2 = UserDefaults.standard.double(forKey: "forkar_co2_saved")
        let currentPoints = UserDefaults.standard.integer(forKey: "forkar_eco_points")
        let currentLevel = currentPoints >= 500 ? "Nivel Campeón Eco" : (currentPoints >= 200 ? "Nivel Avanzado" : (currentPoints >= 100 ? "Nivel Pro" : "Nivel Sostenible"))
        
        if let user = SupabaseManager.shared.currentUser {
            let displayName = user.email?.components(separatedBy: "@").first?.capitalized ?? "Miembro Coki"
            self.syncUserProfile(name: displayName, email: user.email ?? "", userId: user.id.uuidString)
        }
        self.syncEcoImpact(co2: currentCo2, points: currentPoints, level: currentLevel)
        self.syncCopilotInsight("Conducción eco-eficiente activa • Vinculado al iPhone")
    }
    
    /// Transmite sugerencias de Coki Copilot a la muñeca
    public func syncCopilotInsight(_ insight: String) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired else { return }
        
        let payload: [String: Any] = [
            "copilot_insight": insight,
            "is_phone_linked": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(payload)
        }
    }
    
    // MARK: - WCSessionDelegate (Ciclo de Vida iOS)
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isActivating = false
            self.activationStateName = activationState == .activated ? "Activo" : (activationState == .inactive ? "Inactivo" : "No activado")
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
            
            if activationState == .activated {
                self.syncStatusMessage = session.isPaired ? "Conectado al Apple Watch" : "Sin Apple Watch emparejado"
                if session.isPaired && (session.isWatchAppInstalled || self.pendingEcoSync) {
                    self.pendingEcoSync = false
                    self.pushFullEcosystemSync()
                }
            } else if let error = error {
                self.syncStatusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.activationStateName = "Inactivo"
        }
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isActivating = false
            self.activationStateName = "Desactivado"
            // Reactivación segura para soporte de cambio rápido de reloj
            WCSession.default.activate()
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if session.isReachable && self.isPaired {
                self.syncStatusMessage = "Apple Watch al alcance"
            }
        }
    }
    
    public func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    // MARK: - Mensajes Entrantes desde Apple Watch
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingWatchPayload(message)
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleIncomingWatchPayload(message)
        replyHandler(["status": "acknowledged", "timestamp": Date().timeIntervalSince1970])
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingWatchPayload(userInfo)
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleIncomingWatchPayload(applicationContext)
    }
    
    private func handleIncomingWatchPayload(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }
        
        switch action {
        case "eco_check_in":
            let addedPoints = payload["added_points"] as? Int ?? 20
            let addedCo2 = payload["added_co2"] as? Double ?? 0.8
            
            Task { @MainActor in
                let currentCo2 = UserDefaults.standard.double(forKey: "forkar_co2_saved") + addedCo2
                let currentPoints = UserDefaults.standard.integer(forKey: "forkar_eco_points") + addedPoints
                
                UserDefaults.standard.set(currentCo2, forKey: "forkar_co2_saved")
                UserDefaults.standard.set(currentPoints, forKey: "forkar_eco_points")
                
                // Persistencia en Supabase
                _ = try? await SupabaseManager.shared.logUserEcoImpact(
                    actionId: UUID().uuidString,
                    co2Saved: addedCo2,
                    pointsEarned: addedPoints
                )
                
                // Confirmar de vuelta al reloj con totales actualizados
                self.syncEcoImpact(co2: currentCo2, points: currentPoints)
            }
            
        case "request_sync":
            Task { @MainActor in
                self.pushFullEcosystemSync()
            }
            
        case "send_chat_message":
            guard let text = payload["text"] as? String, !text.isEmpty else { return }
            let roomIdStr = payload["room_id"] as? String ?? CSMSCanonicalRooms.communityGlobal
            let defaultRoomUUID = UUID(uuidString: CSMSCanonicalRooms.communityGlobal) ?? UUID()
            let roomUUID = UUID(uuidString: roomIdStr) ?? defaultRoomUUID
            
            Task { @MainActor in
                _ = try? await SupabaseManager.shared.sendMessage(
                    roomId: roomUUID,
                    content: text
                )
            }
            
        default:
            break
        }
    }
}

#else

// MARK: - macOS Safe Stub
public final class ForkarWatchSyncManager: ObservableObject {
    public static let shared = ForkarWatchSyncManager()
    
    @Published public var isPaired: Bool = false
    @Published public var isWatchAppInstalled: Bool = false
    @Published public var isReachable: Bool = false
    @Published public var lastSyncDate: Date? = nil
    @Published public var syncStatusMessage: String = "No aplicable en macOS"
    @Published public var isSyncing: Bool = false
    @Published public var activationStateName: String = "macOS"
    
    private init() {}
    public func activate() {}
    public func syncEcoImpact(co2: Double, points: Int, level: String = "Sostenible") {}
    public func syncUserProfile(name: String, email: String, userId: String) {}
    public func pushFullEcosystemSync() {}
    public func syncCopilotInsight(_ insight: String) {}
}

#endif
