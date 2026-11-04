import Photos
import SwiftUI

/// 照片缩略图。加载完成前用占位色，避免卡片上闪一次空块。
/// `highQuality` 给整理页大卡用：按屏幕物理像素放大 1.5 倍请求，对齐原生相册的清晰度。
///
/// **不在视图里存 UIImage**：图片永远从 `ThumbnailLoader` 的缓存按 `asset` 同步取。
/// 这样切张时视图可以安全复用（不需要 `.id` 强制重建），
/// 既不会显示上一张的旧图被拉伸，也不会因为重建 16 次而顿一下。
struct AsyncThumbnail: View {
    let asset: PHAsset
    var targetSize: CGSize
    var contentMode: ContentMode = .fill
    var highQuality = false
    /// 卡片里用玻璃占位（加载前的空卡片也是「玻璃」），网格里保持实色，避免几十上百个 material 太重。
    var glassPlaceholder = false
    /// 指定占位底色：相纸里用它铺纸色，缓存 miss 的那一帧也不会露出一块灰。
    var placeholderColor: Color?

    @Environment(\.displayScale) private var displayScale
    /// 后台补齐完成后让它自增，触发一次重读缓存。
    @State private var reloadToken = 0

    private var displayed: UIImage? {
        _ = reloadToken
        return ThumbnailLoader.shared.cached(for: asset, targetSize: requestSize,
                                             highQuality: highQuality)
    }

    var body: some View {
        Group {
            if let displayed {
                Image(uiImage: displayed)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let placeholderColor {
                Rectangle().fill(placeholderColor)
            } else if glassPlaceholder {
                Rectangle().fill(.ultraThinMaterial)
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .task(id: asset.localIdentifier) {
            _ = await ThumbnailLoader.shared.image(for: asset, targetSize: requestSize,
                                                   highQuality: highQuality)
            reloadToken += 1
        }
    }

    /// 普通请求原样使用传入尺寸（网格里本来就是按像素给的）；
    /// 高清请求按 displayScale 换算并放大，单边封顶 2800px 防止内存爆掉。
    private var requestSize: CGSize {
        guard highQuality else { return targetSize }
        let scale = displayScale * 1.5
        return CGSize(width: min(targetSize.width * scale, 2800),
                      height: min(targetSize.height * scale, 2800))
    }
}
