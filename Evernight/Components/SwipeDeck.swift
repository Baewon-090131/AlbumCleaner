import SwiftUI

/// 整理页的单卡手势区。
///
/// 一次只显示一张照片卡，居中铺开：
/// - **左滑**：卡片向左飞出 → 下一张**在屏幕正中渐显**
/// - **右滑**：撤回上一个动作（当前卡让开，被撤那张在正中渐显）
/// - **上滑**：删除。不到阈值时外缘浮起绯红光晕；过阈值松手，
///   照片**在被拖到的那个位置**碎成粒子向上飘散，卡片原地自下而上被擦掉
/// - **下拉**：底部浮起相簿轨道。卡片仍能左右自由移动，中心压在第几格，
///   轨道就停在那一格，松手存入；也可以直接点一格
///
/// 手势只把结论交给外层（`onSwipe`），数据变更永远发生在动效播完之后。
/// 换张入场统一交给 `cardLayer` 里的 `transition` + `.id(photo.id)`：
/// 旧卡消失、新卡从 0 透明度在**原位**浮起来。不再手写 opacity——那样会和
/// 数据变更并进同一轮事务，动画被抹平。
struct SwipeDeck: View {
    let photos: [PhotoItem]
    @Binding var index: Int
    let command: DeckCommand?
    @Binding var isPlaying: Bool
    let albums: [AlbumItem]
    /// 顶栏「相簿」按钮选好的目标；手势下拉选的目标直接走 `onAddToAlbum`。
    var albumPick: AlbumItem?
    let endTitle: String
    var endDeleted = 0
    var endFreed = ""
    let sizeLabel: (PhotoItem) -> String
    let onSwipe: (SortMove) -> Bool
    let onFinished: (SortMove) -> Void
    let onTap: (PhotoItem, CGRect) -> Void
    let onAddToAlbum: (AlbumItem) -> Void
    let onReachEnd: () -> Void
    let onSandBurst: (SandBurst) -> Void
    var detailActive = false

    /// 当前卡片的跟手位移（横竖都跟，所以下拉时也能左右选相簿）。
    @State private var drag: CGSize = .zero
    /// 删除阈值光晕（0…1）。
    @State private var glow: CGFloat = 0
    /// 相簿轨道展开度（0…1）。
    @State private var tray: CGFloat = 0
    /// 轨道上当前压着第几格。按**手指原始位移**换算，不受卡片橡皮筋上限影响，
    /// 所以相簿再多也能一路选到底。
    @State private var pickIndex = 0
    /// 碎沙擦拭进度。
    @State private var erase: CGFloat = 0
    /// 卡片整体淡出：飞出 / 存入相簿时让位，让新卡接位时不出现重叠。
    @State private var leaving = false
    @State private var deckSize: CGSize = .zero
    @State private var deckOrigin: CGPoint = .zero

    @Environment(\.displayScale) private var displayScale

    /// 卡片尺寸上限与三个方向阈值都能在「我的 › 整理手感」里调。
    @AppStorage("ac_deck_w") private var cardWidthRatio = 0.98
    @AppStorage("ac_deck_h") private var cardHeightRatio = 1.0
    @AppStorage("ac_deck_swap") private var swapSetting = 88.0
    @AppStorage("ac_deck_del") private var deleteSetting = 104.0
    @AppStorage("ac_deck_tray") private var traySetting = 64.0

    private var swapThreshold: CGFloat { CGFloat(swapSetting) }
    private var deleteThreshold: CGFloat { CGFloat(deleteSetting) }
    private var trayThreshold: CGFloat { CGFloat(traySetting) }

    private var current: PhotoItem? {
        photos.indices.contains(index) ? photos[index] : nil
    }

    private func album(at slot: Int) -> AlbumItem? {
        albums.indices.contains(slot) ? albums[slot] : nil
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let origin = geo.frame(in: .global).origin

            ZStack(alignment: .bottom) {
                if current == nil {
                    MonthDoneView(title: endTitle, deleted: endDeleted, freed: endFreed)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    cardLayer(size: size, origin: origin)
                }

                // 轨道**常驻**在层级里，靠 `tray` 控制显隐。
                // 只在展开时才插入视图会打断正在进行的手势，表现就是「拉到一半拉不动了」。
                AlbumDropTray(albums: albums,
                              selectedIndex: pickIndex,
                              progress: tray,
                              onPick: { picked in onAddToAlbum(picked) })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onAppear { deckSize = size; deckOrigin = origin }
            .onChange(of: size) { _, new in
                deckSize = new
                deckOrigin = geo.frame(in: .global).origin
            }
        }
        .onChange(of: command) { _, value in
            guard let value else { return }
            play(value)
        }
    }
}

