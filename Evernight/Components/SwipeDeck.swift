import SwiftUI

/// 整理页的卡片区。
///
/// 结构照 ReelSort 的排序页：一个居中的**当前卡** + 一张压在它后方、略小略高的**后置卡**。
///
/// 关键做法（与之前几版最大的不同）：
/// 手指抬起时**不等待飞出的旧卡**——旧卡被复制成一张"飞行卡"留在原地继续飞，
/// 真正的当前卡立刻换内容并从后置卡的位置升上来。所以观感是连贯的，
/// 不会出现「旧卡飞到一半、中间空一帧、新卡才出现」。
///
/// - 拖动：卡随手指平移并绕自身微转，后置卡**跟着往上升、往大长**（跟手越大越接近正面）
/// - 左滑 / 右滑：越过 80pt 即出手，旧卡带着惯性旋转飞出屏幕
/// - 上滑：删除。过 90pt 松手，照片在它当时的位置碎成粒子向上飘散
/// - 下拉：底部浮起相簿轨道，卡片仍可左右移动选格子
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
    var detailActive = false

    // MARK: 跟手状态
    @State private var drag: CGSize = .zero
    @State private var glow: CGFloat = 0
    @State private var tray: CGFloat = 0
    @State private var pickIndex = 0
    @State private var erase: CGFloat = 0

    // MARK: 飞行卡（旧卡的复制体，独立飞出去）
    @State private var flying: PhotoItem?
    @State private var flyingCardSize: CGSize = .zero
    @State private var flyingOffset: CGSize = .zero
    @State private var flyingRotation: Double = 0
    @State private var flyingOpacity: Double = 1

    // MARK: 新卡升起 0 → 1（弹簧会冲过 1，那就是那一点回弹）
    @State private var rise: CGFloat = 1

    @State private var deckSize: CGSize = .zero
    @State private var deckOrigin: CGPoint = .zero

    @Environment(\.displayScale) private var displayScale

    @AppStorage("ac_deck_w") private var cardWidthRatio = 1.0
    @AppStorage("ac_deck_h") private var cardHeightRatio = 1.0
    @AppStorage("ac_deck_swap") private var swapSetting = 80.0
    @AppStorage("ac_deck_del") private var deleteSetting = 90.0
    @AppStorage("ac_deck_tray") private var traySetting = 64.0

    // MARK: 常量（对齐 ReelSort 的数值）
    /// 后置卡：缩到 0.95、向上抬 28pt。
    private let backScale: CGFloat = 0.95
    private let backLift: CGFloat = 28
    /// 拖到 120pt 时，后置卡已经完全升到正面。
    private let revealDistance: CGFloat = 120
    /// 卡片绕自身转动的系数：水平 1pt → 0.08°。
    private let rotationFactor: Double = 0.08
    /// 竖直方向打三折：上滑要拖得比左右更长才算数。
    private let verticalDamping: CGFloat = 0.3
    /// 飞行卡出屏时长与曲线。
    private let exitDuration: Double = 0.92
    /// 新卡升起的弹簧。
    private var riseSpring: Animation { .spring(duration: 0.42, bounce: 0.26) }

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
                    MonthDoneView(title: endTitle, deleted: endDeleted, freed: endFreed)
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
        // 跟手越大，后置卡越接近正面
        let reveal = min(abs(drag.width) / revealDistance, 1)

        return ZStack {
            // 后置卡：下一张。静止时缩 0.95、抬 28pt；拖动时随手指往上升
            if let upcoming = nextPhoto {
                cardView(upcoming, size: card)
                    .scaleEffect(backScale + (1 - backScale) * reveal)
                    .offset(y: -backLift * (1 - reveal))
                    .opacity(0.9 + 0.1 * reveal)
                    .allowsHitTesting(false)
            }

            // 当前卡：跟手平移 + 微转，换张时由 `rise` 从后方升上来
            if let photo = current {
                cardView(photo, size: card, glow: glow, erase: erase)
                    .scaleEffect(riseScale)
                    .offset(x: drag.width, y: drag.height + riseLift)
                    .rotationEffect(.degrees(drag.width * rotationFactor))
                    .opacity(detailActive ? 0 : 1)
                    .animation(.smooth(duration: 0.3), value: detailActive)
                    .id(photo.id)
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

            // 飞行卡：旧卡的复制体，只管飞，不参与任何逻辑
            if let flying {
                cardView(flying, size: flyingCardSize)
                    .offset(x: flyingOffset.width, y: flyingOffset.height)
                    .rotationEffect(.degrees(flyingRotation))
                    .opacity(flyingOpacity)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .center)
    }

    @ViewBuilder
    func cardView(_ photo: PhotoItem,
                  size: CGSize,
                  glow: CGFloat = 0,
                  erase: CGFloat = 0) -> some View {
        SwipePhotoCard(photo: photo,
                       cardSize: size,
                       sizeLabel: sizeLabel(photo),
                       glow: glow,
                       erase: erase)
            .frame(width: size.width, height: size.height)
    }

    /// `rise` 为 0 时正好落在后置卡的位置；弹簧冲过 1 就是那一下回弹。
    var riseScale: CGFloat { backScale + (1 - backScale) * rise }
    var riseLift: CGFloat { -backLift * (1 - rise) }

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

                // 竖直打三折：上滑要拖得更久，下拉时卡片沉得慢、给轨道让位
                drag = CGSize(width: rubber(t.width, limit: 260),
                              height: rubber(t.height * verticalDamping, limit: 200))

                // 上滑：越接近删除阈值，外缘的绯红光晕越亮
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
            }
            .onEnded { value in
                guard !isPlaying else { return }
                let t = value.translation

                guard current != nil else {
                    // 空态：右滑回去看最后一张
                    if t.width > swapThreshold, abs(t.width) > abs(t.height), !photos.isEmpty {
                        restoreToLast()
                    } else {
                        springBack()
                    }
                    return
                }

                // 方向判定先用**原始**位移，跟手上的打折不影响阈值
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

    func rubber(_ value: CGFloat, limit: CGFloat) -> CGFloat {
        if value < -limit { return -limit + (value + limit) * 0.28 }
        if value > limit { return limit + (value - limit) * 0.28 }
        return value
    }

    /// 没到阈值：卡片回原位，后置卡退回后方。
    func springBack() {
        withAnimation(.snappy(duration: 0.32)) {
            drag = .zero
            glow = 0
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
        withAnimation(riseSpring) { rise = 1 }
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
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                isPlaying = false
                onFinished(.album)
                poseIncoming()
            }
        }
    }

    enum Exit { case left, right }

    /// 出手：先把当前卡复制成飞行卡，再立刻换内容、让新卡升起来。
    /// **不等**旧卡飞完——这是整套动效连贯的原因。
    func commit(_ move: SortMove, exit: Exit) {
        guard let photo = current else { return }
        isPlaying = true

        let card = cardSize(in: deckSize)
        // 1. 飞行卡接住当前的位移与转角，从这一刻开始独立
        withoutAnimation {
            flying = photo
            flyingCardSize = card
            flyingOffset = drag
            flyingRotation = drag.width * rotationFactor
            flyingOpacity = 1
        }

        // 2. 立刻换数据：当前卡变成下一张，并停在「后方」的位置
        withoutAnimation {
            drag = .zero
            glow = 0
            erase = 0
            tray = 0
            rise = 0
        }
        onFinished(move)

        // 3. 下一帧同时开两条动画：飞行卡出屏、新卡升起
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(16))

            withAnimation(.timingCurve(0.22, 0.74, 0.24, 1, duration: exitDuration)) {
                flyingOffset = exitOffset(exit, card: card)
                flyingRotation = exitRotation(exit)
                flyingOpacity = 0.94
            }
            withAnimation(riseSpring) { rise = 1 }

            // 输入闸门：给新卡 280ms 站稳（ReelSort 的 CARD_READY_DELAY）
            try? await Task.sleep(for: .milliseconds(280))
            isPlaying = false

            // 飞行卡落屏后回收
            try? await Task.sleep(for: .milliseconds(660))
            withoutAnimation {
                flying = nil
                flyingOpacity = 1
                flyingRotation = 0
            }
        }
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
                rise = 0
            }
            onFinished(.delete)
            withAnimation(riseSpring) { rise = 1 }
            try? await Task.sleep(for: .milliseconds(280))
            isPlaying = false
        }
    }

    /// 外部改游标（切月、详情页送进待删除…）后让卡片归位。
    func poseIncoming() {
        withoutAnimation { rise = 0 }
        withAnimation(riseSpring) { rise = 1 }
    }

    func exitOffset(_ exit: Exit, card: CGSize) -> CGSize {
        // 用「半屏 + 卡片」保证无论屏幕多大都真的出画
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
