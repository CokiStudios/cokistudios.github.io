import Foundation
import CoreLocation
import SwiftUI

// MARK: - CS ID User
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

// MARK: - Search Source
public enum SearchSource: String, Codable {
    case appleMaps = "Apple Maps"
    case mapbox = "Mapbox"
    case saved = "Guardado"
}

// MARK: - Apple Maps POI Category
public enum ApplePlaceCategory: String, CaseIterable, Identifiable {
    case gasStation = "Gasolineras"
    case restaurant = "Restaurantes"
    case cafe = "Cafeterías"
    case parking = "Parqueaderos"
    case pharmacy = "Farmacias"
    case store = "Supermercados"
    case evCharger = "Carga EV"
    case bank = "Bancos"
    case hotel = "Hoteles"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .gasStation: return "fuelpump.fill"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .parking: return "parkingsign.circle.fill"
        case .pharmacy: return "cross.case.fill"
        case .store: return "cart.fill"
        case .evCharger: return "bolt.car.fill"
        case .bank: return "banknote.fill"
        case .hotel: return "bed.double.fill"
        }
    }

    public var queryTerm: String {
        switch self {
        case .gasStation: return "gasolinera"
        case .restaurant: return "restaurante"
        case .cafe: return "cafeteria"
        case .parking: return "parqueadero"
        case .pharmacy: return "farmacia"
        case .store: return "supermercado"
        case .evCharger: return "cargador electrico"
        case .bank: return "banco cajero"
        case .hotel: return "hotel"
        }
    }
}

// MARK: - Search Result (Hybrid Apple Maps + Mapbox)
public struct SearchResult: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let address: String
    public let latitude: Double
    public let longitude: Double
    public let distanceMeters: Double?
    public let systemIconName: String
    public let isCategory: Bool
    public let categoryQuery: String?
    public let phoneNumber: String?
    public let url: URL?
    public let poiCategoryName: String?
    public let source: SearchSource

    public init(
        id: UUID = UUID(),
        title: String,
        address: String,
        latitude: Double,
        longitude: Double,
        distanceMeters: Double? = nil,
        systemIconName: String = "mappin.and.ellipse",
        isCategory: Bool = false,
        categoryQuery: String? = nil,
        phoneNumber: String? = nil,
        url: URL? = nil,
        poiCategoryName: String? = nil,
        source: SearchSource = .appleMaps
    ) {
        self.id = id
        self.title = title
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.distanceMeters = distanceMeters
        self.systemIconName = systemIconName
        self.isCategory = isCategory
        self.categoryQuery = categoryQuery
        self.phoneNumber = phoneNumber
        self.url = url
        self.poiCategoryName = poiCategoryName
        self.source = source
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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id || (lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude && lhs.title == rhs.title)
    }
}

// MARK: - Traffic Congestion Level (Mapbox GL)
public enum TrafficCongestionLevel: String, Codable {
    case unknown = "unknown"
    case low = "low"
    case moderate = "moderate"
    case heavy = "heavy"
    case severe = "severe"

    public var label: String {
        switch self {
        case .unknown, .low: return "Tráfico Fluido"
        case .moderate: return "Tráfico Moderado"
        case .heavy: return "Tráfico Pesado"
        case .severe: return "Congestión Severa"
        }
    }

    public var color: Color {
        switch self {
        case .unknown, .low: return Color(red: 56/255, green: 189/255, blue: 248/255) // Cyan
        case .moderate: return Color(red: 245/255, green: 158/255, blue: 11/255) // Amber
        case .heavy: return Color(red: 244/255, green: 63/255, blue: 94/255) // Rose/Red
        case .severe: return Color(red: 185/255, green: 28/255, blue: 28/255) // Deep Crimson
        }
    }

    public var uiColor: UIColor {
        switch self {
        case .unknown, .low: return UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 0.95)
        case .moderate: return UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 0.95)
        case .heavy: return UIColor(red: 244/255, green: 63/255, blue: 94/255, alpha: 0.95)
        case .severe: return UIColor(red: 185/255, green: 28/255, blue: 28/255, alpha: 0.95)
        }
    }
}

