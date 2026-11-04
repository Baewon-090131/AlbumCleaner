import SwiftUI

/// 彩纸：从发射点向上喷出，重力回落、空气阻力、绕自身翻面，2.5s 后各自淡出。
///
/// 全部用 `Canvas` 画，避免一百个 `View` 参与布局与动画事务。
/// 位移用带阻尼的解析解（不是逐帧积分），所以掉帧时轨迹也不会走样。
/// 可以只给一处发射点（待删除页从滑轨喷），也可以给多处（整理完成时满屏放）。
struct ConfettiBurst: View {
    let start: Date
    /// 单点模式：发射点距画布底边的距离（铺满全屏时把它抬到滑轨的位置）。
    var originFromBottom: CGFloat = 0
    /// 多点模式：单位坐标发射点。非空时每处各喷一簇，`originFromBottom` 不参与。
    var origins: [UnitPoint] = []
    /// 每簇的彩纸张数。
    var count: Int = 100

    @State private var clusters: [Cluster]

    private let duration: Double = 3.3

    init(start: Date,
         originFromBottom: CGFloat = 0,
         origins: [UnitPoint] = [],
         count: Int = 100) {
        self.start = start
        self.originFromBottom = originFromBottom
        self.origins = origins
        self.count = count
        let seeds = origins.isEmpty ? [UnitPoint(x: 0.5, y: 1)] : origins
        _clusters = State(initialValue: seeds.map {
            Cluster(origin: $0, particles: ConfettiParticle.make(count: count))
        })
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                guard elapsed < duration else { return }

                for cluster in clusters {
                    // 底边中点是单点模式的特例：只在 y == 1 时用 originFromBottom 抬起
                    let origin = CGPoint(
                        x: cluster.origin.x * size.width,
                        y: cluster.origin.y >= 0.999
                            ? size.height - originFromBottom
                            : cluster.origin.y * size.height
                    )

                    for particle in cluster.particles {
                        let t = elapsed - particle.delay
                        guard t > 0 else { continue }

                        let tc = CGFloat(t)

                        // 照 canvas-confetti 的逐帧积分（60fps）写闭式解：
                        // 每帧 vx *= decay、vy *= decay 后 vy += gravity，位置 += 速度。
                        // 这样初速够大就能冲到屏幕顶部，再被重力一段段拉回来。
                        let n = tc * 60
                        let d: CGFloat = 0.95
                        let g: CGFloat = 0.5
                        let terminal = g / (1 - d)
                        let decayN = pow(d, n)
                        let ramp = d * (1 - decayN) / (1 - d)

                        let x = origin.x
                            + particle.vx * ramp
                            + CGFloat(sin(t * 2.4 + particle.phase)) * 12 * min(tc, 1.5)
                        let y = origin.y + (particle.vy - terminal) * ramp + terminal * n

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

/// 一簇彩纸：一个发射点 + 一组独立随机的粒子。
private struct Cluster {
    let origin: UnitPoint
    let particles: [ConfettiParticle]
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
            let speed = CGFloat.random(in: 40...56)
            let angle = Double.random(in: (90 - 36)...(90 + 36)) * .pi / 180
            return ConfettiParticle(
                vx: CGFloat(cos(angle)) * speed * 0.42,
                vy: -CGFloat(sin(angle)) * speed,
                color: palette.randomElement() ?? Theme.accent,
                shape: Int.random(in: 0...2),
                size: CGFloat.random(in: 7...12),
                spin: Double.random(in: -9...9),
                phase: Double.random(in: 0...(.pi * 2)),
                delay: Double.random(in: 0...0.08),
                fadeStart: Double.random(in: 2.0...2.6)
            )
        }
    }
}