// MARK: - 布局

/// 卡片的跟手位移与显隐。单独拆成一个修饰器，是为了让这两件事**不参与**
/// 外层的 `animation(value: current?.id)`——换张时才该有动画，拖动时必须即时。
private struct DeckCardMotion: ViewModifier {
    let drag: CGSize
    let hidden: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: drag.width, y: drag.height)
            .opacity(hidden ? 0 : 1)
    }
}

private extension SwipeDeck {
    func cardLayer(size: CGSize, origin: CGPoint) -> some View {
        let card = cardSize(in: size)
        let cardOrigin = CGPoint(x: origin.x + (size.width - card.width) / 2 + drag.width,
                                 y: origin.y + (size.height - card.height) / 2 + drag.height)

        return ZStack {
            if let photo = current {
                SwipePhotoCard(photo: photo,
                               cardSize: card,
                               sizeLabel: sizeLabel(photo),
                               glow: glow,
                               erase: erase,
                               onTap: {
                                   guard !isPlaying, tray < 0.2 else { return }
                                   onTap(photo, CGRect(origin: cardOrigin, size: card))
                               })
                    .frame(width: card.width, height: card.height)
                    // 拖动跟手必须即时：位移与透明度都只在这个局部动，
                    // 不能挂到下面的 `.animation(value: current?.id)` 上。
                    .modifier(DeckCardMotion(drag: drag, hidden: detailActive || leaving))
                    .animation(.smooth(duration: 0.3), value: detailActive)
                    // 换张：**旧卡瞬时移除**（它此刻已飞出 / 已擦净，淡出反而会闪回），
                    // 新卡在原点从 0 浮上来——这才是「下一张从屏幕中间渐显」。
                    .id(photo.id)
                    .transition(.asymmetric(insertion: .opacity, removal: .identity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 只对「换成了哪一张」套动画，且只影响 transition 的插入/移除
        .animation(.smooth(duration: 0.42), value: current?.id)
    }

    /// 卡片尺寸：按照片比例铺满卡片区，上限两条比例可在 Debug 里调。
    /// 竖图吃满高度、横图吃满宽度，只留 8pt 呼吸——留白不该由卡片自己让出来。
    func cardSize(in size: CGSize) -> CGSize {
        let maxW = size.width * CGFloat(cardWidthRatio)
        let maxH = max(40, size.height * CGFloat(cardHeightRatio) - Theme.spaceXS * 2)
        let ratio = min(max(current?.ratio ?? 0.75, 0.4), 2.2)
        var w = maxW
        var h = w / ratio
        if h > maxH {
            h = maxH
            w = h * ratio
        }
        return CGSize(width: w, height: h)
    }
}

// MARK: - 手势

private extension SwipeDeck {
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard !isPlaying, current != nil else { return }
                let t = value.translation

                // 自由跟手：横竖都走。下拉时纵向打七折，卡片沉得慢一点、给轨道留出位置
                drag = CGSize(width: rubber(t.width, limit: 220),
                              height: rubber(t.height < 0 ? t.height : t.height * 0.7,
                                             limit: t.height < 0 ? 260 : 200))

                // 上滑：越接近删除阈值，外缘的绯红光晕越亮
                glow = t.height < 0
                    ? min(max((-t.height - 28) / (deleteThreshold - 28), 0), 1)
                    : 0

                // 下拉：升起相簿轨道
                let p = min(max((t.height - 16) / (trayThreshold - 16), 0), 1)
                if abs(tray - p) > 0.02 {
                    withAnimation(.snappy(duration: 0.2)) { tray = p }
                }
                if p > 0.02 {
                    pickIndex = AlbumDropTray.index(forDrag: t.width, count: albums.count)
                }
            }
            .onEnded { value in
                guard !isPlaying else { return }
                let t = value.translation

                guard current != nil else {
                    // 空态：只认「右滑回去看最后一张」
                    if t.width > swapThreshold, abs(t.width) > abs(t.height), !photos.isEmpty {
                        index = photos.count - 1
                    } else {
                        springBack()
                    }
                    return
                }

                if abs(t.width) > abs(t.height), abs(t.width) > swapThreshold {
                    if t.width < 0 {
                        _ = onSwipe(.next)
                    } else if !onSwipe(.undo) {
                        springBack()
                    }
                } else if t.height < -deleteThreshold {
                    if !onSwipe(.delete) { springBack() }
                } else if t.height > trayThreshold, let target = album(at: pickIndex) {
                    onAddToAlbum(target)
                } else {
                    springBack()
                }
            }
    }

    func rubber(_ value: CGFloat, limit: CGFloat) -> CGFloat {
        if value < -limit { return -limit + (value + limit) * 0.3 }
        if value > limit { return limit + (value - limit) * 0.3 }
        return value
    }

    /// 没到阈值：严格回原位，不留半截位移。
    func springBack() {
        withAnimation(.snappy(duration: 0.34)) {
            drag = .zero
            glow = 0
            tray = 0
        }
        pickIndex = 0
    }
}

// MARK: - 动效通道

private extension SwipeDeck {
    func play(_ cmd: DeckCommand) {
        guard !isPlaying else { return }
        switch cmd.move {
        case .next:
            fly(.next, forward: true)

        case .undo:
            isPlaying = true
            if cmd.reverseOf == .delete || cmd.reverseOf == .album {
                // 当前卡让开，被撤那张在正中渐显
                withAnimation(.smooth(duration: 0.2)) { drag = CGSize(width: 150, height: 0) }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(220))
                    settle(.undo)
                }
            } else {
                withAnimation(.bouncy(duration: 0.32, extraBounce: 0.2)) {
                    drag = .zero
                    glow = 0
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    settle(.undo)
                }
            }

        case .delete:
            isPlaying = true
            emitSand()
            withAnimation(.smooth(duration: 0.66)) { erase = 1 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(880))
                settle(.delete)
            }

        case .favorite:
            isPlaying = true
            withAnimation(.bouncy(duration: 0.3, extraBounce: 0.22)) {
                drag = .zero
                glow = 0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(320))
                settle(.favorite)
            }

