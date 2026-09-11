import SwiftUI
import MapKit
import CoreLocation

public struct ContentView: View {
    @StateObject private var locService = LocationAndMapService.shared
    @ObservedObject private var csidManager = CSIDManager.shared

    // Search state
    @State private var searchQuery = ""
    @State private var isSearchFocused = false
    @State private var showSuggestions = false
    @State private var searchDebounceTask: Task<Void, Never>? = nil

    // Sheets & Modes
    @State private var showCSIDSheet = false
    @State private var isHudMode = false
    @State private var isHudMirrored = false
    @State private var selectedMapType: MKMapType = .standard
    @State private var mapTypeIndex = 0 // 0: Dark/Standard, 1: Satellite, 2: Hybrid

    // Map & Camera
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedDestination: SearchResult? = nil
    @State private var activeDestinationName = ""

    // Save Location Alert
    @State private var showSaveAlert = false

    public init() {}

    public var body: some View {
        ZStack {
            // ── 1. NATIVE MAP LAYER ──
            NativeMapView(
                region: $region,
                mapType: selectedMapType,
                routeCoordinates: locService.currentRoute?.coordinates ?? [],
                destinationCoordinate: selectedDestination?.coordinate,
                userLocation: locService.currentLocation?.coordinate
            )
            .ignoresSafeArea()

            // ── 2. TOP FLOATING SEARCH & SUGGESTIONS BAR ──
            VStack(spacing: 8) {
                // Top Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)

                    TextField("Buscar destino, dirección...", text: $searchQuery)
                        .font(.system(size: 15))
                        .foregroundColor(ShineMapsTheme.textPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onTapGesture {
                            showSuggestions = true
                            if searchQuery.isEmpty {
                                locService.searchResults = locService.getCategorySuggestions()
                            }
                        }
                        .onChange(of: searchQuery) { newValue in
                            handleSearchQueryChange(newValue)
                        }

                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            locService.searchResults = locService.getCategorySuggestions()
                            showSuggestions = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ShineMapsTheme.textSub)
                                .font(.system(size: 18))
                        }
                    }

                    Button {
                        if !searchQuery.isEmpty {
                            Task { await locService.searchPlaces(query: searchQuery) }
                        } else {
                            showSuggestions.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ShineMapsTheme.cyanPrimary)
                    }

                    // CS ID Avatar Button
                    Button {
                        showCSIDSheet = true
                    } label: {
                        Text(csidManager.isLoggedIn ? (csidManager.currentUser?.initial ?? "CS") : "CS")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(csidManager.isLoggedIn ? ShineMapsTheme.textPrimary : ShineMapsTheme.cyanPrimary)
                            .frame(width: 36, height: 36)
                            .background(csidManager.isLoggedIn ? ShineMapsTheme.cyanPrimary : ShineMapsTheme.cardGlass)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(ShineMapsTheme.borderSubtle, lineWidth: 1))
                            .shadow(color: csidManager.isLoggedIn ? ShineMapsTheme.cyanPrimary.opacity(0.4) : Color.clear, radius: 8)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .glassCard(cornerRadius: 26)
                .padding(.horizontal, 16)
                .padding(.top, 50)

                // Search Results / Location Suggestions Dropdown
                if showSuggestions && !locService.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(locService.searchResults) { item in
                                    Button {
                                        onSelectPlace(item)
                                    } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: item.systemIconName)
                                                .font(.system(size: 18))
                                                .foregroundColor(ShineMapsTheme.cyanPrimary)
                                                .frame(width: 28)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.title)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(ShineMapsTheme.textPrimary)
                                                    .lineLimit(1)

