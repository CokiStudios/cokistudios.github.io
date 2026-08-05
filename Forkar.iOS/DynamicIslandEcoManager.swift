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
    
    #if os(iOS)
    private var currentActivity: Activity<ForkarEcoActivityAttributes>? = nil
    #endif
    
    func startEcoLiveActivity(co2: Double, pts: Int, userName: String = "Usuario") {
        #if os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = ForkarEcoActivityAttributes(userName: userName)
        let state = ForkarEcoActivityAttributes.ContentState(
            co2Saved: co2,
            ecoPoints: pts,
            statusMessage: "Monitoreo Eco en segundo plano (3 min)"
        )
        
        do {
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(180))
                currentActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } else {
                currentActivity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            }
            
            // Finalizar automáticamente después de 3 minutos (180s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 180) {
                self.stopEcoLiveActivity(finalCo2: co2, finalPts: pts)
            }
        } catch {
            let errStr = String(describing: error)
            if !errStr.contains("unsupportedTarget") && !errStr.contains("visibility") && !errStr.contains("denied") {
                print("Error al iniciar Live Activity / Dynamic Island: \(error)")
            }
        }
        #endif
    }
    
    func updateEcoLiveActivity(co2: Double, pts: Int) {
        #if os(iOS)
        Task {
            let updatedState = ForkarEcoActivityAttributes.ContentState(
                co2Saved: co2,
                ecoPoints: pts,
                statusMessage: "Impacto Eco Actualizado"
            )
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: updatedState, staleDate: Date().addingTimeInterval(180))
                await currentActivity?.update(content)
            } else {
                await currentActivity?.update(using: updatedState)
            }
        }
        #endif
    }
    
    func stopEcoLiveActivity(finalCo2: Double, finalPts: Int) {
        #if os(iOS)
        Task {
            let finalState = ForkarEcoActivityAttributes.ContentState(
                co2Saved: finalCo2,
                ecoPoints: finalPts,
                statusMessage: "Resumen Guardado"
            )
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: finalState, staleDate: nil)
                await currentActivity?.end(content, dismissalPolicy: .immediate)
            } else {
                await currentActivity?.end(using: finalState, dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}
