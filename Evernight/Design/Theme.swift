import SwiftUI

/// 全局设计令牌。数值沿用网页版定的那套（iOS 27 液态玻璃），只是换成 SwiftUI 表达。
enum Theme {
    // 强调色：北洋蓝
    static let accent = Color(red: 0 / 255, green: 47 / 255, blue: 167 / 255)
    static let danger = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)
    static let success = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let warning = Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255)
    static let info = Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255)

    static let cornerIsland: CGFloat = 28
    static let cornerPanel: CGFloat = 28
    static let cornerTile: CGFloat = 20
    static let cornerPlate: CGFloat = 34

    /// 壁纸：四层柔光斑叠在线性底上。放在最底层，所有页面共用。
    static var wall: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 231 / 255, green: 240 / 255, blue: 1.0), location: 0),
                    .init(color: Color(red: 241 / 255, green: 235 / 255, blue: 1.0), location: 0.46),
                    .init(color: Color(red: 1.0, green: 240 / 255, blue: 248 / 255), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(colors: [Color(red: 111 / 255, green: 168 / 255, blue: 1.0).opacity(0.55), .clear],
                           center: .init(x: 0.06, y: -0.08), startRadius: 0, endRadius: 520)
            RadialGradient(colors: [Color(red: 195 / 255, green: 162 / 255, blue: 1.0).opacity(0.5), .clear],
                           center: .init(x: 0.98, y: 0.04), startRadius: 0, endRadius: 460)
            RadialGradient(colors: [Color(red: 110 / 255, green: 214 / 255, blue: 1.0).opacity(0.3), .clear],
                           center: .init(x: 0.78, y: 0.62), startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Color(red: 1.0, green: 176 / 255, blue: 216 / 255).opacity(0.45), .clear],
                           center: .init(x: 0.46, y: 1.06), startRadius: 0, endRadius: 520)
        }
        .ignoresSafeArea()
    }
}

extension Color {
    /// 解析 "#RRGGBB"（设置页存的就是这个格式）；解析失败时退回北洋蓝。
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
