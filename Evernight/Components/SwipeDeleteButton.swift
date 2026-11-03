import SwiftUI

/// 滑动删除条：轨道上有一个圆钮，向右拖到底才确认。
///
/// - 轨道文字「滑动进行删除」，圆钮与轨道填充跟随同一拖动进度；
/// - 未到终点松手：带阻尼弹回起点，不执行；
/// - 到终点松手：箭头变对勾，文字变「已删除 N 项 · 释放 xx MB」，回调 `onConfirm`。
struct SwipeDeleteButton: View {
    let count: Int
    let bytes: Int64
    var enabled: Bool = true
    let onConfirm: () -> Void

    /// 0...1 的拖动进度，驱动圆钮位置与轨道填充。
    @State private var progress: CGFloat = 0
    /// 已确认：锁定在终点并显示对勾。
    @State private var confirmed = false

    private let trackHeight: CGFloat = 56
    private let knobInset: CGFloat = 4
    /// 过这个进度松手就算到终点（留一点余量，不必精确拖到边缘）。
    private let commitThreshold: CGFloat = 0.92

    private var knobSize: CGFloat { trackHeight - knobInset * 2 }
    private var fillColor: Color { enabled ? Theme.danger : Color(.systemGray3) }

    private var label: String {
        if confirmed {
            return "已删除 \(count) 项 · 释放 \(Format.bytes(bytes))"
        }
        return enabled ? "滑动进行删除" : "没有勾选项目"
    }

    var body: some View {
        GeometryReader { geometry in
            let travel = max(1, geometry.size.width - knobSize - knobInset * 2)

            ZStack(alignment: .leading) {
                Capsule().fill(Color(.tertiarySystemFill))

                // 填充与圆钮共用同一个 progress
                Capsule()
                    .fill(fillColor)
                    .frame(width: knobInset + knobSize + travel * progress)

                Text(label)
                    .font(.headline)
                    .foregroundStyle(progress > 0.55 || confirmed ? Color.white : Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.leading, knobSize)

                knob.offset(x: knobInset + travel * progress)
            }
            .frame(width: geometry.size.width, height: trackHeight)
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

    private var knob: some View {
        Circle()
            .fill(.white)
            .frame(width: knobSize, height: knobSize)
            .overlay {
                Image(systemName: confirmed ? "checkmark" : "arrow.right")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(fillColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
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
                    // 阻尼回起点：bouncy 带额外回弹，松手后先回弹再停住，不执行删除
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
