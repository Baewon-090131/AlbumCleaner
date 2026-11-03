import SwiftUI

/// 卡片右侧竖排的圆形玻璃钮（对应参考视频 2 的视频页右侧图标列）。
/// 浮在卡片上，不占布局高度；每个按钮各自一块玻璃，交给 GlassGroup 融合。
struct SortSideBar: View {
    let actions: [SortAction]
    let canUndo: Bool
    let hasPhoto: Bool
    let namespace: Namespace.ID
    let onAction: (SortAction) -> Void

    var body: some View {
        GlassGroup(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(actions) { action in
                    Button {
                        onAction(action)
                    } label: {
                        Image(systemName: action.symbol)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isEnabled(action) ? action.color : Color.secondary.opacity(0.45))
                    .disabled(!isEnabled(action))
                    .accessibilityLabel(action.title)
                    .glassSurface(cornerRadius: 22, morphID: action.id, in: namespace, interactive: true)
                }
            }
        }
        .animation(.snappy(duration: 0.32), value: actions)
    }

    private func isEnabled(_ action: SortAction) -> Bool {
        action == .undo ? canUndo : hasPhoto
    }
}
