import SwiftUI

/// 整理页顶栏：月份胶囊 + 媒体类型胶囊 + 撤回 / 待删除圆钮。
/// 对应参考视频的「[照片 ▾]  ↺ 🗑」一行；月份选择是既有功能，保留在最左。
/// 相簿详情（`albumName != nil`）改显示返回 + 相簿名，不显示月份与筛选。
struct SortTopBar: View {
    let months: [MonthSection]
    let selectedMonthID: String?
    let filter: MediaFilter
    let canUndo: Bool
    var albumName: String? = nil
    let onSelectMonth: (MonthSection) -> Void
    let onSelectFilter: (MediaFilter) -> Void
    let onUndo: () -> Void
    var onBack: () -> Void = {}

    @AppStorage("ac_theme") private var themeHex = "#002FA7"

    var body: some View {
        HStack(spacing: 8) {
            if let albumName {
                backButton(albumName)
            } else {
                MonthMenu(months: months,
                          selectedID: selectedMonthID,
                          onSelect: onSelectMonth)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassSurface(cornerRadius: 17, interactive: true)
                filterMenu
            }

            Spacer(minLength: 8)

            undoButton
            TrayButton()
                .frame(width: 34, height: 34)
                .glassSurface(cornerRadius: 17, interactive: true)
        }
        .frame(height: 44)
    }

    private func backButton(_ name: String) -> some View {
        Button(action: onBack) {
            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .frame(height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("返回相簿")
    }

    /// 媒体类型筛选：主题色实底胶囊，视觉焦点（对应视频里的绿色胶囊）。
    private var filterMenu: some View {
        Menu {
            ForEach(MediaFilter.allCases) { option in
                Button {
                    onSelectFilter(option)
                } label: {
                    if option == filter {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: filter.symbol)
                    .font(.caption.weight(.semibold))
                Text(filter.rawValue)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(hex: themeHex), in: Capsule())
        }
        .accessibilityLabel("媒体类型")
    }

    private var undoButton: some View {
        Button(action: onUndo) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 15, weight: .medium))
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(canUndo ? Color.primary : Color.secondary.opacity(0.45))
        .disabled(!canUndo)
        .glassSurface(cornerRadius: 17, interactive: true)
        .accessibilityLabel("撤回")
    }
}
