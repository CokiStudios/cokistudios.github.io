import Foundation
import SwiftUI
import AppKit

// MARK: - Central Log Manager Observable
@MainActor
public final class LogManager: ObservableObject {
    public static let shared = LogManager()

    @Published public private(set) var entries: [LogEntry] = []
    @Published public var selectedFilter: LogEntry.Category? = nil
    @Published public var searchQuery: String = ""

    private let maxEntries = 500

    private init() {
        log(.system, "✦ UI Connect Native macOS Suite inicializada (Swift 6.4 Direct-to-Metal / APU).")
    }

    public func log(_ category: LogEntry.Category, _ message: String) {
        let entry = LogEntry(category: category, message: message)
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    public func clear() {
        entries.removeAll()
        log(.system, "Registro de consola limpiado.")
    }

    public func copyAllToClipboard() {
        let text = entries.map { "[\($0.timestampFormatted)] [\($0.category.rawValue)] \($0.message)" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        log(.system, "Consola copiada al portapapeles (\(entries.count) entradas).")
    }

    public var filteredEntries: [LogEntry] {
        entries.filter { entry in
            let matchesCategory = selectedFilter == nil || entry.category == selectedFilter
            let matchesQuery = searchQuery.isEmpty || entry.message.localizedCaseInsensitiveContains(searchQuery)
            return matchesCategory && matchesQuery
        }
    }
}
