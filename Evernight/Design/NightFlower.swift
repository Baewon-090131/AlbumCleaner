import SwiftUI

/// 四瓣夜花：全 App 唯一的记号。
///
/// 用在封蜡红的花印（收藏）、月终的小印、空态与图标上。
/// 形状用四段三次贝塞尔画成一片圆润的花瓣，再绕中心旋转四次；
/// 内层可以叠一圈缩小版描边，得到素材里那种“同心线”的感觉。
struct NightFlowerShape: Shape {
    /// 以 0.5 为原型缩放；1 = 原始大小，0.6 = 内圈。
    var scale: CGFloat = 1
    var petals: Int = 4

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        var path = Path()
        for index in 0..<max(petals, 1) {
            let angle = CGFloat(index) * 2 * .pi / CGFloat(max(petals, 1))
            var petal = petalPath(origin: origin, side: side)
            petal = petal.applying(
                CGAffineTransform(translationX: origin.x + side / 2,
                                  y: origin.y + side / 2)
                    .rotated(by: angle)
                    .translatedBy(x: -(origin.x + side / 2),
                                  y: -(origin.y + side / 2))
            )
            if scale != 1 {
                petal = petal.applying(
                    CGAffineTransform(translationX: origin.x + side / 2,
                                      y: origin.y + side / 2)
                        .scaledBy(x: scale, y: scale)
                        .translatedBy(x: -(origin.x + side / 2),
                                      y: -(origin.y + side / 2))
                )
            }
            path.addPath(petal)
        }
        return path
    }

    /// 一片朝上的花瓣，坐标按 100×100 设计，再按 side/100 缩放并落到 rect 的中央。
    private func petalPath(origin: CGPoint, side: CGFloat) -> Path {
        let s = side / 100
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * s, y: origin.y + y * s)
        }
        var path = Path()
        path.move(to: p(50, 50))
        path.addCurve(to: p(34, 15), control1: p(34, 40), control2: p(28, 26))
        path.addCurve(to: p(66, 15), control1: p(39, 5), control2: p(61, 5))
        path.addCurve(to: p(50, 50), control1: p(72, 26), control2: p(66, 40))
        path.closeSubpath()
        return path
    }
}

/// 花印：可填充、可只描边，中心一枚小菱形。
struct NightFlower: View {
    var color: Color = Theme.accent
    var filled = false
    var lineWidth: CGFloat = 1.4
    var showsInner = true
    var showsCenter = true

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                if filled {
                    NightFlowerShape().fill(color)
                }
                if showsInner {
                    NightFlowerShape(scale: 0.6)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                }
                NightFlowerShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                if showsCenter {
                    Path { path in
                        let cx = proxy.size.width / 2
                        let cy = proxy.size.height / 2
                        let r = side * 0.045
                        let v = side * 0.085
                        path.move(to: CGPoint(x: cx, y: cy - v))
                        path.addLine(to: CGPoint(x: cx + r, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy + v))
                        path.addLine(to: CGPoint(x: cx - r, y: cy))
                        path.closeSubpath()
                    }
                    .fill(filled ? Theme.paper : color)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}
