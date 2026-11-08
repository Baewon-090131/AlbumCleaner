import SwiftUI

/// 空态：夜底上一枚大的骨白花线，下面一行标题、一行说明。
///
/// 系统 `ContentUnavailableView` 在深色底上是一个灰图标，和这套界面里"素材的花"的
/// 记号语言不搭。这里统一用素材拆出来的线描花压底，四个页面的空态看起来是同一套东西。
struct NightEmptyState: View {
    let title: String
    var message: String?
    /// 花的大小。列表页 116，整屏空态可以给到 150。
    var flowerSize: CGFloat = 116

    var body: some View {
        VStack(spacing: 0) {
            NightFlower(kind: .line, opacity: 0.16, angle: 8)
                .frame(width: flowerSize, height: flowerSize)
                .padding(.bottom, 18)

            Text(title)
                .font(.pingFang(16, weight: .medium))
                .foregroundStyle(Theme.text)

            if let message {
                Text(message)
                    .font(.pingFang(12))
                    .foregroundStyle(Theme.text3)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
