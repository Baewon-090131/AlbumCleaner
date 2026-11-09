import SwiftUI
import UIKit

/// 点开一张相纸后的详情覆盖层：
/// 0.15s 内以相纸左上角为锚点放大到屏幕中央、背景逐渐变暗，
/// 落定后底部升起「查看详细信息」，点它绕 Y 轴翻 180° 露出背面参数，
/// 再点空白处倒放退出。
struct PhotoDetailView: View {
    let photo: PhotoItem
    let startFrame: CGRect
    let onClose: () -> Void
    /// 收藏 / 待删。都在详情页里操作，整理页不再有下滑收藏。
    var onFavorite: () -> Void = {}
    var onTrash: () -> Void = {}

    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.displayScale) private var displayScale

    @State private var appeared = false
    @State private var flipped = false
    @State private var showingBack = false
    @State private var showButton = false
    /// 只有放大落定之后才开始播放视频 / 实况
    @State private var isPlayingMedia = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    /// 双指缩放：缩放倍率与拖动位移，`Base` 是上一次手势结束时的值。
    @State private var zoom: CGFloat = 1
    @State private var zoomBase: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var panBase: CGSize = .zero

    private let flipDuration: Double = 0.55

    var body: some View {
        GeometryReader { geo in
            let screen = geo.size
            // 按相纸原始比例放大到刚好装进屏幕：不变形、也不裁切
            let startW = max(startFrame.width, 80)
            let startH = max(startFrame.height, 100)
            let grow = max(min(screen.width * 0.96 / startW,
                               (screen.height - 130) / startH), 1)
            let cardWidth = startW * grow
            let cardHeight = startH * grow
            let startScale = startW / cardWidth
            let targetX = (screen.width - cardWidth) / 2
            let targetY = max(40, (screen.height - cardHeight) / 2 - 24)

            ZStack(alignment: .topLeading) {
                Color.black.opacity(appeared ? 0.30 : 0)
                    .ignoresSafeArea()

                flipCard(width: cardWidth, height: cardHeight)
                    .scaleEffect(appeared ? 1 : startScale, anchor: .topLeading)
                    .offset(x: appeared ? targetX : startFrame.minX,
                            y: appeared ? targetY : startFrame.minY)
                    .scaleEffect(zoom, anchor: .center)
                    .offset(pan)
                    .shadow(color: Color.black.opacity(0.65), radius: 30, y: 18)
                    .gesture(zoomGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .onTapGesture { close() }
            .overlay(alignment: .bottom) {
                if showButton {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            circleButton("收藏", "heart", active: photo.asset.isFavorite) {
                                onFavorite()
                            }
                            circleButton("分享", "square.and.arrow.up", active: false) {
                                share()
                            }
                            circleButton("待删", "trash", active: false) {
                                onTrash()
                            }
                        }
                        actionButton
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.smooth(duration: 0.15)) { appeared = true }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(175))
                withAnimation(.snappy(duration: 0.24)) { showButton = true }
                // 落定之后才让视频 / 实况开始播放
                if photo.isVideo || photo.isLivePhoto {
                    try? await Task.sleep(for: .milliseconds(220))
                    isPlayingMedia = true
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(items: shareItems)
        }
    }
}

private extension PhotoDetailView {
    /// 双指捏合缩放；放大后可以单指拖动查看细节。捏回 1 倍以内会弹回原大小。
    var zoomGesture: some Gesture {
        SimultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    zoom = min(max(zoomBase * value.magnification, 0.85), 4)
                }
                .onEnded { _ in
                    zoomBase = zoom
                    if zoom < 1 {
                        withAnimation(.snappy(duration: 0.3)) {
                            zoom = 1
                            zoomBase = 1
                            pan = .zero
                            panBase = .zero
                        }
                    }
                },
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard zoom > 1.01 else { return }
                    pan = CGSize(width: panBase.width + value.translation.width,
                                 height: panBase.height + value.translation.height)
                }
                .onEnded { _ in panBase = pan }
        )
    }

    func flipCard(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            front(width: width, height: height)
                .opacity(showingBack ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? 180 : 0),
                                  axis: (x: 0, y: 1, z: 0),
                                  perspective: 0.55)

            back(width: width, height: height)
                .opacity(showingBack ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : -180),
                                  axis: (x: 0, y: 1, z: 0),
                                  perspective: 0.55)
        }
        .frame(width: width, height: height)
    }

    func front(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            detailMedia(width: width - 20, height: height - 66)
                .frame(width: width - 20, height: height - 66)
                .background(Theme.card)
                .clipped()

            HStack {
                Text(photo.creationText)
                    .font(.typewriter(11))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(Format.bytes(library.fileSize(of: photo)))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.ink3)
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
        }
        .padding(10)
        .frame(width: width, height: height)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 0.8)
        }
    }

    func back(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MEDIA RECORD")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(3)
                .foregroundStyle(Theme.ink3)
                .padding(.bottom, 14)

            row("拍摄时间", photo.creationText)
            divider
            row("文件体积", Format.bytes(library.fileSize(of: photo)))
            divider
            row("媒体类型", mediaKind)
            divider
            row("原始尺寸", dimensions)
            divider
            row("收藏状态", photo.asset.isFavorite ? "已喜欢" : "未喜欢")

            Spacer(minLength: 8)

            Text("evernight · 整理档案")
                .font(.typewriter(10))
                .foregroundStyle(Theme.ink3)
        }
        .padding(18)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(Theme.paperDeep)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 0.8)
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 0.6)
            .padding(.vertical, 9)
    }

    @ViewBuilder
    func detailMedia(width: CGFloat, height: CGFloat) -> some View {
        if photo.isVideo {
            VideoCardContent(asset: photo.asset,
                             cardSize: CGSize(width: width, height: height),
                             isActive: isPlayingMedia,
                             showsControls: true)
        } else if photo.isLivePhoto {
            LivePhotoCardContent(asset: photo.asset,
                                 cardSize: CGSize(width: width, height: height),
                                 isActive: isPlayingMedia)
        } else {
            AsyncThumbnail(asset: photo.asset,
                           targetSize: CGSize(width: width * displayScale,
                                              height: height * displayScale),
                           contentMode: .fit,
                           highQuality: true,
                           placeholderColor: Theme.card)
        }
    }

    func circleButton(_ title: String, _ symbol: String, active: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(.pingFang(10.5, weight: .semibold))
            }
            .foregroundStyle(active ? Theme.accent : Theme.ink)
            .frame(width: 66, height: 54)
            .background(Theme.card.opacity(0.94),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.line, lineWidth: 0.6)
            }
        }
        .buttonStyle(.plain)
    }

    /// 分享：优先用缓存里的图，没有就异步拉一张再弹系统分享面板。
    func share() {
        let size = CGSize(width: 1200, height: 1200)
        if let image = ThumbnailLoader.shared.cached(for: photo.asset,
                                                     targetSize: size,
                                                     highQuality: true) {
            shareItems = [image]
            showShare = true
            return
        }
        Task { @MainActor in
            if let image = await ThumbnailLoader.shared.image(for: photo.asset,
                                                              targetSize: size,
                                                              highQuality: true) {
                shareItems = [image]
                showShare = true
            }
        }
    }

    func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.pingFang(12))
                .foregroundStyle(Theme.ink2)
                .frame(width: 76, alignment: .leading)
            Text(value)
                .font(.typewriter(12))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
    }

    var mediaKind: String {
        if photo.isVideo { return "视频" }
        if photo.isLivePhoto { return "实况照片" }
        return "照片"
    }

    var dimensions: String {
        "\(Int(photo.asset.pixelWidth)) × \(Int(photo.asset.pixelHeight))"
    }

    var actionButton: some View {
        Button {
            toggleFlip()
        } label: {
            Text(flipped ? "返回" : "查看详细信息")
                .font(.pingFang(14, weight: .semibold))
                .foregroundStyle(Theme.paper)
                .frame(width: 220, height: 50)
                .background(Theme.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 36)
    }

    func toggleFlip() {
        let target = !flipped
        withAnimation(.smooth(duration: flipDuration)) { flipped = target }
        // 翻到 90° 那一拍再换面，避免两面同时可见
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(flipDuration * 1000 / 2)))
            showingBack = target
        }
    }

    func close() {
        if flipped {
            toggleFlip()
            return
        }
        // 退出时先复位缩放，倒放才是从相纸原尺寸回缩略图
        withoutAnimation {
            zoom = 1
            zoomBase = 1
            pan = .zero
            panBase = .zero
        }
        withAnimation(.smooth(duration: 0.15)) {
            appeared = false
            showButton = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(165))
            onClose()
        }
    }
}

/// 系统分享面板的 SwiftUI 包装。
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
