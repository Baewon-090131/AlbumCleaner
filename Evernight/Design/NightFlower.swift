import SwiftUI

/// 四瓣夜花：全 App 唯一的记号。
///
/// v0.2 起不再手绘矢量，直接用素材里那张花（`Evernight素材/IMG_7050.jpg`）抠出来的两张位图：
/// - `FlowerSeal`：绯红花瓣 + 骨白同心线，做封蜡花印、图标、权限门；
/// - `FlowerLine`：只有骨白线条，做月终 / 空态 / 水印这类不该抢戏的地方。
///
/// 位图是 640×640、已经压成主题色，所以着色一律走 `.renderingMode(.original)`；
/// 需要别色时用 `.colorMultiply` 或调透明度，不要再 tint（会把红面也染掉）。
struct NightFlower: View {
    enum Kind {
        case seal, line
    }

    var kind: Kind = .seal
    /// 叠加透明度。水印类用 0.10–0.35，花印用 1。
    var opacity: Double = 1
    /// 轻微旋转，做“盖章”的随意感；0 表示不转。
    var angle: Double = 0

    var body: some View {
        Image(kind == .seal ? "FlowerSeal" : "FlowerLine")
            .resizable()
            .renderingMode(.original)
            .aspectRatio(1, contentMode: .fit)
            .opacity(opacity)
            .rotationEffect(.degrees(angle))
            .allowsHitTesting(false)
    }
}

/// 素材里的伞：权限门与空态的大件插画。
struct NightUmbrella: View {
    var body: some View {
        Image("Umbrella")
            .resizable()
            .renderingMode(.original)
            .aspectRatio(contentMode: .fit)
            .allowsHitTesting(false)
    }
}

/// 素材里的月牙星空底。压暗过，直接铺在夜色上。
struct NightMoonPlate: View {
    var opacity: Double = 0.55

    var body: some View {
        Image("MoonPlate")
            .resizable()
            .renderingMode(.original)
            .aspectRatio(contentMode: .fill)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

extension Theme {
    /// 从素材拆出来的 12 朵飞花，供彩纸 / 月终烟花随机取用。
    static let petalSprites = (1...12).map { "Petal\($0)" }
}
