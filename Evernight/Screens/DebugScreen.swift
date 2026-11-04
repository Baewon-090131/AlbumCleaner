import SwiftUI

/// 整理页布局调试面板。五个滑钮直接写 UserDefaults，
/// 与 `PolaroidDeck` 的 `@AppStorage` 共用同一组 key，
/// 所以滑钮一动整理页立刻重绘，返回即可看到实际效果。
struct DebugScreen: View {
    @AppStorage("ac_dbg_paper") private var paperScale = 0.56
    @AppStorage("ac_dbg_shift") private var topShift = 48.0
    @AppStorage("ac_dbg_cord") private var cordTop = 64.0
    @AppStorage("ac_dbg_sag") private var sag = 24.0
    @AppStorage("ac_dbg_peek") private var peek = 26.0

    var body: some View {
        List {
            Section {
                preview
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                    .listRowBackground(Color.clear)
            } header: {
                Text("实时预览")
            } footer: {
                Text("参数直接作用于整理页，返回「整理」即可看到真实效果。")
            }

            Section("相纸") {
                tuner("相纸宽度", value: $paperScale, range: 0.34...0.92, format: "%.2f")
                tuner("整体上下位移", value: $topShift, range: -60...200, format: "%.0f", suffix: "pt 上提")
            }

            Section("绳子") {
                tuner("绳子中点距顶", value: $cordTop, range: -80...300, format: "%.0f", suffix: "pt")
                tuner("绳子下垂", value: $sag, range: 0...80, format: "%.0f", suffix: "pt")
                tuner("邻卡露出", value: $peek, range: 0...120, format: "%.0f", suffix: "pt")
            }

            Section {
                Button("恢复默认值", role: .destructive) { reset() }
            } footer: {
                Text("默认值：宽度 0.56 · 上提 48 · 中点距顶 64 · 下垂 24 · 露出 26")
            }
        }
        .navigationTitle("Debug 精调")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension DebugScreen {
    /// 缩小的示意稿：一条绳 + 一张相纸 + 两片露边的邻卡。
    /// `topShift` 在预览里只取三分之一权重，否则会顶出画框。
    var preview: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let scale = CGFloat(paperScale)
            let shift = CGFloat(topShift)
            let midY = min(max(CGFloat(cordTop) * 0.5, -30), h * 0.7)
            let sagPx = min(CGFloat(sag) * 0.6, h * 0.2)
            let peekPx = CGFloat(peek)
            let paperW = min(max(w * scale, 44), w - 10)
            let paperH = min(max(paperW * 1.28, 44), max(h - midY - sagPx - 14, 40))
            let paperY = midY + 6 - shift * 0.32
            let sideY = max(4, midY - sagPx + 4)

            ZStack(alignment: .topLeading) {
                paper(width: paperW, height: paperH)
                    .offset(x: w - peekPx, y: sideY)

                paper(width: paperW, height: paperH)
                    .offset(x: peekPx - paperW, y: sideY)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY - sagPx))
                    path.addQuadCurve(to: CGPoint(x: w, y: midY - sagPx),
                                      control: CGPoint(x: w / 2, y: midY + sagPx))
                }
                .stroke(Theme.ink3, lineWidth: 1.2)

                paper(width: paperW, height: paperH)
                    .offset(x: (w - paperW) / 2, y: paperY)

                Rectangle()
                    .fill(Theme.ink2)
                    .frame(width: 6, height: 14)
                    .offset(x: w / 2 - 3, y: paperY - 8)
            }
        }
        .frame(height: 210)
        .background(Theme.paperDeep)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 0.5)
        }
    }

    func paper(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Theme.card)
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Theme.line, lineWidth: 0.5)
            }
            .shadow(color: Theme.ink.opacity(0.12), radius: 3, y: 2)
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
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink2)
            }
            Slider(value: value, in: range)
                .tint(Theme.accent)
        }
        .padding(.vertical, 3)
    }

    func reset() {
        paperScale = 0.56
        topShift = 48
        cordTop = 64
        sag = 24
        peek = 26
    }
}
