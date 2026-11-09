import SwiftUI

/// 四瓣夜花：全 App 唯一的记号。
///
/// 用素材里那张花（`Evernight素材/IMG_7050.jpg`）抠出来的两张位图：
/// - `FlowerSeal`：绯红花瓣 + 骨白同心线，做封蜡花印、图标、权限门；
/// - `FlowerLine`：只有骨白线条，做月终 / 空态 / 水印这类不该抢戏的地方。
///
/// 位图已经压成主题色，所以一律 `.renderingMode(.original)`；别再 tint。
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

/// 素材里的伞：权限门的大件插画。
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
