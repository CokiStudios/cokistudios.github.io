//
//  ForkarWatchConnectivity.swift
//  ForkarWatch
//
//  Bi-directional WatchConnectivity bridge between iPhone and Apple Watch
//  Synchronizes Eco Telemetry, CSMS E2EE Chat previews & hardware credentials
//

import Foundation
import WatchConnectivity
internal import Combine

public class ForkarWatchConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = ForkarWatchConnectivity()
    
    @Published public var isReachable: Bool = false
    @Published public var co2Saved: Double = 0.0
    @Published public var ecoPoints: Int = 0
    @Published public var currentLevel: String = "Sostenible"
    @Published public var userName: String = "CS Member"
    @Published public var userInitials: String = "CS"
    @Published public var recentMessages: [WatchChatMessage] = []
    @Published public var isHardwareSEPActive: Bool = true
    
    private let userDefaults = UserDefaults.standard
    
    public override init() {
        super.init()
        loadLocalCache()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    private func loadLocalCache() {
        self.co2Saved = userDefaults.double(forKey: "forkar_watch_co2")
        self.ecoPoints = userDefaults.integer(forKey: "forkar_watch_points")
        if self.ecoPoints == 0 { self.ecoPoints = 120 }
        if self.co2Saved == 0.0 { self.co2Saved = 4.2 }
        self.userName = userDefaults.string(forKey: "forkar_watch_user") ?? "Miembro Coki"
        self.userInitials = String(self.userName.prefix(2)).uppercased()
    }
    
    public func saveLocalCache() {
        userDefaults.set(co2Saved, forKey: "forkar_watch_co2")
        userDefaults.set(ecoPoints, forKey: "forkar_watch_points")
        userDefaults.set(userName, forKey: "forkar_watch_user")
    }
    
    // MARK: - Outgoing Actions from Wrist
    public func sendWristCheckIn(points: Int = 20, co2: Double = 0.8) {
        self.ecoPoints += points
        self.co2Saved += co2
        saveLocalCache()
        
        guard WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = [
            "action": "eco_check_in",
            "added_points": points,
            "added_co2": co2,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("WatchConnectivity error: \(error.localizedDescription)")
            }
        } else {
            try? WCSession.default.updateApplicationContext(payload)
        }
    }
    
    public func sendQuickReply(text: String, roomId: String = "general") {
        let newMsg = WatchChatMessage(
            id: UUID().uuidString,
            sender: self.userName,
            text: text,
            timestamp: Date(),
            isMine: true
        )
        self.recentMessages.insert(newMsg, at: 0)
        
        guard WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = [
            "action": "send_chat_message",
            "room_id": roomId,
            "text": text,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }
    
    // MARK: - WCSessionDelegate
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.processIncomingPayload(message)
        }
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.processIncomingPayload(applicationContext)
        }
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.processIncomingPayload(userInfo)
        }
    }
    
    private func processIncomingPayload(_ dict: [String: Any]) {
        if let co2 = dict["co2_saved"] as? Double {
            self.co2Saved = co2
        }
        if let pts = dict["eco_points"] as? Int {
            self.ecoPoints = pts
        }
        if let name = dict["user_name"] as? String {
            self.userName = name
            self.userInitials = String(name.prefix(2)).uppercased()
        }
        if let level = dict["level_title"] as? String {
            self.currentLevel = level
        }
        if let sepActive = dict["sep_active"] as? Bool {
            self.isHardwareSEPActive = sepActive
        }
        saveLocalCache()
    }
}

// MARK: - Watch Chat Message Model
public struct WatchChatMessage: Identifiable, Hashable {
    public let id: String
    public let sender: String
    public let text: String
    public let timestamp: Date
    public let isMine: Bool
}
