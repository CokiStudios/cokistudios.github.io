import SwiftUI
import MapKit
import CoreLocation

public struct ContentView: View {
    @StateObject private var locService = LocationAndMapService.shared
    @ObservedObject private var csidManager = CSIDManager.shared

    // Search state
    @State private var searchQuery = ""
    @State private var showSuggestions = false
    @State private var searchDebounceTask: Task<Void, Never>? = nil

    // Sheets & Modes
    @State private var showCSIDSheet = false
    @State private var isHudMode = false
    @State private var isHudMirrored = false
    @State private var selectedMapType: MKMapType = .standard
    @State private var mapTypeIndex = 0 // 0: Standard, 1: Satellite, 2: Hybrid
    @State private var is3DNavigation = true

    // Selected Place & Route Selection
    @State private var selectedPlace: SearchResult? = nil
    @State private var showPlaceDetail = false
    @State private var activeCategoryRecommendations: [SearchResult] = []
    @State private var selectedCategoryTitle: String = ""
    @State private var showCategorySheet = false

    // Map & Camera
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    // Save Location Dialog
    @State private var showSaveAlert = false

    public init() {}

    public var body: some View {
        ZStack {
            // ── 1. NATIVE MAP LAYER (Mapbox Directions GL Traffic Polyline & 3D Navigation) ──
            NativeMapView(
                region: $region,
                mapType: selectedMapType,
                route: locService.currentRoute,
                destinationCoordinate: selectedPlace?.coordinate,
                userLocation: locService.currentLocation?.coordinate,
                userHeading: locService.currentHeading,
                isNavigating: locService.currentRoute != nil && is3DNavigation,
                onTapMapCoordinate: { coord in
                    handleMapTap(coordinate: coord)
                }
            )
            .ignoresSafeArea()

            // ── 2. TOP FLOATING SEARCH & CATEGORY BAR (When not navigating) ──
            if locService.currentRoute == nil {
                VStack(spacing: 8) {
                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ShineMapsTheme.cyanPrimary)

                        TextField("Buscar dirección con Apple Maps...", text: $searchQuery)
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
                                locService.updateSearchCompleterQuery("")
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

                    // Apple Maps POI Category Recommendations Carousel
                    if !showSuggestions {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ApplePlaceCategory.allCases) { cat in
                                    Button {
                                        openAppleCategory(cat)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 13))
                                                .foregroundColor(ShineMapsTheme.cyanPrimary)
                                            Text(cat.rawValue)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(ShineMapsTheme.textPrimary)
                                        }
                                        .padding(.horizontal, 12)
                                        .frame(height: 34)
                                        .glassCard(cornerRadius: 17)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Search Results & Apple Maps Live Suggestions Dropdown
                    if showSuggestions && (!locService.searchResults.isEmpty || !locService.completerSuggestions.isEmpty) {
                        VStack(spacing: 0) {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    // Live Autocomplete Suggestions from Apple Maps
                                    if !locService.completerSuggestions.isEmpty && !searchQuery.isEmpty {
                                        ForEach(locService.completerSuggestions) { comp in
                                            Button {
                                                searchQuery = comp.title
                                                Task { await locService.searchPlaces(query: comp.title) }
                                            } label: {
                                                HStack(spacing: 12) {
                                                    Image(systemName: "magnifyingglass")
                                                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                                                        .font(.system(size: 14))

                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(comp.title)
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(ShineMapsTheme.textPrimary)
                                                        Text(comp.address)
                                                            .font(.system(size: 12))
                                                            .foregroundColor(ShineMapsTheme.textSub)
                                                    }
                                                    Spacer()
                                                    Text("Apple Maps")
                                                        .font(.system(size: 10, weight: .semibold))
                                                        .foregroundColor(ShineMapsTheme.cyanAccent)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(ShineMapsTheme.surfaceDark)
                                                        .cornerRadius(6)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                            }
                                            Divider().background(ShineMapsTheme.borderSubtle.opacity(0.4))
                                        }
                                    }

                                    // Resolved Places
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
                                        Divider().background(ShineMapsTheme.borderSubtle.opacity(0.4))
                                    }
                                }
                            }
                            .frame(maxHeight: 280)
                        }
                        .glassCard(cornerRadius: 18)
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer()
                }
            }

            // ── 3. RIGHT FLOATING UTILITY CONTROLS ──
            VStack(spacing: 12) {
                // My Location Center
                Button {
                    centerOnUserLocation()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                        .frame(width: 48, height: 48)
                        .glassCard(cornerRadius: 24)
                }

                // 3D Navigation Perspective Toggle
                Button {
                    withAnimation { is3DNavigation.toggle() }
                } label: {
                    Image(systemName: is3DNavigation ? "view.3d" : "view.2d")
                        .font(.system(size: 18))
                        .foregroundColor(is3DNavigation ? ShineMapsTheme.cyanAccent : ShineMapsTheme.textSub)
                        .frame(width: 48, height: 48)
                        .glassCard(cornerRadius: 24)
                }

                // Map Layers Toggle
                Button {
                    toggleMapLayer()
                } label: {
                    Image(systemName: "square.3.layers.3d")
                        .font(.system(size: 18))
                        .foregroundColor(ShineMapsTheme.textPrimary)
                        .frame(width: 48, height: 48)
                        .glassCard(cornerRadius: 24)
                }

                // HUD Windshield Mirror Mode
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

            // ── 4. MAPBOX DIRECTIONS GL ACTIVE TURN-BY-TURN HUD ──
            if let route = locService.currentRoute {
                VStack(spacing: 12) {
                    // Top Maneuver Banner
                    HStack(spacing: 14) {
                        let activeStep = route.steps.indices.contains(locService.activeManeuverIndex)
                            ? route.steps[locService.activeManeuverIndex]
                            : route.steps.first

                        Image(systemName: activeStep?.maneuverIconName ?? "arrow.up")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(ShineMapsTheme.cyanPrimary)
                            .frame(width: 50, height: 50)
                            .background(ShineMapsTheme.surfaceDark)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(ShineMapsTheme.cyanPrimary.opacity(0.3), lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(activeStep?.instruction ?? "Continúa por la vía")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ShineMapsTheme.textPrimary)
                                .lineLimit(2)

                            if let sec = activeStep?.secondaryInstruction {
                                Text(sec)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ShineMapsTheme.cyanAccent)
                                    .lineLimit(1)
                            }

                            // Traffic Congestion Badge
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(route.overallCongestion.color)
                                    .frame(width: 8, height: 8)
                                Text(route.overallCongestion.label)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(route.overallCongestion.color)

                                Text("• \(route.primaryRoadName)")
                                    .font(.system(size: 11))
                                    .foregroundColor(ShineMapsTheme.textSub)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        // Voice Guidance Mute Toggle
                        Button {
                            locService.toggleVoiceMute()
                        } label: {
                            Image(systemName: locService.isVoiceMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(locService.isVoiceMuted ? ShineMapsTheme.textSub : ShineMapsTheme.cyanPrimary)
                                .frame(width: 40, height: 40)
                                .glassCard(cornerRadius: 20)
                        }
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 24)
                    .padding(.horizontal, 16)
                    .padding(.top, 54)

                    Spacer()

                    // Bottom Trip Dashboard & Speedometer
                    VStack(spacing: 12) {
                        HStack(alignment: .center) {
                            // Trip Info
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(route.formattedDuration)
                                        .font(.system(size: 26, weight: .black))
                                        .foregroundColor(ShineMapsTheme.cyanPrimary)

                                    Text(route.formattedDistance)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(ShineMapsTheme.textPrimary)
                                }

                                Text("Llegada estimada \(route.formattedEta)")
                                    .font(.system(size: 13))
                                    .foregroundColor(ShineMapsTheme.textSub)
                            }

                            Spacer()

                            // Speedometer
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(locService.currentSpeedKmh))")
                                    .font(.system(size: 32, weight: .black, design: .monospaced))
                                    .foregroundColor(ShineMapsTheme.textPrimary)
                                Text("KM/H")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(ShineMapsTheme.cyanPrimary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ShineMapsTheme.surfaceDark)
                            .cornerRadius(14)

                            // Cancel Route Button
                            Button {
                                locService.clearRoute()
                                selectedPlace = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(ShineMapsTheme.roseAccent)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 24)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
                }
                .transition(.opacity)
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
        // Place Detail Sheet (Apple Maps Place & Address Info + Mapbox Route Launcher)
        .sheet(isPresented: $showPlaceDetail) {
            if let place = selectedPlace {
                ApplePlaceDetailSheet(
                    place: place,
                    onStartNavigation: { profile in
                        showPlaceDetail = false
                        startNavigation(to: place, profile: profile)
                    }
                )
                .presentationDetents([.fraction(0.42), .large])
                .presentationDragIndicator(.visible)
            }
        }
        // Category Recommendations Sheet (Apple Maps POIs)
        .sheet(isPresented: $showCategorySheet) {
            CategoryRecommendationsSheet(
                categoryTitle: selectedCategoryTitle,
                places: activeCategoryRecommendations,
                onSelectPlace: { place in
                    showCategorySheet = false
                    onSelectPlace(place)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // CS ID Profile / Auth Sheet
        .sheet(isPresented: $showCSIDSheet) {
            if csidManager.isLoggedIn {
                CSIDProfileSheet()
            } else {
                CSIDAuthSheet()
            }
        }
    }

    // MARK: - Handlers & Actions
    private func handleSearchQueryChange(_ query: String) {
        searchDebounceTask?.cancel()
        locService.updateSearchCompleterQuery(query)

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

    private func openAppleCategory(_ cat: ApplePlaceCategory) {
        selectedCategoryTitle = cat.rawValue
        Task {
            let places = await locService.fetchAppleRecommendations(category: cat)
            await MainActor.run {
                self.activeCategoryRecommendations = places
                self.showCategorySheet = true
            }
        }
    }

    private func onSelectPlace(_ item: SearchResult) {
        if item.isCategory, let query = item.categoryQuery {
            searchQuery = item.title
            Task { await locService.searchPlaces(query: query) }
            return
        }

        showSuggestions = false
        selectedPlace = item
        showPlaceDetail = true

        let coord = item.coordinate
        withAnimation {
            region.center = coord
            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
    }

    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        Task {
            if let resolved = await locService.reverseGeocodeAddress(coordinate: coordinate) {
                let place = SearchResult(
                    title: resolved.name,
                    address: resolved.fullAddress,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    systemIconName: "mappin.and.ellipse",
                    source: .appleMaps
                )
                await MainActor.run {
                    self.selectedPlace = place
                    self.showPlaceDetail = true
                }
            }
        }
    }

    private func startNavigation(to place: SearchResult, profile: RouteProfile) {
        Task {
            _ = await locService.calculateRoute(to: place.coordinate, profile: profile)
            await MainActor.run {
                centerOnUserLocation()
            }
        }
    }

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
}

// MARK: - Apple Maps Place Detail Sheet
struct ApplePlaceDetailSheet: View {
    let place: SearchResult
    let onStartNavigation: (RouteProfile) -> Void

    @State private var selectedProfile: RouteProfile = .drivingTraffic

    var body: some View {
        ZStack {
            ShineMapsTheme.bgDark.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                // Header & Source Badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(place.source.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(ShineMapsTheme.cyanAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ShineMapsTheme.surfaceDark)
                                .cornerRadius(6)

                            if let cat = place.poiCategoryName {
                                Text(cat)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ShineMapsTheme.textSub)
                            }
                        }

                        Text(place.title)
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(ShineMapsTheme.textPrimary)
                            .lineLimit(2)

                        Text(place.address)
                            .font(.system(size: 14))
                            .foregroundColor(ShineMapsTheme.textSub)
                            .lineLimit(2)
                    }

                    Spacer()

                    if let dist = place.formattedDistance {
                        VStack(spacing: 2) {
                            Text(dist)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ShineMapsTheme.cyanPrimary)
                            Text("de distancia")
                                .font(.system(size: 10))
                                .foregroundColor(ShineMapsTheme.textSub)
                        }
                        .padding(10)
                        .glassCard(cornerRadius: 12)
                    }
                }

                // Quick Actions (Call, Web, Share)
                HStack(spacing: 10) {
                    if let phone = place.phoneNumber, let telUrl = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                        Button {
                            UIApplication.shared.open(telUrl)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "phone.fill")
                                Text("Llamar")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ShineMapsTheme.cyanPrimary)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .glassCard(cornerRadius: 19)
                        }
                    }

                    if let url = place.url {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "safari.fill")
                                Text("Sitio Web")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ShineMapsTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .glassCard(cornerRadius: 19)
                        }
                    }
                }

                // Mapbox Route Profile Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Perfil de Ruta (Mapbox Directions GL)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShineMapsTheme.textSub)

                    HStack(spacing: 8) {
                        ForEach(RouteProfile.allCases) { prof in
                            Button {
                                selectedProfile = prof
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: prof.icon)
                                    Text(prof.label)
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(selectedProfile == prof ? ShineMapsTheme.bgDark : ShineMapsTheme.textPrimary)
                                .padding(.horizontal, 10)
                                .frame(height: 34)
                                .background(selectedProfile == prof ? ShineMapsTheme.cyanPrimary : ShineMapsTheme.surfaceDark)
                                .cornerRadius(17)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 17)
                                        .stroke(selectedProfile == prof ? ShineMapsTheme.cyanAccent : ShineMapsTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                    }
                }

                Spacer()

                // Primary Action Button: Iniciar Ruta con Mapbox Directions GL
                Button {
                    onStartNavigation(selectedProfile)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Iniciar Ruta con Mapbox Directions GL")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(ShineMapsTheme.bgDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(ShineMapsTheme.cyanGradient)
                    .cornerRadius(26)
                    .shadow(color: ShineMapsTheme.cyanPrimary.opacity(0.5), radius: 12, x: 0, y: 6)
                }
                .padding(.bottom, 16)
            }
            .padding(22)
        }
    }
}

