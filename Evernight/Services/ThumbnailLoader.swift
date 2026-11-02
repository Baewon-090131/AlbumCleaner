import Photos
import UIKit

/// 缩略图加载 + 内存缓存。
/// NSCache 与 PHCachingImageManager 本身线程安全，所以这里不加 actor 隔离，避免每张图都切主线程。
final class ThumbnailLoader: @unchecked Sendable {
    static let shared = ThumbnailLoader()

    private let manager = PHCachingImageManager()
    private let cache = NSCache<NSString, UIImage>()
    /// 前置大卡的原图级请求单独一个缓存：单张可达几十 MB，不能用 240 张的上限。
    private let fullCache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 240
        fullCache.countLimit = 8
    }

    /// 请求指定尺寸的缩略图；degraded 的中间帧直接丢掉，避免闪一次低清图。
    /// `highQuality` 时走大卡缓存（只留 8 张）。
    func image(for asset: PHAsset, targetSize: CGSize, highQuality: Bool = false) async -> UIImage? {
        let store = highQuality ? fullCache : cache
        let key = "\(asset.localIdentifier)|\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
        if let cached = store.object(forKey: key) { return cached }

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

                if let image { self?.store(for: highQuality).setObject(image, forKey: key) }
                continuation.resume(returning: image)
            }
        }
    }

    private func store(for highQuality: Bool) -> NSCache<NSString, UIImage> {
        highQuality ? fullCache : cache
    }
}