                                                Text(item.address)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(ShineMapsTheme.textSub)
                                                    .lineLimit(1)
                                            }

                                            Spacer()

                                            if let dist = item.formattedDistance {
                                                Text(dist)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(ShineMapsTheme.cyanPrimary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(ShineMapsTheme.surfaceDark)
                                                    .cornerRadius(10)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }

                                    Divider()
                                        .background(ShineMapsTheme.borderSubtle.opacity(0.5))
                                }
                            }
                        }
                        .frame(maxHeight: 280)
                    }
                    .glassCard(cornerRadius: 18)
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Quick Destination Chips (Casa, Estudio, Guardar)
                if !showSuggestions && locService.currentRoute == nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                navigateToSavedPlace("home", defaultName: "Casa")
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "house.fill")
                                    Text("Casa")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ShineMapsTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .glassCard(cornerRadius: 18)
                            }

                            Button {
                                navigateToSavedPlace("work", defaultName: "Estudio")
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "briefcase.fill")
                                    Text("Estudio")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ShineMapsTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .glassCard(cornerRadius: 18)
                            }

                            Button {
                                showSaveAlert = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                    Text("Guardar")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ShineMapsTheme.cyanPrimary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .glassCard(cornerRadius: 18)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                Spacer()
            }

            // ── 3. RIGHT FLOATING CONTROLS ──
            VStack(spacing: 12) {
                // My Location
                Button {
                    centerOnUserLocation()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                        .frame(width: 48, height: 48)
                        .glassCard(cornerRadius: 24)
                }

                // Map Layers
                Button {
                    toggleMapLayer()
                } label: {
                    Image(systemName: "square.3.layers.3d")
                        .font(.system(size: 18))
                        .foregroundColor(ShineMapsTheme.textPrimary)
                        .frame(width: 48, height: 48)
                        .glassCard(cornerRadius: 24)
                }

                // HUD Mode
                Button {
                    withAnimation { isHudMode = true }
                } label: {
                    Image(systemName: "gauge.with.needle")
                        .font(.system(size: 18))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                        .frame(width: 48, height: 48)
                        .glassCard(cornerRadius: 24)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)

            // ── 4. TURN-BY-TURN NAVIGATION CARD ──
            if let route = locService.currentRoute {
                VStack {
                    Spacer()

                    VStack(spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            // Turn Arrow SF Symbol
                            let firstStep = route.steps.first
                            Image(systemName: firstStep?.maneuverIconName ?? "arrow.up")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(ShineMapsTheme.cyanPrimary)
                                .frame(width: 46, height: 46)
                                .background(ShineMapsTheme.surfaceDark)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(firstStep?.instruction ?? "Continúa por la ruta")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(ShineMapsTheme.textPrimary)
                                    .lineLimit(2)

                                HStack(spacing: 12) {
                                    Text("\(route.formattedDuration) • \(route.formattedDistance)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(ShineMapsTheme.cyanPrimary)

                                    Text("Llegada \(route.formattedEta)")
                                        .font(.system(size: 13))
                                        .foregroundColor(ShineMapsTheme.textSub)
                                }
                            }

                            Spacer()

                            // Close Navigation
                            Button {
                                locService.clearRoute()
                                selectedDestination = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(ShineMapsTheme.roseAccent)
                            }
                        }

                        // Speed Indicator
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "speedometer")
                                    .foregroundColor(ShineMapsTheme.cyanPrimary)
                                Text("\(Int(locService.currentSpeedKmh)) km/h")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(ShineMapsTheme.textPrimary)
                            }

                            Spacer()

                            Text(activeDestinationName)
                                .font(.system(size: 13))
                                .foregroundColor(ShineMapsTheme.textSub)
                                .lineLimit(1)
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 22)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── 5. WINDSHIELD HUD OVERLAY ──
            if isHudMode {
                HudOverlayView(
                    isMirrored: $isHudMirrored,
                    speed: locService.currentSpeedKmh,
                    instruction: locService.currentRoute?.steps.first?.instruction ?? "Mantén tu carril",
                    distance: locService.currentRoute?.steps.first?.formattedDistance ?? "--",
                    maneuverIcon: locService.currentRoute?.steps.first?.maneuverIconName ?? "arrow.up",
                    onClose: {
                        withAnimation { isHudMode = false }
                    }
                )
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showCSIDSheet) {
            if csidManager.isLoggedIn {
                CSIDProfileSheet()
            } else {
                CSIDAuthSheet()
            }
        }
        .confirmationDialog("Guardar ubicación actual en CS ID", isPresented: $showSaveAlert, titleVisibility: .visible) {
            Button("Casa") { saveCurrentLocation("home", name: "Casa") }
            Button("Estudio") { saveCurrentLocation("work", name: "Estudio") }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Search Handling
    private func handleSearchQueryChange(_ query: String) {
        searchDebounceTask?.cancel()
        if query.isEmpty {
            locService.searchResults = locService.getCategorySuggestions()
            showSuggestions = true
            return
        }
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            await locService.searchPlaces(query: query)
        }
    }

    private func onSelectPlace(_ item: SearchResult) {
        if item.isCategory, let cat = item.categoryQuery {
            searchQuery = item.title
            Task { await locService.searchPlaces(query: cat) }
            return
        }

        showSuggestions = false
        searchQuery = item.title
        selectedDestination = item
        activeDestinationName = item.title

        let coord = item.coordinate
        withAnimation {
            region.center = coord
            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }

        Task {
            _ = await locService.calculateRoute(to: coord)
        }
    }

    // MARK: - Navigation & Saved Places
    private func centerOnUserLocation() {
        guard let userCoord = locService.currentLocation?.coordinate else { return }
        withAnimation {
            region.center = userCoord
            region.span = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        }
    }

    private func toggleMapLayer() {
        mapTypeIndex = (mapTypeIndex + 1) % 3
        switch mapTypeIndex {
        case 0: selectedMapType = .standard
        case 1: selectedMapType = .satellite
        default: selectedMapType = .hybrid
        }
    }

    private func saveCurrentLocation(_ key: String, name: String) {
        guard let loc = locService.currentLocation?.coordinate else { return }
        UserDefaults.standard.set(loc.latitude, forKey: "\(key)_lat")
        UserDefaults.standard.set(loc.longitude, forKey: "\(key)_lng")
    }

    private func navigateToSavedPlace(_ key: String, defaultName: String) {
        let lat = UserDefaults.standard.double(forKey: "\(key)_lat")
        let lng = UserDefaults.standard.double(forKey: "\(key)_lng")
        guard lat != 0 && lng != 0 else { return }

        let item = SearchResult(
            title: defaultName,
            address: defaultName,
            latitude: lat,
            longitude: lng,
            systemIconName: key == "home" ? "house.fill" : "briefcase.fill"
        )
        onSelectPlace(item)
    }
}

