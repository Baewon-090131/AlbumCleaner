import SwiftUI

@main
struct EvernightApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// 全局界面状态：任何页面的「待删除托盘」都经它弹出回收站；「我的」也经它开合。
@Observable
@MainActor
final class UIState {
    var showTrash = false
    var showMine = false
    /// 点开的照片详情。放在全局而不是某个页面里，
    /// 这样它才能盖在底栏之上、并让底栏跟着背景一起模糊。
    var detailPhoto: PhotoItem?
    /// 点击时相纸在屏幕上的矩形，详情页以它的左上角为锚点放大。
    var detailFrame: CGRect = .zero
    /// 详情页点了「待删」：先倒放回缩略图，再交给整理页走删除动效。
    var pendingTrash: PhotoItem?
    /// 整理完一个月的庆祝烟花。发射点由 `MainTabView` 按底栏上边界算，画满整屏。
    var celebrationStart: Date?
    /// 删除时的碎沙。画在 `MainTabView` 最上层，飘散不受相纸边界限制。
    var sandBurst: SandBurst?

    func celebrate() {
        celebrationStart = Date()
    }

    func playSand(_ burst: SandBurst?) {
        sandBurst = burst
    }
}

/// 顶层：壁纸 + 权限门 + 主界面。数据源在这里创建，往下用 environment 传。
struct RootView: View {
    @State private var library = PhotoLibraryService()
    @State private var ui = UIState()
    /// 相似检测结果常驻这里：切 tab 不重扫。
    @State private var similarity = SimilarityService()

    var body: some View {
        ZStack {
            Theme.wall
            content
        }
        .environment(library)
        .environment(ui)
        .environment(similarity)
        .task { await library.load() }
    }

    @ViewBuilder
    private var content: some View {
        if library.isLoading {
            LoadingStateView()
        } else if library.isDenied {
            PermissionStateView { Task { await library.load() } }
        } else {
            MainTabView()
        }
    }
}

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
            Text("正在加载照片库…")
                .font(.pingFang(13))
                .foregroundStyle(Theme.text2)
        }
        .padding(28)
        .glassSurface(cornerRadius: Theme.cornerPanel)
    }
}

private struct PermissionStateView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            NightFlower(color: Theme.accent, lineWidth: 1.5)
                .frame(width: 44, height: 44)
            Text("需要照片访问权限")
                .font(.pingFang(17, weight: .medium))
            Text("在「设置 › 隐私与安全性 › 照片」里允许 Evernight 访问照片后回到这里。")
                .font(.pingFang(12))
                .foregroundStyle(Theme.text2)
                .multilineTextAlignment(.center)
            Button("重新检查", action: retry)
                .glassButtonStyle(prominent: true)
                .tint(Theme.accent)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .glassSurface(cornerRadius: Theme.cornerPanel)
    }
}

