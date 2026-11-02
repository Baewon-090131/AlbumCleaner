import Photos
import UIKit
import Observation

/// 照片库的唯一数据源：权限、按月分组、相簿、回收站、系统相簿写入。
/// 视图只读它的 `private(set)` 属性，所有写操作都走这里的方法。
@Observable
@MainActor
final class PhotoLibraryService {
    private(set) var months: [MonthSection] = []
    private(set) var albums: [AlbumItem] = []
    private(set) var storage: StorageInfo = .empty
    private(set) var isLoading = true
    private(set) var isDenied = false

    /// 应用内回收站：删除先落到这里，只有「彻底删除」才真正动系统相册。
    private(set) var trash: [PhotoItem] = []

    /// 累计战果：彻底删除成功时落账，存 UserDefaults。
    private(set) var totalCleaned: Int
    private(set) var totalFreedBytes: Int64

    private var fileSizeCache: [String: Int64] = [:]

    init() {
        totalCleaned = UserDefaults.standard.integer(forKey: "ac_totalCleaned")
        totalFreedBytes = Int64(UserDefaults.standard.double(forKey: "ac_totalFreed"))
    }

    // MARK: - 加载

    func load() async {
        isLoading = true
        defer { isLoading = false }

        guard await requestAuthorization() else {
            isDenied = true
            return
        }
        isDenied = false

        let assets = fetchAllAssets()
        months = groupByMonth(assets)
        albums = fetchAlbums()
        storage = readStorage()
    }

    func refreshStorage() {
        storage = readStorage()
    }

    // MARK: - 整理

    func moveToTrash(_ item: PhotoItem) {
        trash.insert(item, at: 0)
        removeFromMonths(item.id)
    }

    func restore(_ item: PhotoItem) {
        trash.removeAll { $0.id == item.id }
        guard let date = item.creationDate else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M"
        let key = formatter.string(from: date)
        guard let monthIndex = months.firstIndex(where: { $0.id == key }) else { return }

        // 按创建日期插回原位，而不是粗暴地塞到最前面
        let insertAt = months[monthIndex].photos.firstIndex {
            ($0.creationDate ?? .distantPast) < date
        } ?? months[monthIndex].photos.count
        months[monthIndex].photos.insert(item, at: insertAt)
    }

    func removeFromTrash(_ item: PhotoItem) {
        trash.removeAll { $0.id == item.id }
    }

    func emptyTrash() {
        trash.removeAll()
    }

