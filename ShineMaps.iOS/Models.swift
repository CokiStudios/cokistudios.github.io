import Foundation
import CoreLocation

public struct CSIDUser: Codable, Identifiable {
    public let id: String
    public let email: String
    public let name: String

    public var initial: String {
        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return String(name.prefix(1)).uppercased()
        }
        return String(email.prefix(1)).uppercased()
    }
}

public struct SearchResult: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let address: String
    public let latitude: Double
    public let longitude: Double
    public let distanceMeters: Double?
    public let systemIconName: String
    public let isCategory: Bool
    public let categoryQuery: String?

    public init(
        title: String,
        address: String,
        latitude: Double,
        longitude: Double,
        distanceMeters: Double? = nil,
        systemIconName: String = "mappin.and.ellipse",
        isCategory: Bool = false,
        categoryQuery: String? = nil
    ) {
        self.title = title
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.distanceMeters = distanceMeters
        self.systemIconName = systemIconName
        self.isCategory = isCategory
        self.categoryQuery = categoryQuery
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var formattedDistance: String? {
        guard let d = distanceMeters else { return nil }
        if d < 1000 {
            return "\(Int(d)) m"
        } else {
            return String(format: "%.1f km", d / 1000.0)
        }
    }
}

public struct RouteStep: Identifiable {
    public let id = UUID()
    public let instruction: String
    public let distanceMeters: Double
    public let maneuverIconName: String

    public var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters)) m"
        } else {
            return String(format: "%.1f km", distanceMeters / 1000.0)
        }
    }
}

public struct RouteInfo {
    public let distanceMeters: Double
    public let durationSeconds: Double
    public let steps: [RouteStep]
    public let coordinates: [CLLocationCoordinate2D]

    public var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters)) m"
        } else {
            return String(format: "%.1f km", distanceMeters / 1000.0)
        }
    }

    public var formattedDuration: String {
        let mins = Int(durationSeconds / 60)
        if mins < 60 {
            return "\(mins) min"
        } else {
            let hours = mins / 60
            let rem = mins % 60
            return "\(hours) h \(rem) min"
        }
    }

    public var formattedEta: String {
        let arrival = Date().addingTimeInterval(durationSeconds)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: arrival)
    }
}

public struct SavedPlace: Codable, Identifiable {
    public let id: String
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let systemIconName: String
}
