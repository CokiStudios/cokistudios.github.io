//
//  ShineMapsWatchComplications.swift
//  ShineMapsWatch
//
//  Created by Coki Studios.
//  WidgetKit complications for Shine Maps watch faces.
//

import WidgetKit
import SwiftUI

struct ShineMapsComplicationEntry: TimelineEntry {
    let date: Date
    let nextTurnIcon: String
    let distanceString: String
    let nextInstruction: String
    let isNavigating: Bool
}

struct ShineMapsComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShineMapsComplicationEntry {
        ShineMapsComplicationEntry(
            date: Date(),
            nextTurnIcon: "arrow.turn.up.right",
            distanceString: "300m",
            nextInstruction: "Gira a la derecha",
            isNavigating: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShineMapsComplicationEntry) -> Void) {
        let entry = ShineMapsComplicationEntry(
            date: Date(),
            nextTurnIcon: ShineMapsWatchConnectivity.shared.currentManeuverIcon,
            distanceString: ShineMapsWatchConnectivity.shared.distanceToNextManeuver,
            nextInstruction: ShineMapsWatchConnectivity.shared.currentInstruction,
            isNavigating: ShineMapsWatchConnectivity.shared.isNavigating
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShineMapsComplicationEntry>) -> Void) {
        let entry = ShineMapsComplicationEntry(
            date: Date(),
            nextTurnIcon: ShineMapsWatchConnectivity.shared.currentManeuverIcon,
            distanceString: ShineMapsWatchConnectivity.shared.distanceToNextManeuver,
            nextInstruction: ShineMapsWatchConnectivity.shared.currentInstruction,
            isNavigating: ShineMapsWatchConnectivity.shared.isNavigating
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30)))
        completion(timeline)
    }
}

struct ShineMapsComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ShineMapsComplicationProvider.Entry
    
    private let emeraldColor = Color(red: 16/255, green: 185/255, blue: 129/255)
    private let cyanColor = Color(red: 56/255, green: 189/255, blue: 248/255)

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                if entry.isNavigating {
                    VStack(spacing: 1) {
                        Image(systemName: entry.nextTurnIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(emeraldColor)
                        Text(entry.distanceString)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "map.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(cyanColor)
                }
            }

        case .accessoryCorner:
            if entry.isNavigating {
                Image(systemName: entry.nextTurnIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(emeraldColor)
                    .widgetLabel {
                        Text(entry.distanceString)
                    }
            } else {
                Image(systemName: "map.fill")
                    .foregroundColor(cyanColor)
                    .widgetLabel {
                        Text("Shine Maps")
                    }
            }

        case .accessoryRectangular:
            if entry.isNavigating {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: entry.nextTurnIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(emeraldColor)
                        Text("En \(entry.distanceString)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text(entry.nextInstruction)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .foregroundColor(cyanColor)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Shine Maps")
                            .font(.system(size: 11, weight: .bold))
                        Text("Navegación Lista")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
            }

        case .accessoryInline:
            if entry.isNavigating {
                ViewThatFits {
                    Label("\(entry.distanceString) · \(entry.nextInstruction)", systemImage: entry.nextTurnIcon)
                    Label(entry.distanceString, systemImage: entry.nextTurnIcon)
                }
            } else {
                Label("Shine Maps", systemImage: "map.fill")
            }

        default:
            Image(systemName: "map.fill")
        }
    }
}

public struct ShineMapsComplicationsWidget: Widget {
    public let kind: String = "ShineMapsComplicationsWidget"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShineMapsComplicationProvider()) { entry in
            ShineMapsComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Shine Maps")
        .description("Instrucciones de giro y estado de navegación en tu esfera de Apple Watch.")
        #if os(watchOS)
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
        #endif
    }
}
