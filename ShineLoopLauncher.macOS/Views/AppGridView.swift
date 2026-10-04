import SwiftUI

// MARK: - Console App Grid View
public struct AppGridView: View {
    @ObservedObject var vm: LauncherViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 280), spacing: 20)
    ]

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(vm.filteredApps.enumerated()), id: \.element.id) { index, app in
                    let isSelected = (index == vm.selectedIndex)

                    GameCardView(
                        app: app,
                        isSelected: isSelected,
                        isHero: false,
                        onSelect: {
                            vm.selectApp(at: index)
                        },
                        onLaunch: {
                            vm.launchApp(app)
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}
