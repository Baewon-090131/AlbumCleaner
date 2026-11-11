import SwiftUI

/// 整理页的卡片区。
///
/// 机制照 ReelSort 1.4.4 的排序页（参考物是 `抄作业/Payload/ReelSort.app/index.html`）。
///
/// **最重要的那条**：手指抬起时不等旧卡飞完。旧卡先被复制成一张"飞行卡"接管
/// 当前位移与转角，真正的当前卡立刻换内容、停在后方位置，随后升起。
/// 这样中间不会有空帧。
///
/// 三条与参考稿对齐、之前没做对的细节：
/// 1. **方向光**：拖动时卡片**内缘**亮起一道同向的内发光（右滑从左缘、左滑从右缘），
///    颜色跟动作走；这是整套交互里唯一的实时方向反馈。
/// 2. **后置卡随拖拽长大**：0.96 → 1.00、-28pt → 0，拖到 120pt 时完全升到正面。
/// 3. **新卡升起按关键帧过冲**：0.96/-28 → 1.008/-2（68%）→ 1.0/0，
///    不是平滑 spring——先冲过头再落定。
struct SwipeDeck: View {
    let photos: [PhotoItem]
    @Binding var index: Int
    let command: DeckCommand?
    @Binding var isPlaying: Bool
    let albums: [AlbumItem]
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
    /// 单轮制：翻完本轮后「继续整理」。nil 表示这是整月的最后一张，没有下一轮。
    var onNextRound: (() -> Void)?
    /// 结算页直达待删除。
    var onOpenTrash: (() -> Void)?
    var detailActive = false

    // MARK: 跟手
    @State private var drag: CGSize = .zero
    @State private var glow: CGFloat = 0
    /// 方向光：+1 = 向右（从左边缘亮），-1 = 向左（从右边缘亮），0 = 不亮。
    @State private var hint: Int = 0
    /// 方向光的浓度 0…1。
    @State private var hintStrength: CGFloat = 0
    /// 这次拖动对应哪个动作；决定方向光的颜色。
    @State private var hintDeletes = true
    @State private var tray: CGFloat = 0
    @State private var pickIndex = 0
    @State private var erase: CGFloat = 0

    // MARK: 飞行卡
    @State private var flying: PhotoItem?
    @State private var flyingCardSize: CGSize = .zero
    @State private var flyingOffset: CGSize = .zero
    @State private var flyingRotation: Double = 0

    // MARK: 新卡升起（关键帧过冲：0 → 1.008 → 1）
    @State private var rise: CGFloat = 0

    @State private var deckSize: CGSize = .zero
    @State private var deckOrigin: CGPoint = .zero

    @Environment(\.displayScale) private var displayScale

    @AppStorage("ac_deck_w") private var cardWidthRatio = 1.0
    @AppStorage("ac_deck_h") private var cardHeightRatio = 1.0
    @AppStorage("ac_deck_swap") private var swapSetting = 80.0
    @AppStorage("ac_deck_del") private var deleteSetting = 90.0
    @AppStorage("ac_deck_tray") private var traySetting = 64.0

    // MARK: 常量（逐项对齐参考稿）
    /// 后置卡：缩 0.96、上抬 28pt。
    private let backScale: CGFloat = 0.96
    private let backLift: CGFloat = 28
    /// 拖到 120pt，后置卡完全升到正面。
    private let revealDistance: CGFloat = 120
    /// 转角：水平 1pt → 0.08°。
    private let rotationFactor: Double = 0.08
    /// 竖直打三折。
    private let verticalDamping: CGFloat = 0.3
    /// 方向光的起亮阈值（参考稿是 20pt）。
    private let hintThreshold: CGFloat = 20
    /// 飞行卡出屏。
    private let exitDuration: Double = 0.92
    private let exitCurve = Animation.timingCurve(0.22, 0.74, 0.24, 1, duration: 0.92)

    private var swapThreshold: CGFloat { CGFloat(swapSetting) }
    private var deleteThreshold: CGFloat { CGFloat(deleteSetting) }
    private var trayThreshold: CGFloat { CGFloat(traySetting) }

