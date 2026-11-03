import SwiftUI

/// 整理页的工具栏：左边「月份 + 媒体类型」，右边「撤回 + 待删除」。
///
/// 全部作为独立的 `ToolbarItem` 交给系统——玻璃背景、分组间距、按压反馈都由
/// 系统按 Liquid Glass 规范处理，**不要**在这里再叠自绘玻璃（会玻璃叠玻璃）。
/// 卡片上不放任何按钮：删除 / 收藏走上滑、下滑手势，左右拖动是浏览绳子，
/// 「下一张」与「撤回」不再由手势承担，撤回因此回到顶栏。
struct SortToolbar: ToolbarContent {
    let months: [MonthSection]
    let selectedMonthID: String?
    let filter: MediaFilter
    let showsMonth: Bool
    let canUndo: Bool
    let onSelectMonth: (MonthSection) -> Void
    let onSelectFilter: (MediaFilter) -> Void
    let onUndo: () -> Void

    @AppStorage("ac_theme_v2") private var themeHex = "#2B4A6F"

    var body: some ToolbarContent {
        if showsMonth {
            ToolbarItem(placement: .topBarLeading) {
                MonthMenu(months: months,
                          selectedID: selectedMonthID,
                          onSelect: onSelectMonth)
            }

            ToolbarItem(placement: .topBarLeading) {
                filterMenu
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            TrayButton()
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!canUndo)
            .accessibilityLabel("撤回")
        }
    }

    /// 媒体类型筛选：走系统 `Menu` + 主题色 tint，不填实底（toolbar 按钮不加自定义底色）。
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
            Label(filter.rawValue, systemImage: filter.symbol)
                .font(.subheadline.weight(.medium))
        }
        .tint(Color(hex: themeHex))
        .accessibilityLabel("媒体类型")
    }
}
