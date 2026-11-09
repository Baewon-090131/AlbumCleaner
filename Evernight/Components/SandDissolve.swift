import Photos
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

/// 一次碎沙：粒子 + 起始时刻 + 照片在屏幕上的位置 + 总时长。
struct SandBurst {
    let grains: [SandGrain]
    let start: Date
    /// 照片窗口**此刻**在屏幕上的矩形（全局坐标，含跟手位移）。
    /// 沙粒的起点就按它换算——上滑到哪儿，粒子就从哪儿散开。
    let frameInScreen: CGRect
    let life: Double = 1.2
}

/// 碎沙画布：整张照片按 50 × 30（约 1500 粒）拆开，底部先动、向上飘、
/// 边飘边缩小，最后 0.1s 左右淡出。铺满整屏绘制，坐标直接用屏幕坐标。
struct SandCanvas: View {
    let burst: SandBurst

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(burst.start)
            Canvas { context, _ in
                guard elapsed < burst.life else { return }
                let origin = burst.frameInScreen.origin
                let photoSize = burst.frameInScreen.size

                for grain in burst.grains {
                    let t = elapsed - grain.delay
                    guard t > 0 else { continue }

                    // 每粒都有自己 0.75s 的寿命：晚开始的那些也能完整飘完
                    let p = t / 0.75
                    guard p < 1 else { continue }

                    let x = origin.x + grain.nx * photoSize.width
                        + grain.drift * CGFloat(t)
                        + CGFloat(sin(t * 22 + grain.phase)) * 5
                    let y = origin.y + grain.ny * photoSize.height - grain.rise * CGFloat(t)
                    guard y > -24 else { continue }

                    let scale = 1 - CGFloat(p) * 0.72
                    let alpha = p > 0.78 ? max(0, 1 - (p - 0.78) / 0.22) : 1
                    guard alpha > 0 else { continue }

                    let side = photoSize.width * 0.026 * scale
                    context.fill(Path(CGRect(x: x - side / 2, y: y - side / 2,
                                             width: side, height: side)),
                                 with: .color(grain.color.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// 把缩略图缩到 50 × 30，逐像素取色，生成沙粒。
enum SandSampler {
    static func burst(for photo: PhotoItem,
                      targetSize: CGSize,
                      frameInScreen: CGRect) -> SandBurst? {
        // 先读卡片缓存；万一 miss（比如刚启动就删），当场同步拉一张小图兜底，
        // 否则采不到颜色、一粒沙都出不来。
        let image = ThumbnailLoader.shared.cached(for: photo.asset,
                                                  targetSize: targetSize,
                                                  highQuality: true)
            ?? syncThumbnail(for: photo.asset)
        guard let image, let cg = image.cgImage else { return nil }

        let cols = 50
        let rows = 30
        var buffer = [UInt8](repeating: 0, count: cols * rows * 4)

        buffer.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress,
                                      width: cols, height: rows,
                                      bitsPerComponent: 8,
                                      bytesPerRow: cols * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                                          | CGBitmapInfo.byteOrder32Big.rawValue) else { return }
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
                    delay: Double(1 - ny) * 0.42 + Double.random(in: 0...0.04)
                ))
            }
        }
        return SandBurst(grains: grains, start: .now, frameInScreen: frameInScreen)
    }

    /// 缓存 miss 时的兜底：同步请求一张 96×96 的小图，只为拿到颜色分布。
    /// `isSynchronous` 会阻塞主线程几十毫秒，但只在没有缓存时发生一次。
    private static func syncThumbnail(for asset: PHAsset) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false

        var result: UIImage?
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: 96, height: 96),
                                              contentMode: .aspectFill,
                                              options: options) { image, _ in
            result = image
        }
        return result
    }
}
