import SwiftUI

/// 自定义底部栏：左边是「整理 / 相似 / 相簿」三栏胶囊，右边「我的」是独立圆形按钮。
/// 胶囊是一整块玻璃（不是三个按钮各自一块再融合——它本来就是一个整体容器）。
struct AppTabBar: View {
    /// 「我的」zoom 转场的源 id，MainTabView 的 cover 也用它。
    static let mineTransitionID = "mine"

    @Binding var selection: AppTab
    let mineActive: Bool
    /// 「我的」圆钮作为 zoom 转场的源，需要和 cover 共用同一个命名空间。
    let namespace: Namespace.ID
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

            mineButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var mineButton: some View {
        if #available(iOS 18.0, *) {
            mineLabel.matchedTransitionSource(id: Self.mineTransitionID, in: namespace)
        } else {
            mineLabel
        }
    }

    private var mineLabel: some View {
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

    private func tabButton(_ tab: AppTab) -> some View {
        let on = selection == tab && !mineActive
        return Button {
            withAnimation(.snappy(duration: 0.3)) { selection = tab }
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