// MARK: - Traffic Segment for GL Polyline
public struct TrafficSegment: Identifiable {
    public let id = UUID()
    public let startCoordinate: CLLocationCoordinate2D
    public let endCoordinate: CLLocationCoordinate2D
    public let congestion: TrafficCongestionLevel

    public init(
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D,
        congestion: TrafficCongestionLevel
    ) {
        self.startCoordinate = start
        self.endCoordinate = end
        self.congestion = congestion
    }
}

// MARK: - Route Profile
public enum RouteProfile: String, CaseIterable, Identifiable {
    case drivingTraffic = "mapbox/driving-traffic"
    case driving = "mapbox/driving"
    case cycling = "mapbox/cycling"
    case walking = "mapbox/walking"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .drivingTraffic: return "Conducción (Tráfico)"
        case .driving: return "Ruta Directa"
        case .cycling: return "Bicicleta"
        case .walking: return "Peatonal"
        }
    }

    public var icon: String {
        switch self {
        case .drivingTraffic: return "car.side.fill"
        case .driving: return "car.fill"
        case .cycling: return "bicycle"
        case .walking: return "figure.walk"
        }
    }
}

// MARK: - Route Step (Mapbox Turn-by-Turn GL)
public struct RouteStep: Identifiable {
    public let id: UUID
    public let instruction: String
    public let secondaryInstruction: String?
    public let distanceMeters: Double
    public let durationSeconds: Double
    public let maneuverIconName: String
    public let maneuverType: String
    public let maneuverModifier: String
    public let coordinate: CLLocationCoordinate2D?
    public let voiceInstruction: String?

    public init(
        id: UUID = UUID(),
        instruction: String,
        secondaryInstruction: String? = nil,
        distanceMeters: Double,
        durationSeconds: Double = 0.0,
        maneuverIconName: String = "arrow.up",
        maneuverType: String = "continue",
        maneuverModifier: String = "straight",
        coordinate: CLLocationCoordinate2D? = nil,
        voiceInstruction: String? = nil
    ) {
        self.id = id
        self.instruction = instruction
        self.secondaryInstruction = secondaryInstruction
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.maneuverIconName = maneuverIconName
        self.maneuverType = maneuverType
        self.maneuverModifier = maneuverModifier
        self.coordinate = coordinate
        self.voiceInstruction = voiceInstruction
    }

    public var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters)) m"
        } else {
            return String(format: "%.1f km", distanceMeters / 1000.0)
        }
    }
}

// MARK: - Route Info (Mapbox Directions GL Output)
public struct RouteInfo {
    public let distanceMeters: Double
    public let durationSeconds: Double
    public let steps: [RouteStep]
    public let coordinates: [CLLocationCoordinate2D]
    public let trafficSegments: [TrafficSegment]
    public let profile: RouteProfile
    public let primaryRoadName: String
    public let overallCongestion: TrafficCongestionLevel

    public init(
        distanceMeters: Double,
        durationSeconds: Double,
        steps: [RouteStep],
        coordinates: [CLLocationCoordinate2D],
        trafficSegments: [TrafficSegment] = [],
        profile: RouteProfile = .drivingTraffic,
        primaryRoadName: String = "Ruta sugerida",
        overallCongestion: TrafficCongestionLevel = .low
    ) {
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.steps = steps
        self.coordinates = coordinates
        self.trafficSegments = trafficSegments
        self.profile = profile
        self.primaryRoadName = primaryRoadName
        self.overallCongestion = overallCongestion
    }

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
            return "\(max(1, mins)) min"
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

// MARK: - Saved Place
public struct SavedPlace: Codable, Identifiable {
    public let id: String
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let systemIconName: String

    public init(id: String, name: String, latitude: Double, longitude: Double, systemIconName: String) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.systemIconName = systemIconName
    }
}