// MARK: - Native MapKit Wrapper with Route Overlay
struct NativeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var mapType: MKMapType
    var routeCoordinates: [CLLocationCoordinate2D]
    var destinationCoordinate: CLLocationCoordinate2D?
    var userLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.mapType = mapType
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.mapType = mapType

        // Update Overlays
        uiView.removeOverlays(uiView.overlays)
        if !routeCoordinates.isEmpty {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            uiView.addOverlay(polyline)
        }

        // Update Annotations
        uiView.removeAnnotations(uiView.annotations)
        if let dest = destinationCoordinate {
            let pin = MKPointAnnotation()
            pin.coordinate = dest
            pin.title = "Destino"
            uiView.addAnnotation(pin)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NativeMapView

        init(_ parent: NativeMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 0.95)
                renderer.lineWidth = 6
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let identifier = "DestinationPin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.markerTintColor = UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1)
                view?.glyphImage = UIImage(systemName: "mappin.and.ellipse")
            }
            return view
        }
    }
}

// MARK: - Windshield HUD Overlay View
struct HudOverlayView: View {
    @Binding var isMirrored: Bool
    var speed: Double
    var instruction: String
    var distance: String
    var maneuverIcon: String
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Top control bar
                HStack {
                    Button {
                        isMirrored.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                            Text(isMirrored ? "Espejo Activado" : "Modo Parabrisas")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(18)
                    }

                    Spacer()

                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(ShineMapsTheme.textSub)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Centered HUD display (Mirrored or Normal)
                VStack(spacing: 16) {
                    Image(systemName: maneuverIcon)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)

                    Text(instruction)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Text(distance)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ShineMapsTheme.cyanAccent)

                    // Big Speedometer
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(speed))")
                            .font(.system(size: 96, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text("KM/H")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(ShineMapsTheme.cyanPrimary)
                    }
                }
                .scaleEffect(x: isMirrored ? -1 : 1, y: 1)

                Spacer()
            }
        }
    }
}
