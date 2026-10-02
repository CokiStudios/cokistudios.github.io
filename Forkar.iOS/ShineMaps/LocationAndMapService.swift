import Foundation
import CoreLocation
import MapKit
import AVFoundation
internal import Combine

public class LocationAndMapService: NSObject, ObservableObject, CLLocationManagerDelegate, MKLocalSearchCompleterDelegate {
    public static let shared = LocationAndMapService()

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let searchCompleter = MKLocalSearchCompleter()
    private let speechSynthesizer = AVSpeechSynthesizer()

    private var mapboxToken: String {
        let b64 = "cGsuZXlKMUlqb2lhbVZ5YVhoa1pYWmxiRzl3YVc1bmFTSXNJbUVpT2lKamJXaGlaSFUwWW5neE5qRjJNbXR3ZFhBeGFXdHlkalI1SW4wLjBYeDcyNEVwbjN4M25KOGhBWUMxZEE="
        if let data = Data(base64Encoded: b64), let token = String(data: data, encoding: .utf8) {
            return token
        }
        return ""
    }

    // Published State
    @Published public var currentLocation: CLLocation? = nil
    @Published public var currentSpeedKmh: Double = 0.0
    @Published public var currentHeading: Double = 0.0
    @Published public var searchResults: [SearchResult] = []
    @Published public var completerSuggestions: [SearchResult] = []
    @Published public var isSearching: Bool = false
    @Published public var currentRoute: RouteInfo? = nil
    @Published public var activeManeuverIndex: Int = 0
    @Published public var selectedProfile: RouteProfile = .drivingTraffic
    @Published public var isVoiceMuted: Bool = false
    @Published public var currentResolvedAddress: String? = nil
    @Published public var recommendationsByCategory: [ApplePlaceCategory: [SearchResult]] = [:]

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2 // meters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
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

