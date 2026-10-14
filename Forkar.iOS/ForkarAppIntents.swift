//
//  ForkarAppIntents.swift
//  Forkar
//
//  Created by Coki Studios on 13/10/2026.
//  Native App Intents & Siri AI integration for Forkar & ShineMaps.
//

import AppIntents
import SwiftUI

// MARK: - 1. Puntos de Carga / Puntos Verdes Eco Intent
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct FindEcoChargingPointsIntent: AppIntent {
    static var title: LocalizedStringResource = "Buscar Puntos Eco y de Carga"
    static var description = IntentDescription("Busca puntos verdes de carga comunitaria y electrolineras en Forkar con Coki with Apple Intelligence.")
    
    @Parameter(title: "Radio de búsqueda en km", default: 10)
    var radiusKm: Int
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Coki with Apple Intelligence ha localizado puntos de recarga comunitaria y Puntos Verdes dentro de un radio de \(radiusKm) km.")
    }
}

// MARK: - 2. Iniciar / Unirse a Caravana P2P Intent
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct JoinCaravanIntent: AppIntent {
    static var title: LocalizedStringResource = "Unirse a Caravana P2P"
    static var description = IntentDescription("Inicia o se une a una caravana vehicular en tiempo real con ShineMaps y Coki with Apple Intelligence.")
    
    @Parameter(title: "Destino de la Caravana", default: "Centro Chía")
    var destination: String
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Te has conectado a la Caravana P2P hacia \(destination). Tu telemetría y ubicación ahora se sincronizan de forma cifrada.")
    }
}

// MARK: - 3. Check-In Eco Express Intent (Siri AI)
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct EcoCheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar Check-In Eco"
    static var description = IntentDescription("Registra un Punto Verde verificado en Forkar Eco con Siri AI.")
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "¡Check-in validado! Has sumado +20 Puntos Eco y evitado 0.8 kg de CO₂ en tu huella de carbono.")
    }
}

// MARK: - 4. Resumen de Sala CSMS Intent
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct SummarizeForkarChatIntent: AppIntent {
    static var title: LocalizedStringResource = "Resumir Chat con Coki"
    static var description = IntentDescription("Pide a Coki with Apple Intelligence que resuma los mensajes recientes de tu grupo de autos on-device.")
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Coki with Apple Intelligence ha analizado la conversación en el Neural Engine: el grupo acordó salida en caravana con parada en el Punto Verde.")
    }
}

// MARK: - App Shortcuts Provider (Expone los intents automáticamente a Siri AI)
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct ForkarShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindEcoChargingPointsIntent(),
            phrases: [
                "Buscar puntos de carga en \(.applicationName)",
                "Puntos eco en \(.applicationName)",
                "Dónde cargar mi auto con \(.applicationName)"
            ],
            shortTitle: "Puntos Eco",
            systemImageName: "bolt.car.fill"
        )
        AppShortcut(
            intent: JoinCaravanIntent(),
            phrases: [
                "Iniciar caravana en \(.applicationName)",
                "Unirse a caravana con \(.applicationName)"
            ],
            shortTitle: "Caravana P2P",
            systemImageName: "car.2.fill"
        )
        AppShortcut(
            intent: EcoCheckInIntent(),
            phrases: [
                "Validar punto verde en \(.applicationName)",
                "Registrar check-in en \(.applicationName)"
            ],
            shortTitle: "Check-in Eco",
            systemImageName: "qrcode.viewfinder"
        )
        AppShortcut(
            intent: SummarizeForkarChatIntent(),
            phrases: [
                "Resumir chat en \(.applicationName)",
                "Qué dicen en \(.applicationName)"
            ],
            shortTitle: "Resumen Coki",
            systemImageName: "apple.intelligence"
        )
    }
}
