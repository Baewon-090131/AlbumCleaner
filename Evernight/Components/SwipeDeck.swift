import SwiftUI

/// 整理页的单卡手势区。
///
/// **卡片区**由 `GeometryReader` 给定：顶栏以下、底栏以上的那块矩形。
/// 每张照片卡都居中于这块区域的中点，尺寸被夹在区域内（四周各留 8pt），
/// 所以无论照片是竖是横，卡片中点都落在区域中心、也不会越界。
///
/// 手势：
/// - **左滑**：当前卡随手指平移，越过阈值飞出屏幕 → 下一张从「缩小按压」态用 Spring 升到正常
/// - **右滑**：撤回。把上一步的「滑动分拣」**倒做**——当前卡向右让开，
///   被撤那张从左侧飞回中心并弹回原大
/// - **上滑**：删除。不到阈值外缘浮起绯红光晕；过阈值松手，照片在**它当时所在的位置**
///   碎成粒子向上飘散，卡片原地自下而上被擦掉
/// - **下拉**：底部浮起相簿轨道。卡片仍能左右移动，压在第几格就存进哪一格；也能直接点一格
///
/// 手势只把结论交给外层（`onSwipe`），数据变更永远发生在动效播完之后。
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
    /// 轨道上压着第几格。按手指原始位移换算，不受卡片橡皮筋上限影响。
    @State private var pickIndex = 0
    /// 碎沙擦拭进度。
    @State private var erase: CGFloat = 0
    /// 入场缩放：0.94 = 缩小按压态，1 = 正常。换张时由它做 Spring 过渡。
    @State private var enterScale: CGFloat = 1
    /// 入场横向偏移：撤回时被撤那张从左侧飞回，所以从负值升到 0。
    @State private var enterOffset: CGFloat = 0
    @State private var deckSize: CGSize = .zero
    @State private var deckOrigin: CGPoint = .zero

    @Environment(\.displayScale) private var displayScale

    /// 卡片尺寸上限与三个方向阈值都能在「我的 › 整理手感」里调。
    @AppStorage("ac_deck_w") private var cardWidthRatio = 1.0
    @AppStorage("ac_deck_h") private var cardHeightRatio = 1.0
    @AppStorage("ac_deck_swap") private var swapSetting = 88.0
    @AppStorage("ac_deck_del") private var deleteSetting = 104.0
    @AppStorage("ac_deck_tray") private var traySetting = 64.0

    private var swapThreshold: CGFloat { CGFloat(swapSetting) }
    private var deleteThreshold: CGFloat { CGFloat(deleteSetting) }
    private var trayThreshold: CGFloat { CGFloat(traySetting) }

    /// 缩小按压态的比例：新卡就停在这个尺寸等着被升上来。
    private let pressedScale: CGFloat = 0.94
    /// 入场用的弹性曲线：先快后慢、末尾带一点回弹（不是恒定斜率）。
    /// `spring(duration:bounce:)` 是 iOS 17 API，正好是本工程的部署目标。
    private var enterSpring: Animation { .spring(duration: 0.5, bounce: 0.2) }

    private var current: PhotoItem? {
        photos.indices.contains(index) ? photos[index] : nil
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let origin = geo.frame(in: .global).origin
            let card = cardSize(in: size)

            ZStack(alignment: .bottom) {
                if current == nil {
                    // 花落在卡片区正中：容器给满、内容居中，MonthDoneView 自己负责生长
                    MonthDoneView(title: endTitle, deleted: endDeleted, freed: endFreed)
                        .frame(width: size.width, height: size.height, alignment: .center)
                } else {
                    cardLayer(card: card, origin: origin, size: size)
                }

                // 轨道**常驻**在层级里，靠 `tray` 控制显隐。
                // 只在展开时才插入视图会打断正在进行的手势，表现就是「拉到一半拉不动了」。
                AlbumDropTray(albums: albums,
                              selectedIndex: pickIndex,
                              progress: tray,
                              onPick: { picked in onAddToAlbum(picked) })
            }
            .frame(width: size.width, height: size.height)
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

/// 卡片的跟手位移 / 按压缩放 / 入场偏移。
/// 拆成修饰器是为了让这些量**不参与**任何按 `index` 触发的动画——
/// 拖动必须即时，入场才该有 Spring。
private struct DeckCardMotion: ViewModifier {
    let drag: CGSize
    let scale: CGFloat
    let offsetX: CGFloat
    let hidden: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(x: drag.width + offsetX, y: drag.height)
            .opacity(hidden ? 0 : 1)
    }
}

