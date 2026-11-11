import SwiftUI

/// 翻过本月最后一张之后：照片不再出现，只留一句收尾。
///
/// 花在**卡片区正中**长出来：尺寸 0 → 目标、透明度 0 → 1 渐显；
/// 同时转角在 0.5s 内从 45° 转到 135°——用 `spring(duration:bounce:)`，
/// 也就是先快后慢、末尾带一点回弹的非线性曲线，不是匀速也不是线性缓动。
/// 文字排在花下方，不与花重叠。
struct MonthDoneView: View {
    var title: String = "本月整理完毕"
    /// 本次删除的结算：张数与释放体积（已格式化）。没删就整行不显示。
    var deleted: Int = 0
    var freed: String = ""
    /// 单轮制下还有下一轮可开；nil 表示整月都翻完了，不给这个按钮。
    var onNextRound: (() -> Void)?
    /// 有待删除项时给一个直达入口。
    var onOpenTrash: (() -> Void)?

    /// 与「待删除」空态同一尺寸，两页的记号看起来是一套东西。
    private let flowerSize: CGFloat = NightEmptyState.defaultFlowerSize

    @State private var appeared = false
    /// 花的转角：0.5s 内 45° → 135°。
    @State private var angle: Double = 45

    /// 旋转：0.5s、带 0.22 的回弹。`duration` 是显式时长，
    /// 比 `response` 更能保证「0.5s 内转完」。
    private var turnSpring: Animation { .spring(duration: 0.5, bounce: 0.22) }
    /// 长大与渐显：同一族弹性曲线，稍慢一点，让花先转、再稳稳落定。
    private var bloomSpring: Animation { .spring(duration: 0.62, bounce: 0.12) }

    var body: some View {
        // 以「花」为唯一的布局基准：花占满容器、居中于卡片区；
        // 文字用 overlay 挂在花下面，不参与测量，所以不会把花挤离中心。
        NightFlower(kind: .line, opacity: 1, angle: angle)
            .frame(width: flowerSize, height: flowerSize)
            .scaleEffect(appeared ? 1 : 0.001)
            .opacity(appeared ? 1 : 0)
            .animation(turnSpring, value: angle)
            .animation(bloomSpring, value: appeared)
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.pingFang(20, weight: .semibold))
                        .foregroundStyle(Theme.text)

                    if deleted > 0 {
                        HStack(spacing: 4) {
                            Text("本次删除")
                                .font(.pingFang(12))
                                .foregroundStyle(Theme.text3)
                            Text("\(deleted)")
                                .font(.typewriter(12, weight: .semibold))
                                .foregroundStyle(Theme.accentText)
                            Text("张 · 释放")
                                .font(.pingFang(12))
                                .foregroundStyle(Theme.text3)
                            Text(freed)
                                .font(.typewriter(12, weight: .semibold))
                                .foregroundStyle(Theme.text2)
                        }
                    }

                    // 动作：有下一轮就给「继续整理」，否则只留回看提示
                    if let onNextRound {
                        HStack(spacing: 10) {
                            pill("继续整理", filled: true, action: onNextRound)
                            if let onOpenTrash {
                                pill("看待删除", filled: false, action: onOpenTrash)
                            }
                        }
                        .padding(.top, 6)
                    } else {
                        Text("向右滑可以再检查一遍")
                            .font(.pingFang(11))
                            .foregroundStyle(Theme.text3)
                    }
                }
                .fixedSize()
                // 从花的下沿再让 34 起排
                .offset(y: flowerSize + 30)
                .opacity(appeared ? 1 : 0)
                .animation(bloomSpring, value: appeared)
            }
            .onAppear(perform: bloom)
    }

    /// 结算页的两个按钮。克制：主按钮实心、次按钮只有描边。
    private func pill(_ text: String,
                      filled: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.pingFang(13, weight: .semibold))
                .foregroundStyle(filled ? Theme.paper : Theme.text2)
                .padding(.horizontal, 18)
                .frame(height: 36)
                .background {
                    if filled {
                        Capsule().fill(Theme.accent)
                    } else {
                        Capsule().strokeBorder(Theme.text.opacity(0.18), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    /// 下一帧再开动画：首次渲染必须落在「不存在」那一帧，否则直接从终态出现、看不到过程。
    private func bloom() {
        withoutAnimation {
            appeared = false
            angle = 45
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(16))
            angle = 135
            appeared = true
        }
    }
}
