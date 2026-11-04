import SwiftUI

/// 彩纸：从底边中点向上喷出，重力回落、空气阻力、绕自身翻面，2.5s 后各自淡出。
///
/// 全部用 `Canvas` 画，避免一百个 `View` 参与布局与动画事务。
/// 位移用带阻尼的解析解（不是逐帧积分），所以掉帧时轨迹也不会走样。
struct ConfettiBurst: View {
    let start: Date
    /// 发射点距画布底边的距离：铺满全屏时可以把它抬到滑轨的位置。
    var originFromBottom: CGFloat = 0

    @State private var particles = ConfettiParticle.make(count: 100)

    private let drag: CGFloat = 1.3      // 空气阻力系数
    private let gravity: CGFloat = 420   // 重力（pt/s²）
    private let duration: Double = 3.3

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                guard elapsed < duration else { return }
                let origin = CGPoint(x: size.width / 2, y: size.height - originFromBottom)

                for particle in particles {
                    let t = elapsed - particle.delay
                    guard t > 0 else { continue }

                    let tc = CGFloat(t)
                    let damp = CGFloat(exp(-Double(drag) * t))
                    let x = origin.x
                        + particle.vx / drag * (1 - damp)
                        + CGFloat(sin(t * 2.2 + particle.phase)) * 14 * min(tc, 1.2)
                    let y = origin.y
                        + (particle.vy / drag + gravity / (drag * drag)) * (1 - damp)
                        - gravity / drag * tc

                    let alpha = fade(t: t, start: particle.fadeStart)
                    guard alpha > 0 else { continue }

                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(particle.spin * t))
                    let flip = cos(particle.spin * t * 1.6)
                    ctx.scaleBy(x: flip < 0 ? -1 : 1, y: 1)

                    let path = shapePath(particle)
                    ctx.fill(path, with: .color(particle.color.opacity(alpha)))
                    if flip < 0 {
                        // 背面：叠一层黑让它变暗
                        ctx.fill(path, with: .color(.black.opacity(0.26 * alpha)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func fade(t: Double, start: Double) -> Double {
        guard t > start else { return 1 }
        return max(0, 1 - (t - start) / 0.35)
    }

    private func shapePath(_ particle: ConfettiParticle) -> Path {
        switch particle.shape {
        case 0:
            let rect = CGRect(x: -3, y: -particle.size, width: 6, height: particle.size * 2)
            return Path(rect)
        case 1:
            let d = particle.size
            return Path(ellipseIn: CGRect(x: -d / 2, y: -d / 2, width: d, height: d))
        default:
            let d = particle.size
            return Path(CGRect(x: -d / 2, y: -d / 2, width: d, height: d))
        }
    }
}

private struct ConfettiParticle {
    let vx: CGFloat
    let vy: CGFloat
    let color: Color
    /// 0 = 长条，1 = 圆片，2 = 方片。
    let shape: Int
    let size: CGFloat
    let spin: Double
    let phase: Double
    let delay: Double
    let fadeStart: Double

    /// 五色主题色，形状随机；发射角在正上方 ±36° 内。
    static func make(count: Int) -> [ConfettiParticle] {
        let palette = [Theme.accent, Theme.danger, Theme.success, Theme.warning, Theme.info]
        return (0..<count).map { _ in
            let speed = CGFloat.random(in: 420...640)
            let angle = Double.random(in: (90 - 36)...(90 + 36)) * .pi / 180
            return ConfettiParticle(
                vx: CGFloat(cos(angle)) * speed,
                vy: -CGFloat(sin(angle)) * speed,
                color: palette.randomElement() ?? Theme.accent,
                shape: Int.random(in: 0...2),
                size: CGFloat.random(in: 7...12),
                spin: Double.random(in: -9...9),
                phase: Double.random(in: 0...(.pi * 2)),
                delay: Double.random(in: 0...0.08),
                fadeStart: Double.random(in: 2.2...2.8)
            )
        }
    }
}
