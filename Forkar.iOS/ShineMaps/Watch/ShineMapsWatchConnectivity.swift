//
//  ShineMapsWatchConnectivity.swift
//  ShineMapsWatch
//
//  Created by Coki Studios.
//  Bi-directional WCSession bridge syncing turn-by-turn navigation, haptic cues,
//  speed telemetry, and nearby POIs between iPhone/CarPlay and Apple Watch.
//

import Foundation
import WatchConnectivity
import WatchKit
internal import Combine

public struct WatchPOI: Identifiable, Codable, Hashable {
    public var id: String
    public var name: String
    public var category: String
    public var distance: String
    public var icon: String
    public var latitude: Double
    public var longitude: Double
    
    public init(id: String = UUID().uuidString, name: String, category: String, distance: String, icon: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.category = category
        self.distance = distance
        self.icon = icon
        self.latitude = latitude
        self.longitude = longitude
    }
}

public class ShineMapsWatchConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = ShineMapsWatchConnectivity()
    
    @Published public var isReachable: Bool = false
    @Published public var isNavigating: Bool = false
    @Published public var destinationName: String = "Destino Seleccionado"
    @Published public var currentInstruction: String = "Continúa recto"
    @Published public var currentManeuverIcon: String = "arrow.up"
    @Published public var distanceToNextManeuver: String = "450 m"
    @Published public var distanceMeters: Double = 450.0
    @Published public var etaString: String = "--:--"
    @Published public var remainingTime: String = "-- min"
    @Published public var totalRemainingDistance: String = "-- km"
    @Published public var currentSpeedKmh: Int = 0
    @Published public var speedLimitKmh: Int = 60
    @Published public var nextInstruction: String = "En 450m gira a la derecha"
    @Published public var nearbyPOIs: [WatchPOI] = []
    
    private var lastHapticStepId: String = ""
    private var hasTriggered100mHaptic: Bool = false
    private var hasTriggered20mHaptic: Bool = false
    
    public override init() {
        super.init()
        setupWatchConnectivity()
        loadDefaultSamplePOIs()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    private func loadDefaultSamplePOIs() {
        // Valores iniciales reales mientras sincroniza con el backend/iPhone
        self.nearbyPOIs = [
            WatchPOI(name: "Electrolinera Enel X", category: "Carga EV", distance: "650 m", icon: "bolt.car.fill", latitude: 4.6533, longitude: -74.0836),
            WatchPOI(name: "Parqueadero Central", category: "Parking", distance: "280 m", icon: "parkingsign.circle.fill", latitude: 4.6540, longitude: -74.0810),
            WatchPOI(name: "Punto Verde Reciclaje", category: "Eco", distance: "1.1 km", icon: "arrow.3.trianglepath", latitude: 4.6580, longitude: -74.0850),
            WatchPOI(name: "Estación Terpel", category: "Gasolina", distance: "900 m", icon: "fuelpump.fill", latitude: 4.6510, longitude: -74.0890)
        ]
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
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.processReceivedData(applicationContext)
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.processReceivedData(message)
        }
    }
    
    private func processReceivedData(_ data: [String: Any]) {
        if let nav = data["is_navigating"] as? Bool {
            self.isNavigating = nav
        }
        if let dest = data["destination_name"] as? String {
            self.destinationName = dest
        }
        if let inst = data["instruction"] as? String {
            self.currentInstruction = inst
        }
        if let icon = data["maneuver_icon"] as? String {
            self.currentManeuverIcon = icon
        }
        if let distStr = data["distance_formatted"] as? String {
            self.distanceToNextManeuver = distStr
        }
        if let distM = data["distance_meters"] as? Double {
            self.distanceMeters = distM
            self.checkHapticTriggers(distance: distM)
        }
        if let eta = data["eta"] as? String {
            self.etaString = eta
        }
        if let remTime = data["remaining_time"] as? String {
            self.remainingTime = remTime
        }
        if let remDist = data["remaining_distance"] as? String {
            self.totalRemainingDistance = remDist
        }
        if let speed = data["speed_kmh"] as? Int {
            self.currentSpeedKmh = speed
        }
        if let limit = data["speed_limit_kmh"] as? Int {
            self.speedLimitKmh = limit
        }
        if let next = data["next_instruction"] as? String {
            self.nextInstruction = next
        }
        if let rawPOIs = data["nearby_pois"] as? [[String: Any]] {
            self.nearbyPOIs = rawPOIs.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let cat = dict["category"] as? String,
                      let dist = dict["distance"] as? String,
                      let icon = dict["icon"] as? String else { return nil }
                let lat = dict["lat"] as? Double ?? 0.0
                let lon = dict["lon"] as? Double ?? 0.0
                return WatchPOI(name: name, category: cat, distance: dist, icon: icon, latitude: lat, longitude: lon)
            }
        }
    }
    
    // MARK: - Smart Wrist Haptics
    private func checkHapticTriggers(distance: Double) {
        let isTurnRight = currentManeuverIcon.contains("right")
        let isTurnLeft = currentManeuverIcon.contains("left")
        
        if distance <= 120 && distance > 30 && !hasTriggered100mHaptic {
            hasTriggered100mHaptic = true
            if isTurnRight {
                WKInterfaceDevice.current().play(.directionRight)
            } else if isTurnLeft {
                WKInterfaceDevice.current().play(.directionLeft)
            } else {
                WKInterfaceDevice.current().play(.notification)
            }
        } else if distance <= 30 && !hasTriggered20mHaptic {
            hasTriggered20mHaptic = true
            if isTurnRight {
                WKInterfaceDevice.current().play(.directionRight)
            } else if isTurnLeft {
                WKInterfaceDevice.current().play(.directionLeft)
            } else {
                WKInterfaceDevice.current().play(.success)
            }
        } else if distance > 150 {
            // Reset for upcoming step
            hasTriggered100mHaptic = false
            hasTriggered20mHaptic = false
        }
    }
    
    // MARK: - User Commands from Wrist
    public func stopNavigation() {
        self.isNavigating = false
        WKInterfaceDevice.current().play(.click)
        sendMessageToCompanion(["action": "stop_navigation"])
    }
    
    public func navigateToPOI(_ poi: WatchPOI) {
        self.isNavigating = true
        self.destinationName = poi.name
        self.currentInstruction = "Iniciando ruta hacia \(poi.name)"
        self.currentManeuverIcon = "arrow.up.circle.fill"
        self.distanceToNextManeuver = "50 m"
        WKInterfaceDevice.current().play(.start)
        
        sendMessageToCompanion([
            "action": "start_route_to_poi",
            "poi_name": poi.name,
            "lat": poi.latitude,
            "lon": poi.longitude
        ])
    }
    
    public func requestReroute() {
        WKInterfaceDevice.current().play(.retry)
        sendMessageToCompanion(["action": "reroute"])
    }
    
    private func sendMessageToCompanion(_ dict: [String: Any]) {
        guard WCSession.default.isReachable else {
            try? WCSession.default.updateApplicationContext(dict)
            return
        }
        WCSession.default.sendMessage(dict, replyHandler: nil) { error in
            print("[ShineMapsWatch] Error enviando a iPhone: \(error.localizedDescription)")
        }
    }
}
