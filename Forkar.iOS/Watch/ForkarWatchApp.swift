//
//  ForkarWatchApp.swift
//  ForkarWatch
//
//  Standalone & Companion watchOS Application entry point for Forkar
//

import SwiftUI

@main
struct ForkarWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ForkarWatchContentView()
                .preferredColorScheme(.dark)
        }
    }
}
