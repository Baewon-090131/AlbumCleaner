import Photos

/// 一张照片/视频。PHAsset 不是值类型，这里只是把它包起来，附带界面需要的派生属性。
struct PhotoItem: Identifiable {
    let asset: PHAsset

    var id: String { asset.localIdentifier }
    var creationDate: Date? { asset.creationDate }
    var isVideo: Bool { asset.mediaType == .video }
    var isLivePhoto: Bool { asset.mediaSubtypes.contains(.photoLive) }

    /// 宽高比：卡片按它决定尺寸，横图撑满宽度、竖图撑满高度。
    var ratio: Double {
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else { return 0.75 }
        return Double(asset.pixelWidth) / Double(asset.pixelHeight)
    }

    var duration: TimeInterval { asset.duration }

    var creationText: String {
        guard let date = asset.creationDate else { return "" }
        return PhotoItem.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()
}

struct MonthSection: Identifiable {
    let id: String
    let title: String
    var photos: [PhotoItem]
}

struct AlbumItem: Identifiable {
    let id: String
    let name: String
    let count: Int
    let coverAsset: PHAsset?
}

struct StorageInfo {
    let total: Int64
    let free: Int64

    var used: Int64 { max(0, total - free) }
    var usedRatio: Double { total > 0 ? Double(used) / Double(total) : 0 }

    static let empty = StorageInfo(total: 0, free: 0)
}

enum Format {
    static func bytes(_ value: Int64) -> String {
        guard value > 0 else { return "0 KB" }
        let mb = Double(value) / (1024 * 1024)
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024) }
        if mb >= 1 { return String(format: "%.1f MB", mb) }
        return "\(max(1, Int((Double(value) / 1024).rounded()))) KB"
    }

    static func gigabytes(_ value: Int64) -> String {
        "\(Int((Double(value) / (1024 * 1024 * 1024)).rounded())) GB"
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
