import Photos
import SwiftUI

/// 照片缩略图。加载完成前占位，避免卡片上闪一次空块。
/// `highQuality` 给整理页前置大卡用：按屏幕物理像素放大 1.5 倍请求，对齐原生相册的清晰度。
struct AsyncThumbnail: View {
    let asset: PHAsset
    var targetSize: CGSize
    var contentMode: ContentMode = .fill
    var highQuality = false

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .task(id: asset.localIdentifier) {
            image = await ThumbnailLoader.shared.image(for: asset, targetSize: requestSize,
                                                       highQuality: highQuality)
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
