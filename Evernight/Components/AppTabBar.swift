import SwiftUI

/// 自定义底部栏：左边是「整理 / 相似 / 相簿」三栏胶囊，右边「我的」是独立圆形按钮。
/// 胶囊是一整块玻璃（不是三个按钮各自一块再融合——它本来就是一个整体容器）。
struct AppTabBar: View {
    @Binding var selection: AppTab
    let mineActive: Bool
    let onMine: () -> Void

    @AppStorage("ac_theme") private var themeHex = "#002FA7"

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(AppTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(6)
            .glassSurface(cornerRadius: 36)

            Button(action: onMine) {
                VStack(spacing: 3) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 24))
                    Text("我的")
                        .font(.system(size: 9.5, weight: .medium))
                }
                .foregroundStyle(mineActive ? Color(hex: themeHex) : Color.secondary)
                .frame(width: 62, height: 62)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassSurface(cornerRadius: 31, interactive: true)
            .accessibilityLabel("我的")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let on = selection == tab && !mineActive
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 19))
                Text(tab.title)
                    .font(.system(size: 9.5, weight: .medium))
            }
            .foregroundStyle(on ? Color(hex: themeHex) : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                if on {
                    Capsule().fill(Color(hex: themeHex).opacity(0.12))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}
