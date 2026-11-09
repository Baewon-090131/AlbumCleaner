import SwiftUI

/// 整理页的单卡手势区（液态玻璃版）。
///
/// 一次只显示一张照片卡，四个方向各管一件事：
/// - **左滑**：下一张（卡片向左飞出，下一张从右侧进来）
/// - **右滑**：撤回上一个动作（卡片向右飞出，被撤那张从上方落回）
/// - **上滑**：删除。不到阈值时卡片外缘浮起绯红光晕；过阈值松手，照片碎成粒子向上飘散
/// - **下拉**：底部升起相簿托盘，松手就把这张存进当前高亮的那一格
///
/// 与旧「挂绳相纸」一样：手势只把结论交给外层（`onSwipe` / `onFinished`），
/// 数据变更永远发生在动效播完之后。
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

    /// 当前卡片的跟手位移。
    @State private var drag: CGSize = .zero
    /// 删除阈值光晕（0…1）。
    @State private var glow: CGFloat = 0
    /// 相簿托盘展开度（0…1）。
    @State private var tray: CGFloat = 0
    /// 托盘里被悬停的相簿。
    @State private var hovered: AlbumItem?
    /// 碎沙擦拭进度。
    @State private var erase: CGFloat = 0
    /// 撤回删除 / 存入相簿时临时落回来的那张。
    @State private var ghost: PhotoItem?
    @State private var ghostOpacity: Double = 1
    @State private var deckSize: CGSize = .zero
    @State private var deckOrigin: CGPoint = .zero
    /// 卡片自己触发的游标变化已经播过动效，下一次 `onChange` 不再补一次入场。
    @State private var suppressEnter = false

    @Environment(\.displayScale) private var displayScale

    private let swapThreshold: CGFloat = 90
    private let deleteThreshold: CGFloat = 110
    private let trayThreshold: CGFloat = 70

    private var current: PhotoItem? {
        photos.indices.contains(index) ? photos[index] : nil
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let origin = geo.frame(in: .global).origin

            ZStack(alignment: .bottom) {
                if current == nil {
                    MonthDoneView(title: endTitle, deleted: endDeleted, freed: endFreed)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                } else {
                    cardLayer(size: size, origin: origin)
                }

                if tray > 0.01, !albums.isEmpty {
                    AlbumDropTray(albums: albums, hovered: hovered, progress: tray)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onAppear { deckSize = size; deckOrigin = origin }
            .onChange(of: size) { _, new in deckSize = new; deckOrigin = origin }
        }
        .onChange(of: command) { _, value in
            guard let value else { return }
            play(value)
        }
        .onChange(of: index) { old, new in
            if suppressEnter {
                suppressEnter = false
                return
            }
            guard old != new else { return }
            enter(from: new > old ? 1 : -1)
        }
    }
}

// MARK: - 布局