    private var current: PhotoItem? {
        photos.indices.contains(index) ? photos[index] : nil
    }
    private var nextPhoto: PhotoItem? {
        photos.indices.contains(index + 1) ? photos[index + 1] : nil
    }
    private func album(at slot: Int) -> AlbumItem? {
        albums.indices.contains(slot) ? albums[slot] : nil
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let origin = geo.frame(in: .global).origin
            let card = cardSize(in: size)

            ZStack(alignment: .bottom) {
                if current == nil {
                    MonthDoneView(title: endTitle,
                                  deleted: endDeleted,
                                  freed: endFreed,
                                  onNextRound: onNextRound,
                                  onOpenTrash: onOpenTrash)
                        .frame(width: size.width, height: size.height, alignment: .center)
                } else {
                    cardArea(card: card, origin: origin, size: size)
                }

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

// MARK: - 卡片区

private extension SwipeDeck {
    func cardArea(card: CGSize, origin: CGPoint, size: CGSize) -> some View {
        let center = CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
        let reveal = min(abs(drag.width) / revealDistance, 1)

        return ZStack {
            // 后置卡：下一张。随拖拽把后置卡拉向正面
            if let upcoming = nextPhoto {
                SwipePhotoCard(photo: upcoming, cardSize: card, sizeLabel: sizeLabel(upcoming))
                    .frame(width: card.width, height: card.height)
                    .scaleEffect(backScale + (1 - backScale) * reveal)
                    .offset(y: -backLift * (1 - reveal))
                    .opacity(0.9 + 0.1 * reveal)
                    .allowsHitTesting(false)
            }

            // 当前卡
            if let photo = current {
                SwipePhotoCard(photo: photo,
                               cardSize: card,
                               sizeLabel: sizeLabel(photo),
                               glow: glow,
                               erase: erase,
                               hintSide: hint,
                               hintStrength: hintStrength,
                               hintDeletes: hintDeletes)
                    .frame(width: card.width, height: card.height)
                    .scaleEffect(riseScale)
                    .offset(x: drag.width, y: drag.height + riseLift)
                    .rotationEffect(.degrees(drag.width * rotationFactor))
                    .opacity(detailActive ? 0 : 1)
                    .animation(.smooth(duration: 0.3), value: detailActive)
                    .contentShape(RoundedRectangle(cornerRadius: Theme.radiusCard,
                                                   style: .continuous))
                    .onTapGesture {
                        guard !isPlaying, tray < 0.2 else { return }
                        let frame = CGRect(x: center.x - card.width / 2 + drag.width,
                                           y: center.y - card.height / 2 + drag.height,
                                           width: card.width,
                                           height: card.height)
                        onTap(photo, frame)
                    }
            }

            // 飞行卡：只管飞
            if let flying {
                SwipePhotoCard(photo: flying, cardSize: flyingCardSize, sizeLabel: "")
                    .frame(width: flyingCardSize.width, height: flyingCardSize.height)
                    .offset(x: flyingOffset.width, y: flyingOffset.height)
                    .rotationEffect(.degrees(flyingRotation))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .center)
    }

    /// 新卡升起：按参考稿的 `nextCardRise` 三段关键帧映射。
    ///
    /// 0%    scale .96  / y -28
    /// 68%   scale 1.008 / y -2   ← 过冲，这是那一下"弹"
    /// 100%  scale 1    / y 0
    ///
    /// 单个 `rise` 从 0 走到 1（弹簧会冲过 1），再由 `riseScale` / `riseLift`
    /// 按 68% 折点分段插值。这样既保留过冲，又不会把位移和缩放错开。
    var riseScale: CGFloat {
        let p = min(max(rise, 0), 1)
        return p < 0.68
            ? backScale + (1.008 - backScale) * (p / 0.68)
            : 1.008 + (1 - 1.008) * ((p - 0.68) / 0.32)
    }

    var riseLift: CGFloat {
        let p = min(max(rise, 0), 1)
        return p < 0.68
            ? -backLift + (backLift - 2) * (p / 0.68)
            : -2 + 2 * ((p - 0.68) / 0.32)
    }

    /// 卡片尺寸：按照片比例铺满卡片区，四周各留 8pt，中点与区域中点重合。
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

                drag = CGSize(width: rubber(t.width, limit: 260),
                              height: rubber(t.height * verticalDamping, limit: 200))

                updateHints(t)
            }
            .onEnded { value in
                guard !isPlaying else { return }
                let t = value.translation

                guard current != nil else {
                    if t.width > swapThreshold, abs(t.width) > abs(t.height), !photos.isEmpty {
                        restoreToLast()
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
                } else if t.height < -deleteThreshold, abs(t.height) > abs(t.width) {
                    if !onSwipe(.delete) { springBack() }
                } else if t.height > trayThreshold, let target = album(at: pickIndex) {
                    onAddToAlbum(target)
                } else {
                    springBack()
                }
            }
    }

    /// 方向提示：上滑 → 删除光；左右 → 按该方向对应的动作给光。
    func updateHints(_ t: CGSize) {
        // 上滑：越接近删除阈值，外缘绯红越亮
        glow = t.height < 0
            ? min(max((-t.height - 24) / (deleteThreshold - 24), 0), 1)
            : 0

        // 下拉：升起相簿轨道
        let p = min(max((t.height - 16) / (trayThreshold - 16), 0), 1)
        if abs(tray - p) > 0.02 {
            withAnimation(.snappy(duration: 0.2)) { tray = p }
        }
        if p > 0.02 {
            pickIndex = AlbumDropTray.index(forDrag: t.width, count: albums.count)
        }

        // 横向方向光：|位移| 与 |纵向| 谁大听谁的（与参考稿同一判定）
        let strength = min(max(abs(t.width), abs(t.height)) / 100, 1)
        if abs(t.width) > abs(t.height), abs(t.width) > hintThreshold {
            hintStrength = strength
            if t.width > 0 {
                hint = 1
                hintDeletes = false          // 右滑 = 撤回，不是删除
            } else {
                hint = -1
                hintDeletes = false          // 左滑 = 下一张，也不是删除
            }
        } else if t.height < -28, abs(t.height) > abs(t.width) {
            hint = 1                         // 从下缘往上亮
            hintStrength = strength
            hintDeletes = true
        } else {
            hintStrength = 0
        }
    }

    func rubber(_ value: CGFloat, limit: CGFloat) -> CGFloat {
        if value < -limit { return -limit + (value + limit) * 0.28 }
        if value > limit { return limit + (value - limit) * 0.28 }
        return value
    }

    /// 没到阈值：卡片回原位，方向光熄灭。
    func springBack() {
        withAnimation(.snappy(duration: 0.32)) {
            drag = .zero
            glow = 0
            hintStrength = 0
            tray = 0
        }
        pickIndex = 0
    }

    /// 空态右滑回看：从后方升起最后一张。
    func restoreToLast() {
        withoutAnimation {
            index = photos.count - 1
            rise = 0
        }
        riseCard()
    }
}

// MARK: - 动效通道

private extension SwipeDeck {
    func play(_ cmd: DeckCommand) {
        guard !isPlaying else { return }
        switch cmd.move {
        case .next:
            commit(.next, exit: .left)
        case .undo:
            commit(.undo, exit: .right)
        case .delete:
            deleteNow()
        case .favorite:
            isPlaying = true
            withAnimation(.bouncy(duration: 0.3, extraBounce: 0.22)) {
                drag = .zero
                glow = 0
                hintStrength = 0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(320))
                isPlaying = false
                onFinished(.favorite)
            }
        case .album:
            isPlaying = true
            withAnimation(.smooth(duration: 0.28)) {
                drag = CGSize(width: 0, height: deckSize.height)
                tray = 0
                hintStrength = 0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                isPlaying = false
                onFinished(.album)
                rise = 0
                riseCard()
            }
        }
    }

    enum Exit { case left, right }

    /// 出手：先把当前卡复制成飞行卡，再立刻换内容、让新卡升起来。
    func commit(_ move: SortMove, exit: Exit) {
        guard let photo = current else { return }
        isPlaying = true

        let card = cardSize(in: deckSize)
        withoutAnimation {
            flying = photo
            flyingCardSize = card
            flyingOffset = drag
            flyingRotation = drag.width * rotationFactor
        }

        withoutAnimation {
            drag = .zero
            glow = 0
            hintStrength = 0
            erase = 0
            tray = 0
            rise = 0
        }
        onFinished(move)

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(16))

            withAnimation(exitCurve) {
                flyingOffset = exitOffset(exit, card: card)
                flyingRotation = exitRotation(exit)
            }
            riseCard()

            // 输入闸门：参考稿的 CARD_READY_DELAY
            try? await Task.sleep(for: .milliseconds(280))
            isPlaying = false

            try? await Task.sleep(for: .milliseconds(660))
            withoutAnimation {
                flying = nil
                flyingRotation = 0
            }
        }
    }

