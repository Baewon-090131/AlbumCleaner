import SwiftUI

/// 单张照片卡。也是「媒体即卡片」：照片 / 播放器本身构成卡片实体，
/// 不再垫一层 `.regularMaterial` 让媒体浮在上面——材质在动画中每帧重采样背景，
/// 会让卡片发飘、露边，也让换卡时多一层重绘。
struct SortCard: View {
    let photo: PhotoItem
    let sizeLabel: String
    let bounds: CGSize
    /// 前置卡为 true：视频 / 实况才加载播放器，后置待命卡只用缩略图。
    var isFront = true
    /// 普通照片的点按：开全屏查看。媒体卡的点按被播放控制占用，不会走到这里。
    var onOpenViewer: () -> Void = {}

    /// 横图占满宽度、竖图占满高度；比例夹在 0.32–3.2，避免超长图把卡片压成一条线。
    private var cardSize: CGSize {
        let ratio = min(max(photo.ratio, 0.32), 3.2)
        let maxWidth = max(0, bounds.width - 8)
        let maxHeight = max(0, bounds.height - 8)
        var width = maxWidth
        var height = maxWidth / ratio
        if height > maxHeight {
            height = maxHeight
            width = maxHeight * ratio
        }
        return CGSize(width: width, height: height)
    }

    var body: some View {
        media
            .frame(width: cardSize.width, height: cardSize.height)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerPlate, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cornerPlate, style: .continuous)
                    .strokeBorder(.white.opacity(0.55), lineWidth: 0.5)
            }
            .shadow(color: Color(red: 12 / 255, green: 18 / 255, blue: 48 / 255).opacity(0.20),
                    radius: 12, y: 8)
            .overlay { badges }
            .accessibilityLabel("待整理的照片")
    }

    @ViewBuilder
    private var media: some View {
        if photo.isVideo {
            VideoCardContent(asset: photo.asset, cardSize: cardSize, isActive: isFront)
        } else if photo.isLivePhoto {
            LivePhotoCardContent(asset: photo.asset, cardSize: cardSize, isActive: isFront)
        } else {
            // 前后卡都按同一尺寸请求高清图：换位时缓存必然命中，不会闪灰块
            AsyncThumbnail(asset: photo.asset, targetSize: cardSize,
                           contentMode: .fill, highQuality: true, glassPlaceholder: true)
                .onTapGesture { onOpenViewer() }
        }
    }

    private var badges: some View {
        VStack {
            HStack {
                Spacer()
                if photo.isVideo {
                    Label(Format.duration(photo.duration), systemImage: "play.fill").badgeStyle()
                } else if photo.isLivePhoto {
                    Text("LIVE").badgeStyle()
                }
            }
            Spacer()
            HStack {
                if !photo.creationText.isEmpty {
                    Text(photo.creationText).badgeStyle()
                }
                Spacer()
                if !sizeLabel.isEmpty {
                    Text(sizeLabel).badgeStyle()
                }
            }
        }
        .padding(12)
        .allowsHitTesting(false)
    }
}

struct EmptyDeckView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.success)
            Text("本月项目已整理完毕")
                .font(.headline)
            Text("删除的照片已移入待删除")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassSurface(cornerRadius: Theme.cornerPlate)
    }
}

extension View {
    /// 卡片角和右上角的小标签统一造型。
    func badgeStyle() -> some View {
        self
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(.black.opacity(0.42), in: Capsule())
    }
}
