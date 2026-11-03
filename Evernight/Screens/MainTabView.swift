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

/// 主界面：三个 tab 的内容区 + 底部一行（3 栏玻璃胶囊 +「我的」独立圆形玻璃钮）。
///
/// 为什么不用系统 `TabView`：系统 tab bar 是整体渲染的，**没有公开 API** 能在它右侧
/// 再并排放一个独立圆钮（`tabViewBottomAccessory` 只能显示在底栏上方或内联）。
/// 所以底栏用一个容器承载，玻璃走 Apple 官方的 `glassEffect` / `GlassEffectContainer`
/// —— 材质由系统渲染，只是布局由我们决定。
struct MainTabView: View {
    @AppStorage("ac_theme_v2") private var themeHex = "#2B4A6F"
    @Environment(UIState.self) private var ui
    @State private var selection: AppTab = .sort
    /// 「我的」的 zoom 转场：源是底栏圆钮，目标是全屏 cover。
    @Namespace private var mineNamespace

    private static let mineTransitionID = "mine"
    /// 底栏占位：圆钮 62 + 下边距 10 + 呼吸 20
    private static let barReserve: CGFloat = 92
    private static let knobSize: CGFloat = 62

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

    private var bottomBar: some View {
        GlassGroup(spacing: 12) {
            HStack(spacing: 10) {
                tabPill
                mineKnob
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    /// 三栏胶囊：一块玻璃包住三个按钮（系统 tab bar 正是这个结构）。
    private var tabPill: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .glassSurface(cornerRadius: 36)
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

    /// 「我的」：独立圆形玻璃，与胶囊同一行。
    @ViewBuilder
    private var mineKnob: some View {
        if #available(iOS 18.0, *) {
            mineButton.matchedTransitionSource(id: Self.mineTransitionID, in: mineNamespace)
        } else {
            mineButton
        }
    }

    private var mineButton: some View {
        Button {
            ui.showMine = true
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24))
                Text("我的")
                    .font(.system(size: 9.5, weight: .medium))
            }
            .foregroundStyle(ui.showMine ? Color(hex: themeHex) : Theme.ink2)
            .frame(width: Self.knobSize, height: Self.knobSize)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassSurface(cornerRadius: Self.knobSize / 2, interactive: true)
        .accessibilityLabel("我的")
    }

    // MARK: - 呈现

    /// 「我的」：从底栏圆钮扩散到全屏；退出用右上角 ×，转场自动倒放。
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
