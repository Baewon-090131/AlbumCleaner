import SwiftUI

/// 顶部临时提示（已移到回收站 / 已存入相簿）。系统没有对应的临时提示控件，这里自绘一条胶囊。
struct ToastBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.pingFang(12.5, weight: .semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Theme.nightRaised.opacity(0.96), in: Capsule())
            .overlay { Capsule().strokeBorder(Theme.nightLine, lineWidth: 0.5) }
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