private extension SwipeDeck {
    func cardLayer(size: CGSize, origin: CGPoint) -> some View {
        let card = cardSize(in: size)
        // 卡片在卡片区里垂直居中，再整体上提 12pt（给底部托盘留呼吸）
        let centerY = (size.height - 24 - card.height) / 2
        let photo = ghost ?? current

        return ZStack {
            if let photo {
                SwipePhotoCard(photo: photo,
                               cardSize: card,
                               sizeLabel: ghost == nil ? sizeLabel(photo) : "",
                               glow: ghost == nil ? glow : 0,
                               erase: ghost == nil ? erase : 0,
                               onTap: {
                                   guard ghost == nil else { return }
                                   onTap(photo, CGRect(x: origin.x + (size.width - card.width) / 2 + drag.width,
                                                       y: origin.y + centerY + drag.height,
                                                       width: card.width,
                                                       height: card.height))
                               })
                    .frame(width: card.width, height: card.height)
                    .offset(x: drag.width, y: drag.height)
                    .opacity(detailActive ? 0 : ghostOpacity)
                    .animation(.smooth(duration: 0.3), value: detailActive)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.bottom, 24)
    }

    /// 卡片尺寸：竖图保持比例，横图收进 4:3；最宽 94%、最高 60%。
    func cardSize(in size: CGSize) -> CGSize {
        let maxW = size.width * 0.94
        let maxH = size.height * 0.60
        let ratio = min(max(current?.ratio ?? 0.75, 0.55), 1.9)
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
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isPlaying else { return }
                let t = value.translation

                // 空态：只认「右滑回去看最后一张」
                guard current != nil else { return }

                if abs(t.width) > abs(t.height) {
                    // 左右：只负责位移，不展开托盘
                    drag = CGSize(width: rubber(t.width), height: 0)
                    glow = 0
                    if tray != 0 { withAnimation(.snappy(duration: 0.2)) { tray = 0 } }
                    hovered = nil
                    return
                }

                if t.height < 0 {
                    // 上滑：跟手 + 阈值光晕
                    drag = CGSize(width: t.width * 0.2, height: rubberVertical(t.height))
                    let p = (-t.height - 40) / (deleteThreshold - 40)
                    glow = min(max(p, 0), 1)
                    if tray != 0 { withAnimation(.snappy(duration: 0.2)) { tray = 0 } }
                    hovered = nil
                } else {
                    // 下拉：卡片跟手坠一点，底部升起相簿托盘
                    drag = CGSize(width: 0, height: rubberVertical(t.height) * 0.5)
                    let p = min(max((t.height - 24) / (trayThreshold - 24), 0), 1)
                    if abs(tray - p) > 0.01 { withAnimation(.snappy(duration: 0.2)) { tray = p } }
                    glow = 0

                    // 卡片当前中心（含跟手位移）落在托盘的第几格
                    let centerX = deckSize.width / 2 + drag.width
                    if let hit = AlbumDropTray.index(at: centerX, count: albums.count) {
                        hovered = albums[hit]
                    } else {
                        hovered = nil
                    }
                }
            }
            .onEnded { value in
                guard !isPlaying else { return }
                let t = value.translation

                guard current != nil else {
                    if t.width > swapThreshold, abs(t.width) > abs(t.height), !photos.isEmpty {
                        suppressEnter = true
                        index = photos.count - 1
                    }
                    return
                }

                if abs(t.width) > abs(t.height) {
                    if t.width < -swapThreshold {
                        commitHorizontal(.next, forward: true)
                    } else if t.width > swapThreshold {
                        // 右滑 = 撤回上一个动作
                        if onSwipe(.undo) {
                            commitHorizontal(.undo, forward: false)
                        } else {
                            springBack()
                        }
                    } else {
                        springBack()
                    }
                    return
                }

                if t.height < 0 {
                    if t.height < -deleteThreshold {
                        guard onSwipe(.delete) else { return springBack() }
                        playDelete()
                    } else {
                        springBack()
                    }
                } else {
                    // 下拉松手：命中相簿就存进去，否则托盘收回
                    if let target = hovered, t.height > trayThreshold {
                        withAnimation(.snappy(duration: 0.26)) {
                            tray = 0
                            drag = .zero
                        }
                        onAddToAlbum(target)
                    } else {
                        withAnimation(.snappy(duration: 0.3)) {
                            tray = 0
                            drag = .zero
                        }
                    }
                    hovered = nil
                }
            }
    }

    func rubber(_ value: CGFloat) -> CGFloat {
        let limit: CGFloat = 160
        if value < -limit { return -limit + (value + limit) * 0.3 }
        if value > limit { return limit + (value - limit) * 0.3 }
        return value
    }

    func rubberVertical(_ value: CGFloat) -> CGFloat {
        let limit: CGFloat = 200
        if value < -limit { return -limit + (value + limit) * 0.3 }
        if value > limit { return limit + (value - limit) * 0.3 }
        return value
    }

    func springBack() {
        withAnimation(.snappy(duration: 0.34)) {
            drag = .zero
            glow = 0
            tray = 0
        }
        hovered = nil
    }

    /// 水平飞出：播完飞出 → 无动画复位并改数据 → 新卡从反方向进场。
    func commitHorizontal(_ move: SortMove, forward: Bool) {
        guard !isPlaying else { return }
        isPlaying = true
        suppressEnter = true
        let distance = deckSize.width + 120
        withAnimation(.smooth(duration: 0.28)) {
            drag = CGSize(width: forward ? -distance : distance, height: 0)
            glow = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            withoutAnimation {
                drag = .zero
                tray = 0
                hovered = nil
                isPlaying = false
                onFinished(move)
            }
            // 左滑翻过最后一张：交给外层放烟花，空态接手
            if move == .next, index >= photos.count {
                onReachEnd()
            }
        }
    }