        case .album:
            isPlaying = true
            withAnimation(.smooth(duration: 0.3)) {
                drag = CGSize(width: 0, height: deckSize.height + 200)
                tray = 0
                leaving = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(310))
                settle(.album)
            }
        }
    }

    /// 左 / 右滑走：卡片顺着手势方向飞出并淡掉。
    /// 位移与淡出必须在**同一个** `withAnimation` 里，否则卡片会先瞬隐再飞。
    func fly(_ move: SortMove, forward: Bool) {
        guard !isPlaying else { return }
        isPlaying = true
        let distance = deckSize.width + 200
        withAnimation(.smooth(duration: 0.26)) {
            drag = CGSize(width: forward ? -distance : distance, height: drag.height * 0.5)
            glow = 0
            leaving = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(268))
            settle(move)
            if move == .next, index >= photos.count { onReachEnd() }
        }
    }

    /// 复位动效状态与数据变更放在同一帧：拆开会闪。
    ///
    /// 旧卡的移除是瞬时的（`removal: .identity`），所以这里可以直接把 `leaving`
    /// 归零而不会让旧卡在中心闪一下；新卡的入场由 `cardLayer` 的 insertion 过渡负责。
    func settle(_ move: SortMove) {
        withoutAnimation {
            drag = .zero
            glow = 0
            erase = 0
            tray = 0
            leaving = false
            isPlaying = false
        }
        onFinished(move)
    }

    /// 采样本张照片的像素，从**它此刻所在的位置**起飞。
    func emitSand() {
        guard let photo = current, deckSize != .zero else { return }
        let card = cardSize(in: deckSize)
        let request = CGSize(
            width: min(card.width * displayScale * 1.5, 2800),
            height: min(card.height * displayScale * 1.5, 2800)
        )
        // 关键：带上跟手位移。上滑到哪儿，粒子就从哪儿散。
        let frame = CGRect(
            x: deckOrigin.x + (deckSize.width - card.width) / 2 + drag.width,
            y: deckOrigin.y + (deckSize.height - card.height) / 2 + drag.height,
            width: card.width,
            height: card.height
        )
        if let burst = SandSampler.burst(for: photo, targetSize: request, frameInScreen: frame) {
            onSandBurst(burst)
        }
    }
}