        // Update completer region
        searchCompleter.region = MKCoordinateRegion(
            center: latest.coordinate,
            latitudinalMeters: 30000,
            longitudinalMeters: 30000
        )
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            self.currentHeading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }

    // MARK: - MKLocalSearchCompleterDelegate (Apple Maps Live Suggestions)
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let userLoc = currentLocation
        let mapped: [SearchResult] = completer.results.prefix(6).map { comp in
            SearchResult(
                title: comp.title,
                address: comp.subtitle.isEmpty ? "Recomendación Apple Maps" : comp.subtitle,
                latitude: userLoc?.coordinate.latitude ?? 4.7110,
                longitude: userLoc?.coordinate.longitude ?? -74.0721,
                systemIconName: "magnifyingglass.circle.fill",
                isCategory: false,
                source: .appleMaps
            )
        }
        DispatchQueue.main.async {
            self.completerSuggestions = mapped
        }
    }

    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Fallback silently if offline
    }

    public func updateSearchCompleterQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            completerSuggestions = []
            searchCompleter.queryFragment = ""
        } else {
            searchCompleter.queryFragment = trimmed
        }
    }

    // MARK: - Apple Maps: Category Suggestions & Recommendations
    public func getCategorySuggestions() -> [SearchResult] {
        let userCoord = currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721)

        return ApplePlaceCategory.allCases.map { cat in
            SearchResult(
                title: cat.rawValue,
                address: "Explorar \(cat.rawValue.lowercased()) recomendadas cerca de ti",
                latitude: userCoord.latitude,
                longitude: userCoord.longitude,
                systemIconName: cat.icon,
                isCategory: true,
                categoryQuery: cat.queryTerm,
                poiCategoryName: cat.rawValue,
                source: .appleMaps
            )
        }
    }

    public func fetchAppleRecommendations(category: ApplePlaceCategory) async -> [SearchResult] {
        let userCoord = currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category.queryTerm
        request.region = MKCoordinateRegion(
            center: userCoord,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            let userLoc = currentLocation ?? CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)

            let results: [SearchResult] = response.mapItems.map { item in
                let coord = item.placemark.coordinate
                let dist = userLoc.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
                return SearchResult(
                    title: item.name ?? category.rawValue,
                    address: item.placemark.title ?? "\(category.rawValue) recomendada",
                    latitude: coord.latitude,
                    longitude: coord.longitude,
                    distanceMeters: dist,
                    systemIconName: category.icon,
                    phoneNumber: item.phoneNumber,
                    url: item.url,
                    poiCategoryName: item.pointOfInterestCategory?.rawValue ?? category.rawValue,
                    source: .appleMaps
                )
            }

            let sorted = results.sorted { ($0.distanceMeters ?? .infinity) < ($1.distanceMeters ?? .infinity) }

            await MainActor.run {
                self.recommendationsByCategory[category] = sorted
            }
            return sorted
        } catch {
            return []
        }
    }

    // MARK: - Apple Maps: Reverse Geocoding Address Resolver
    public func reverseGeocodeAddress(coordinate: CLLocationCoordinate2D) async -> (name: String, fullAddress: String)? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let p = placemarks.first else { return nil }

            let primaryName = p.name ?? p.thoroughfare ?? "Ubicación fijada"
            var parts: [String] = []
            if let st = p.subThoroughfare { parts.append(st) }
            if let th = p.thoroughfare { parts.append(th) }
            if let loc = p.subLocality ?? p.locality { parts.append(loc) }
            if let city = p.administrativeArea { parts.append(city) }

            let full = parts.joined(separator: ", ")
            let finalAddress = full.isEmpty ? primaryName : full

            await MainActor.run {
                self.currentResolvedAddress = finalAddress
            }
            return (name: primaryName, fullAddress: finalAddress)
        } catch {
            return nil
        }
    }

    // MARK: - Hybrid Search Places (Apple Maps POI & Geocoding + Mapbox GL Proximity)
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
        let userLoc = currentLocation ?? CLLocation(latitude: userLat, longitude: userLng)

        // 1. First priority: Apple Maps Natural Language & POI Search
        var combinedResults: [SearchResult] = []
        let appleReq = MKLocalSearch.Request()
        appleReq.naturalLanguageQuery = trimmed
        appleReq.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: userLat, longitude: userLng),
            latitudinalMeters: 25000,
            longitudinalMeters: 25000
        )

        do {
            let appleSearch = MKLocalSearch(request: appleReq)
            let appleResponse = try await appleSearch.start()

            for item in appleResponse.mapItems {
                let coord = item.placemark.coordinate
                let dist = userLoc.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
                let icon = iconForCategory(name: item.name ?? "", poiCat: item.pointOfInterestCategory?.rawValue)

                combinedResults.append(
                    SearchResult(
                        title: item.name ?? "Lugar",
                        address: item.placemark.title ?? item.name ?? "Dirección Apple Maps",
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        distanceMeters: dist,
                        systemIconName: icon,
                        phoneNumber: item.phoneNumber,
                        url: item.url,
                        poiCategoryName: item.pointOfInterestCategory?.rawValue,
                        source: .appleMaps
                    )
                )
            }
        } catch {
            // Proceed to Mapbox geocoding if Apple Maps had no matches
        }

        // 2. Mapbox Places Proximity Geocoding for GL Routing Parity
        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://api.mapbox.com/geocoding/v5/mapbox.places/\(encoded).json?access_token=\(mapboxToken)&proximity=\(userLng),\(userLat)&language=es,en&limit=6") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let features = json["features"] as? [[String: Any]] {

                    for f in features {
                        let title = (f["text"] as? String) ?? "Lugar"
                        let placeName = (f["place_name"] as? String) ?? title
                        guard let center = f["center"] as? [Double], center.count == 2 else { continue }
                        let lon = center[0]
                        let lat = center[1]

                        // Avoid exact duplicates
                        let isDup = combinedResults.contains { res in
                            abs(res.latitude - lat) < 0.0005 && abs(res.longitude - lon) < 0.0005
                        }
                        if isDup { continue }

                        let dist = userLoc.distance(from: CLLocation(latitude: lat, longitude: lon))
                        let icon = iconForCategory(name: title + " " + placeName, poiCat: nil)

                        combinedResults.append(
                            SearchResult(
                                title: title,
                                address: placeName,
                                latitude: lat,
                                longitude: lon,
                                distanceMeters: dist,
                                systemIconName: icon,
                                source: .mapbox
                            )
                        )
                    }
                }
            } catch {
                // Keep Apple Maps results
            }
        }

        // Sort by distance
        combinedResults.sort { ($0.distanceMeters ?? .infinity) < ($1.distanceMeters ?? .infinity) }

        await MainActor.run {
            self.searchResults = combinedResults
            self.isSearching = false
        }
    }

    // MARK: - Mapbox Directions GL (Turn-by-Turn, Traffic Annotations & Congestion)
    public func calculateRoute(
        to destination: CLLocationCoordinate2D,
        profile: RouteProfile = .drivingTraffic
    ) async -> RouteInfo? {
        let startLat = currentLocation?.coordinate.latitude ?? 4.7110
        let startLng = currentLocation?.coordinate.longitude ?? -74.0721

        let urlString = "https://api.mapbox.com/directions/v5/\(profile.rawValue)/\(startLng),\(startLat);\(destination.longitude),\(destination.latitude)?steps=true&geometries=geojson&overview=full&annotations=congestion,distance,duration&banner_instructions=true&voice_instructions=true&language=es&access_token=\(mapboxToken)"
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

            // Geometry Coordinates
            var routeCoords: [CLLocationCoordinate2D] = []
            if let geom = firstRoute["geometry"] as? [String: Any],
               let coordinates = geom["coordinates"] as? [[Double]] {
                for pair in coordinates {
                    if pair.count >= 2 {
                        routeCoords.append(CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
                    }
                }
            }

            // Steps & Traffic Segments
            var stepItems: [RouteStep] = []
            var trafficSegments: [TrafficSegment] = []
            var primaryRoadName = "Ruta Mapbox GL"
            var congestionCounts: [TrafficCongestionLevel: Int] = [.low: 0, .moderate: 0, .heavy: 0, .severe: 0]

            if let legs = firstRoute["legs"] as? [[String: Any]],
               let firstLeg = legs.first {

                // Parse Congestion Annotations for Directions GL Color Coding
                if let annotation = firstLeg["annotation"] as? [String: Any],
                   let congestions = annotation["congestion"] as? [String] {
                    for i in 0..<min(congestions.count, max(0, routeCoords.count - 1)) {
                        let raw = congestions[i]
                        let level = TrafficCongestionLevel(rawValue: raw) ?? .low
                        congestionCounts[level, default: 0] += 1
                        trafficSegments.append(
                            TrafficSegment(
                                start: routeCoords[i],
                                end: routeCoords[i + 1],
                                congestion: level
                            )
                        )
                    }
                }

                // Parse Maneuvers & Banner Instructions
                if let steps = firstLeg["steps"] as? [[String: Any]] {
                    for s in steps {
                        let stepDist = (s["distance"] as? Double) ?? 0.0
                        let stepDur = (s["duration"] as? Double) ?? 0.0
                        var stepInstruction = "Continúa por la vía"
                        var secondaryText: String? = nil
                        var maneuverIcon = "arrow.up"
                        var maneuverType = "continue"
                        var maneuverMod = "straight"
                        var stepCoord: CLLocationCoordinate2D? = nil

                        if let name = s["name"] as? String, !name.isEmpty, primaryRoadName == "Ruta Mapbox GL" {
                            primaryRoadName = name
                        }

                        if let maneuver = s["maneuver"] as? [String: Any] {
                            stepInstruction = (maneuver["instruction"] as? String) ?? stepInstruction
                            maneuverMod = (maneuver["modifier"] as? String) ?? "straight"
                            maneuverType = (maneuver["type"] as? String) ?? "continue"

                            if let loc = maneuver["location"] as? [Double], loc.count >= 2 {
                                stepCoord = CLLocationCoordinate2D(latitude: loc[1], longitude: loc[0])
                            }

                            maneuverIcon = iconForManeuver(type: maneuverType, modifier: maneuverMod)
                        }

                        // Banner Instructions (Lanes & Secondary guidance)
                        if let banners = s["bannerInstructions"] as? [[String: Any]],
                           let firstBanner = banners.first,
                           let primary = firstBanner["primary"] as? [String: Any] {
                            if let text = primary["text"] as? String {
                                stepInstruction = text
                            }
                            if let secondary = firstBanner["secondary"] as? [String: Any],
                               let secText = secondary["text"] as? String {
                                secondaryText = secText
                            }
                        }

                        // Voice Instructions
                        var voiceText: String? = nil
                        if let voices = s["voiceInstructions"] as? [[String: Any]],
                           let firstVoice = voices.first {
                            voiceText = firstVoice["announcement"] as? String
                        }

                        stepItems.append(
                            RouteStep(
                                instruction: stepInstruction,
                                secondaryInstruction: secondaryText,
                                distanceMeters: stepDist,
                                durationSeconds: stepDur,
                                maneuverIconName: maneuverIcon,
                                maneuverType: maneuverType,
                                maneuverModifier: maneuverMod,
                                coordinate: stepCoord,
                                voiceInstruction: voiceText
                            )
                        )
                    }
                }
            }

            // Determine overall congestion level
            let totalSegs = max(1, trafficSegments.count)
            let heavyRatio = Double((congestionCounts[.heavy] ?? 0) + (congestionCounts[.severe] ?? 0)) / Double(totalSegs)
            let modRatio = Double(congestionCounts[.moderate] ?? 0) / Double(totalSegs)

            let overallLevel: TrafficCongestionLevel = {
                if heavyRatio > 0.25 { return .heavy }
                if modRatio > 0.25 { return .moderate }
                return .low
            }()

            let routeInfo = RouteInfo(
                distanceMeters: totalDistance,
                durationSeconds: totalDuration,
                steps: stepItems,
                coordinates: routeCoords,
                trafficSegments: trafficSegments,
                profile: profile,
                primaryRoadName: primaryRoadName,
                overallCongestion: overallLevel
            )

            await MainActor.run {
                self.currentRoute = routeInfo
                self.activeManeuverIndex = 0
                self.selectedProfile = profile

                // Spoken audio navigation announcement
                if !self.isVoiceMuted, let firstStep = stepItems.first {
                    self.speakManeuver(firstStep.voiceInstruction ?? firstStep.instruction)
                }
            }

            return routeInfo
        } catch {
            return nil
        }
    }

    // MARK: - Voice Navigation (AVSpeechSynthesizer)
    public func speakManeuver(_ text: String) {
        guard !text.isEmpty && !isVoiceMuted else { return }
        DispatchQueue.main.async {
            if self.speechSynthesizer.isSpeaking {
                self.speechSynthesizer.stopSpeaking(at: .immediate)
            }
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "es-MX") ?? AVSpeechSynthesisVoice(language: "es-ES")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.volume = 1.0
            self.speechSynthesizer.speak(utterance)
        }
    }

    public func toggleVoiceMute() {
        self.isVoiceMuted.toggle()
        if isVoiceMuted && speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    public func clearRoute() {
        self.currentRoute = nil
        self.activeManeuverIndex = 0
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - Helper Icon Mapping
    private func iconForCategory(name: String, poiCat: String?) -> String {
        let lower = (name + " " + (poiCat ?? "")).lowercased()
        if lower.contains("gasolin") || lower.contains("combustible") || lower.contains("petro") || lower.contains("terpel") || lower.contains("primax") || lower.contains("esso") || lower.contains("mobil") || lower.contains("texaco") {
            return "fuelpump.fill"
        } else if lower.contains("restauran") || lower.contains("pizza") || lower.contains("burger") || lower.contains("comida") || lower.contains("asador") || lower.contains("grill") {
            return "fork.knife"
        } else if lower.contains("parquea") || lower.contains("parking") || lower.contains("estaciona") {
            return "parkingsign.circle.fill"
        } else if lower.contains("farma") || lower.contains("droguer") || lower.contains("salud") || lower.contains("medic") || lower.contains("cruz") {
            return "cross.case.fill"
        } else if lower.contains("cafe") || lower.contains("coffee") || lower.contains("panader") {
            return "cup.and.saucer.fill"
        } else if lower.contains("supermer") || lower.contains("tienda") || lower.contains("exito") || lower.contains("jumbo") || lower.contains("d1") || lower.contains("carulla") || lower.contains("market") {
            return "cart.fill"
        } else if lower.contains("cargador") || lower.contains("ev") || lower.contains("electr") {
            return "bolt.car.fill"
        } else if lower.contains("hotel") || lower.contains("hospedaje") {
            return "bed.double.fill"
        } else if lower.contains("banco") || lower.contains("atm") || lower.contains("cajero") {
            return "banknote.fill"
        }
        return "mappin.and.ellipse"
    }

    private func iconForManeuver(type: String, modifier: String) -> String {
        let lowerType = type.lowercased()
        let lowerMod = modifier.lowercased()

        if lowerType.contains("arrive") {
            return "flag.checkered"
        } else if lowerType.contains("roundabout") || lowerType.contains("rotary") {
            return "arrow.triangle.roundabout"
        } else if lowerType.contains("fork") {
            return "arrow.triangle.branch"
        } else if lowerType.contains("merge") {
            return "arrow.triangle.merge"
        } else if lowerMod.contains("uturn") {
            return "arrow.uturn.left"
        } else if lowerMod.contains("sharp right") {
            return "arrow.turn.up.forward.right"
        } else if lowerMod.contains("sharp left") {
            return "arrow.turn.up.forward.left"
        } else if lowerMod.contains("right") {
            return "arrow.turn.up.right"
        } else if lowerMod.contains("left") {
            return "arrow.turn.up.left"
        }
        return "arrow.up"
    }
}
