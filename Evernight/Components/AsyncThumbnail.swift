import Photos
import SwiftUI

/// 照片缩略图。加载完成前占位，避免卡片上闪一次空块。
struct AsyncThumbnail: View {
    let asset: PHAsset
    var targetSize: CGSize
    var contentMode: ContentMode = .fill

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
            image = await ThumbnailLoader.shared.image(for: asset, targetSize: targetSize)
        }
    }
}
