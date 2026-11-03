import SwiftUI

/// 滑动删除条（对齐参考稿「滑动确认」的形态）。
///
/// 结构只有三层：轨道胶囊、跟随进度的填充、圆钮；文字压在轨道正中。
/// - 圆钮直径 = 轨道高度 − 两侧各 4pt，**垂直居中**，与轨道左右内边距一致；
/// - 填充从轨道最左边缘起、高度与轨道相同，和圆钮共用同一个 `progress`，
///   起点时填充正好是一个圆形（宽 = 高 = 轨道高），不会露出直角边；
/// - 未到终点松手用 `.bouncy` 弹回起点，不执行；
/// - 到终点松手确认：箭头变对勾，文字变「已删除 N 项 · 释放 xx MB」。
struct SwipeDeleteButton: View {
    let count: Int
    let bytes: Int64
    var enabled: Bool = true
    let onConfirm: () -> Void

    @State private var progress: CGFloat = 0
    @State private var confirmed = false

    private let trackHeight: CGFloat = 56
    /// 圆钮与轨道边缘的内边距，四边一致，保证上下左右都对齐。
    private let inset: CGFloat = 4
    private let commitThreshold: CGFloat = 0.92

    private var knobSize: CGFloat { trackHeight - inset * 2 }
    private var fillColor: Color { enabled ? Theme.danger : Color(.systemGray3) }

    private var label: String {
        if confirmed {
            return "已删除 \(count) 项 · 释放 \(Format.bytes(bytes))"
        }
        return enabled ? "滑动进行删除" : "没有勾选项目"
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let travel = max(1, width - inset * 2 - knobSize)

            ZStack(alignment: .topLeading) {
                // 轨道
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: width, height: trackHeight)

                // 填充：从最左边起，起点宽度等于轨道高度 → 正好是一个圆
                Capsule()
                    .fill(fillColor)
                    .frame(width: inset * 2 + knobSize + travel * progress,
                           height: trackHeight)

                // 文字压在轨道正中；圆钮滑过时会自然盖住左侧
                Text(label)
                    .font(.headline)
                    .foregroundStyle(progress > 0.5 || confirmed ? Color.white : Color.secondary)
                    .frame(width: width, height: trackHeight, alignment: .center)
                    .allowsHitTesting(false)

                // 圆钮：用 offset 显式定位，避免不同 alignment 造成上下不齐
                Circle()
                    .fill(fillColor)
                    .frame(width: knobSize, height: knobSize)
                    .overlay {
                        Image(systemName: confirmed ? "checkmark" : "arrow.right")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                    .offset(x: inset + travel * progress, y: inset)
            }
            .frame(width: width, height: trackHeight)
            .contentShape(Capsule())
            .gesture(dragGesture(travel: travel))
        }
        .frame(height: trackHeight)
        .sensoryFeedback(.impact(weight: .heavy), trigger: confirmed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint(enabled ? "向右滑动到底部以彻底删除" : "")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            guard enabled, !confirmed else { return }
            confirm()
        }
    }

    private func dragGesture(travel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard enabled, !confirmed else { return }
                progress = min(1, max(0, value.translation.width / travel))
            }
            .onEnded { _ in
                guard enabled, !confirmed else { return }
                if progress >= commitThreshold {
                    confirm()
                } else {
                    // 阻尼回起点：带额外回弹，松手后先弹一下再停住，不执行删除
                    withAnimation(.bouncy(duration: 0.42, extraBounce: 0.2)) {
                        progress = 0
                    }
                }
            }
    }

    private func confirm() {
        withAnimation(.snappy(duration: 0.28)) { progress = 1 }
        confirmed = true
        // 让「已删除 …」与对勾先落稳，再执行真正的删除
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            onConfirm()
        }
    }
}
