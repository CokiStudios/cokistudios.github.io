import Foundation
import CarPlay
import CoreLocation
import MapKit

public class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPMapTemplateDelegate {
    public var interfaceController: CPInterfaceController?
    public var mapTemplate: CPMapTemplate?
    private var navigationSession: CPNavigationSession?
    private var activeTrip: CPTrip?

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        let mapTemp = CPMapTemplate()
        mapTemp.mapDelegate = self
        self.mapTemplate = mapTemp

        setupNavigationBar(on: mapTemp)
        interfaceController.setRootTemplate(mapTemp, animated: true, completion: nil)
    }

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        self.mapTemplate = nil
        self.navigationSession = nil
        self.activeTrip = nil
    }

    // MARK: - Navigation Bar Setup
    private func setupNavigationBar(on mapTemp: CPMapTemplate) {
        // Recommendations via Apple Maps POI
        let recsButton = CPBarButton(title: "Lugares") { [weak self] _ in
            self?.presentAppleRecommendationsList()
        }

        let homeButton = CPBarButton(title: "Casa") { [weak self] _ in
            self?.routeToSavedPlace(named: "Casa")
        }

        let workButton = CPBarButton(title: "Estudio") { [weak self] _ in
            self?.routeToSavedPlace(named: "Estudio")
        }

        mapTemp.leadingNavigationBarButtons = [recsButton, homeButton, workButton]

        // CS ID status & Voice Mute toggle
        let csidTitle = CSIDManager.shared.isLoggedIn ? (CSIDManager.shared.currentUser?.initial ?? "CS") : "CS"
        let csidButton = CPBarButton(title: csidTitle) { [weak self] _ in
            self?.showCarPlayCSIDAlert()
        }

        mapTemp.trailingNavigationBarButtons = [csidButton]
    }

    // MARK: - Apple Maps Recommendations List Template on CarPlay
    private func presentAppleRecommendationsList() {
        let categories: [ApplePlaceCategory] = [.gasStation, .restaurant, .cafe, .parking, .pharmacy]

        var sections: [CPListSection] = []

        let groupItems: [CPListItem] = categories.map { cat in
            let item = CPListItem(
                text: cat.rawValue,
                detailText: "Explorar \(cat.rawValue.lowercased()) cercanas con Apple Maps",
                image: UIImage(systemName: cat.icon)
            )
            item.handler = { [weak self] _, completion in
                self?.loadCategoryPlaces(category: cat)
                completion()
            }
            return item
        }

        sections.append(CPListSection(items: groupItems, header: "Recomendaciones Apple Maps", sectionIndexTitle: nil))

        let listTemplate = CPListTemplate(title: "Lugares Cercanos", sections: sections)
        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }

    private func loadCategoryPlaces(category: ApplePlaceCategory) {
        Task {
            let places = await LocationAndMapService.shared.fetchAppleRecommendations(category: category)

            await MainActor.run {
                let items: [CPListItem] = places.prefix(8).map { place in
                    let detail = place.formattedDistance != nil ? "\(place.formattedDistance!) • \(place.address)" : place.address
                    let item = CPListItem(
                        text: place.title,
                        detailText: detail,
                        image: UIImage(systemName: category.icon)
                    )
                    item.handler = { [weak self] _, completion in
                        self?.interfaceController?.popToRootTemplate(animated: true, completion: nil)
                        self?.startRouteTo(place: place)
                        completion()
                    }
                    return item
                }

                let section = CPListSection(items: items, header: "\(category.rawValue) cercanas", sectionIndexTitle: nil)
                let detailList = CPListTemplate(title: category.rawValue, sections: [section])
                self.interfaceController?.pushTemplate(detailList, animated: true, completion: nil)
            }
        }
    }

    // MARK: - Mapbox Directions GL Navigation Session
    private func startRouteTo(place: SearchResult) {
        Task {
            if let route = await LocationAndMapService.shared.calculateRoute(to: place.coordinate, profile: .drivingTraffic) {
                await MainActor.run {
                    self.startCarPlayNavigation(with: route, destinationName: place.title)
                }
            }
        }
    }

    private func routeToSavedPlace(named: String) {
        let key = named == "Casa" ? "home" : "work"
        let lat = UserDefaults.standard.double(forKey: "\(key)_lat")
        let lng = UserDefaults.standard.double(forKey: "\(key)_lng")

        guard lat != 0 && lng != 0 else {
            let alert = CPAlertTemplate(
                titleVariants: ["\(named) no guardada"],
                actions: [CPAlertAction(title: "Aceptar", style: .default, handler: { _ in })]
            )
            interfaceController?.presentTemplate(alert, animated: true, completion: nil)
            return
        }

        let target = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        Task {
            if let route = await LocationAndMapService.shared.calculateRoute(to: target, profile: .drivingTraffic) {
                await MainActor.run {
                    self.startCarPlayNavigation(with: route, destinationName: named)
                }
            }
        }
    }

    public func startCarPlayNavigation(with route: RouteInfo, destinationName: String) {
        guard let mapTemp = self.mapTemplate else { return }

        let destCoord = route.coordinates.last ?? CLLocationCoordinate2D()
        let destPlacemark = MKPlacemark(coordinate: destCoord)
        let destinationItem = MKMapItem(placemark: destPlacemark)
        destinationItem.name = destinationName

        let originItem = MKMapItem.forCurrentLocation()

        let summary = "\(route.formattedDuration) • \(route.formattedDistance) • \(route.overallCongestion.label)"
        let cpTrip = CPTrip(
            origin: originItem,
            destination: destinationItem,
            routeChoices: [
                CPRouteChoice(
                    summaryVariants: [summary, "\(route.formattedDuration) • \(route.formattedDistance)"],
                    additionalInformationVariants: [route.primaryRoadName, "Mapbox Directions GL"],
                    selectionSummaryVariants: ["Ruta Mapbox GL"]
                )
            ]
        )
        self.activeTrip = cpTrip

        let session = mapTemp.startNavigationSession(for: cpTrip)
        self.navigationSession = session

        // Upcoming Maneuvers with SF Symbols
        var maneuvers: [CPManeuver] = []
        for step in route.steps.prefix(5) {
            let maneuver = CPManeuver()
            maneuver.instructionVariants = [step.instruction]
            if let sec = step.secondaryInstruction {
                maneuver.instructionVariants.append(sec)
            }
            maneuver.symbolImage = UIImage(systemName: step.maneuverIconName)
            maneuvers.append(maneuver)
        }
        session.upcomingManeuvers = maneuvers

        // Travel Estimates
        let measurementDist = Measurement(value: route.distanceMeters, unit: UnitLength.meters)
        let estimates = CPTravelEstimates(distanceRemaining: measurementDist, timeRemaining: route.durationSeconds)
        mapTemp.updateEstimates(estimates, for: cpTrip)

        // Navigation Bar when Active: End Navigation button
        let endButton = CPBarButton(title: "Terminar") { [weak self] _ in
            self?.stopCarPlayNavigation()
        }
        let voiceButton = CPBarButton(title: LocationAndMapService.shared.isVoiceMuted ? "Silencio" : "Voz") { _ in
            LocationAndMapService.shared.toggleVoiceMute()
        }
        mapTemp.trailingNavigationBarButtons = [voiceButton, endButton]
    }

    public func stopCarPlayNavigation() {
        navigationSession?.finishTrip()
        navigationSession = nil
        activeTrip = nil
        LocationAndMapService.shared.clearRoute()

        if let mapTemp = self.mapTemplate {
            setupNavigationBar(on: mapTemp)
        }
    }

    private func showCarPlayCSIDAlert() {
        let isAuth = CSIDManager.shared.isLoggedIn
        let userName = CSIDManager.shared.currentUser?.name ?? "No autenticado"
        let email = CSIDManager.shared.currentUser?.email ?? ""
        let msg = isAuth ? "Sesión activa: \(userName) (\(email))" : "Inicia sesión con tu CS ID en tu iPhone para sincronizar lugares."

        let alert = CPAlertTemplate(
            titleVariants: ["Shine Maps — CS ID", msg],
            actions: [
                CPAlertAction(title: "Entendido", style: .default, handler: { [weak self] _ in
                    self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
                })
            ]
        )
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }

    // MARK: - CPMapTemplateDelegate
    public func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {}
    public func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {}
}
