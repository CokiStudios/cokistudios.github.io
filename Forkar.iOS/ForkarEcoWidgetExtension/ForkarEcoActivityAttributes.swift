import Foundation
#if canImport(ActivityKit)
import ActivityKit

// MARK: - Attributes struct for Dynamic Island & Lock Screen Live Activity
@available(iOS 16.1, macOS 14.0, *)
public struct ForkarEcoActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var co2Saved: Double
        public var ecoPoints: Int
        public var statusMessage: String
        public var dailyGoalProgress: Double
        public var treesPreserved: Double
        public var lastUpdated: Date
        
        public init(
            co2Saved: Double,
            ecoPoints: Int,
            statusMessage: String,
            dailyGoalProgress: Double = 0.65,
            treesPreserved: Double? = nil,
            lastUpdated: Date = Date()
        ) {
            self.co2Saved = co2Saved
            self.ecoPoints = ecoPoints
            self.statusMessage = statusMessage
            self.dailyGoalProgress = min(max(dailyGoalProgress, 0.05), 1.0)
            self.treesPreserved = treesPreserved ?? max(0.1, co2Saved / 21.77)
            self.lastUpdated = lastUpdated
        }
    }
    
    public var userName: String
    
    public init(userName: String) {
        self.userName = userName
    }
}
#endif
