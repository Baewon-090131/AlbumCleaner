import SwiftUI

/// 拍立得相纸的尺寸：照片窗口 + 白边 + 底部 note 区。
///
/// 照片区比例规则：**竖图保留原始比例**（相纸跟着变窄变高），
/// **横图 / 方图进正方形窗口**，照片本身按原比例 `aspectFit`，上下留白就是相纸的白边。
struct PolaroidMetrics {
    let photo: CGSize
    let pad: CGFloat = 9
    let noteHeight: CGFloat = 44

    var paper: CGSize {
        CGSize(width: photo.width + pad * 2, height: photo.height + pad + noteHeight)
    }

    /// 相纸**按照片原始比例**长（竖图窄高、横图宽矮），只对极端比例做收口，
    /// 保证相纸不会细成一条、也不会长成一门板。照片用 `aspectFit`，
    /// 窗口与比例一致时没有留白；只有接近 16:9 这类更扁的图会留很窄的一条。
    static func make(for photo: PhotoItem, bounds: CGSize, paperScale: CGFloat = 0.66) -> PolaroidMetrics {
        let paperWidth = min(max(bounds.width * paperScale, 110), max(110, bounds.width - 24))
        let baseWidth = paperWidth - 18
        let ratio = min(max(photo.ratio, 0.42), 2.2)
        let maxHeight = max(bounds.height * 0.66, 180)
        let minHeight = baseWidth * 0.6

        var height = baseWidth / ratio
        var width = baseWidth
        if height > maxHeight {
            height = maxHeight
            width = height * ratio
        }
        if height < minHeight {
            height = minHeight
        }
        return PolaroidMetrics(photo: CGSize(width: width, height: height))
    }
}

/// 一张拍立得相纸：白边 + 底部手写日期 + 顶部木夹。
/// 照片就是相纸本身，没有额外的材质叠层——投影只加在相纸这一层，
/// 拖动时不会每帧重采样背景。
struct PolaroidCard: View {
    let photo: PhotoItem
    let metrics: PolaroidMetrics
    let sizeLabel: String
    /// 当前中间那张为 true：只有它加载视频 / 实况播放器。
    var isFront = true
    /// 碎沙擦拭：0 = 完整，1 = 全部消失。遮罩从**底部**往上收，所以底边先被擦掉。
    var erase: CGFloat = 0
    /// 是否加载视频 / 实况播放器。整理页里一律 false（只显示静态帧，点按才进详情），
    /// 详情页里传 true 才开始真正播放。
    var allowPlayback = false
    var onOpenViewer: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            photoWindow
                .frame(width: metrics.photo.width, height: metrics.photo.height)
                .clipped()
                .overlay(alignment: .topLeading) { mediaBadge }
            note
                .frame(width: metrics.photo.width, height: metrics.noteHeight)
        }
        .padding(.horizontal, metrics.pad)
        .padding(.top, metrics.pad)
        .background(Theme.card)
        .shadow(color: Theme.ink.opacity(0.10), radius: 2, y: 1)
        .shadow(color: Theme.ink.opacity(0.22), radius: 18, y: 16)
        .mask(eraseMask)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("待整理的照片")
    }

    /// 底部先透明；`erase` 越大，透明区越往上长，边界留 6% 的软过渡。
    private var eraseMask: LinearGradient {
        let edge: CGFloat = 0.06
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

    @ViewBuilder
    private var photoWindow: some View {
        if photo.isVideo, allowPlayback {
            VideoCardContent(asset: photo.asset, cardSize: metrics.photo, isActive: isFront)
        } else if photo.isLivePhoto, allowPlayback {
            LivePhotoCardContent(asset: photo.asset, cardSize: metrics.photo, isActive: isFront)
        } else {
            // 窗口尺寸恒定，所有照片都 fit 进来，不裁切也不拉伸
            AsyncThumbnail(asset: photo.asset, targetSize: metrics.photo,
                           contentMode: .fit,
                           highQuality: true,
                           placeholderColor: Theme.card)
                .background(Theme.card)
                .onTapGesture { onOpenViewer() }
        }
    }

    /// note 区：左边拍摄日期（衬线斜体），右边体积（等宽小字）。
    private var note: some View {
        HStack(spacing: 6) {
            Text(photo.creationText)
                .font(.system(size: 14, design: .serif).italic())
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Spacer(minLength: 4)
            if !sizeLabel.isEmpty {
                Text(sizeLabel)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.ink3)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private var mediaBadge: some View {
        if photo.isVideo || photo.isLivePhoto {
            Text(photo.isVideo ? Format.duration(photo.duration) : "LIVE")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.card)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Theme.scrim.opacity(0.55), in: RoundedRectangle(cornerRadius: 2))
                .padding(7)
        }
    }

}

/// 木夹。放在卡片之外绘制，`zIndex` 高于绳子——绳子从卡片上方横过，夹子压在绳上。
struct PolaroidPeg: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: "#C9A67A"),
                                          Color(hex: "#E3C9A1"),
                                          Color(hex: "#B8915F")],
                                 startPoint: .leading,
                                 endPoint: .trailing))
            .frame(width: 10, height: 30)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(hex: "#503C1E").opacity(0.45))
                    .frame(width: 2, height: 7)
                    .padding(.top, 8)
            }
            .shadow(color: Theme.ink.opacity(0.25), radius: 2, y: 2)
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
                .foregroundStyle(Theme.ink2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassSurface(cornerRadius: Theme.cornerPlate)
    }
}
