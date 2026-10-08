import SwiftUI

/// Liquid Glass 适配层。
///
/// iOS 26 起直接调用系统 `glassEffect`（浮动功能层用 `.regular`，压在照片上的可点区域可传 `clear`）；
/// 更早的系统退回 `.ultraThinMaterial`，保证层级关系一致、不会因为降级而糊成一片。
extension View {
    @ViewBuilder
    func glassSurface(
        cornerRadius: CGFloat,
        clear: Bool = false,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(glassStyle(clear: clear, tint: tint, interactive: interactive),
                             in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    @available(iOS 26.0, *)
    private func glassStyle(clear: Bool, tint: Color?, interactive: Bool) -> Glass {
        var glass: Glass = clear ? .clear : .regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
}

/// 内容层容器：卡片、分组这类承载阅读的表面。按 HIG，内容层不用 Liquid Glass，
/// 这里用一层偏实的高亮材质把文字托住。
struct ContentPanel<Content: View>: View {
    var cornerRadius: CGFloat = Theme.cornerPanel
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(.regularMaterial,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.65), lineWidth: 0.5)
            )
            .shadow(color: Color(red: 22 / 255, green: 32 / 255, blue: 72 / 255).opacity(0.10),
                    radius: 10, y: 6)
    }
}