    /// 真正从系统相册删除（回收站里的「彻底删除」）。返回是否成功——
    /// 用户在系统弹窗里拒绝时返回 false，界面据此决定要不要放回未勾选项。
    @discardableResult
    func deleteFromSystem(_ items: [PhotoItem]) async -> Bool {
        guard !items.isEmpty else { return false }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(items.map(\.asset) as NSArray)
            }
            let freed = items.reduce(into: Int64(0)) { $0 += fileSize(of: $1) }
            for item in items { removeFromTrash(item) }
            totalCleaned += items.count
            totalFreedBytes += freed
            UserDefaults.standard.set(totalCleaned, forKey: "ac_totalCleaned")
            UserDefaults.standard.set(Double(totalFreedBytes), forKey: "ac_totalFreed")
            return true
        } catch {
            // 用户可能在系统弹窗里拒绝；保持回收站原样，交给界面提示
            return false
        }
    }

    func setFavorite(_ item: PhotoItem, _ value: Bool) {
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: item.asset)
            request.isFavorite = value
        }
    }

    func add(_ item: PhotoItem, to album: AlbumItem) {
        guard let collection = fetchCollection(album.id) else { return }
        PHPhotoLibrary.shared().performChanges {
            guard let request = PHAssetCollectionChangeRequest(for: collection) else { return }
            request.addAssets([item.asset] as NSArray)
        }
    }

    /// 把照片从相簿里移出（撤回「存入相簿」用）。照片本身留在系统相册，只是不在这个相簿里。
    func remove(_ item: PhotoItem, from album: AlbumItem) {
        guard let collection = fetchCollection(album.id) else { return }
        PHPhotoLibrary.shared().performChanges {
            guard let request = PHAssetCollectionChangeRequest(for: collection) else { return }
            request.removeAssets([item.asset] as NSArray)
        }
    }

    // MARK: - 相簿

    func photos(in album: AlbumItem) -> [PhotoItem] {
        guard let collection = fetchCollection(album.id) else { return [] }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(in: collection, options: options)
        var items: [PhotoItem] = []
        result.enumerateObjects { asset, _, _ in
            items.append(PhotoItem(asset: asset))
        }
        return items
    }

    /// 用户自建相簿里的空相簿（智能相簿不可删，不算进来）。
    var emptyUserAlbums: [AlbumItem] {
        albums.filter { $0.isUserAlbum && $0.count == 0 }
    }

    /// 相簿结构变更后重拉列表（新建 / 重命名 / 删除之后）。
    func reloadAlbums() {
        albums = fetchAlbums()
    }

    /// 新建相簿，直接写进系统相册。
    func createAlbum(named name: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: trimmed)
            }
            reloadAlbums()
            return true
        } catch { return false }
    }

    func renameAlbum(_ album: AlbumItem, to name: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let collection = fetchCollection(album.id) else { return false }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                guard let request = PHAssetCollectionChangeRequest(for: collection) else { return }
                request.title = trimmed
            }
            reloadAlbums()
            return true
        } catch { return false }
    }

    /// 删除相簿本体（照片留在系统相册）。
    func deleteAlbums(_ targets: [AlbumItem]) async -> Bool {
        let collections = targets.compactMap { fetchCollection($0.id) }
        guard !collections.isEmpty else { return false }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.deleteAssetCollections(collections as NSArray)
            }
            reloadAlbums()
            return true
        } catch { return false }
    }

    /// 删除相簿并把里面的照片一起从系统相册删掉。
    func deleteAlbumWithPhotos(_ album: AlbumItem) async -> Bool {
        guard let collection = fetchCollection(album.id) else { return false }
        let assets = PHAsset.fetchAssets(in: collection, options: nil)
        guard assets.count > 0 else { return await deleteAlbums([album]) }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets)
                PHAssetCollectionChangeRequest.deleteAssetCollections([collection] as NSArray)
            }
            reloadAlbums()
            return true
        } catch { return false }
    }

    /// 把相簿里的全部照片搬到另一个相簿（原相簿变空，不删）。
    func moveAllPhotos(from source: AlbumItem, to target: AlbumItem) async -> Bool {
        guard let from = fetchCollection(source.id), let to = fetchCollection(target.id) else { return false }
        let assets = PHAsset.fetchAssets(in: from, options: nil)
        guard assets.count > 0 else { return false }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                if let addRequest = PHAssetCollectionChangeRequest(for: to) {
                    addRequest.addAssets(assets)
                }
                if let removeRequest = PHAssetCollectionChangeRequest(for: from) {
                    removeRequest.removeAssets(assets)
                }
            }
            reloadAlbums()
            return true
        } catch { return false }
    }

    // MARK: - 收藏

    /// 系统相册里所有收藏项（「我的 → 已喜欢」列表用）。
    func favoritePhotos() -> [PhotoItem] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "isFavorite == YES")
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: options)
        var items: [PhotoItem] = []
        result.enumerateObjects { asset, _, _ in items.append(PhotoItem(asset: asset)) }
        return items
    }

    // MARK: - 体积

    func fileSize(of item: PhotoItem) -> Int64 {
        if let cached = fileSizeCache[item.id] { return cached }
        var total: Int64 = 0
        for resource in PHAssetResource.assetResources(for: item.asset) {
            if let size = resource.value(forKey: "fileSize") as? Int64 { total += size }
        }
        fileSizeCache[item.id] = total
        return total
    }

    var trashByteCount: Int64 {
        trash.reduce(into: Int64(0)) { sum, item in sum += fileSize(of: item) }
    }

    // MARK: - 内部

    private func requestAuthorization() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return status == .authorized || status == .limited
        default:
            return false
        }
    }

    private func fetchAllAssets() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    private func groupByMonth(_ assets: [PHAsset]) -> [MonthSection] {
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-M"
        let titleFormatter = DateFormatter()
        titleFormatter.dateFormat = "yyyy年M月"

        var buckets: [String: [PhotoItem]] = [:]
        var order: [String] = []

        for asset in assets {
            guard let date = asset.creationDate else { continue }
            let key = keyFormatter.string(from: date)
            if buckets[key] == nil {
                buckets[key] = []
                order.append(key)
            }
            buckets[key]?.append(PhotoItem(asset: asset))
        }

        return order.compactMap { key in
            guard let photos = buckets[key], let first = photos.first?.creationDate else { return nil }
            return MonthSection(id: key, title: titleFormatter.string(from: first), photos: photos)
        }
    }

    private func removeFromMonths(_ id: String) {
        for index in months.indices {
            months[index].photos.removeAll { $0.id == id }
        }
    }

    private func fetchCollection(_ identifier: String) -> PHAssetCollection? {
        PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil).firstObject
    }

    private func fetchAlbums() -> [AlbumItem] {
        let coverOptions = PHFetchOptions()
        coverOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        coverOptions.fetchLimit = 1

        func payload(_ collection: PHAssetCollection, isUserAlbum: Bool) -> AlbumItem? {
            guard let name = collection.localizedTitle else { return nil }
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            let cover = PHAsset.fetchAssets(in: collection, options: coverOptions).firstObject
            return AlbumItem(id: collection.localIdentifier, name: name, count: count,
                             coverAsset: cover, isUserAlbum: isUserAlbum)
        }

        var result: [AlbumItem] = []
        PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            .enumerateObjects { collection, _, _ in
                if let item = payload(collection, isUserAlbum: false) { result.append(item) }
            }
        PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
            .enumerateObjects { collection, _, _ in
                if let item = payload(collection, isUserAlbum: true) { result.append(item) }
            }
        return result
    }

    private func readStorage() -> StorageInfo {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        guard let values = try? url.resourceValues(
            forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        ) else { return .empty }
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = values.volumeAvailableCapacityForImportantUsage ?? 0
        return StorageInfo(total: total, free: free)
    }
}
