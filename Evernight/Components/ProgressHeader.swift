import SwiftUI

/// 整理页顶部的细进度条：横贯一条轨道 + 右侧剩余数量。
/// 不再套玻璃胶囊外壳——外壳会多占约 20pt 高度，也会与顶栏的胶囊重复。
struct ProgressHeader: View {
    let processed: Int
    let total: Int
    let remaining: Int
    var tint: Color = Theme.accent

    private var progress: Double {
        guard total > 0 else { return 1 }
        return min(1, Double(processed) / Double(total))
    }

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.18))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, geometry.size.width * progress))
                }
                .frame(height: 6)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 18)

            Text("\(remaining)")
                .font(.headline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 2)
        .frame(height: 22)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("已处理 \(processed) 项，共 \(total) 项，剩余 \(remaining) 项")
    }
}