// MARK: - Category Recommendations Sheet
struct CategoryRecommendationsSheet: View {
    let categoryTitle: String
    let places: [SearchResult]
    let onSelectPlace: (SearchResult) -> Void

    var body: some View {
        ZStack {
            ShineMapsTheme.bgDark.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(categoryTitle)
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(ShineMapsTheme.textPrimary)

                        Text("Recomendaciones de Apple Maps en tiempo real")
                            .font(.system(size: 13))
                            .foregroundColor(ShineMapsTheme.cyanPrimary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                if places.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .tint(ShineMapsTheme.cyanPrimary)
                        Text("Buscando lugares recomendados...")
                            .font(.system(size: 14))
                            .foregroundColor(ShineMapsTheme.textSub)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(places) { place in
                            Button {
                                onSelectPlace(place)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: place.systemIconName)
                                        .font(.system(size: 20))
                                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(place.title)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(ShineMapsTheme.textPrimary)
                                            .lineLimit(1)

                                        Text(place.address)
                                            .font(.system(size: 12))
                                            .foregroundColor(ShineMapsTheme.textSub)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    if let dist = place.formattedDistance {
                                        Text(dist)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(ShineMapsTheme.cyanPrimary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(ShineMapsTheme.surfaceDark)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(ShineMapsTheme.cardGlass)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
}

// MARK: - Native MapKit Wrapper with Mapbox Directions GL Traffic Polyline
struct NativeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var mapType: MKMapType
    var route: RouteInfo?
    var destinationCoordinate: CLLocationCoordinate2D?
    var userLocation: CLLocationCoordinate2D?
    var userHeading: Double
    var isNavigating: Bool
    var onTapMapCoordinate: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = mapType

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.mapType = mapType

        // Update Overlays (Mapbox Directions GL Traffic Congestion Multi-Segment Polyline)
        uiView.removeOverlays(uiView.overlays)
        context.coordinator.congestionMap.removeAll()

        if let currentRoute = route, !currentRoute.trafficSegments.isEmpty {
            for seg in currentRoute.trafficSegments {
                var points = [seg.startCoordinate, seg.endCoordinate]
                let poly = MKPolyline(coordinates: &points, count: 2)
                context.coordinator.congestionMap[ObjectIdentifier(poly)] = seg.congestion
                uiView.addOverlay(poly)
            }
        } else if let currentRoute = route, !currentRoute.coordinates.isEmpty {
            let poly = MKPolyline(coordinates: currentRoute.coordinates, count: currentRoute.coordinates.count)
            context.coordinator.congestionMap[ObjectIdentifier(poly)] = .low
            uiView.addOverlay(poly)
        }

        // Update Annotations
        uiView.removeAnnotations(uiView.annotations)
        if let dest = destinationCoordinate {
            let pin = MKPointAnnotation()
            pin.coordinate = dest
            pin.title = "Destino"
            uiView.addAnnotation(pin)
        }

        // 3D Navigation Camera Tracking - Only when view bounds are established
        if uiView.bounds.width > 0 && uiView.bounds.height > 0 {
            if isNavigating, let user = userLocation {
                let camera = MKMapCamera(
                    lookingAtCenter: user,
                    fromDistance: 450,
                    pitch: 60,
                    heading: userHeading
                )
                uiView.setCamera(camera, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NativeMapView
        var congestionMap: [ObjectIdentifier: TrafficCongestionLevel] = [:]

        init(_ parent: NativeMapView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onTapMapCoordinate(coord)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let congestion = congestionMap[ObjectIdentifier(polyline)] ?? .low
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = congestion.uiColor
                renderer.lineWidth = 7
                renderer.lineCap = .round
                renderer.lineJoin = .round
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
