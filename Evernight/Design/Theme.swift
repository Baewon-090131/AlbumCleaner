import SwiftUI

/// 全局设计令牌：复古胶片色板 + 圆角。
///
/// 取色逻辑：奶油纸底 + 深靛蓝主色 + 砖红 / 橄榄 / 赭黄点缀。
/// 中性色全部带暖调（不用纯黑纯白），阴影与描边都跟着暖色走，
/// 这样整块界面看起来像一张旧相纸，而不是默认的系统冷灰。
enum Theme {
    // 纸面
    static let paper = Color(red: 245 / 255, green: 239 / 255, blue: 227 / 255)      // #F5EFE3
    static let paperDeep = Color(red: 237 / 255, green: 228 / 255, blue: 211 / 255)  // #EDE4D3
    static let card = Color(red: 251 / 255, green: 247 / 255, blue: 238 / 255)       // #FBF7EE

    // 墨色（暖黑）
    static let ink = Color(red: 43 / 255, green: 38 / 255, blue: 32 / 255)           // #2B2620
    static let ink2 = Color(red: 110 / 255, green: 101 / 255, blue: 87 / 255)        // #6E6557
    static let ink3 = Color(red: 162 / 255, green: 152 / 255, blue: 138 / 255)       // #A2988A
    static let line = Color(red: 217 / 255, green: 207 / 255, blue: 188 / 255)       // #D9CFBC

    // 强调色：复古深靛
    static let accent = Color(red: 43 / 255, green: 74 / 255, blue: 111 / 255)       // #2B4A6F
    static let danger = Color(red: 169 / 255, green: 67 / 255, blue: 47 / 255)       // #A9432F 砖红
    static let success = Color(red: 91 / 255, green: 115 / 255, blue: 80 / 255)      // #5B7350 橄榄
    static let warning = Color(red: 176 / 255, green: 122 / 255, blue: 46 / 255)     // #B07A2E 赭黄
    static let info = Color(red: 78 / 255, green: 101 / 255, blue: 119 / 255)        // #4E6577 灰蓝

    /// 深色统计卡（暖深棕，不用纯黑）
    static let dark = Color(red: 38 / 255, green: 34 / 255, blue: 28 / 255)          // #26221C

    // 面层
    /// 轨道 / 输入底
    static let track = Color(red: 226 / 255, green: 217 / 255, blue: 201 / 255)      // #E2D9C9
    /// 压在照片上的暗角标底
    static let scrim = Color(red: 43 / 255, green: 38 / 255, blue: 32 / 255)         // #2B2620

    static let cornerIsland: CGFloat = 28
    static let cornerPanel: CGFloat = 28
    static let cornerTile: CGFloat = 20
    /// 照片卡：比面板略收，配合 16pt 页边距不显笨重
    static let cornerCard: CGFloat = 28
    static let cornerPlate: CGFloat = 34

    /// 壁纸：奶油纸底 + 三处极淡的暖色光斑（琥珀 / 砖 / 橄榄）。
    /// 只在最底层铺一次，所有页面共用。
    static var wall: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 249 / 255, green: 244 / 255, blue: 233 / 255), location: 0),
                    .init(color: Color(red: 243 / 255, green: 236 / 255, blue: 222 / 255), location: 0.52),
                    .init(color: Color(red: 237 / 255, green: 228 / 255, blue: 211 / 255), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(colors: [Color(red: 214 / 255, green: 168 / 255, blue: 96 / 255).opacity(0.30), .clear],
                           center: .init(x: 0.08, y: -0.06), startRadius: 0, endRadius: 520)
            RadialGradient(colors: [Color(red: 166 / 255, green: 78 / 255, blue: 58 / 255).opacity(0.14), .clear],
                           center: .init(x: 0.96, y: 0.10), startRadius: 0, endRadius: 460)
            RadialGradient(colors: [Color(red: 120 / 255, green: 134 / 255, blue: 96 / 255).opacity(0.16), .clear],
                           center: .init(x: 0.62, y: 1.02), startRadius: 0, endRadius: 520)
        }
        .ignoresSafeArea()
    }
}

extension Color {
    /// 解析 "#RRGGBB"（设置页存的就是这个格式）；解析失败时退回主题深靛。
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
