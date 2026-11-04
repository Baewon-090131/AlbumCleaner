import SwiftUI

/// 整理页顶部的进度条：一条轨道占满整行，下面一行小字报数。
/// 数字走老式打字机（等宽），汉字用系统默认字体。
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
        VStack(spacing: 5) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.ink.opacity(0.14))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, geometry.size.width * progress))
                }
            }
            .frame(height: 5)

            HStack(spacing: 4) {
                Text("已整理")
                    .font(.system(size: 10))
                Text("\(processed)")
                    .font(.typewriter(10, weight: .medium))
                Spacer(minLength: 0)
                Text("剩余")
                    .font(.system(size: 10))
                Text("\(left) / \(total)")
                    .font(.typewriter(10, weight: .medium))
            }
            .foregroundStyle(Theme.ink.opacity(0.62))
        }
        .frame(height: 22)
        .animation(.snappy(duration: 0.35), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("已整理 \(processed) 项，共 \(total) 项，剩余 \(left) 项")
    }
}
