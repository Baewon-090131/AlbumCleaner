import SwiftUI

enum AppTab: Hashable {
    case sort, albums, mine
}

/// 三个 tab 全部用系统 TabView，底部栏就是原生 UITabBar（iOS 26 上自动带 Liquid Glass）。
struct MainTabView: View {
    @AppStorage("ac_theme") private var themeHex = "#002FA7"
    @State private var selection: AppTab = .sort

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                SortScreen()
            }
            .tabItem { Label("整理", systemImage: "rectangle.stack") }
            .tag(AppTab.sort)

            NavigationStack {
                AlbumsScreen()
            }
            .tabItem { Label("相簿", systemImage: "photo.on.rectangle") }
            .tag(AppTab.albums)

            NavigationStack {
                MineScreen()
            }
            .tabItem { Label("我的", systemImage: "person") }
            .tag(AppTab.mine)
        }
        .tint(Color(hex: themeHex))
    }
}
