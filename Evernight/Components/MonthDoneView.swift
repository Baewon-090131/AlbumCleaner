import SwiftUI

/// 翻过本月最后一张之后：照片不再出现，只留一句收尾。
/// 夜桌上直接写字，不盖卡片；标题上方一枚小的线描花，是这一页唯一的装饰。
struct MonthDoneView: View {
    var title: String = "本月整理完毕"
    /// 本次删除的结算：张数与释放体积（已格式化）。没删就整行不显示。
    var deleted: Int = 0
    var freed: String = ""

    var body: some View {
        VStack(spacing: 10) {
            NightFlower(kind: .line, opacity: 0.34)
                .frame(width: 26, height: 26)
                .padding(.bottom, 2)

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

            Text("向右滑可以再检查一遍")
                .font(.pingFang(11))
                .foregroundStyle(Theme.text3)
        }
    }
}
