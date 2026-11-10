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

/// 主界面：系统 `TabView` 的四个页签（整理 / 相似 / 相簿 / 我的）。
///
/// 底栏交回系统：iOS 26 的原生 `TabView` 自己就是一块液态玻璃浮岛，
/// 选中态、按压回弹、安全区补偿都由系统负责，比自己拼一块玻璃更稳。
/// 「我的」不再是全屏 cover，它和另外三页一样是普通页签——切页走同一种转场。
struct MainTabView: View {
    @Environment(UIState.self) private var ui
    @Environment(PhotoLibraryService.self) private var library

    @State private var selection: AppTab = .sort

    var body: some View {
        // `@Environment` 拿到的是不可变引用，要拿 `$ui.showTrash` 这样的绑定位
        // 必须先在 body 里包一层 `@Bindable`。
        @Bindable var ui = ui

        ZStack(alignment: .bottom) {
            tabView
                .tint(Theme.accent)

            // 删除的碎沙：铺满整屏，可以飘出卡片
            if let burst = ui.sandBurst {
                SandCanvas(burst: burst)
                    .ignoresSafeArea()
                    .zIndex(3.5)
                    .id(burst.start)
            }

            // 整理完一个月的烟花：从底栏上沿附近向上喷，铺满整屏
            if let start = ui.celebrationStart {
                ConfettiBurst(start: start,
                              origins: [UnitPoint(x: 0.25, y: 0.86),
                                        UnitPoint(x: 0.5, y: 0.86),
                                        UnitPoint(x: 0.75, y: 0.86)])
                    .ignoresSafeArea()
                    .zIndex(3)
                    .id(start)
            }

            // 详情盖在整屏之上：底栏也会跟着背景一起模糊
            if let photo = ui.detailPhoto {
                PhotoDetailView(photo: photo, startFrame: ui.detailFrame,
                                onClose: { ui.detailPhoto = nil },
                                onFavorite: { library.setFavorite(photo, true) },
                                onTrash: {
                    ui.detailPhoto = nil
                    let target = photo
                    // 等倒放那 0.15s 走完，再让整理页按上滑删除的动效处理
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(200))
                        ui.pendingTrash = target
                    }
                })
                .zIndex(4)
            }
        }
        .animation(.smooth(duration: 0.3), value: ui.detailPhoto?.id)
        .onChange(of: ui.celebrationStart) { _, value in
            guard let value else { return }
            // 粒子在 3.3s 内落完，多留一点余量再把整层撤掉
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3.6))
                if ui.celebrationStart == value { ui.celebrationStart = nil }
            }
        }
        .onChange(of: ui.sandBurst?.start) { _, value in
            guard let value else { return }
            // 沙粒 1.2s 内飘完，多留一拍撤层
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1300))
                if ui.sandBurst?.start == value { ui.sandBurst = nil }
            }
        }
        .sheet(isPresented: $ui.showTrash) { trashSheet }
    }

    /// 四个页签全部交给系统 `TabView`：底栏的液态玻璃、选中态、按压回弹、
    /// 安全区补偿都由系统负责，不再自己拼一块玻璃去对齐。
    private var tabView: some View {
        TabView(selection: $selection) {
            NavigationStack { SortScreen() }
                .tabItem { Label(AppTab.sort.title, systemImage: AppTab.sort.symbol) }
                .tag(AppTab.sort)

            NavigationStack { SimilarScreen() }
                .tabItem { Label(AppTab.similar.title, systemImage: AppTab.similar.symbol) }
                .tag(AppTab.similar)

            NavigationStack { AlbumsScreen() }
                .tabItem { Label(AppTab.albums.title, systemImage: AppTab.albums.symbol) }
                .tag(AppTab.albums)

            NavigationStack { MineScreen() }
                .tabItem { Label(AppTab.mine.title, systemImage: AppTab.mine.symbol) }
                .tag(AppTab.mine)
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