private extension SwipeDeck {
    func cardLayer(card: CGSize, origin: CGPoint, size: CGSize) -> some View {
        // 区域中心（全局），详情页的放大动画以它为锚
        let center = CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)

        return ZStack {
            if let photo = current {
                SwipePhotoCard(photo: photo,
                               cardSize: card,
                               sizeLabel: sizeLabel(photo),
                               glow: glow,
                               erase: erase,
                               onTap: {
                                   guard !isPlaying, tray < 0.2 else { return }
                                   let frame = CGRect(x: center.x - card.width / 2 + drag.width,
                                                      y: center.y - card.height / 2 + drag.height,
                                                      width: card.width,
                                                      height: card.height)
                                   onTap(photo, frame)
                               })
                    .frame(width: card.width, height: card.height)
                    .modifier(DeckCardMotion(drag: drag,
                                             scale: enterScale,
                                             offsetX: enterOffset,
                                             hidden: detailActive))
                    .id(photo.id)
                    .transition(.identity)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    /// 卡片尺寸：按照片比例铺满卡片区，四周各留 8pt（区域中点即卡片中点）。
    /// 竖图吃满高度、横图吃满宽度；比例夹在 `0.4…2.2`，极端长图也不会撑破区域。
    func cardSize(in size: CGSize) -> CGSize {
        let inset = Theme.spaceXS
        let maxW = max(40, size.width * CGFloat(cardWidthRatio) - inset * 2)
        let maxH = max(40, size.height * CGFloat(cardHeightRatio) - inset * 2)
        let ratio = min(max(current?.ratio ?? 0.75, 0.4), 2.2)
        let fullHeight = maxW / ratio
        if fullHeight <= maxH { return CGSize(width: maxW, height: fullHeight) }
        return CGSize(width: maxH * ratio, height: maxH)
    }
}

// MARK: - 手势

private extension SwipeDeck {
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard !isPlaying, current != nil else { return }
                let t = value.translation

                // 自由跟手：横竖都走。下拉时纵向打七折，卡片沉得慢一点、给轨道留位置
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
                    // 空态：只认「右滑回去看最后一张」——同样走一次入场（缩放 + 从右侧飞回）
                    if t.width > swapThreshold, abs(t.width) > abs(t.height), !photos.isEmpty {
                        withoutAnimation {
                            index = photos.count - 1
                            enterScale = pressedScale
                            enterOffset = -deckSize.width * 0.5
                        }
                        withAnimation(enterSpring) {
                            enterScale = 1
                            enterOffset = 0
                        }
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

    func album(at slot: Int) -> AlbumItem? {
        albums.indices.contains(slot) ? albums[slot] : nil
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
            // 把「左滑分拣」倒做：当前卡顺着右滑方向飞出，
            // 被撤那张随后从左侧飞回中心（入场量在 settle 里给）
            isPlaying = true
            withAnimation(.smooth(duration: 0.24)) {
                drag = CGSize(width: deckSize.width + 200, height: 0)
                glow = 0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                settle(.undo)
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
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(310))
                settle(.album)
            }
        }
    }

    /// 左 / 右滑走：卡片顺着手势方向飞出屏幕。
    func fly(_ move: SortMove, forward: Bool) {
        guard !isPlaying else { return }
        isPlaying = true
        let distance = deckSize.width + 200
        withAnimation(.smooth(duration: 0.26)) {
            drag = CGSize(width: forward ? -distance : distance, height: drag.height * 0.5)
            glow = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(268))
            settle(move)
            if move == .next, index >= photos.count { onReachEnd() }
        }
    }

    /// 复位动效状态与数据变更放在同一帧：拆开会闪。
    ///
    /// 入场量按操作给：
    /// - **下一张 / 删除 / 存相簿**：新卡从「缩小按压态」原位 Spring 升到正常
    /// - **撤回**：分拣倒做，被撤那张从左侧飞回中心，同时从按压态弹回原大
    /// - **收藏**：游标不动，静默归位
    func settle(_ move: SortMove) {
        withoutAnimation {
            drag = .zero
            glow = 0
            erase = 0
            tray = 0
            isPlaying = false
            switch move {
            case .next, .delete, .album:
                enterScale = pressedScale
                enterOffset = 0
            case .undo:
                enterScale = pressedScale
                enterOffset = -deckSize.width * 0.55
            case .favorite:
                enterScale = 1
                enterOffset = 0
            }
        }
        onFinished(move)
        withAnimation(enterSpring) {
            enterScale = 1
            enterOffset = 0
        }
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
