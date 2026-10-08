import SwiftUI

/// 整理页底部操作岛：撤回 / 删除 / 下一张 / 相簿。
/// 相簿详情页只传前三个动作，岛的形状保持一致。
struct SortActionBar: View {
    let actions: [SortAction]
    let canUndo: Bool
    let hasPhoto: Bool
    let onAction: (SortAction) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(actions) { action in
                let enabled = isEnabled(action)
                Button {
                    onAction(action)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: action.symbol)
                            .font(.system(size: 20, weight: .regular))
                            .frame(width: 46, height: 46)
                            .background(.ultraThinMaterial,
                                        in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                        Text(action.title)
                            .font(.system(size: 10.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(enabled ? action.color : Color.secondary.opacity(0.4))
                .disabled(!enabled)
                .accessibilityLabel(action.title)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassSurface(cornerRadius: Theme.cornerIsland)
    }

    private func isEnabled(_ action: SortAction) -> Bool {
        action == .undo ? canUndo : hasPhoto
    }
}
