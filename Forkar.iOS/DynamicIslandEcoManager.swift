import SwiftUI
internal import Combine

#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import WidgetKit

// MARK: - Attributes struct for Dynamic Island & Lock Screen Live Activity (iOS 16.1+)
@available(iOS 16.1, *)
public struct ForkarEcoActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var co2Saved: Double
        public var ecoPoints: Int
        public var statusMessage: String
        public var dailyGoalProgress: Double
        public var treesPreserved: Double
        
        public init(
            co2Saved: Double,
            ecoPoints: Int,
            statusMessage: String,
            dailyGoalProgress: Double = 0.65,
            treesPreserved: Double? = nil
        ) {
            self.co2Saved = co2Saved
            self.ecoPoints = ecoPoints
            self.statusMessage = statusMessage
            self.dailyGoalProgress = min(max(dailyGoalProgress, 0.05), 1.0)
            self.treesPreserved = treesPreserved ?? max(0.1, co2Saved / 21.77)
        }
    }
    
    public var userName: String
    
    public init(userName: String) {
        self.userName = userName
    }
}

// MARK: - Dynamic Island Eco Manager (Pure Liquid Glass - iOS 16.1+)
@available(iOS 16.1, *)
class DynamicIslandEcoManager: ObservableObject {
    static let shared = DynamicIslandEcoManager()
    
    @Published var isLiveActivityActive: Bool = false
    private var currentActivity: Activity<ForkarEcoActivityAttributes>? = nil
    
    init() {
        checkActiveActivities()
    }
    
    private func checkActiveActivities() {
        if let existing = Activity<ForkarEcoActivityAttributes>.activities.first(where: { $0.activityState == .active }) {
            self.currentActivity = existing
            self.isLiveActivityActive = true
        } else {
            self.isLiveActivityActive = false
        }
    }
    
    func startEcoLiveActivity(co2: Double, pts: Int, userName: String = "Usuario") {
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
            statusMessage: "Monitoreo Eco en Tiempo Real",
            dailyGoalProgress: min(1.0, max(0.15, co2 / 20.0))
        )
        
        do {
            let staleDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())
            let content = ActivityContent(state: state, staleDate: staleDate)
            currentActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            
            DispatchQueue.main.async {
                self.isLiveActivityActive = true
            }
        } catch {
            let errStr = String(describing: error)
            if !errStr.contains("unsupportedTarget") && !errStr.contains("visibility") && !errStr.contains("denied") {
                print("Error al iniciar Live Activity / Dynamic Island: \(error)")
            }
        }
    }
    
    func updateEcoLiveActivity(co2: Double, pts: Int, message: String = "Impacto Eco Actualizado") {
        if currentActivity == nil || currentActivity?.activityState != .active {
            currentActivity = Activity<ForkarEcoActivityAttributes>.activities.first(where: { $0.activityState == .active })
        }
        
        guard let activity = currentActivity else { return }
        
        Task {
            let updatedState = ForkarEcoActivityAttributes.ContentState(
                co2Saved: co2,
                ecoPoints: pts,
                statusMessage: message,
                dailyGoalProgress: min(1.0, max(0.15, co2 / 20.0))
            )
            let staleDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())
            let content = ActivityContent(state: updatedState, staleDate: staleDate)
            await activity.update(content)
            
            await MainActor.run {
                self.isLiveActivityActive = true
            }
        }
    }
    
    func stopEcoLiveActivity(finalCo2: Double, finalPts: Int) {
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
                statusMessage: "Resumen Eco Guardado",
                dailyGoalProgress: 1.0
            )
            let content = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(content, dismissalPolicy: .immediate)
            
            await MainActor.run {
                self.currentActivity = nil
                self.isLiveActivityActive = false
            }
        }
    }
    
    func toggleEcoLiveActivity(co2: Double, pts: Int, userName: String = "Usuario") {
        if isLiveActivityActive {
            stopEcoLiveActivity(finalCo2: co2, finalPts: pts)
        } else {
            startEcoLiveActivity(co2: co2, pts: pts, userName: userName)
        }
    }
}
#else
// MARK: - macOS Fallback
class DynamicIslandEcoManager: ObservableObject {
    static let shared = DynamicIslandEcoManager()
    @Published var isLiveActivityActive: Bool = false
    
    func startEcoLiveActivity(co2: Double, pts: Int, userName: String = "Usuario") {}
    func updateEcoLiveActivity(co2: Double, pts: Int, message: String = "Impacto Eco Actualizado") {}
    func stopEcoLiveActivity(finalCo2: Double, finalPts: Int) {}
    func toggleEcoLiveActivity(co2: Double, pts: Int, userName: String = "Usuario") {}
}
#endif
