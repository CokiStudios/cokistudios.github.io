import Foundation
import CoreLocation
import MapKit
internal import Combine

public class LocationAndMapService: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationAndMapService()

    private let locationManager = CLLocationManager()
    private var mapboxToken: String {
        let b64 = "cGsuZXlKMUlqb2lhbVZ5YVhoa1pYWmxiRzl3YVc1bmFTSXNJbUVpT2lKamJXaGlaSFUwWW5neE5qRjJNbXR3ZFhBeGFXdHlkalI1SW4wLjBYeDcyNEVwbjN4M25KOGhBWUMxZEE="
        if let data = Data(base64Encoded: b64), let token = String(data: data, encoding: .utf8) {
            return token
        }
        return ""
    }

    @Published public var currentLocation: CLLocation? = nil
    @Published public var currentSpeedKmh: Double = 0.0
    @Published public var currentHeading: Double = 0.0
    @Published public var searchResults: [SearchResult] = []
    @Published public var isSearching: Bool = false
    @Published public var currentRoute: RouteInfo? = nil
    @Published public var activeManeuverIndex: Int = 0

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2 // meters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        self.currentLocation = latest

        let speed = latest.speed // m/s
        if speed > 0 {
            self.currentSpeedKmh = speed * 3.6
        } else {
            self.currentSpeedKmh = 0.0
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            self.currentHeading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }

    // MARK: - Category Suggestions by Location
    public func getCategorySuggestions() -> [SearchResult] {
        let userCoord = currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721)

        return [
            SearchResult(
                title: "Gasolineras cercanas",
                address: "Estaciones de combustible y recarga próximas",
                latitude: userCoord.latitude,
                longitude: userCoord.longitude,
                systemIconName: "fuelpump.fill",
                isCategory: true,
                categoryQuery: "gasolinera"
            ),
            SearchResult(
                title: "Restaurantes y comida",
                address: "Comida rápida, cafeterías y gastronomía",
                latitude: userCoord.latitude,
                longitude: userCoord.longitude,
                systemIconName: "fork.knife",
                isCategory: true,
                categoryQuery: "restaurante"
            ),
            SearchResult(
                title: "Parqueaderos",
                address: "Estacionamientos y parqueaderos seguros",
                latitude: userCoord.latitude,
                longitude: userCoord.longitude,
                systemIconName: "parkingsign.circle.fill",
                isCategory: true,
                categoryQuery: "parqueadero"
            ),
            SearchResult(
                title: "Farmacias y droguerías",
                address: "Salud, medicamentos de turno y primeros auxilios",
                latitude: userCoord.latitude,
                longitude: userCoord.longitude,
                systemIconName: "cross.case.fill",
                isCategory: true,
                categoryQuery: "farmacia"
            ),
            SearchResult(
                title: "Cafeterías y panaderías",
                address: "Café de especialidad, bebidas y pastelería",
                latitude: userCoord.latitude,
                longitude: userCoord.longitude,
                systemIconName: "cup.and.saucer.fill",
                isCategory: true,
                categoryQuery: "cafeteria"
            ),
            SearchResult(
                title: "Supermercados y tiendas",
                address: "Mercados, abarrotes y compras rápidas",
                latitude: userCoord.latitude,
                longitude: userCoord.longitude,
                systemIconName: "cart.fill",
                isCategory: true,
                categoryQuery: "supermercado"
            )
        ]
    }

    // MARK: - Mapbox Proximity Geocoding
    public func searchPlaces(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await MainActor.run {
                self.searchResults = getCategorySuggestions()
                self.isSearching = false
            }
            return
        }

        await MainActor.run { self.isSearching = true }

        let userLat = currentLocation?.coordinate.latitude ?? 4.7110
        let userLng = currentLocation?.coordinate.longitude ?? -74.0721
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.mapbox.com/geocoding/v5/mapbox.places/\(encoded).json?access_token=\(mapboxToken)&proximity=\(userLng),\(userLat)&language=es,en&limit=8") else {
            await MainActor.run { self.isSearching = false }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let features = json["features"] as? [[String: Any]] else {
                await MainActor.run { self.isSearching = false }
                return
            }

            var results: [SearchResult] = []
            let userLoc = currentLocation ?? CLLocation(latitude: userLat, longitude: userLng)

            for f in features {
                let title = (f["text"] as? String) ?? "Lugar"
                let placeName = (f["place_name"] as? String) ?? title
                guard let center = f["center"] as? [Double], center.count == 2 else { continue }
                let lon = center[0]
                let lat = center[1]

                let targetLoc = CLLocation(latitude: lat, longitude: lon)
                let distMeters = userLoc.distance(from: targetLoc)

                let lower = (title + " " + placeName).lowercased()
                let icon: String = {
                    if lower.contains("gasolin") || lower.contains("combustible") || lower.contains("petro") || lower.contains("terpel") || lower.contains("primax") || lower.contains("esso") || lower.contains("mobil") || lower.contains("texaco") {
                        return "fuelpump.fill"
                    } else if lower.contains("restauran") || lower.contains("pizza") || lower.contains("burger") || lower.contains("comida") || lower.contains("asador") || lower.contains("grill") {
                        return "fork.knife"
                    } else if lower.contains("parquea") || lower.contains("parking") || lower.contains("estaciona") {
                        return "parkingsign.circle.fill"
                    } else if lower.contains("farma") || lower.contains("droguer") || lower.contains("salud") || lower.contains("medic") || lower.contains("cruz") || lower.contains("rebaja") {
                        return "cross.case.fill"
                    } else if lower.contains("cafe") || lower.contains("coffee") || lower.contains("panader") {
                        return "cup.and.saucer.fill"
                    } else if lower.contains("supermer") || lower.contains("tienda") || lower.contains("exito") || lower.contains("jumbo") || lower.contains("d1") || lower.contains("ara") || lower.contains("carulla") || lower.contains("market") {
                        return "cart.fill"
                    } else if lower.contains("aeropuerto") || lower.contains("airport") {
                        return "airplane"
                    }
                    return "mappin.and.ellipse"
                }()

                results.append(
                    SearchResult(
                        title: title,
                        address: placeName,
                        latitude: lat,
                        longitude: lon,
                        distanceMeters: distMeters,
                        systemIconName: icon
                    )
                )
            }

            results.sort { ($0.distanceMeters ?? .infinity) < ($1.distanceMeters ?? .infinity) }

            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        } catch {
            await MainActor.run { self.isSearching = false }
        }
    }

    // MARK: - Mapbox Directions Route Calculation
    public func calculateRoute(to destination: CLLocationCoordinate2D) async -> RouteInfo? {
        let startLat = currentLocation?.coordinate.latitude ?? 4.7110
        let startLng = currentLocation?.coordinate.longitude ?? -74.0721

        let urlString = "https://api.mapbox.com/directions/v5/mapbox/driving-traffic/\(startLng),\(startLat);\(destination.longitude),\(destination.latitude)?steps=true&geometries=geojson&overview=full&language=es&access_token=\(mapboxToken)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let routes = json["routes"] as? [[String: Any]],
                  let firstRoute = routes.first else {
                return nil
            }

            let totalDistance = (firstRoute["distance"] as? Double) ?? 0.0
            let totalDuration = (firstRoute["duration"] as? Double) ?? 0.0

            // Coordinates
            var routeCoords: [CLLocationCoordinate2D] = []
            if let geom = firstRoute["geometry"] as? [String: Any],
               let coordinates = geom["coordinates"] as? [[Double]] {
                for pair in coordinates {
                    if pair.count >= 2 {
                        routeCoords.append(CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
                    }
                }
            }

            // Steps
            var stepItems: [RouteStep] = []
            if let legs = firstRoute["legs"] as? [[String: Any]],
               let firstLeg = legs.first,
               let steps = firstLeg["steps"] as? [[String: Any]] {
                for s in steps {
                    let stepDist = (s["distance"] as? Double) ?? 0.0
                    var stepInstruction = "Continúa por la vía"
                    var maneuverIcon = "arrow.up"

                    if let maneuver = s["maneuver"] as? [String: Any] {
                        stepInstruction = (maneuver["instruction"] as? String) ?? stepInstruction
                        let mod = (maneuver["modifier"] as? String) ?? ""
                        let type = (maneuver["type"] as? String) ?? ""

                        if mod.contains("right") || type.contains("right") {
                            maneuverIcon = "arrow.turn.up.right"
                        } else if mod.contains("left") || type.contains("left") {
                            maneuverIcon = "arrow.turn.up.left"
                        } else if type.contains("arrive") {
                            maneuverIcon = "flag.checkered"
                        } else if mod.contains("straight") {
                            maneuverIcon = "arrow.up"
                        }
                    }

                    stepItems.append(
                        RouteStep(
                            instruction: stepInstruction,
                            distanceMeters: stepDist,
                            maneuverIconName: maneuverIcon
                        )
                    )
                }
            }

            let routeInfo = RouteInfo(
                distanceMeters: totalDistance,
                durationSeconds: totalDuration,
                steps: stepItems,
                coordinates: routeCoords
            )

            await MainActor.run {
                self.currentRoute = routeInfo
                self.activeManeuverIndex = 0
            }

            return routeInfo
        } catch {
            return nil
        }
    }

    public func clearRoute() {
        self.currentRoute = nil
        self.activeManeuverIndex = 0
    }
}
