//
//  ForkarWatchComplications.swift
//  ForkarWatch
//
//  WidgetKit Complications for Apple Watch Faces
//

import WidgetKit
import SwiftUI

public struct ForkarWatchTimelineEntry: TimelineEntry {
    public let date: Date
    public let co2Saved: Double
    public let ecoPoints: Int
    public let levelTitle: String
}

public struct ForkarWatchTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> ForkarWatchTimelineEntry {
        ForkarWatchTimelineEntry(date: Date(), co2Saved: 12.5, ecoPoints: 240, levelTitle: "Oro")
    }

    public func getSnapshot(in context: Context, completion: @escaping (ForkarWatchTimelineEntry) -> Void) {
        let entry = ForkarWatchTimelineEntry(
            date: Date(),
            co2Saved: UserDefaults.standard.double(forKey: "forkar_watch_co2"),
            ecoPoints: UserDefaults.standard.integer(forKey: "forkar_watch_points"),
            levelTitle: "Sostenible"
        )
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<ForkarWatchTimelineEntry>) -> Void) {
        let co2 = UserDefaults.standard.double(forKey: "forkar_watch_co2")
        let points = UserDefaults.standard.integer(forKey: "forkar_watch_points")
        let currentEntry = ForkarWatchTimelineEntry(
            date: Date(),
            co2Saved: co2 > 0 ? co2 : 8.4,
            ecoPoints: points > 0 ? points : 180,
            levelTitle: "Eco Active"
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct ForkarWatchComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ForkarWatchTimelineEntry

    public var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                    Text("\(entry.co2Saved, specifier: "%.1f")")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            
        case .accessoryCorner:
            Image(systemName: "leaf.fill")
                .foregroundColor(.green)
                .widgetLabel {
                    Text("\(entry.co2Saved, specifier: "%.1f") kg")
                }
                
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text("Forkar Eco")
                        .font(.system(size: 11, weight: .bold))
                }
                Text("\(entry.co2Saved, specifier: "%.1f") kg CO₂ ahorrados")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("\(entry.ecoPoints) pts acumulados")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.yellow)
            }
            
        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                Text("\(entry.co2Saved, specifier: "%.1f") kg CO₂")
            }
            
        default:
            Text("\(entry.co2Saved, specifier: "%.1f") kg")
        }
    }
}

public struct ForkarWatchComplication: Widget {
    public let kind: String = "ForkarWatchComplication"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ForkarWatchTimelineProvider()) { entry in
            ForkarWatchComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Forkar Eco")
        .description("Muestra tu ahorro de CO₂ y puntos en tu esfera de Apple Watch.")
        #if os(watchOS)
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
        #endif
    }
}
