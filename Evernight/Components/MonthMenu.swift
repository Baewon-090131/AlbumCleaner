import SwiftUI

/// 整理页左上角的月份切换：外观是玻璃胶囊，选项面板交给系统的 `Menu`。
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
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
        }
        .accessibilityLabel("选择月份")
    }
}
