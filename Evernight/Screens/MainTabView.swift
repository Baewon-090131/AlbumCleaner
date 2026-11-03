import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    case sort, similar, albums

    var id: Self { self }

    var title: String {
        switch self {
        case .sort: "整理"
        case .similar: "相似"
        case .albums: "相簿"
        }
    }

    var symbol: String {
        switch self {
        case .sort: "rectangle.stack"
        case .similar: "square.on.square"
        case .albums: "photo.on.rectangle"
        }
    }
}

/// 主界面：三个 tab 的内容区 + 自定义底部栏（3 栏玻璃胶囊 +「我的」独立圆钮）。
/// 不再用系统 TabView——「我的」要单独拿出来：点按后从圆钮扩散到全屏（iOS 18+ 的 zoom 转场）。
struct MainTabView: View {
    @AppStorage("ac_theme") private var themeHex = "#002FA7"
    @Environment(UIState.self) private var ui
    @State private var selection: AppTab = .sort
    /// 「我的」的 zoom 转场：源是底栏圆钮，目标是全屏 cover，进出共用这一个命名空间。
    @Namespace private var mineNamespace

    var body: some View {
        @Bindable var ui = ui
        ZStack(alignment: .bottom) {
            tabContent
                // 给悬浮底栏留位
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 92) }

            AppTabBar(selection: $selection,
                      mineActive: ui.showMine,
                      namespace: mineNamespace) {
                ui.showMine = true
            }
        }
        .tint(Color(hex: themeHex))
        .fullScreenCover(isPresented: $ui.showMine) { mineCover }
        .sheet(isPresented: $ui.showTrash) { trashSheet }
    }

    /// 三个 tab 常驻、只切显隐：整理页的游标与撤销栈、相似页的扫描结果都不因切换丢失。
    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    switch tab {
                    case .sort: SortScreen()
                    case .similar: SimilarScreen()
                    case .albums: AlbumsScreen()
                    }
                }
                .opacity(selection == tab ? 1 : 0)
                .allowsHitTesting(selection == tab)
            }
        }
    }

    /// 「我的」：从底栏圆钮扩散到全屏；iOS 18 以下是普通的全屏覆盖。
    @ViewBuilder
    private var mineCover: some View {
        if #available(iOS 18.0, *) {
            NavigationStack { MineScreen() }
                .background(Theme.wall)
                .navigationTransition(.zoom(sourceID: AppTabBar.mineTransitionID, in: mineNamespace))
        } else {
            NavigationStack { MineScreen() }
                .background(Theme.wall)
        }
    }

    /// 待删除：系统 sheet，抓握条与圆角交给系统，进场 / 退场都是标准 sheet 动效。
    private var trashSheet: some View {
        NavigationStack { TrashScreen() }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Theme.cornerIsland)
            .presentationBackground { Theme.wall }
    }
}
