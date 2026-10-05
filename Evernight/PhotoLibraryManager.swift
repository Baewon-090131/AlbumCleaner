import UIKit
import Photos
import AVKit
import PhotosUI

class PhotoLibraryManager: NSObject {

    static let shared = PhotoLibraryManager()

    private let imageManager = PHCachingImageManager()
    private var cachedAssets: [String: PHAsset] = [:]
    // 缩略图缓存（按 identifier+size 维度），避免重复请求造成卡顿
    private let thumbnailCache = NSCache<NSString, UIImage>()

    // 请求照片库权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        default:
            completion(false)
        }
    }

    // 获取所有照片和视频，按创建日期倒序
    func fetchAllAssets() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
            self.cachedAssets[asset.localIdentifier] = asset
        }
        return assets
    }

    // 按月份分组
    func groupAssetsByMonth(_ assets: [PHAsset]) -> [[String: Any]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M"
        let titleFormatter = DateFormatter()
        titleFormatter.dateFormat = "yyyy年M月"
        let monthNameFormatter = DateFormatter()
        monthNameFormatter.dateFormat = "M月"

        var groups: [String: [PHAsset]] = [:]
        var order: [String] = []

        for asset in assets {
            guard let date = asset.creationDate else { continue }
            let key = formatter.string(from: date)
            if groups[key] == nil {
                groups[key] = []
                order.append(key)
            }
            groups[key]?.append(asset)
        }

        var result: [[String: Any]] = []
        for key in order {
            guard let monthAssets = groups[key], let firstDate = monthAssets.first?.creationDate else { continue }
            let photos: [[String: Any]] = monthAssets.map { self.photoPayload(for: $0) }
            result.append([
                "id": key,
                "year": Calendar.current.component(.year, from: firstDate),
                "month": Calendar.current.component(.month, from: firstDate),
                "title": titleFormatter.string(from: firstDate),
                "shortTitle": monthNameFormatter.string(from: firstDate),
                "photos": photos
            ])
        }
        return result
    }

    // v3.0：照片描述统一出口（月份与相簿共用），补上卡片角标需要的日期与体积
    private let creationDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()

    private var fileSizeCache: [String: Int64] = [:]

    func photoPayload(for asset: PHAsset) -> [String: Any] {
        // 宽高比用于前端自适应多种尺寸媒体（横图/竖图/全景/Live Photo）
        let ratio: Double = asset.pixelWidth > 0 && asset.pixelHeight > 0
            ? Double(asset.pixelWidth) / Double(asset.pixelHeight)
            : 0.75
        return [
            "id": asset.localIdentifier,
            "isVideo": asset.mediaType == .video,
            "isLivePhoto": asset.mediaSubtypes.contains(.photoLive),
            "duration": asset.mediaType == .video ? formatDuration(asset.duration) : NSNull(),
            "thumbnailUrl": "photo://\(asset.localIdentifier)",
            "favorite": asset.isFavorite,
            "ratio": ratio,
            "creationDate": asset.creationDate.map { creationDateFormatter.string(from: $0) } ?? "",
            "fileSize": fileSize(for: asset)
        ]
    }

    // PHAsset 没有公开的文件大小属性，逐张读资源的 fileSize 并缓存。
    // 相册数量很大时这里会慢，后续要优化就改成后台索引 + 落盘缓存。
    func fileSize(for asset: PHAsset) -> Int64 {
        let key = asset.localIdentifier
        if let cached = fileSizeCache[key] { return cached }
        var total: Int64 = 0
        for resource in PHAssetResource.assetResources(for: asset) {
            if let size = resource.value(forKey: "fileSize") as? Int64 {
                total += size
            }
        }
        fileSizeCache[key] = total
        return total
    }

    // 读取某个相簿内的全部项目（相簿详情页用）
    func fetchAlbumAssets(_ albumIdentifier: String) -> [[String: Any]] {
        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumIdentifier], options: nil)
        guard let collection = collections.firstObject else { return [] }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(in: collection, options: options)
        var result: [[String: Any]] = []
        assets.enumerateObjects { asset, _, _ in
            result.append(self.photoPayload(for: asset))
        }
        return result
    }

    // 机身存储占用（我的页数据卡）
    func storageInfo() -> [String: Any] {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        var total: Int64 = 0
        var free: Int64 = 0
        if let values = try? url.resourceValues(
            forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]) {
            total = Int64(values.volumeTotalCapacity ?? 0)
            free = values.volumeAvailableCapacityForImportantUsage ?? 0
        }
        return ["total": total, "free": free, "used": max(0, total - free)]
    }

    // 获取相簿列表
    func fetchAlbums() -> [[String: Any]] {
        var albums: [[String: Any]] = []

        let coverOptions = PHFetchOptions()
        coverOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        coverOptions.fetchLimit = 1

        func payload(_ collection: PHAssetCollection, _ type: String) -> [String: Any]? {
            guard let title = collection.localizedTitle else { return nil }
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            let coverAsset = PHAsset.fetchAssets(in: collection, options: coverOptions).firstObject
            return [
                "id": collection.localIdentifier,
                "name": title,
                "count": count,
                "type": type,
                "gradient": self.gradientForAlbum(title),
                "cover": coverAsset.map { "photo://\($0.localIdentifier)" } ?? ""
            ]
        }

        // 智能相簿（个人收藏、最近项目等）
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        smartAlbums.enumerateObjects { collection, _, _ in
            if let item = payload(collection, "smart") { albums.append(item) }
        }

        // 用户创建的相簿
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            if let item = payload(collection, "user") { albums.append(item) }
        }

        return albums
    }

    // 获取缩略图（highQualityFormat 只回调一次，避免 WKURLSchemeTask 重复完成崩溃）
    // 带 NSCache 缓存：同一照片重复请求直接命中缓存，明显降低卡顿
    func requestThumbnail(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = "\(asset.localIdentifier)|\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            completion(cached)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    self.thumbnailCache.setObject(image, forKey: cacheKey)
                }
                completion(image)
            }
        }
    }

    // v2.4：按照片原始比例构造缩略图请求尺寸（长边 400pt，比屏宽略大，放大显示不发糊），源头不裁切照片比例
    func targetSizeForAsset(_ asset: PHAsset) -> CGSize {
        let scale = UIScreen.main.scale
        let base: CGFloat = 400 * scale
        var w = base
        var h = base
        if asset.pixelWidth > 0 && asset.pixelHeight > 0 {
            let ratio = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
            if ratio >= 1 {
                w = base
                h = base / ratio
            } else {
                h = base
                w = base * ratio
            }
        }
        return CGSize(width: w, height: h)
    }

    // v2.3：预缓存最新一批照片缩略图（进月份前提前加载到 NSCache，翻页更跟手）
    func prefetchThumbnails(_ assets: [PHAsset], count: Int = 24) {
        let limit = min(count, assets.count)
        guard limit > 0 else { return }
        for asset in assets.prefix(limit) {
            let size = targetSizeForAsset(asset)
            let cacheKey = "\(asset.localIdentifier)|\(Int(size.width))x\(Int(size.height))" as NSString
            if thumbnailCache.object(forKey: cacheKey) != nil { continue }
            requestThumbnail(for: asset, size: size) { _ in }
        }
    }

    // 根据localIdentifier获取asset
    func asset(for identifier: String) -> PHAsset? {
        if let cached = cachedAssets[identifier] { return cached }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return result.firstObject
    }

    // MARK: - 视频与 Live Photo 播放（v2.2.4）

    private var playerVC: AVPlayerViewController?
    private var livePhotoVC: LivePhotoViewController?

    // 播放媒体（视频 → AVPlayerViewController 全屏；Live Photo → PHLivePhotoView 全屏）
    func playMedia(_ identifier: String) {
        guard let asset = asset(for: identifier) else { return }

        if asset.mediaType == .video {
            playVideo(asset)
        } else if asset.mediaSubtypes.contains(.photoLive) {
            playLivePhoto(asset)
        }
    }

    private func playVideo(_ asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        imageManager.requestPlayerItem(forVideo: asset, options: options) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self = self, let item = item,
                      let topVC = self.topViewController() else { return }
                let player = AVPlayer(playerItem: item)
                let vc = AVPlayerViewController()
                vc.player = player
                vc.modalPresentationStyle = .fullScreen
                vc.allowsPictureInPicturePlayback = false
                self.playerVC = vc
                topVC.present(vc, animated: true) {
                    player.play()
                }
                // 播放结束自动关闭
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: item, queue: .main
                ) { [weak vc] _ in
                    vc?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    private func playLivePhoto(_ asset: PHAsset) {
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: UIScreen.main.bounds.width * scale,
                                height: UIScreen.main.bounds.height * scale)

        imageManager.requestLivePhoto(for: asset, targetSize: targetSize,
                                      contentMode: .aspectFit, options: options) { [weak self] livePhoto, _ in
            DispatchQueue.main.async {
                guard let self = self, let livePhoto = livePhoto,
                      let topVC = self.topViewController() else { return }
                let vc = LivePhotoViewController(livePhoto: livePhoto)
                vc.modalPresentationStyle = .fullScreen
                self.livePhotoVC = vc
                topVC.present(vc, animated: true, completion: nil)
            }
        }
    }

    // MARK: - 视频 / Live 数据流（v2.5 自动播放）

    // 获取视频数据：视频 → AVURLAsset 读文件；Live Photo → pairedVideo 资源
    // 供 WKURLSchemeHandler(video://) 内嵌自动播放使用
    // completion 保证在主线程回调
    func requestVideoData(for identifier: String, completion: @escaping (Data?, String?) -> Void) {
        guard let asset = asset(for: identifier) else {
            DispatchQueue.main.async { completion(nil, nil) }
            return
        }

        if asset.mediaType == .video {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            // iOS 26 SDK：requestAVAsset 第一个参数标签改为 forVideo
            imageManager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let urlAsset = avAsset as? AVURLAsset else {
                    DispatchQueue.main.async { completion(nil, nil) }
                    return
                }
                let data = try? Data(contentsOf: urlAsset.url)
                let ext = urlAsset.url.pathExtension.lowercased()
                let mime = ext == "mov" ? "video/quicktime" : "video/mp4"
                DispatchQueue.main.async { completion(data, mime) }
            }
        } else if asset.mediaSubtypes.contains(.photoLive) {
            // Live Photo：取配对视频资源（pairedVideo / video）
            let resources = PHAssetResource.assetResources(for: asset)
            guard let videoRes = resources.first(where: { $0.type == .pairedVideo || $0.type == .video }) else {
                DispatchQueue.main.async { completion(nil, nil) }
                return
            }
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            var chunks: [Data] = []
            // iOS 26 SDK：dataHandler 更名为 dataReceivedHandler
            PHAssetResourceManager.default().requestData(for: videoRes, options: options, dataReceivedHandler: { data in
                chunks.append(data)
            }, completionHandler: { _ in
                let joined = chunks.reduce(Data(), +)
                DispatchQueue.main.async { completion(joined, "video/quicktime") }
            })
        } else {
            DispatchQueue.main.async { completion(nil, nil) }
        }
    }

    // 找到当前可 present 的顶层控制器
    private func topViewController() -> UIViewController? {
        var topVC: UIViewController?
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            topVC = window.rootViewController
        }
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }
        return topVC
    }

    // 彻底删除照片（从系统照片库）
    func deleteAssets(_ identifiers: [String], completion: @escaping (Bool, Error?) -> Void) {
        let assets = identifiers.compactMap { asset(for: $0) }
        guard !assets.isEmpty else {
            completion(false, nil)
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    // 收藏照片
    func setFavorite(_ identifier: String, favorite: Bool, completion: @escaping (Bool) -> Void) {
        guard let asset = asset(for: identifier) else {
            completion(false)
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = favorite
        }) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    // 添加到相簿
    func addToAlbum(_ assetIdentifier: String, albumIdentifier: String, completion: @escaping (Bool) -> Void) {
        guard let asset = asset(for: assetIdentifier),
              let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumIdentifier], options: nil).firstObject else {
            completion(false)
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCollectionChangeRequest(for: album)
            request?.addAssets([asset] as NSArray)
        }) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    // 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // 相簿渐变色
    private func gradientForAlbum(_ name: String) -> String {
        let gradients = [
            "linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%)",
            "linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)",
            "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
            "linear-gradient(135deg, #fa709a 0%, #fee140 100%)",
            "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)",
            "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)",
            "linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%)",
            "linear-gradient(135deg, #89f7fe 0%, #66a6ff 100%)",
        ]
        let hash = abs(name.hashValue) % gradients.count
        return gradients[hash]
    }
}
