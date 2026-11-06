import SwiftUI

/// 一次彻底删除的结果，交给滑轨展示。
struct DeleteResult: Equatable {
    let count: Int
    let bytes: Int64
}

/// 滑动删除条。形态对齐参考组件（slide-button）：
///
/// - 轨道是一条浅灰胶囊，圆钮与轨道同高、贴左边缘起步，拖动时放大 1.05；
/// - 填充条永远从轨道最左边缘长出来，宽度 = 圆钮位移 + 8（略盖住圆钮接缝）；
/// - 阈值 0.9，未到阈值松手用 bouncy 回弹归零，不执行；
/// - 到阈值后**保持整条滑轨**（不收缩、不显示转圈），等外部删除完成；
/// - 外部给出 `result` 后才收缩到 66%，换成对勾与「已删除 N 项 · 释放 …」。
struct SwipeDeleteButton: View {
    let count: Int
    let bytes: Int64
    var enabled: Bool = true
    /// 外部正在执行删除：保持满轨、禁用手势。
    var isDeleting = false
    /// 外部删除完成后的结果；非 nil 时进入完成态。
    var result: DeleteResult? = nil
    let onConfirm: () -> Void

    @State private var progress: CGFloat = 0
    @State private var armed = false
    @State private var isDragging = false

    private let trackHeight: CGFloat = 50
    private let commitThreshold: CGFloat = 0.9
    /// 完成态相对全宽的占比（参考组件 12rem → 8rem）。
    private let collapsedRatio: CGFloat = 0.66
    /// 填充比圆钮多出来的宽度，避免两者之间露缝。
    private let fillOverlap: CGFloat = 8

    private var done: Bool { result != nil }

    private var fillColor: Color { enabled ? Theme.danger : Theme.text.opacity(0.16) }

    private var label: String {
        if let result {
            return "已删除 \(result.count) 项 · 释放 \(Format.bytes(result.bytes))"
        }
        return enabled ? "滑动进行删除" : "没有勾选项目"
    }

    var body: some View {
        GeometryReader { geometry in
            let full = geometry.size.width
            let trackWidth = done ? full * collapsedRatio : full
            // 圆钮与轨道同高，可移动距离就是轨道长减去圆钮直径
            let travel = max(1, trackWidth - trackHeight)

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(Theme.track)
                    .frame(width: trackWidth, height: trackHeight)

                // 填充：贴左边缘起，起点宽度 = 轨道高（正好是一个圆）
                Capsule()
                    .fill(fillColor)
                    .frame(width: min(trackWidth, trackHeight + travel * progress + fillOverlap),
                           height: trackHeight)

                if done {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text(label)
                            .font(.pingFang(13, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .frame(width: trackWidth, height: trackHeight, alignment: .center)
                    .transition(.opacity)
                } else {
                    Text(label)
                        .font(.headline)
                        .foregroundStyle(progress > 0.5 ? Theme.paper : Theme.text2)
                        .frame(width: trackWidth, height: trackHeight, alignment: .center)
                        .opacity(1 - progress * 1.4)
                        .allowsHitTesting(false)
                }

                // 圆钮：贴左边缘起步，用 offset 显式定位保证上下左右对齐
                Circle()
                    .fill(fillColor)
                    .frame(width: trackHeight, height: trackHeight)
                    .overlay {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color.black.opacity(0.5), radius: 4, y: 2)
                    .scaleEffect(isDragging ? 1.05 : 1)
                    .offset(x: travel * progress)
                    .opacity(armed || done ? 0 : 1)
            }
            .frame(width: trackWidth, height: trackHeight)
            .frame(width: full, height: trackHeight, alignment: .center)
            .contentShape(Capsule())
            .gesture(dragGesture(travel: travel))
        }
        .frame(height: trackHeight)
        .sensoryFeedback(.impact(weight: .heavy), trigger: armed)
        .onChange(of: isDeleting) { old, new in
            // 删除失败：退回起点，允许重新滑一次
            guard old, !new, !done else { return }
            withAnimation(.bouncy(duration: 0.3, extraBounce: 0.12)) {
                progress = 0
                armed = false
            }
        }
        .onChange(of: result) { old, new in
            // 结果被清空（彩纸播完）：滑轨回到可再次滑动的起始态
            guard old != nil, new == nil else { return }
            withAnimation(.snappy(duration: 0.3)) {
                progress = 0
                armed = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint(enabled ? "向右滑动到底部以彻底删除" : "")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            guard enabled, !armed, !isDeleting, !done else { return }
            confirm()
        }
    }

    private func dragGesture(travel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard enabled, !armed, !isDeleting, !done else { return }
                isDragging = true
                progress = min(1, max(0, value.translation.width / travel))
            }
            .onEnded { _ in
                guard enabled, !armed, !isDeleting, !done else { return }
                isDragging = false
                if progress >= commitThreshold {
                    confirm()
                } else {
                    withAnimation(.bouncy(duration: 0.3, extraBounce: 0.12)) {
                        progress = 0
                    }
                }
            }
    }

    private func confirm() {
        withAnimation(.snappy(duration: 0.32)) {
            progress = 1
            armed = true
        }
        // 让滑轨先落稳，再开始真正的删除；期间保持满轨，不显示转圈
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            onConfirm()
        }
    }
}
