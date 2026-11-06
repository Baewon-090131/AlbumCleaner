import SwiftUI

/// 全局设计令牌：长夜 · 相纸 · 封蜡红。
///
/// 取色逻辑：夜紫近黑的桌面，骨白相纸，绯红只做“封蜡”级别的重音。
/// 中性色全部带一点紫调（不用纯黑纯白），阴影走纯黑、描边走骨白的低透明，
/// 这样界面像一张夜里被灯照到的相纸，而不是系统深色模式。
enum Theme {
    // MARK: - 夜桌
    /// 桌面底色（最深）
    static let night = Color(hex: "#120E18")
    /// 抬升面：底栏、胶囊、弹层
    static let nightRaised = Color(hex: "#1A1424")
    /// 面板：分组、sheet
    static let nightPanel = Color(hex: "#241B31")
    /// 夜上的发丝线
    static let nightLine = Color(hex: "#EFE8F2").opacity(0.12)
    static let nightLineSoft = Color(hex: "#EFE8F2").opacity(0.07)

    // MARK: - 夜上文字
    static let text = Color(hex: "#EFE8F2")
    static let text2 = Color(hex: "#A99DB8")
    static let text3 = Color(hex: "#8C7FA0")

    // MARK: - 相纸
    static let paper = Color(hex: "#F3ECE7")
    static let paperDeep = Color(hex: "#E7DDD8")
    static let card = Color(hex: "#F3ECE7")

    // MARK: - 纸上墨色
    static let ink = Color(hex: "#241D2A")
    static let ink2 = Color(hex: "#6B6170")
    static let ink3 = Color(hex: "#5F5566")
    /// 纸上的发丝线
    static let line = Color(hex: "#241D2A").opacity(0.10)

    // MARK: - 封蜡红（全 App 唯一的强调色）
    static let accent = Color(hex: "#C42340")
    /// 夜色上的小红字 / 图标：提亮一档，保证 4.5:1
    static let accentText = Color(hex: "#E0556F")
    static let danger = Color(hex: "#C42340")
    static let success = Color(hex: "#6E8B7B")
    static let warning = Color(hex: "#B07A2E")
    static let info = Color(hex: "#7A8FA6")

    /// 深色统计卡（与面板同一层）
    static let dark = Color(hex: "#1A1424")

    // MARK: - 面层
    /// 轨道 / 输入底
    static let track = Color(hex: "#EFE8F2").opacity(0.10)
    /// 压在照片上的暗角标底
    static let scrim = Color(hex: "#0B0810")

    static let cornerIsland: CGFloat = 28
    static let cornerPanel: CGFloat = 28
    static let cornerTile: CGFloat = 20
    /// 照片卡：比面板略收，配合 16pt 页边距不显笨重
    static let cornerCard: CGFloat = 28
    static let cornerPlate: CGFloat = 34

    /// 夜桌：一层极缓的紫黑渐变，没有光晕、没有木纹。
    static var wall: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "#171020"), location: 0),
                .init(color: Color(hex: "#120E18"), location: 0.55),
                .init(color: Color(hex: "#0F0B14"), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

extension Font {
    /// 数字 / 英文：老式打字机（等宽）。
    static func typewriter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// 汉字：系统字族（iOS 上是 PingFang SC）。
    static func pingFang(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// 旧版花字，仅保留给还没换掉的页面。
    static func scriptItalic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif).italic()
    }
}

/// 汉字走 PingFang、拉丁与数字走打字机。
/// 把一串文本按字符拆成 run，再拼成一个 `Text`，这样同一行里两种字族能共存。
enum MixedType {
    static func text(_ string: String, size: CGFloat, weight: Font.Weight = .regular) -> Text {
        var result = Text("")
        for (run, ascii) in runs(of: string) {
            let font: Font = ascii ? .typewriter(size, weight: weight)
                                  : .pingFang(size, weight: weight)
            result = result + Text(run).font(font)
        }
        return result
    }

    /// 连续的同族字符合成一段：ASCII 字母数字算“西文”，其余（含中文标点）算中文。
    private static func runs(of string: String) -> [(String, Bool)] {
        var output: [(String, Bool)] = []
        var buffer = ""
        var currentIsASCII: Bool?
        for ch in string {
            let isASCII = ch.isASCII && (ch.isLetter || ch.isNumber || ch.isPunctuation || ch == " ")
            if currentIsASCII == nil || currentIsASCII == isASCII {
                buffer.append(ch)
                currentIsASCII = isASCII
            } else {
                output.append((buffer, currentIsASCII ?? false))
                buffer = String(ch)
                currentIsASCII = isASCII
            }
        }
        if !buffer.isEmpty { output.append((buffer, currentIsASCII ?? false)) }
        return output
    }
}

extension Color {
    /// 解析 "#RRGGBB"；解析失败时退回封蜡红。
    init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let raw = UInt32(value, radix: 16) else {
            self = Theme.accent
            return
        }
        self.init(
            red: Double((raw >> 16) & 0xFF) / 255,
            green: Double((raw >> 8) & 0xFF) / 255,
            blue: Double(raw & 0xFF) / 255
        )
    }
}
