import AVKit
import CoreMedia
import Photos
import PhotosUI
import SwiftUI

/// 视频卡内容：AVPlayerLayer 直接嵌进卡片，出现即静音循环播放，点按暂停 / 继续。
/// 只在前置卡激活（`isActive`）；后置待命卡退化为静态缩略图，避免凭空多起一个播放器。
struct VideoCardContent: View {
    let asset: PHAsset
    /// 卡片尺寸（点），缩略图按它请求，保证与卡片一致、不留边。
    let cardSize: CGSize
    var isActive: Bool

    @AppStorage("ac_videoMuted") private var muted = true
    @AppStorage("ac_autoVideo") private var autoPlay = true

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    /// 播到头的观察者，disappear 时摘掉，防止泄漏。
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            if let player, isActive {
                PlayerLayerView(player: player)
                    .onTapGesture { toggle() }
            } else {
                AsyncThumbnail(asset: asset, targetSize: cardSize,
                               contentMode: .fill, highQuality: true, glassPlaceholder: true)
            }

            // 左上：静音切换
            if player != nil, isActive {
                muteBadge
            }

            // 底部：细进度条
            if isPlaying || progress > 0 {
                progressBar
            }
        }
        .task(id: asset.localIdentifier) {
            guard isActive else { return }
            await load()
        }
        .onDisappear { stop() }
    }

    private var muteBadge: some View {
        VStack {
            HStack {
                Button {
                    muted.toggle()
                    player?.isMuted = muted
                } label: {
                    Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Theme.scrim.opacity(0.5), in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            Spacer()
        }
        .padding(12)
    }

    private var progressBar: some View {
        VStack {
            Spacer()
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.35))
                    Capsule().fill(.white)
                        .frame(width: max(0, geometry.size.width * progress))
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .allowsHitTesting(false)
    }

    private func load() async {
        let avAsset = await withCheckedContinuation { (continuation: CheckedContinuation<AVAsset?, Never>) in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            var resumed = false
            PHCachingImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: avAsset)
            }
        }
        guard let avAsset else { return }

        let item = AVPlayerItem(asset: avAsset)
        let player = AVPlayer(playerItem: item)
        player.isMuted = muted
        // 循环：播到头回卷再播
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        // 进度：每 0.2s 采样一次
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 30),
                                       queue: .main) { time in
            let duration = item.duration.seconds
            guard duration.isFinite, duration > 0 else { return }
            progress = time.seconds / duration
        }
        self.player = player
        if autoPlay {
            player.play()
            isPlaying = true
        }
    }

    private func toggle() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func stop() {
        player?.pause()
        isPlaying = false
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }
}

/// 包一层 AVPlayerLayer，让视频按卡片尺寸等比适配（SwiftUI 的 VideoPlayer 控制不了 contentMode）。
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) { fatalError("不用 storyboard") }
}

/// 实况卡内容：PHLivePhotoView 包进卡片，出现时自动播一次实况效果，点按重播。
struct LivePhotoCardContent: View {
    let asset: PHAsset
    /// 卡片尺寸（点），缩略图按它请求，与卡片一致。
    let cardSize: CGSize
    var isActive: Bool

    @AppStorage("ac_autoLive") private var autoPlay = true
    @State private var livePhoto: PHLivePhoto?
    /// 点按重播靠这个自增值传给 representable，在 updateUIView 里认出变化。
    @State private var replayToken = 0

    var body: some View {
        ZStack {
            if let livePhoto, isActive {
                LivePhotoView(livePhoto: livePhoto, replayToken: replayToken)
                    .onTapGesture { replayToken += 1 }
            } else {
                AsyncThumbnail(asset: asset, targetSize: cardSize,
                               contentMode: .fill, highQuality: true, glassPlaceholder: true)
            }
        }
        .task(id: asset.localIdentifier) {
            guard isActive else { return }
            await load()
            if autoPlay { replayToken += 1 }
        }
    }

    private func load() async {
        livePhoto = await withCheckedContinuation { (continuation: CheckedContinuation<PHLivePhoto?, Never>) in
            let options = PHLivePhotoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            var resumed = false
            PHCachingImageManager.default().requestLivePhoto(
                for: asset, targetSize: CGSize(width: 1200, height: 1200),
                contentMode: .aspectFit, options: options
            ) { livePhoto, info in
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if degraded { return }
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: livePhoto)
            }
        }
    }

    private struct LivePhotoView: UIViewRepresentable {
        let livePhoto: PHLivePhoto
        let replayToken: Int

        /// context.coordinator 只读，coordinator 用引用类型才能记下上次播到哪个 token。
        final class Coordinator {
            var lastToken = 0
        }

        func makeCoordinator() -> Coordinator { Coordinator() }

        func makeUIView(context: Context) -> PHLivePhotoView {
            let view = PHLivePhotoView()
            view.livePhoto = livePhoto
            view.contentMode = .scaleAspectFill
            return view
        }

        func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
            if uiView.livePhoto !== livePhoto {
                uiView.livePhoto = livePhoto
            }
            // replayToken 变化 = 要播一次（首次载入的自动播放也走这条路）
            if context.coordinator.lastToken != replayToken {
                context.coordinator.lastToken = replayToken
                if replayToken > 0 {
                    uiView.startPlayback(with: .full)
                }
            }
        }
    }
}
