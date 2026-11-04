import SwiftUI

/// 「整理照片」主题：单张大相纸居中，没有绳子。左右跟手切张、
/// 上滑删除时整张向上淡出（不碎沙），下滑收藏弹回。
struct GlassDeck: View {
    let photos: [PhotoItem]
    @Binding var index: Int
    let sizeLabel: (PhotoItem) -> String
    let onSwipe: (SortMove) -> Bool
    let onFinished: (SortMove) -> Void
    let onTap: (PhotoItem, CGRect) -> Void
    let onAddToAlbum: () -> Void
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
            ZStack {
                if let photo = current {
                    card(photo, in: size)
                        .offset(offset)
                        .opacity(detailActive ? 0 : fade)
                        .gesture(dragGesture)
                        .contextMenu {
                            Button {
                                onAddToAlbum()
                            } label: {
                                Label("存入相簿", systemImage: "photo.stack")
                            }
                        }
                } else {
                    EmptyDeckView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { deckSize = size }
            .onChange(of: size) { _, new in deckSize = new }
        }
    }
}

private extension GlassDeck {
    func card(_ photo: PhotoItem, in size: CGSize) -> some View {
        let metrics = PolaroidMetrics.make(for: photo, bounds: size, paperScale: CGFloat(paperScale))
        return PolaroidCard(photo: photo,
                            metrics: metrics,
                            sizeLabel: sizeLabel(photo),
                            isFront: true,
                            onOpenViewer: {
                                onTap(photo, CGRect(x: (size.width - metrics.paper.width) / 2,
                                                    y: (size.height - metrics.paper.height) / 2,
                                                    width: metrics.paper.width,
                                                    height: metrics.paper.height))
                            })
            .frame(width: metrics.paper.width, height: metrics.paper.height)
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isPlaying else { return }
                offset = value.translation
            }
            .onEnded { value in
                guard !isPlaying, current != nil else { return }
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
                } else if t.height > 40 {
                    guard onSwipe(.favorite) else { return springBack() }
                    springBack()
                } else {
                    springBack()
                }
            }
    }

    /// 浏览是纯跟手的：直接改游标，卡片换人但不播动画。
    func commit(forward: Bool) {
        let next = forward ? index + 1 : index - 1
        guard photos.indices.contains(next) else { return springBack() }
        lastSelfIndex = next
        index = next
        offset = .zero
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
