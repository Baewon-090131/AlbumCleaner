import SwiftUI

/// 整理页顶部的进度：一条占满整行的细轨道，下面一行报数。
/// 数字走老式打字机（等宽，天然对齐），汉字走 PingFang。
/// 报数只给两组事实——「已整理 3 / 42」与「剩余 39 张」，不重复同一个数字。
struct ProgressHeader: View {
    let processed: Int
    let total: Int
    var remaining: Int = -1
    var tint: Color = Theme.accent

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(processed) / Double(total))
    }

    private var left: Int {
        remaining >= 0 ? remaining : max(0, total - processed)
    }

    var body: some View {
        VStack(spacing: 7) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.track)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, geometry.size.width * progress))
                }
            }
            .frame(height: 5)

            HStack(spacing: 4) {
                Text("已整理")
                    .font(.pingFang(10.5))
                    .foregroundStyle(Theme.text3)
                Text("\(processed)")
                    .font(.typewriter(11, weight: .medium))
                    .foregroundStyle(Theme.text2)
                Text("/")
                    .font(.typewriter(11))
                    .foregroundStyle(Theme.text3)
                Text("\(total)")
                    .font(.typewriter(11))
                    .foregroundStyle(Theme.text3)

                Spacer(minLength: 12)

                Text("剩余")
                    .font(.pingFang(10.5))
                    .foregroundStyle(Theme.text3)
                Text("\(left)")
                    .font(.typewriter(11, weight: .medium))
                    .foregroundStyle(Theme.text2)
                Text("张")
                    .font(.pingFang(10.5))
                    .foregroundStyle(Theme.text3)
            }
        }
        .frame(height: 28)
        .animation(.smooth(duration: 0.35), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("已整理 \(processed) 项，共 \(total) 项，剩余 \(left) 项")
    }
}
