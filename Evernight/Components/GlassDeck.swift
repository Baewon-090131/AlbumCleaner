import SwiftUI

/// 「整理照片」主题：单张大相纸居中，没有绳子。左右跟手切张、
/// 上滑删除时整张向上淡出（不碎沙），下滑收藏弹回。
struct GlassDeck: View {
    let photos: [PhotoItem]
    @Binding var index: Int
    /// 翻过最后一张后空态写的那句话。
    let endTitle: String
    let sizeLabel: (PhotoItem) -> String
    let onSwipe: (SortMove) -> Bool
    let onFinished: (SortMove) -> Void
    let onTap: (PhotoItem, CGRect) -> Void
    let onAddToAlbum: () -> Void
    /// 翻过最后一张时回调一次（放烟花）。
    let onReachEnd: () -> Void
    /// 详情页打开时把卡片交给详情层，避免两层画面重复。
    var detailActive = false

    @AppStorage("ac_dbg_paper") private var paperScale: Double = 0.90

    @State private var offset: CGSize = .zero
    @State private var fade: Double = 1
    @State private var isPlaying = false
    @State private var deckSize: CGSize = .zero
    @State private var lastSelfIndex: Int?

    private let threshold: CGFloat = 90

    private var current: PhotoItem? {
        photos.indices.contains(index) ? photos[index] : nil
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let origin = geo.frame(in: .global).origin
            ZStack {
                if let photo = current {
                    card(photo, in: size, origin: origin)
                        .offset(offset)
                        .opacity(detailActive ? 0 : fade)
                } else {
                    MonthDoneView(title: endTitle)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 手势挂在容器上：空态没有卡片，也得能向右滑回去
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onAppear { deckSize = size }
            .onChange(of: size) { _, new in deckSize = new }
        }
    }
}

private extension GlassDeck {
    func card(_ photo: PhotoItem, in size: CGSize, origin: CGPoint) -> some View {
        let metrics = PolaroidMetrics.make(for: photo, bounds: size, paperScale: CGFloat(paperScale))
        return PolaroidCard(photo: photo,
                            metrics: metrics,
                            sizeLabel: sizeLabel(photo),
                            isFront: true,
                            onOpenViewer: {
                                onTap(photo, CGRect(x: origin.x + (size.width - metrics.paper.width) / 2,
                                                    y: origin.y + (size.height - metrics.paper.height) / 2,
                                                    width: metrics.paper.width,
                                                    height: metrics.paper.height))
                            })
            .frame(width: metrics.paper.width, height: metrics.paper.height)
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isPlaying, current != nil else { return }
                offset = value.translation
            }
            .onEnded { value in
                guard !isPlaying else { return }
                guard current != nil else {
                    let t = value.translation
                    if t.width > threshold, abs(t.width) > abs(t.height), photos.count > 0 {
                        index = photos.count - 1
                    }
                    return
                }
                let t = value.translation

                if abs(t.width) > abs(t.height) {
                    if t.width < -threshold { commit(forward: true) }
                    else if t.width > threshold { commit(forward: false) }
                    else { springBack() }
                    return
                }

                if t.height < -threshold {
                    guard onSwipe(.delete) else { return springBack() }
                    flyUpAndFinish(.delete)
                } else {
                    springBack()
                }
            }
    }

    /// 浏览是纯跟手的：直接改游标，卡片换人但不播动画。
    func commit(forward: Bool) {
        let next = forward ? index + 1 : index - 1
        guard next >= 0, next <= photos.count else { return springBack() }
        if forward, next == photos.count {
            finishMonth()
            return
        }
        lastSelfIndex = next
        index = next
        offset = .zero
    }

    /// 最后一张继续向前：卡片向上滑出，游标落到 `photos.count`，空态淡入并放烟花。
    func finishMonth() {
        isPlaying = true
        withAnimation(.smooth(duration: 0.3)) {
            offset = CGSize(width: 0, height: -700)
            fade = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.32))
            withAnimation(.smooth(duration: 0.3)) {
                index = photos.count
                offset = .zero
                fade = 1
            }
            isPlaying = false
            onReachEnd()
        }
    }

    /// 删除：整张向上滑出并淡掉，替掉原来的碎沙。
    func flyUpAndFinish(_ move: SortMove) {
        isPlaying = true
        withAnimation(.smooth(duration: 0.32)) {
            offset = CGSize(width: 0, height: -900)
            fade = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.34))
            withoutAnimation {
                offset = .zero
                fade = 1
                isPlaying = false
                onFinished(move)
            }
        }
    }

    func springBack() {
        withAnimation(.snappy(duration: 0.32)) {
            offset = .zero
            fade = 1
        }
    }
}
