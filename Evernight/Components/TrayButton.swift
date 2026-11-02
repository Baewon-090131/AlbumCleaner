import SwiftUI

/// 待删除托盘：垃圾桶圆钮 + 红色角标实时计数。整理页与相簿页的右上入口共用。
/// 点击由外层把全局 `UIState.showTrash` 置真，回收站以全屏覆盖弹出。
struct TrayButton: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(UIState.self) private var ui

    var body: some View {
        Button {
            ui.showTrash = true
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .overlay(alignment: .topTrailing) {
                    if !library.trash.isEmpty {
                        Text("\(min(library.trash.count, 99))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.danger, in: Capsule())
                            .offset(x: 10, y: -8)
                    }
                }
        }
        .accessibilityLabel("待删除")
    }
}
