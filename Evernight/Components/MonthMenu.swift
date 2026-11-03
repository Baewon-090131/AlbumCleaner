import SwiftUI

/// 整理页工具栏的月份切换：选项面板交给系统的 `Menu`。
/// 外观完全交给系统 toolbar（Liquid Glass 由系统按规范绘制），这里不叠任何自绘材质。
struct MonthMenu: View {
    let months: [MonthSection]
    let selectedID: String?
    let onSelect: (MonthSection) -> Void

    var body: some View {
        Menu {
            ForEach(months) { candidate in
                Button {
                    onSelect(candidate)
                } label: {
                    if candidate.id == selectedID {
                        Label(candidate.title, systemImage: "checkmark")
                    } else {
                        Text(candidate.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(months.first { $0.id == selectedID }?.title ?? "选择月份")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
        }
        .accessibilityLabel("选择月份")
    }
}
