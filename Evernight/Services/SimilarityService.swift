import Photos
import UIKit
import Observation

/// 一组相似照片。`bestID` 是组内评分最高、默认保留的那张。
struct SimilarGroup: Identifiable {
    let id: Int
    var photos: [PhotoItem]
    let bestID: String

    var others: [PhotoItem] { photos.filter { $0.id != bestID } }

    /// 组内最新拍摄年份，给年份筛选用。
    var latestYear: Int? {
        photos.compactMap(\.creationDate)
            .map { Calendar.current.component(.year, from: $0) }
            .max()
    }
}

/// 相似检测：全库静态照片算 64 位 dHash 指纹 → 16 位分段分桶找候选对 →
/// 汉明距离 ≤ 7 的并成一组。指纹落 UserDefaults，之后只增量扫新照片。
/// 视频不参与（抽帧比对成本高、收益低）。
@Observable
@MainActor
final class SimilarityService {
    private(set) var groups: [SimilarGroup] = []
    private(set) var isScanning = false
    private(set) var progress: Double = 0
    private(set) var hasScanned = false
    /// 已扫到的静态照片总数（界面上报「发现 N 组 · M 张可清理」用）。
    private(set) var scannedCount = 0

    private var fingerprints: [String: UInt64]
    /// 组内挑「最优」时的体积分，由视图层注入（fileSize 的缓存归 PhotoLibraryService）。
    private var fileSizeProvider: (PhotoItem) -> Int64 = { _ in 0 }

    private let cacheKey = "ac_similar_hash_v1"
    /// 汉明距离阈值：越小越严格。7 是「连拍 / 同场景微调」档。
    private let threshold = 7

    init() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([String: UInt64].self, from: data) {
            fingerprints = cached
        } else {
            fingerprints = [:]
        }
    }

    /// 全量入口：传入当前库里的照片（不含回收站）。增量部分只算没指纹的。
    func scan(photos: [PhotoItem], fileSize: @escaping (PhotoItem) -> Int64) async {
        guard !isScanning else { return }
        isScanning = true
        progress = 0
        defer {
            isScanning = false
            hasScanned = true
        }
        fileSizeProvider = fileSize

        let targets = photos.filter { !$0.isVideo }
        scannedCount = targets.count

        // 清掉已经不在库里的指纹
        let alive = Set(targets.map(\.id))
        fingerprints = fingerprints.filter { alive.contains($0.key) }

        let pending = targets.filter { fingerprints[$0.id] == nil }
        let total = max(1, pending.count)
        var done = 0

        if !pending.isEmpty {
            await withTaskGroup(of: (String, UInt64?).self) { group in
                var iterator = pending.makeIterator()
                // 6 路并发喂满
                for _ in 0..<6 {
                    guard let photo = iterator.next() else { break }
                    group.addTask { (photo.id, await Self.fingerprint(of: photo.asset)) }
                }
                while let (id, hash) = await group.next() {
                    if let hash { fingerprints[id] = hash }
                    done += 1
                    if done % 12 == 0 || done == total {
                        progress = Double(done) / Double(total)
                    }
                    if let photo = iterator.next() {
                        group.addTask { (photo.id, await Self.fingerprint(of: photo.asset)) }
                    }
                }
            }
            saveCache()
        }
        progress = 1

        groups = buildGroups(
            photos: targets,
            score: { photo in
                Double(photo.asset.pixelWidth * photo.asset.pixelHeight)
                    + Double(fileSize(photo)) / 1_000_000
            }
        )
    }

    /// 照片被送走（进回收站 / 彻底删除）后同步分组：少于 2 张的组直接散伙。
    func remove(_ ids: Set<String>) {
        groups = groups.compactMap { group in
            let photos = group.photos.filter { !ids.contains($0.id) }
            guard photos.count >= 2 else { return nil }
            let bestID = ids.contains(group.bestID) ? photos[0].id : group.bestID
            return SimilarGroup(id: group.id, photos: photos, bestID: bestID)
        }
    }

    // MARK: - 分组

    /// 分桶 + 并查集都在主 actor 上跑：分桶后候选对很少，万级照片也就几十毫秒。
    private func buildGroups(
        photos: [PhotoItem],
        score: (PhotoItem) -> Double
    ) -> [SimilarGroup] {
        // 16 位分段分桶：候选对数量从 O(n²) 降到近似 O(n)
        var buckets: [UInt16: [String]] = [:]
        for (id, hash) in fingerprints {
            for shift in stride(from: 0, through: 48, by: 16) {
                let key = UInt16(truncatingIfNeeded: hash >> shift)
                buckets[key, default: []].append(id)
            }
        }

        // 并查集
        var parent: [String: String] = [:]
        func root(of x: String) -> String {
            var node = x
            var path: [String] = []
            while let next = parent[node], next != node {
                path.append(node)
                node = next
            }
            for item in path { parent[item] = node }
            return node
        }

        func hamming(_ a: UInt64, _ b: UInt64) -> Int { (a ^ b).nonzeroBitCount }

        for ids in buckets.values {
            // 巨桶一般是全白 / 全黑这类通用内容，跳过避免误判风暴
            guard ids.count > 1, ids.count <= 60 else { continue }
            for i in 0..<ids.count {
                for j in (i + 1)..<ids.count {
                    guard let a = fingerprints[ids[i]], let b = fingerprints[ids[j]],
                          hamming(a, b) <= threshold else { continue }
                    parent[root(of: ids[i])] = root(of: ids[j])
                }
            }
        }

        // 收成组
        var clustered: [String: [String]] = [:]
        for id in fingerprints.keys {
            if let own = parent[id] {
                clustered[root(of: own), default: []].append(id)
            }
        }

        let byID = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0) })
        var result: [SimilarGroup] = []
        for (_, ids) in clustered where ids.count >= 2 {
            let members = ids.compactMap { byID[$0] }
            guard members.count >= 2 else { continue }
            let best = members.max(by: { score($0) < score($1) }) ?? members[0]
            let ordered = members.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
            result.append(SimilarGroup(id: result.count, photos: ordered, bestID: best.id))
        }
        // 组按最新照片排序，新的在前
        result.sort {
            ($0.photos.first?.creationDate ?? .distantPast) > ($1.photos.first?.creationDate ?? .distantPast)
        }
        // 组 id 重排成稳定递增
        return result.enumerated().map { index, group in
            SimilarGroup(id: index, photos: group.photos, bestID: group.bestID)
        }
    }

    // MARK: - 指纹

    /// 64x64 缩略图 → 9x8 灰度 → dHash。走 ThumbnailLoader 复用其缓存与请求封装。
    nonisolated private static func fingerprint(of asset: PHAsset) async -> UInt64? {
        guard let image = await ThumbnailLoader.shared.image(for: asset,
                                                             targetSize: CGSize(width: 64, height: 64)),
              let cgImage = image.cgImage else { return nil }
        return dHash(cgImage)
    }

    /// 9x8 灰度图上比较左右相邻像素，得 64 位差异哈希。
    nonisolated private static func dHash(_ image: CGImage) -> UInt64? {
        let width = 9, height = 8
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &pixels, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hash: UInt64 = 0
        for y in 0..<height {
            for x in 0..<(width - 1) where pixels[y * width + x] > pixels[y * width + x + 1] {
                hash |= 1 << (y * 8 + x)
            }
        }
        return hash
    }

    private func saveCache() {
        guard let data = try? JSONEncoder().encode(fingerprints) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
}
