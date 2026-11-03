import SwiftUI

// MARK: - Liquid Glass 入口

extension View {
    /// 单个浮动玻璃面（进度胶囊、加载页、提示卡）。
    @ViewBuilder
    func glassSurface(
        cornerRadius: CGFloat,
        clear: Bool = false,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(makeGlass(clear: clear, tint: tint, interactive: interactive),
                             in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    /// 会随界面变化改变形状的玻璃面。同一 `namespace` 里相同 `id` 的形状会被系统平滑变形，
    /// 例如操作岛从「四个按钮」变成相簿详情页的「三个按钮」。
    @ViewBuilder
    func glassSurface(
        cornerRadius: CGFloat,
        morphID: some Hashable,
        in namespace: Namespace.ID,
        tint: Color? = nil,
        interactive: Bool = true
    ) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(makeGlass(clear: false, tint: tint, interactive: interactive),
                             in: .rect(cornerRadius: cornerRadius))
                .glassEffectID(morphID, in: namespace)
        } else {
            self.background(.ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

@available(iOS 26.0, *)
private func makeGlass(clear: Bool, tint: Color?, interactive: Bool) -> Glass {
    var glass: Glass = clear ? .clear : .regular
    if let tint { glass = glass.tint(tint) }
    if interactive { glass = glass.interactive() }
    return glass
}

extension View {
    /// 原生玻璃按钮样式。iOS 26 用系统的 `.glass` / `.glassProminent`，
    /// 更早系统退到 `.bordered` 系列。
    @ViewBuilder
    func glassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            if prominent {
                self.buttonStyle(.borderedProminent)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - 内容层

/// 卡片、分组这类承载阅读的表面。按 HIG，内容层不该用 Liquid Glass，
/// 这里用偏实的高亮材质把文字托住，避免半透明叠半透明。
/// 材质本身偏冷，所以压一层暖纸色，让它在奶油底上不发灰。
struct ContentPanel<Content: View>: View {
    var cornerRadius: CGFloat = Theme.cornerPanel
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(.regularMaterial,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(Theme.card.opacity(0.55),
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.line.opacity(0.55), lineWidth: 0.5)
            )
            .shadow(color: Theme.ink.opacity(0.10), radius: 10, y: 6)
    }
}