    /// 外部改游标时让新卡从指定方向滑进来（1 = 从右，-1 = 从左）。
    func enter(from side: CGFloat) {
        withoutAnimation { drag = CGSize(width: side * 150, height: 0) }
        withAnimation(.smooth(duration: 0.32)) { drag = .zero }
    }

    /// 删除：整屏碎沙 + 卡片自下而上被擦掉，再改数据。
    func playDelete() {
        isPlaying = true
        emitSand()
        withAnimation(.smooth(duration: 0.72)) { erase = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            finishNow(.delete, refill: true)
        }
    }

    /// 采样本张照片的像素，生成一整屏的碎沙。
    func emitSand() {
        guard let photo = current, deckSize != .zero else { return }
        let card = cardSize(in: deckSize)
        let request = CGSize(
            width: min(card.width * displayScale * 1.5, 2800),
            height: min(card.height * displayScale * 1.5, 2800)
        )
        let centerY = (deckSize.height - 24 - card.height) / 2
        let frame = CGRect(
            x: deckOrigin.x + (deckSize.width - card.width) / 2,
            y: deckOrigin.y + centerY,
            width: card.width,
            height: card.height
        )
        if let burst = SandSampler.burst(for: photo, targetSize: request, frameInScreen: frame) {
            onSandBurst(burst)
        }
    }
}

// MARK: - 命令（顶栏按钮与撤回共用）

private extension SwipeDeck {
    func play(_ cmd: DeckCommand) {
        guard !isPlaying else { return }
        switch cmd.move {
        case .delete:
            isPlaying = true
            emitSand()
            withAnimation(.smooth(duration: 0.72)) { erase = 1 }
            Task {
                try? await Task.sleep(for: .milliseconds(950))
                finishNow(.delete, refill: true)
            }

        case .album:
            isPlaying = true
            withAnimation(.smooth(duration: 0.3)) {
                drag = CGSize(width: 0, height: 180)
                tray = 0
            }
            Task {
                try? await Task.sleep(for: .milliseconds(320))
                finishNow(.album, refill: true)
            }

        case .favorite:
            isPlaying = true
            withAnimation(.bouncy(duration: 0.3, extraBounce: 0.2)) { drag = .zero }
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                finishNow(.favorite)
            }

        case .next:
            commitHorizontal(.next, forward: true)

        case .undo:
            isPlaying = true
            if let incoming = cmd.incoming,
               cmd.reverseOf == .delete || cmd.reverseOf == .album {
                // 当前卡让开，被撤那张从上方落回
                withAnimation(.smooth(duration: 0.26)) { drag = CGSize(width: 160, height: 0) }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(260))
                    withoutAnimation {
                        ghost = incoming
                        ghostOpacity = 0
                        drag = .zero
                    }
                    withAnimation(.snappy(duration: 0.36)) { ghostOpacity = 1 }
                    try? await Task.sleep(for: .milliseconds(360))
                    finishNow(.undo)
                }
            } else {
                withAnimation(.bouncy(duration: 0.28, extraBounce: 0.2)) { drag = .zero }
                Task {
                    try? await Task.sleep(for: .seconds(0.28))
                    finishNow(.undo)
                }
            }
        }
    }

    /// 复位动效状态与数据变更放在同一帧：拆开会闪。
    /// `refill` = 删掉 / 存进相簿后，下一张要从右侧补位进来。
    func finishNow(_ move: SortMove, refill: Bool = false) {
        // 删除 / 相簿 / 撤回都会改游标；入场动效已在这里统一处理
        if move == .delete || move == .album || move == .undo { suppressEnter = true }
        withoutAnimation {
            drag = refill ? CGSize(width: deckSize.width * 0.55, height: 0) : .zero
            glow = 0
            tray = 0
            hovered = nil
            erase = 0
            ghost = nil
            ghostOpacity = 1
            isPlaying = false
            onFinished(move)
        }
        guard refill else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(16))
            withAnimation(.smooth(duration: 0.34)) { drag = .zero }
        }
    }
}
