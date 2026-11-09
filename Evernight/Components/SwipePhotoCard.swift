import SwiftUI

/// 整理页的单张照片卡（液态玻璃版）。
///
/// 与旧拍立得相纸不同：**没有白边、没有木夹**，照片自己就是卡片。
/// 圆角 24，顶部两枚胶囊角标（左：HDR / 实况 / 视频，右：日期 · 体积）。
/// 拖动到删除阈值时整张卡外缘浮起一圈绯红光晕（`glow` 0 → 1）。
struct SwipePhotoCard: View {
    let photo: PhotoItem
    let cardSize: CGSize
    let sizeLabel: String
    /// 删除阈值光晕：0 = 无，1 = 到阈值。
    var glow: CGFloat = 0
    /// 碎沙擦拭：0 = 完整，1 = 消失。
    var erase: CGFloat = 0
    var onTap: () -> Void = {}

    private let radius: CGFloat = 24

    var body: some View {
        AsyncThumbnail(asset: photo.asset,
                       targetSize: cardSize,
                       contentMode: .fill,
                       highQuality: true,
                       placeholderColor: Theme.nightPanel)
            .frame(width: cardSize.width, height: cardSize.height)
            .clipped()
            .overlay(alignment: .topLeading) { leftBadge }
            .overlay(alignment: .topTrailing) { rightBadge }
            .overlay(alignment: .topTrailing) {
                if photo.asset.isFavorite {
                    NightFlower(kind: .seal, angle: -8)
                        .frame(width: 40, height: 40)
                        .padding(48)
                        .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
            }
            .overlay {
                // 阈值光晕：贴边一道绯红线，外侧再发光
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(0.9 * Double(glow)), lineWidth: 2)
            }
            .shadow(color: Theme.accent.opacity(0.6 * Double(glow)), radius: 24 * glow)
            .shadow(color: .black.opacity(0.55), radius: 22, y: 16)
            .mask(eraseMask)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .onTapGesture { onTap() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("待整理的照片")
    }

    /// 底部先透明；`erase` 越大透明区越往上长。
    private var eraseMask: LinearGradient {
        let edge: CGFloat = 0.08
        let boundary = max(0, min(1, 1 - erase))
        return LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: max(0, boundary - edge)),
                .init(color: .clear, location: boundary),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var leftBadge: some View {
        Text(photo.isVideo ? "视频" : (photo.isLivePhoto ? "实况" : "HDR"))
            .font(.typewriter(9, weight: .semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(10)
    }

    private var rightBadge: some View {
        HStack(spacing: 3) {
            Text(photo.creationText)
            if !sizeLabel.isEmpty {
                Text("·")
                Text(sizeLabel)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .semibold))
        }
        .font(.typewriter(9.5))
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(10)
    }
}

/// 相簿托盘：下拉时从底部升起，横向一排相簿，卡片悬在哪一格就高亮哪一格。
struct AlbumDropTray: View {
    let albums: [AlbumItem]
    /// 被卡片悬停命中的相簿。
    let hovered: AlbumItem?
    /// 0 = 完全收起，1 = 完全展开。
    let progress: CGFloat

    /// 单格宽 / 间距 / 两侧留白，手势命中判定用同一组数。
    static let chip: CGFloat = 84
    static let gap: CGFloat = 10
    static let inset: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("拖到相簿")
                .font(.pingFang(11))
                .foregroundStyle(Theme.text3)
                .padding(.horizontal, Self.inset)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.gap) {
                    ForEach(albums) { album in
                        chipView(album)
                    }
                    moreChip
                }
                .padding(.horizontal, Self.inset)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background {
            Theme.nightRaised.opacity(0.94)
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.nightLine).frame(height: 0.5)
                }
        }
        .opacity(Double(progress))
        .offset(y: (1 - progress) * 60)
        .allowsHitTesting(progress > 0.5)
    }

    /// 卡片中心 x 落在第几格；超出可见范围返回 nil。
    static func index(at x: CGFloat, count: Int) -> Int? {
        let step = chip + gap
        let raw = Int(((x - inset) / step).rounded(.down))
        guard raw >= 0, raw < count else { return nil }
        return raw
    }

    private func chipView(_ album: AlbumItem) -> some View {
        let on = hovered?.id == album.id
        return Rectangle()
            .fill(Theme.nightPanel)
            .frame(width: Self.chip, height: Self.chip)
            .overlay {
                if let cover = album.coverAsset {
                    AsyncThumbnail(asset: cover,
                                   targetSize: CGSize(width: Self.chip * 2, height: Self.chip * 2),
                                   contentMode: .fill)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.62)],
                               startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(on ? Theme.accent : Theme.nightLine,
                                  lineWidth: on ? 2 : 0.5)
            }
            .overlay(alignment: .bottomLeading) {
                Text(album.name)
                    .font(.pingFang(9))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 5)
            }
            .overlay(alignment: .topTrailing) {
                Text("\(album.count)")
                    .font(.typewriter(8.5, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.35), in: Capsule())
                    .padding(5)
            }
            .scaleEffect(on ? 1.04 : 1)
            .animation(.snappy(duration: 0.2), value: on)
    }

    private var moreChip: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Theme.nightPanel)
            .frame(width: Self.chip, height: Self.chip)
            .overlay {
                VStack(spacing: 2) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                    Text("更多")
                        .font(.pingFang(9))
                }
                .foregroundStyle(Theme.text3)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.nightLine, lineWidth: 0.5)
            }
    }
}
