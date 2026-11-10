import SwiftUI

/// 空态：夜底上一枚大的骨白花线，下面一行标题、一行说明。
///
/// 系统 `ContentUnavailableView` 在深色底上是一个灰图标，和这套界面里"素材的花"的
/// 记号语言不搭。这里统一用素材拆出来的线描花压底，四个页面的空态看起来是同一套东西。
struct NightEmptyState: View {
    /// 与「月终」页共用同一个基准尺寸，两页的记号看起来是一套东西。
    static let flowerSize: CGFloat = 116

    let title: String
    var message: String?
    /// 花的大小。列表页 116，整屏空态可以给到 150。
    var flowerSize: CGFloat = NightEmptyState.flowerSize
    /// 花要不要一直慢慢转。「待删除」空态要它转（20s 一圈匀速），其余页保持静止。
    var spins = false

    /// 旋转角。静止时固定在 8°（素材里那个随手盖章的角度）。
    @State private var angle: Double = 8

    private static let spinPeriod: Double = 20

    var body: some View {
        VStack(spacing: 0) {
            NightFlower(kind: .line, opacity: 0.16, angle: angle)
                .frame(width: flowerSize, height: flowerSize)
                .padding(.bottom, 18)
                .onAppear {
                    guard spins else { return }
                    // 20s 一圈、匀速、不停：线性曲线 + 无限重复，不加任何缓动
                    angle = 8
                    withAnimation(.linear(duration: Self.spinPeriod)
                        .repeatForever(autoreverses: false)) {
                        angle = 8 + 360
                    }
                }

            Text(title)
                .font(.pingFang(16, weight: .semibold))
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
