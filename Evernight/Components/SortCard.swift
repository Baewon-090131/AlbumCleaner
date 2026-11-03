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

    static func make(for photo: PhotoItem, bounds: CGSize) -> PolaroidMetrics {
        let paperWidth = min(max(bounds.width * 0.46, 132), 186)
        let photoWidth = paperWidth - 18
        let ratio = min(max(photo.ratio, 0.32), 3.2)
        let maxPhotoHeight = max(bounds.height * 0.56, 150)

        guard ratio < 1 else {
            return PolaroidMetrics(photo: CGSize(width: photoWidth, height: photoWidth))
        }
        var height = photoWidth / ratio
        var width = photoWidth
        if height > maxPhotoHeight {
            height = maxPhotoHeight
            width = height * ratio
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
        .overlay(alignment: .top) { peg }
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
        if photo.isVideo {
            VideoCardContent(asset: photo.asset, cardSize: metrics.photo, isActive: isFront)
        } else if photo.isLivePhoto {
            LivePhotoCardContent(asset: photo.asset, cardSize: metrics.photo, isActive: isFront)
        } else {
            // 方形窗口里的横图必须 fit，否则会被裁掉两侧、破坏原始比例
            AsyncThumbnail(asset: photo.asset, targetSize: metrics.photo,
                           contentMode: isSquare ? .fit : .fill,
                           highQuality: true)
                .background(Theme.card)
                .onTapGesture { onOpenViewer() }
        }
    }

    private var isSquare: Bool {
        abs(metrics.photo.width - metrics.photo.height) < 0.5
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

    /// 木夹：两色渐变的小夹子，压在相纸顶边中央。
    private var peg: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: "#C9A67A"),
                                          Color(hex: "#E3C9A1"),
                                          Color(hex: "#B8915F")],
                                 startPoint: .leading,
                                 endPoint: .trailing))
            .frame(width: 10, height: 26)
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