    /// 新卡升起。曲线本身用弹簧（带过冲），形状由 `riseScale` / `riseLift` 的分段映射定义。
    func riseCard() {
        withAnimation(.spring(duration: 0.34, bounce: 0.28)) { rise = 1 }
    }

    /// 上滑删除：碎沙从卡片当前位置起飞，卡片原地自下而上被擦掉，然后换张。
    func deleteNow() {
        guard current != nil else { return }
        isPlaying = true
        emitSand()
        withAnimation(.smooth(duration: 0.66)) { erase = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(760))
            withoutAnimation {
                drag = .zero
                glow = 0
                erase = 0
                tray = 0
                hintStrength = 0
                rise = 0
            }
            onFinished(.delete)
            riseCard()
            try? await Task.sleep(for: .milliseconds(280))
            isPlaying = false
        }
    }

    func exitOffset(_ exit: Exit, card: CGSize) -> CGSize {
        // 半屏 + 卡片，保证任何屏幕尺寸都真的出画
        let dx = deckSize.width / 2 + card.width
        switch exit {
        case .left:  return CGSize(width: -dx, height: drag.height * 0.3)
        case .right: return CGSize(width: dx, height: drag.height * 0.3)
        }
    }

    func exitRotation(_ exit: Exit) -> Double {
        switch exit {
        case .left:  return -16
        case .right: return 16
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
