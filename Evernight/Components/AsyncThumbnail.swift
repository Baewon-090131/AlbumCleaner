import Photos
import SwiftUI

/// 照片缩略图。加载完成前占位，避免卡片上闪一次空块。
/// `highQuality` 给整理页大卡用：按屏幕物理像素放大 1.5 倍请求，对齐原生相册的清晰度。
///
/// **同步读缓存**是关键：图片在 body 求值时先查 NSCache，视图重建（换卡时前后卡互换）
/// 能立刻拿到已有图片，不会经过 `.task` 的下一轮，因此不会闪一帧灰色占位。
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
    @State private var image: UIImage?

    private var displayed: UIImage? {
        image ?? ThumbnailLoader.shared.cached(for: asset, targetSize: requestSize,
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
            let upgraded = await ThumbnailLoader.shared.image(for: asset, targetSize: requestSize,
                                                              highQuality: highQuality)
            guard let upgraded, upgraded !== image else { return }
            // 只在后台补齐时淡入替换，不做「先清空再加载」
            withAnimation(.smooth(duration: 0.12)) { image = upgraded }
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
