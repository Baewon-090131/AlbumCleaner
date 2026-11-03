import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    case sort, similar, albums, mine

    var id: Self { self }

    var title: String {
        switch self {
        case .sort: "整理"
        case .similar: "相似"
        case .albums: "相簿"
        case .mine: "我的"
        }
    }

    var symbol: String {
        switch self {
        case .sort: "rectangle.stack"
        case .similar: "square.on.square"
        case .albums: "photo.on.rectangle"
        case .mine: "person.crop.circle"
        }
    }
}

/// 主界面：系统 `TabView`（Liquid Glass 底栏由系统渲染，不是自绘）。
///
/// iOS 26 及以上：3 个 tab + `.tabViewBottomAccessory` 放「我的」入口——
/// 底栏正常时它显示在底栏上方一条，底栏收起时内联进底栏；
/// 「我的」点按后仍从这条入口扩散到全屏（zoom 转场）。
/// iOS 17–25：没有 accessory，退回 4 个 tab。
struct MainTabView: View {
    @AppStorage("ac_theme_v2") private var themeHex = "#2B4A6F"
    @Environment(UIState.self) private var ui
    @State private var selection: AppTab = .sort
    /// 「我的」的 zoom 转场：源是底栏上方的入口条，目标是全屏 cover。
    @Namespace private var mineNamespace

    private static let mineTransitionID = "mine"

    var body: some View {
        @Bindable var ui = ui
        tabRoot
            .tint(Color(hex: themeHex))
            .fullScreenCover(isPresented: $ui.showMine) { mineCover }
            .sheet(isPresented: $ui.showTrash) { trashSheet }
    }

    @ViewBuilder
    private var tabRoot: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selection) {
                sortTab
                similarTab
                albumsTab
            }
            .tabViewBottomAccessory { mineAccessory }
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            TabView(selection: $selection) {
                sortTab
                similarTab
                albumsTab
                mineTab
            }
        }
    }

    // MARK: - 各 tab

    private var sortTab: some View {
        NavigationStack { SortScreen() }
            .background(Theme.wall)
            .tabItem { Label("整理", systemImage: "rectangle.stack") }
            .tag(AppTab.sort)
    }

    private var similarTab: some View {
        NavigationStack { SimilarScreen() }
            .background(Theme.wall)
            .tabItem { Label("相似", systemImage: "square.on.square") }
            .tag(AppTab.similar)
    }

    private var albumsTab: some View {
        NavigationStack { AlbumsScreen() }
            .background(Theme.wall)
            .tabItem { Label("相簿", systemImage: "photo.on.rectangle") }
            .tag(AppTab.albums)
    }

    /// iOS 17–25 的回退：没有 accessory，就把「我的」放成一个普通 tab。
    private var mineTab: some View {
        NavigationStack { MineScreen(showsCloseButton: false) }
            .background(Theme.wall)
            .tabItem { Label("我的", systemImage: "person.crop.circle") }
            .tag(AppTab.mine)
    }

    // MARK: - 「我的」入口

    @ViewBuilder
    private var mineAccessory: some View {
        if #available(iOS 18.0, *) {
            accessoryButton.matchedTransitionSource(id: Self.mineTransitionID, in: mineNamespace)
        } else {
            accessoryButton
        }
    }

    private var accessoryButton: some View {
        Button {
            ui.showMine = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 18))
                Text("我的")
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.ink3)
            }
            .foregroundStyle(Color(hex: themeHex))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("我的")
    }

    /// 「我的」：从入口条扩散到全屏；退出用右上角 ×，转场自动倒放。
    @ViewBuilder
    private var mineCover: some View {
        if #available(iOS 18.0, *) {
            NavigationStack { MineScreen() }
                .background(Theme.wall)
                .navigationTransition(.zoom(sourceID: Self.mineTransitionID, in: mineNamespace))
        } else {
            NavigationStack { MineScreen() }
                .background(Theme.wall)
        }
    }

    /// 待删除：系统 sheet，抓握条与圆角交给系统。
    private var trashSheet: some View {
        NavigationStack { TrashScreen() }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Theme.cornerIsland)
            .presentationBackground { Theme.wall }
    }
}
