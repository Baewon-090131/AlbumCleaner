import SwiftUI

/// 整理页底部操作岛：撤回 / 删除 / 下一张 / 相簿。
///
/// 每个按钮各自是一块 Liquid Glass，交给 `GlassGroup`（`GlassEffectContainer`）合并——
/// 相邻形状会自己融合成一条岛，不需要再套一层玻璃外框。相簿详情页少一个按钮时，
/// 靠同一个 `namespace` 里的 `glassEffectID` 让剩下的玻璃平滑变形。
struct SortActionBar: View {
    let actions: [SortAction]
    let canUndo: Bool
    let hasPhoto: Bool
    let namespace: Namespace.ID
    let onAction: (SortAction) -> Void

    var body: some View {
        GlassGroup(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(actions) { action in
                    GlassActionButton(
                        action: action,
                        enabled: isEnabled(action),
                        namespace: namespace,
                        onAction: { onAction(action) }
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: actions)
    }

    private func isEnabled(_ action: SortAction) -> Bool {
        action == .undo ? canUndo : hasPhoto
    }
}

private struct GlassActionButton: View {
    let action: SortAction
    let enabled: Bool
    let namespace: Namespace.ID
    let onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            VStack(spacing: 3) {
                Image(systemName: action.symbol)
                    .font(.system(size: 20, weight: .regular))
                Text(action.title)
                    .font(.system(size: 10.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? action.color : Color.secondary.opacity(0.45))
        .disabled(!enabled)
        .accessibilityLabel(action.title)
        // glassEffect 放在布局与外观之后；interactive 让玻璃响应按压
        .glassSurface(cornerRadius: 22, morphID: action.id, in: namespace, interactive: true)
    }
}
