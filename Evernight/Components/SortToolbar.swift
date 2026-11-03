import SwiftUI

/// 整理页的工具栏：左边「月份 + 媒体类型」，右边「待删除」。
///
/// 全部作为独立的 `ToolbarItem` 交给系统——玻璃背景、分组间距、按压反馈都由
/// 系统按 Liquid Glass 规范处理，**不要**在这里再叠自绘玻璃（会玻璃叠玻璃）。
/// 整理页的操作（删除 / 下一张 / 撤回 / 收藏）**只走四向手势**，卡片上不放任何按钮；
/// 相簿详情不显示月份与筛选（`showsMonth == false`），标题由导航栏的相簿名承担。
struct SortToolbar: ToolbarContent {
    let months: [MonthSection]
    let selectedMonthID: String?
    let filter: MediaFilter
    let showsMonth: Bool
    let onSelectMonth: (MonthSection) -> Void
    let onSelectFilter: (MediaFilter) -> Void

    @AppStorage("ac_theme") private var themeHex = "#002FA7"

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
