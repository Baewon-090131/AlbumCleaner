import SwiftUI

/// 顶部临时提示（已移到回收站 / 已存入相簿）。系统没有对应的临时提示控件，这里自绘一条胶囊。
struct ToastBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.black.opacity(0.78), in: Capsule())
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
