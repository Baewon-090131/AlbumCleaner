import SwiftUI

/// 一粒沙：归一化起始坐标 + 它原来那个像素的颜色。
struct SandGrain {
    let nx: CGFloat
    let ny: CGFloat
    let color: Color
    let rise: CGFloat
    let drift: CGFloat
    let phase: Double
    let delay: Double
}

/// 一次碎沙：粒子 + 起始时刻 + 总时长。
struct SandBurst {
    let grains: [SandGrain]
    let start: Date
    let life: Double = 0.8
}

/// 碎沙画布：整张照片按 50 × 40（约 2000 粒）拆开，底部先动、向上飘、
/// 边飘边缩小，最后 0.1s 左右淡出。
struct SandCanvas: View {
    let burst: SandBurst

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(burst.start)
            Canvas { context, size in
                guard elapsed < burst.life else { return }
                for grain in burst.grains {
                    let t = elapsed - grain.delay
                    guard t > 0 else { continue }

                    let progress = t / burst.life
                    let x = grain.nx * size.width
                        + grain.drift * CGFloat(t)
                        + CGFloat(sin(t * 22 + grain.phase)) * 5
                    let y = grain.ny * size.height - grain.rise * CGFloat(t)
                    guard y > -24 else { continue }

                    let scale = 1 - CGFloat(progress) * 0.65
                    let alpha = progress > 0.86 ? max(0, 1 - (progress - 0.86) / 0.14) : 1
                    guard alpha > 0 else { continue }

                    let side = size.width * 0.026 * scale
                    context.fill(Path(CGRect(x: x - side / 2, y: y - side / 2,
                                             width: side, height: side)),
                                 with: .color(grain.color.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// 把缩略图缩到 50 × 40，逐像素取色，生成沙粒。
enum SandSampler {
    static func burst(for photo: PhotoItem, targetSize: CGSize) -> SandBurst? {
        guard let image = ThumbnailLoader.shared.cached(for: photo.asset,
                                                        targetSize: targetSize,
                                                        highQuality: true),
              let cg = image.cgImage else { return nil }

        let cols = 50
        let rows = 40
        var buffer = [UInt8](repeating: 0, count: cols * rows * 4)

        buffer.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress,
                                      width: cols, height: rows,
                                      bitsPerComponent: 8,
                                      bytesPerRow: cols * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            // 翻转 y 轴，让 buffer 的第 0 行对应照片顶部
            ctx.translateBy(x: 0, y: CGFloat(rows))
            ctx.scaleBy(x: 1, y: -1)
            ctx.interpolationQuality = .low
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cols, height: rows))
        }

        var grains: [SandGrain] = []
        grains.reserveCapacity(cols * rows)
        for row in 0..<rows {
            for col in 0..<cols {
                let offset = (row * cols + col) * 4
                let color = Color(red: Double(buffer[offset]) / 255,
                                  green: Double(buffer[offset + 1]) / 255,
                                  blue: Double(buffer[offset + 2]) / 255)
                let nx = (CGFloat(col) + 0.5) / CGFloat(cols)
                let ny = (CGFloat(row) + 0.5) / CGFloat(rows)
                grains.append(SandGrain(
                    nx: nx,
                    ny: ny,
                    color: color,
                    rise: CGFloat.random(in: 380...620),
                    drift: CGFloat.random(in: -70...70),
                    phase: Double.random(in: 0...(.pi * 2)),
                    delay: Double(1 - ny) * 0.12 + Double.random(in: 0...0.04)
                ))
            }
        }
        return SandBurst(grains: grains, start: .now)
    }
}
