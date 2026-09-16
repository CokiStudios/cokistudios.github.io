import SwiftUI
import ActivityKit
import WidgetKit
internal import Combine

// Attributes struct for Dynamic Island & Lock Screen Live Activity
public struct ForkarEcoActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var co2Saved: Double
        public var ecoPoints: Int
        public var statusMessage: String
        
        public init(co2Saved: Double, ecoPoints: Int, statusMessage: String) {
            self.co2Saved = co2Saved
            self.ecoPoints = ecoPoints
            self.statusMessage = statusMessage
        }
    }
    
    public var userName: String
    
    public init(userName: String) {
        self.userName = userName
    }
}

class DynamicIslandEcoManager: ObservableObject {
    static let shared = DynamicIslandEcoManager()
    
    @Published var isLiveActivityActive: Bool = false
    
    #if os(iOS)
    private var currentActivity: Activity<ForkarEcoActivityAttributes>? = nil
    #endif
    
    init() {
        #if os(iOS)
        checkActiveActivities()
        #endif
    }
    
    private func checkActiveActivities() {
        #if os(iOS)
        if let existing = Activity<ForkarEcoActivityAttributes>.activities.first(where: { $0.activityState == .active }) {
            self.currentActivity = existing
            self.isLiveActivityActive = true
        } else {
            self.isLiveActivityActive = false
        }
        #endif
    }
    
    func startEcoLiveActivity(co2: Double, pts: Int, userName: String = "Usuario") {
        #if os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // Si ya existe una Live Activity activa, solo la actualizamos
        if let existing = Activity<ForkarEcoActivityAttributes>.activities.first(where: { $0.activityState == .active }) {
            self.currentActivity = existing
            DispatchQueue.main.async { self.isLiveActivityActive = true }
            updateEcoLiveActivity(co2: co2, pts: pts)
            return
        }
        
        let attributes = ForkarEcoActivityAttributes(userName: userName)
        let state = ForkarEcoActivityAttributes.ContentState(
            co2Saved: co2,
            ecoPoints: pts,
            statusMessage: "Monitoreo Eco en Tiempo Real"
        )
        
        do {
            let staleDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: state, staleDate: staleDate)
                currentActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } else {
                currentActivity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            }
            
            DispatchQueue.main.async {
                self.isLiveActivityActive = true
            }
        } catch {
            let errStr = String(describing: error)
            if !errStr.contains("unsupportedTarget") && !errStr.contains("visibility") && !errStr.contains("denied") {
                print("Error al iniciar Live Activity / Dynamic Island: \(error)")
            }
        }
        #endif
    }
    
    func updateEcoLiveActivity(co2: Double, pts: Int, message: String = "Impacto Eco Actualizado") {
        #if os(iOS)
        if currentActivity == nil || currentActivity?.activityState != .active {
            currentActivity = Activity<ForkarEcoActivityAttributes>.activities.first(where: { $0.activityState == .active })
        }
        
        guard let activity = currentActivity else { return }
        
        Task {
            let updatedState = ForkarEcoActivityAttributes.ContentState(
                co2Saved: co2,
                ecoPoints: pts,
                statusMessage: message
            )
            let staleDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: updatedState, staleDate: staleDate)
                await activity.update(content)
            } else {
                await activity.update(using: updatedState)
            }
            
            await MainActor.run {
                self.isLiveActivityActive = true
            }
        }
        #endif
    }
    
    func stopEcoLiveActivity(finalCo2: Double, finalPts: Int) {
        #if os(iOS)
        if currentActivity == nil || currentActivity?.activityState != .active {
            currentActivity = Activity<ForkarEcoActivityAttributes>.activities.first(where: { $0.activityState == .active })
        }
        
        guard let activity = currentActivity else {
            DispatchQueue.main.async { self.isLiveActivityActive = false }
            return
        }
        
        Task {
            let finalState = ForkarEcoActivityAttributes.ContentState(
                co2Saved: finalCo2,
                ecoPoints: finalPts,
                statusMessage: "Resumen Eco Guardado"
            )
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            } else {
                await activity.end(using: finalState, dismissalPolicy: .immediate)
            }
            
            await MainActor.run {
                self.currentActivity = nil
                self.isLiveActivityActive = false
            }
        }
        #endif
    }
    
    func toggleEcoLiveActivity(co2: Double, pts: Int, userName: String = "Usuario") {
        if isLiveActivityActive {
            stopEcoLiveActivity(finalCo2: co2, finalPts: pts)
        } else {
            startEcoLiveActivity(co2: co2, pts: pts, userName: userName)
        }
    }
}
