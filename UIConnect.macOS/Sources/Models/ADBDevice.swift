import Foundation

// MARK: - ADB Device Model
public struct ADBDevice: Identifiable, Hashable, Sendable {
    public var id: String { serial }
    public let serial: String
    public let state: String
    public let model: String
    public let product: String
    public let isWiFi: Bool
    public var batteryLevel: String
    public var isShineDevice: Bool

    public init(
        serial: String,
        state: String,
        model: String = "Unknown",
        product: String = "Unknown",
        batteryLevel: String = "N/A"
    ) {
        self.serial = serial
        self.state = state
        self.model = model
        self.product = product
        self.batteryLevel = batteryLevel
        self.isWiFi = serial.contains(":")
        
        let lower = (model + " " + product).lowercased()
        self.isShineDevice = lower.contains("shine") || lower.contains("x1") || lower.contains("xa1") || lower.contains("f1") || lower.contains("i1") || lower.contains("nomad")
    }

    public var displayName: String {
        if isShineDevice {
            return "Shine \(model.replacingOccurrences(of: "Shine_", with: "").replacingOccurrences(of: "shine_", with: "").uppercased())"
        }
        return model.isEmpty || model == "Unknown" ? serial : model
    }
}
