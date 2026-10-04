import SwiftUI

public struct NativeFileTreeView: View {
    @ObservedObject var vm: IDEViewModel

    public init(vm: IDEViewModel) {
        self.vm = vm
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Sidebar Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.22, green: 0.74, blue: 0.97))

                    Text("EXPLORADOR")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // New .loop File Button
                Button {
                    vm.createNewLoopFile()
                } label: {
                    Image(systemName: "plus.square.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.0, green: 0.96, blue: 0.83))
                }
                .buttonStyle(.plain)
                .help("Nuevo archivo .loop")

                // Refresh Button
                Button {
                    vm.loadWorkspace()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("Refrescar workspace")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.04, green: 0.06, blue: 0.10))

            Divider().background(Color.white.opacity(0.08))

            // File Tree List
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(vm.fileTree) { node in
                        FileNodeRowView(node: node, level: 0, vm: vm)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
        }
        .background(Color(red: 0.03, green: 0.05, blue: 0.08))
    }
}

// Separate struct to support recursive tree without SwiftUI opaque type inference cycles
public struct FileNodeRowView: View {
    public let node: FileNode
    public let level: Int
    @ObservedObject public var vm: IDEViewModel

    public var body: some View {
        if node.isDirectory {
            DisclosureGroup {
                if let children = node.children {
                    ForEach(children) { child in
                        FileNodeRowView(node: child, level: level + 1, vm: vm)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: node.iconName)
                        .font(.system(size: 11))
                        .foregroundColor(node.iconColor)

                    Text(node.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.vertical, 3)
            }
            .accentColor(.white.opacity(0.4))
            .padding(.leading, CGFloat(level * 10))
        } else {
            Button {
                vm.openFile(url: node.url)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: node.iconName)
                        .font(.system(size: 11))
                        .foregroundColor(node.iconColor)

                    Text(node.name)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(vm.activeTabId == node.url.path ? Color(red: 0.0, green: 0.96, blue: 0.83) : .white.opacity(0.75))
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(vm.activeTabId == node.url.path ? Color.white.opacity(0.08) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .padding(.leading, CGFloat(level * 10))
        }
    }
}
