import SwiftUI

// MARK: - Live Terminal Log Drawer View
public struct LogDrawerView: View {
    @ObservedObject var logger = LogManager.shared

    public var body: some View {
        VStack(spacing: 0) {
            // Log Drawer Toolbar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(UITheme.green)
                    Text("Consola del Sistema & Enlace en Vivo")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(UITheme.textPrimary)
                }

                Spacer()

                // Category Filter Pills
                HStack(spacing: 6) {
                    FilterPill(title: "Todos", isSelected: logger.selectedFilter == nil) {
                        logger.selectedFilter = nil
                    }

                    ForEach(LogEntry.Category.allCases, id: \.self) { cat in
                        FilterPill(title: cat.rawValue, isSelected: logger.selectedFilter == cat, color: cat.color) {
                            logger.selectedFilter = cat
                        }
                    }
                }

                // Copy Button
                Button(action: {
                    logger.copyAllToClipboard()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(UITheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Copiar todo el registro")

                // Clear Button
                Button(action: {
                    logger.clear()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(UITheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Limpiar registro")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(UITheme.cardBg)
            .overlay(Rectangle().frame(height: 1).foregroundColor(UITheme.cardBorder), alignment: .top)

            // Scrollable Log Content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(logger.filteredEntries) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text("[\(entry.timestampFormatted)]")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(UITheme.textSecondary)

                                Text("[\(entry.category.rawValue)]")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(entry.category.color)

                                Text(entry.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(UITheme.textPrimary)
                                    .textSelection(.enabled)
                            }
                            .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .background(UITheme.logBg)
                .onChange(of: logger.entries.count) {
                    if let last = logger.entries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(height: 160)
        .overlay(Rectangle().frame(height: 1).foregroundColor(UITheme.cardBorder), alignment: .top)
    }
}

// MARK: - Category Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = UITheme.primary
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(isSelected ? color.opacity(0.25) : Color.clear)
                .foregroundColor(isSelected ? color : UITheme.textSecondary)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? color.opacity(0.6) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
