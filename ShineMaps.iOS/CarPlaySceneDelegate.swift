import Foundation
import CarPlay
import CoreLocation
import MapKit

public class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPMapTemplateDelegate {
    public var interfaceController: CPInterfaceController?
    public var mapTemplate: CPMapTemplate?
    private var navigationSession: CPNavigationSession?

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        let mapTemp = CPMapTemplate()
        mapTemp.mapDelegate = self
        self.mapTemplate = mapTemp

        // Leading Bar Buttons (Home & Work shortcuts)
        let homeButton = CPBarButton(title: "Casa") { [weak self] _ in
            self?.routeToSavedPlace(named: "Casa")
        }
        let workButton = CPBarButton(title: "Estudio") { [weak self] _ in
            self?.routeToSavedPlace(named: "Estudio")
        }
        mapTemp.leadingNavigationBarButtons = [homeButton, workButton]

        // Trailing Bar Button (HUD Mirror & CS ID state)
        let csidTitle = CSIDManager.shared.isLoggedIn ? (CSIDManager.shared.currentUser?.initial ?? "CS") : "CS"
        let csidButton = CPBarButton(title: csidTitle) { [weak self] _ in
            self?.showCarPlayCSIDAlert()
        }
        mapTemp.trailingNavigationBarButtons = [csidButton]

        interfaceController.setRootTemplate(mapTemp, animated: true, completion: nil)
    }

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        self.mapTemplate = nil
        self.navigationSession = nil
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
            if let route = await LocationAndMapService.shared.calculateRoute(to: target) {
                await MainActor.run {
                    self.startCarPlayNavigation(with: route, destinationName: named)
                }
            }
        }
    }

    public func startCarPlayNavigation(with route: RouteInfo, destinationName: String) {
        guard let mapTemp = self.mapTemplate else { return }

        let cpTrip = CPTrip(
            origin: MKMapItem.forCurrentLocation(),
            destination: MKMapItem(placemark: MKPlacemark(coordinate: route.coordinates.last ?? CLLocationCoordinate2D())),
            routeChoices: [CPRouteChoice(summaryVariants: [route.formattedDistance, route.formattedDuration], additionalInformationVariants: [destinationName], selectionSummaryVariants: ["Ruta directa"])]
        )

        let session = mapTemp.startNavigationSession(for: cpTrip)
        self.navigationSession = session

        // Display first maneuver
        if let firstStep = route.steps.first {
            let maneuver = CPManeuver()
            maneuver.instructionVariants = [firstStep.instruction]
            session.upcomingManeuvers = [maneuver]
        }
    }

    private func showCarPlayCSIDAlert() {
        let isAuth = CSIDManager.shared.isLoggedIn
        let userName = CSIDManager.shared.currentUser?.name ?? "No autenticado"
        let message = isAuth ? "Sesión activa: \(userName)" : "Inicia sesión con tu CS ID en tu iPhone"

        let alert = CPAlertTemplate(
            titleVariants: ["Shine Maps — CS ID"],
            actions: [
                CPAlertAction(title: "Entendido", style: .default, handler: { [weak self] _ in
                    self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
                })
            ]
        )
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }
}
