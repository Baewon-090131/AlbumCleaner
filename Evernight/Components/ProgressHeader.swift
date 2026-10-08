import SwiftUI

/// 整理页顶部的进度胶囊：一条轨道 + 游标 + 右侧剩余数量。
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
        HStack(spacing: 14) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.18))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, geometry.size.width * progress))
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                        .offset(x: geometry.size.width * progress - 8)
                }
                .frame(height: 6)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 20)

            Text("\(remaining)")
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Theme.success)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .glassSurface(cornerRadius: 22)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("已处理 \(processed) 项，共 \(total) 项，剩余 \(remaining) 项")
    }
}
