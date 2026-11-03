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
                .font(.subheadline)
                .foregroundStyle(Theme.ink2)
        }
        .padding(28)
        .glassSurface(cornerRadius: Theme.cornerPanel)
    }
}

private struct PermissionStateView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
            Text("需要照片访问权限")
                .font(.headline)
            Text("在「设置 › 隐私与安全性 › 照片」里允许 Evernight 访问照片后回到这里。")
                .font(.footnote)
                .foregroundStyle(Theme.ink2)
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
