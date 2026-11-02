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
/// 不再用系统 TabView——「我的」要单独拿出来，点按后从底部上滑覆盖当前页。
struct MainTabView: View {
    @AppStorage("ac_theme") private var themeHex = "#002FA7"
    @Environment(UIState.self) private var ui
    @State private var selection: AppTab = .sort
    /// 「我的」面板的跟手下拉距离；松手超过阈值就关掉。
    @State private var mineDrag: CGFloat = 0

    var body: some View {
        @Bindable var ui = ui
        ZStack(alignment: .bottom) {
            tabContent
                // 给悬浮底栏留位
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 92) }

            if ui.showMine {
                mineSheet
                    .transition(.move(edge: .bottom))
            }

            AppTabBar(selection: $selection, mineActive: ui.showMine) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                    ui.showMine.toggle()
                    mineDrag = 0
                }
            }
        }
        .tint(Color(hex: themeHex))
        .fullScreenCover(isPresented: $ui.showTrash) {
            NavigationStack { TrashScreen() }
        }
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

    /// 「我的」：从底部上滑覆盖，顶部留一道圆角缝；抓握条下拉可关。
    private var mineSheet: some View {
        MineScreen(onClose: closeMine,
                   onDrag: { delta in mineDrag = max(0, delta) },
                   onDragEnd: { delta in
                       if delta > 110 { closeMine() } else {
                           withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { mineDrag = 0 }
                       }
                   })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
            .shadow(color: .black.opacity(0.18), radius: 20, y: -6)
            .padding(.top, 28)
            .offset(y: mineDrag)
    }

    private func closeMine() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            ui.showMine = false
            mineDrag = 0
        }
    }
}
