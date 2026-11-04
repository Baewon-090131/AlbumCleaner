import SwiftUI

/// 粗调：直接拖那张示意相纸来摆位置，不用看数字。
/// 上下拖 = 绳子中点高度 · 左右拖 = 邻卡露出 · 双指捏合 = 相纸大小。
/// 参数与「Debug 精调」共用同一组 UserDefaults key，改动立刻作用于整理页。
struct CoarseDebugScreen: View {
    @AppStorage("ac_dbg_paper") private var paperScale = 0.56
    @AppStorage("ac_dbg_cord") private var cordTop = 64.0
    @AppStorage("ac_dbg_sag") private var sag = 24.0
    @AppStorage("ac_dbg_peek") private var peek = 26.0

    @State private var cordStart: Double?
    @State private var peekStart: Double?
    @State private var scaleStart: Double?

    var body: some View {
        VStack(spacing: 0) {
            canvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            legend
                .padding(.horizontal, 20)
                .padding(.top, 10)

            Button("恢复默认值", role: .destructive) { reset() }
                .buttonStyle(.bordered)
                .padding(.vertical, 18)
        }
        .background(Theme.wall)
        .navigationTitle("Debug 粗调")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension CoarseDebugScreen {
    var canvas: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let scale = CGFloat(paperScale)
            let mid = CGFloat(cordTop)
            let sagPx = CGFloat(sag)
            let peekPx = CGFloat(peek)
            let paperW = min(max(w * scale, 70), w - 8)
            let paperH = min(max(paperW * 1.34, 80), max(h - mid - 16, 60))
            let sideY = max(2, mid - sagPx + 4)
            let mainY = max(2, mid + 6)

            ZStack(alignment: .topLeading) {
                sheet(width: paperW, height: paperH)
                    .offset(x: w - peekPx, y: sideY)

                sheet(width: paperW, height: paperH)
                    .offset(x: peekPx - paperW, y: sideY)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: mid - sagPx))
                    path.addQuadCurve(to: CGPoint(x: w, y: mid - sagPx),
                                      control: CGPoint(x: w / 2, y: mid + sagPx))
                }
                .stroke(Theme.ink3, lineWidth: 1.6)

                sheet(width: paperW, height: paperH)
                    .offset(x: (w - paperW) / 2, y: mainY)

                Rectangle()
                    .fill(Theme.ink2)
                    .frame(width: 7, height: 16)
                    .offset(x: w / 2 - 3.5, y: mainY - 9)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(magnifyGesture)
        }
    }

    /// 上下拖改绳子高度，左右拖改邻卡露出；两个方向独立，不会互相打架。
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if cordStart == nil, peekStart == nil {
                    cordStart = cordTop
                    peekStart = peek
                }
                if let base = cordStart {
                    cordTop = min(max(base + Double(value.translation.height), -80), 300)
                }
                if let base = peekStart {
                    peek = min(max(base + Double(value.translation.width) * 0.8, 0), 120)
                }
            }
            .onEnded { _ in
                cordStart = nil
                peekStart = nil
            }
    }

    var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if scaleStart == nil { scaleStart = paperScale }
                if let base = scaleStart {
                    paperScale = min(max(base * Double(value.magnification), 0.34), 0.92)
                }
            }
            .onEnded { _ in scaleStart = nil }
    }

    var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            row("上下拖", "绳子中点距顶 \(Int(cordTop))pt")
            row("左右拖", "邻卡露出 \(Int(peek))pt")
            row("双指捏合", "相纸宽度 \(String(format: "%.2f", paperScale))")
        }
        .font(.footnote)
        .foregroundStyle(Theme.ink2)
    }

    func row(_ gesture: String, _ detail: String) -> some View {
        HStack(spacing: 8) {
            Text(gesture)
                .foregroundStyle(Theme.ink)
                .frame(width: 64, alignment: .leading)
            Text(detail)
                .monospacedDigit()
        }
    }

    func sheet(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Theme.card)
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.line, lineWidth: 0.5)
            }
            .shadow(color: Theme.ink.opacity(0.14), radius: 4, y: 3)
    }

    func reset() {
        paperScale = 0.56
        cordTop = 64
        sag = 24
        peek = 26
    }
}
