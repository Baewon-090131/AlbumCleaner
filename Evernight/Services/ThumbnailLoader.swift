import Photos
import UIKit

/// 缩略图加载 + 内存缓存。
/// NSCache 与 PHCachingImageManager 本身线程安全，所以这里不加 actor 隔离，避免每张图都切主线程。
final class ThumbnailLoader: @unchecked Sendable {
    static let shared = ThumbnailLoader()

    private let manager = PHCachingImageManager()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 240
    }

    /// 请求指定尺寸的缩略图；degraded 的中间帧直接丢掉，避免闪一次低清图。
    func image(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        let key = "\(asset.localIdentifier)|\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        return await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            let lock = NSLock()
            var resumed = false

            manager.requestImage(for: asset, targetSize: targetSize,
                                 contentMode: .aspectFill, options: options) { [weak self] image, info in
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if degraded { return }

                lock.lock()
                let alreadyDone = resumed
                resumed = true
                lock.unlock()
                guard !alreadyDone else { return }

                if let image { self?.cache.setObject(image, forKey: key) }
                continuation.resume(returning: image)
            }
        }
    }
}
