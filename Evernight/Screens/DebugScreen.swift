import SwiftUI

/// 整理页卡片区的实时调参面板。
///
/// 参数直接写 UserDefaults，`SwipeDeck` 用同名 `@AppStorage` 读，
/// 所以拖滑钮时返回「整理」就能看到真实手感，不用重跑。
struct DebugScreen: View {
    @AppStorage("ac_deck_w") private var cardWidthRatio = 0.98
    @AppStorage("ac_deck_h") private var cardHeightRatio = 1.0
    @AppStorage("ac_deck_swap") private var swap = 88.0
    @AppStorage("ac_deck_del") private var del = 104.0
    @AppStorage("ac_deck_tray") private var tray = 64.0

    var body: some View {
        List {
            Section {
                preview
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    .listRowBackground(Color.clear)
            } header: {
                Text("实时预览")
            } footer: {
                Text("按 3:4 竖图示意，实际尺寸随照片比例在这两条上限内缩放。")
            }

            Section("卡片") {
                tuner("最大宽度", value: $cardWidthRatio, range: 0.70...1.0, format: "%.2f")
                tuner("最大高度", value: $cardHeightRatio, range: 0.60...1.0, format: "%.2f")
            }

            Section("手感") {
                tuner("左右切张阈值", value: $swap, range: 50...160, format: "%.0f", suffix: "pt")
                tuner("上滑删除阈值", value: $del, range: 60...200, format: "%.0f", suffix: "pt")
                tuner("下拉托盘阈值", value: $tray, range: 30...140, format: "%.0f", suffix: "pt")
            }

            Section {
                Button("恢复默认值", role: .destructive) { reset() }
            } footer: {
                Text("默认：宽 0.98 · 高 1.0 · 切张 88 · 删除 104 · 托盘 64")
            }
        }
        .navigationTitle("整理手感")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension DebugScreen {
    /// 缩小示意：一块夜底上按当前比例摆一张卡，外框就是可用区。
    var preview: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxW = w * CGFloat(cardWidthRatio)
            let maxH = h * CGFloat(cardHeightRatio)
            let card = sampleCardSize(maxW: maxW, maxH: maxH)

            ZStack {
                Rectangle()
                    .fill(Theme.text.opacity(0.04))
                    .frame(width: maxW, height: maxH)

                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .fill(Theme.nightPanel)
                    .frame(width: card.width, height: card.height)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                            .strokeBorder(Theme.text.opacity(0.10), lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.42), radius: 12, y: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 240)
        .background(Theme.night, in: RoundedRectangle(cornerRadius: Theme.cornerPanel,
                                                     style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous)
                .strokeBorder(Theme.nightLine, lineWidth: 0.5)
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    /// 按 3:4 竖图算示意卡尺寸。抽成普通函数，`ViewBuilder` 里只放视图。
    func sampleCardSize(maxW: CGFloat, maxH: CGFloat) -> CGSize {
        let ratio: CGFloat = 3.0 / 4.0
        let fullHeight = maxW / ratio
        if fullHeight <= maxH { return CGSize(width: maxW, height: fullHeight) }
        return CGSize(width: maxH * ratio, height: maxH)
    }

    func tuner(_ title: String,
               value: Binding<Double>,
               range: ClosedRange<Double>,
               format: String,
               suffix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue) + suffix)
                    .font(.typewriter(13))
                    .foregroundStyle(Theme.text2)
            }
            Slider(value: value, in: range)
                .tint(Theme.accent)
        }
        .padding(.vertical, 3)
    }

    func reset() {
        cardWidthRatio = 0.98
        cardHeightRatio = 1.0
        swap = 88
        del = 104
        tray = 64
    }
}
