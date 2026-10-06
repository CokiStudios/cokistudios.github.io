//
//  ShineMapsWatchContentView.swift
//  ShineMapsWatch
//
//  Created by Coki Studios.
//  Ultra-fluid, high-contrast watchOS HUD for Shine Maps.
//  Features Turn-by-Turn Maneuvers, Haptic Cues, Speed Telemetry & Nearby POIs.
//

import SwiftUI
import WatchKit

struct ShineMapsWatchContentView: View {
    @ObservedObject var connectivity = ShineMapsWatchConnectivity.shared
    @State private var selectedTab: Int = 0
    
    private let cyanAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    private let emeraldAccent = Color(red: 16/255, green: 185/255, blue: 129/255)
    private let warningAmber = Color(red: 245/255, green: 158/255, blue: 11/255)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - TAB 1: Live Maneuver HUD / Idle Screen
            if connectivity.isNavigating {
                ActiveNavigationHUDView(connectivity: connectivity)
                    .tag(0)
            } else {
                IdleStartHUDView(connectivity: connectivity, onGoToPOIs: { selectedTab = 1 })
                    .tag(0)
            }
            
            // MARK: - TAB 2: Nearby POIs (EV, Parking, Eco)
            NearbyPOIsView(connectivity: connectivity)
                .tag(1)
            
            // MARK: - TAB 3: Telemetry & Connection Status
            LiveTelemetryStatusView(connectivity: connectivity)
                .tag(2)
        }
        .tabViewStyle(.page)
    }
}

// MARK: - 1. Active Navigation HUD View
struct ActiveNavigationHUDView: View {
    @ObservedObject var connectivity: ShineMapsWatchConnectivity
    
    private let cyanAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    private let emeraldAccent = Color(red: 16/255, green: 185/255, blue: 129/255)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Top Header: Destination + Distance
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(emeraldAccent)
                    Text(connectivity.destinationName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                // Maneuver Big Banner
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [emeraldAccent.opacity(0.3), cyanAccent.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 46, height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(emeraldAccent.opacity(0.6), lineWidth: 1.5)
                            )
                        
                        Image(systemName: connectivity.currentManeuverIcon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(emeraldAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(connectivity.distanceToNextManeuver)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(connectivity.currentInstruction)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(14)
                
                // Telemetry Bar: Speed & ETA
                HStack(spacing: 6) {
                    // Speed Limit / Live Speed
                    HStack(spacing: 4) {
                        Text("\(connectivity.currentSpeedKmh)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(connectivity.currentSpeedKmh > connectivity.speedLimitKmh ? .red : .white)
                        Text("km/h")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // ETA & Remaining Time
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(connectivity.etaString)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(cyanAccent)
                        Text("\(connectivity.remainingTime) · \(connectivity.totalRemainingDistance)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 4)
                
                // Next Subsequent Maneuver Preview
                if !connectivity.nextInstruction.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.turn.up.right")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                        Text(connectivity.nextInstruction)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 6)
                }
                
                // Actions: Stop & Reroute
                HStack(spacing: 8) {
                    Button(action: {
                        connectivity.stopNavigation()
                    }) {
                        Label("Finalizar", systemImage: "xmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red.opacity(0.3))
                    
                    Button(action: {
                        connectivity.requestReroute()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(cyanAccent)
                    }
                    .buttonStyle(.bordered)
                    .tint(cyanAccent.opacity(0.3))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Idle Screen (Ready to Navigate)
struct IdleStartHUDView: View {
    @ObservedObject var connectivity: ShineMapsWatchConnectivity
    var onGoToPOIs: () -> Void
    
    private let cyanAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    private let emeraldAccent = Color(red: 16/255, green: 185/255, blue: 129/255)
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [cyanAccent, emeraldAccent], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                    .frame(width: 52, height: 52)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [cyanAccent, emeraldAccent], startPoint: .top, endPoint: .bottom))
            }
            .padding(.top, 4)
            
            Text("Shine Maps")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(connectivity.isReachable ? "Conectado a iPhone" : "GPS Autónomo")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(connectivity.isReachable ? emeraldAccent : .orange)
            
            Button(action: onGoToPOIs) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .bold))
                    Text("Puntos Cercanos")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
            }
            .buttonStyle(.borderedProminent)
            .tint(emeraldAccent)
            .padding(.top, 4)
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - 2. Nearby POIs View (Quick Wrist Navigation)
struct NearbyPOIsView: View {
    @ObservedObject var connectivity: ShineMapsWatchConnectivity
    
    var body: some View {
        List {
            Section(header: Text("PUNTOS CERCA").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)) {
                ForEach(connectivity.nearbyPOIs) { poi in
                    Button(action: {
                        connectivity.navigateToPOI(poi)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: poi.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colorForCategory(poi.category))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(poi.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                HStack(spacing: 4) {
                                    Text(poi.category)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(colorForCategory(poi.category))
                                    Text("•")
                                        .font(.system(size: 9))
                                        .foregroundColor(.gray)
                                    Text(poi.distance)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.carousel)
    }
    
    private func colorForCategory(_ cat: String) -> Color {
        switch cat {
        case "Carga EV": return Color(red: 16/255, green: 185/255, blue: 129/255)
        case "Parking": return Color(red: 56/255, green: 189/255, blue: 248/255)
        case "Eco": return Color(red: 52/255, green: 211/255, blue: 153/255)
        case "Gasolina": return Color(red: 245/255, green: 158/255, blue: 11/255)
        default: return .white
        }
    }
}

// MARK: - 3. Live Telemetry & Compass
struct LiveTelemetryStatusView: View {
    @ObservedObject var connectivity: ShineMapsWatchConnectivity
    
    private let cyanAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("ESTADO DE RUTA")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("VELOCÍMETRO")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.gray)
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("\(connectivity.currentSpeedKmh)")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("km/h")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.bottom, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("LÍMITE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.gray)
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("\(connectivity.speedLimitKmh)")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(red: 245/255, green: 158/255, blue: 11/255))
                            Text("km/h")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.bottom, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                }
                
                // Hardware & Connectivity badges
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(connectivity.isReachable ? .green : .gray)
                            .font(.system(size: 11))
                        Text(connectivity.isReachable ? "Sincronizado con CarPlay" : "Buscando iPhone")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(cyanAccent)
                            .font(.system(size: 11))
                        Text("Giro Háptico en Muñeca Activo")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }
            .padding(.horizontal, 4)
        }
    }
}
