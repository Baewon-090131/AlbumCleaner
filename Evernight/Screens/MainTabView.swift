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

/// 主界面：三个 tab 的内容区 + 底部一块四合一玻璃胶囊（整理 / 相似 / 相簿 / 我的）。
///
/// 为什么不用系统 `TabView`：iOS 26 的 `TabView` 只有 3 个 tab 加 `TabRole.prominent`
/// 才能做 N+1（iOS 27 才有 `TabRole.prominent`）。当前 CI 的 Xcode 26.6 编不了 iOS 27
/// 的 Beta API，所以四个入口收进同一块玻璃，材质仍走官方 `glassEffect`。
/// 「我的」第 4 个按钮点按后照样从按钮位置 zoom 扩散到全屏。
struct MainTabView: View {
    @AppStorage("ac_theme_v2") private var themeHex = "#2B4A6F"
    @Environment(UIState.self) private var ui
    @State private var selection: AppTab = .sort
    /// 「我的」的 zoom 转场：源是胶囊里第 4 个按钮，目标是全屏 cover。
    @Namespace private var mineNamespace

    private static let mineTransitionID = "mine"
    /// 底栏占位：胶囊 62（6 内边距 + 50 按钮 + 6）+ 下边距 10 + 呼吸 20
    private static let barReserve: CGFloat = 92

    var body: some View {
        @Bindable var ui = ui
        ZStack(alignment: .bottom) {
            Theme.wall

            tabContent
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: Self.barReserve)
                }

            bottomBar
        }
        .tint(Color(hex: themeHex))
        .fullScreenCover(isPresented: $ui.showMine) { mineCover }
        .sheet(isPresented: $ui.showTrash) { trashSheet }
    }

    /// 三个 tab 常驻、只切显隐：整理页游标与撤销栈、相似页扫描结果不因切换丢失。
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

    // MARK: - 底栏

    /// 四合一胶囊：一块玻璃包住四个按钮，与系统 tab bar 同一结构。
    private var bottomBar: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
            mineButton
        }
        .padding(6)
        .glassSurface(cornerRadius: 36)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isOn = selection == tab
        return Button {
            withAnimation(.snappy(duration: 0.26)) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 19))
                Text(tab.title)
                    .font(.system(size: 9.5, weight: .medium))
            }
            .foregroundStyle(isOn ? Color(hex: themeHex) : Theme.ink2)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isOn ? Color(hex: themeHex).opacity(0.12) : .clear,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    /// 「我的」：胶囊里的第 4 个按钮，形态与另外三个一致；它是弹出面板而不是 tab，
    /// 所以不带选中态。zoom 转场的源就挂在这个按钮上。
    @ViewBuilder
    private var mineButton: some View {
        if #available(iOS 18.0, *) {
            mineTapButton.matchedTransitionSource(id: Self.mineTransitionID, in: mineNamespace)
        } else {
            mineTapButton
        }
    }

    private var mineTapButton: some View {
        Button {
            ui.showMine = true
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 19))
                Text("我的")
                    .font(.system(size: 9.5, weight: .medium))
            }
            .foregroundStyle(Theme.ink2)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("我的")
    }

    // MARK: - 呈现

    /// 「我的」：从胶囊第 4 个按钮扩散到全屏；退出用右上角 ×，转场自动倒放。
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
