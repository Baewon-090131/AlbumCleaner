import SwiftUI

/// 不带任何动画地改状态。动效复位必须这样走——
/// 否则卡片会在复位的那一帧重新播一遍过渡。
func withoutAnimation(_ work: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, work)
}

/// 整理页的卡片区：**一次只挂一张**拍立得相纸，吊在一条下垂的绳子上。
///
/// 层级：卡片在最下，绳子横过卡片上方，木夹压在绳子上——所以一眼能看出是「挂」着的。
/// 手势：
/// - **左右拖动**：相纸沿绳子滑一段并绕木夹摆动；松手不过阈值就弹回，过阈值切上一张 / 下一张
///   （只改浏览位置，不进撤销栈）。
/// - **上滑**：摘下这张 —— 照片碎成约 2000 粒沙向上飘散，相纸自下而上被擦掉。
/// - **下滑**：收藏，弹回原位。
struct PolaroidDeck: View {
    let photos: [PhotoItem]
    /// 当前这张在 `photos` 里的下标。
    @Binding var index: Int
    let command: DeckCommand?
    @Binding var isPlaying: Bool
    let sizeLabel: (PhotoItem) -> String
    /// 手势判定结果；返回是否受理（撤回但栈空时返回 false，卡片归位）。
    let onSwipe: (SortMove) -> Bool
    let onFinished: (SortMove) -> Void
    let onTap: (PhotoItem) -> Void
    let onAddToAlbum: () -> Void

    /// 水平偏移：负 = 卡片向左滑（看下一张）。
    @State private var dragOffset: CGFloat = 0
    /// 相纸绕木夹摆动的角度（弧度）。
    @State private var dragAngle: Double = 0
    /// 垂直跟手位移。
    @State private var frontLift: CGSize = .zero
    /// 撤回删除 / 存入相簿时，临时挂回来的那张。
    @State private var ghost: PhotoItem?
    @State private var ghostLift: CGFloat = 0
    @State private var ghostOpacity: Double = 1
    /// 碎沙。
    @State private var sand: SandBurst?
    /// 相纸从下往上被擦掉的比例（0 → 1）。
    @State private var eraseProgress: CGFloat = 0
    /// 卡片区尺寸（采样缩略图时要用它算请求尺寸，必须与 `PolaroidCard` 一致才能命中缓存）。
    @State private var deckSize: CGSize = .zero
    /// 自己写 `index` 时记下目标值，避免把切卡当成外部撤回再播一次入场。
    @State private var lastSelfIndex: Int?

    /// 以下五项是「我的 → Debug 模式」里可调的布局参数，直接落 UserDefaults，
    /// 整理页与调试面板读写同一组 key，滑钮一动卡片区立刻重绘。
    @AppStorage("ac_dbg_paper") private var paperScale: Double = 0.56
    @AppStorage("ac_dbg_shift") private var topShift: Double = 48
    @AppStorage("ac_dbg_cord") private var cordTopValue: Double = 64
    @AppStorage("ac_dbg_sag") private var sagValue: Double = 24
    @AppStorage("ac_dbg_peek") private var peekValue: Double = 26

    /// 绳子的挂高（从卡片区顶部算）。
    var cordTop: CGFloat { CGFloat(cordTopValue) }
    /// 绳子中点的下垂量。
    var sag: CGFloat { CGFloat(sagValue) }
    /// 相纸顶边留出绳子 + 木夹的高度。
    private let cordGap: CGFloat = 8
    private let deleteThreshold: CGFloat = 90
    private let favoriteThreshold: CGFloat = 40
    private let swapThreshold: CGFloat = 90

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack(alignment: .topLeading) {
                // 前后各两张全部提前渲染：相邻两张可见（各露 peek），
                // 再往外两张停在屏外，只为把图片和播放器先加载好，
                // 切过去时不会再闪一帧。
                ForEach(-2...2, id: \.self) { offset in
                    if let photo = photo(at: offset) {
                        card(offset == 0 ? (ghost ?? photo) : photo,
                             direction: offset,
                             in: size)
                    }
                }
                if currentPhoto == nil {
                    EmptyDeckView()
                        .frame(width: size.width, height: size.height)
                }

                cord(width: size.width)
                    .zIndex(1)

                // 木夹跟着卡片走，压在绳子上
                peg(in: size)
                    .zIndex(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 整组（绳子 + 木夹 + 相纸）一起上提，抵消上方多出来的留白
            .offset(y: -CGFloat(topShift))
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onAppear { deckSize = size }
            .onChange(of: size) { _, new in deckSize = new }
        }
        .onChange(of: command) { _, value in
            guard let value else { return }
            play(value)
        }
        .onChange(of: index) { old, new in
            if let pending = lastSelfIndex, pending == new {
                lastSelfIndex = nil
                return
            }
            guard old != new else { return }
            // 外部改游标（撤回）：游标前进时新卡从右边进来，后退时从左边进来
            enter(from: new > old ? 1 : -1)
        }
    }
}

// MARK: - 排布

private extension PolaroidDeck {
    var currentPhoto: PhotoItem? {
        photos.indices.contains(index) ? photos[index] : nil
    }

    /// 相对当前游标偏移 offset 张的那张照片；越界返回 nil。
    func photo(at offset: Int) -> PhotoItem? {
        let i = index + offset
        return photos.indices.contains(i) ? photos[i] : nil
    }

    /// 绳子上 x 处的挂点高度（二次曲线）。`cordTop` 是**中点**距卡片区顶部的距离。
    func cordY(_ x: CGFloat, width: CGFloat) -> CGFloat {
        let t = min(max(x / max(width, 1), 0), 1)
        return cordTop - sag + 4 * sag * t * (1 - t)
    }

    func cord(width: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: cordTop - sag))
            path.addQuadCurve(to: CGPoint(x: width, y: cordTop - sag),
                              control: CGPoint(x: width / 2, y: cordTop + sag))
        }
        .stroke(Theme.ink3, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        .frame(width: width, height: max(0, cordTop + 4))
        .allowsHitTesting(false)
    }

    /// 邻卡在屏幕边缘露出的宽度。
    var peek: CGFloat { CGFloat(peekValue) }

    @ViewBuilder
    func peg(in size: CGSize) -> some View {
        let centerX = size.width / 2 + dragOffset
        PolaroidPeg()
            .offset(x: centerX - 5, y: cordY(centerX, width: size.width) - 12)
            .allowsHitTesting(false)
    }

    /// - Parameter direction: 0 = 当前卡，±1 = 左右邻卡（露出 peek），±2 = 屏外预热。
    @ViewBuilder
    func card(_ photo: PhotoItem, direction: Int, in size: CGSize) -> some View {
        let metrics = PolaroidMetrics.make(for: photo, bounds: size, paperScale: CGFloat(paperScale))
        let isCurrent = direction == 0
        let isGhost = isCurrent && ghost != nil
        let width = metrics.paper.width
        // 邻卡的中心放在「让它在屏幕边缘露出 peek」的位置上；再往外两张直接推到屏外
        let baseX: CGFloat = {
            guard !isCurrent else { return size.width / 2 }
            let sign: CGFloat = direction > 0 ? 1 : -1
            let distance: CGFloat = abs(direction) == 1
                ? size.width / 2 + width / 2 - peek
                : size.width + 80 + CGFloat(abs(direction) - 2) * 60
            return size.width / 2 + sign * distance
        }()
        // 三张都 1:1 跟手，整组沿绳一起滑动；切张时靠位移补偿保证落点连续
        let centerX = baseX + dragOffset
        // 相纸顶边落在绳子下方，木夹跨在绳上、下半截压在纸上
        let topY = cordY(centerX, width: size.width) + cordGap

        PolaroidCard(photo: photo,
                     metrics: metrics,
                     sizeLabel: isCurrent && !isGhost ? sizeLabel(photo) : "",
                     isFront: isCurrent && !isGhost,
                     erase: isCurrent ? eraseProgress : 0,
                     onOpenViewer: { if isCurrent { onTap(photo) } })
            .frame(width: metrics.paper.width, height: metrics.paper.height)
            .overlay(alignment: .topLeading) {
                if isCurrent, let sand {
                    SandCanvas(burst: sand)
                        .frame(width: metrics.photo.width, height: metrics.photo.height)
                        .offset(x: metrics.pad, y: metrics.pad)
                }
            }
            .rotationEffect(.radians(isCurrent ? dragAngle : 0), anchor: .top)
            .offset(x: centerX - metrics.paper.width / 2,
                    y: topY + (isGhost ? ghostLift : (isCurrent ? frontLift.height : 0)))
            .opacity(isGhost ? ghostOpacity : 1)
            .zIndex(isCurrent ? 0 : -1)
            .contextMenu {
                if isCurrent, !isGhost {
                    Button {
                        onAddToAlbum()
                    } label: {
                        Label("存入相簿", systemImage: "photo.stack")
                    }
                }
            }
    }
}

// MARK: - 手势

private extension PolaroidDeck {
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard !isPlaying, currentPhoto != nil else { return }
                let translation = value.translation
                if abs(translation.width) > abs(translation.height) {
                    // 沿绳子滑动；两端超出只给 35%
                    dragOffset = rubber(translation.width)
                    dragAngle = min(max(Double(translation.width) * 0.0006, -0.06), 0.06)
                } else {
                    // 只让下滑有一点跟手反馈；**上滑不要移动卡片**，松手后原地消散
                    frontLift = CGSize(width: 0, height: max(0, translation.height) * 0.5)
                }
            }
            .onEnded { value in
                guard !isPlaying, currentPhoto != nil else { return }
                let translation = value.translation

                if abs(translation.width) > abs(translation.height) {
                    if translation.width < -swapThreshold {
                        commitSwipe(forward: true)
                    } else if translation.width > swapThreshold {
                        commitSwipe(forward: false)
                    } else {
                        springBack()
                    }
                    return
                }

                if translation.height < -deleteThreshold {
                    guard onSwipe(.delete) else { return springBack() }
                } else if translation.height > favoriteThreshold {
                    guard onSwipe(.favorite) else { return springBack() }
                } else {
                    springBack()
                }
            }
    }

    /// 水平位移的橡皮筋：只允许滑出一小段，不能把卡片拖出绳子。
    func rubber(_ value: CGFloat) -> CGFloat {
        let limit: CGFloat = 150
        if value < -limit { return -limit + (value + limit) * 0.35 }
        if value > limit { return limit + (value - limit) * 0.35 }
        return value
    }

    /// 相邻两张的中心距：正好等于邻卡贴边停在 `peek` 处时的距离。
    func neighborSpacing() -> CGFloat {
        guard let photo = currentPhoto else { return deckSize.width }
        let width = PolaroidMetrics.make(for: photo, bounds: deckSize, paperScale: CGFloat(paperScale)).paper.width
        return deckSize.width / 2 + width / 2 - peek
    }

    /// 跟手切张：游标立刻改掉，同时把整组位移补偿一个「相邻中心距」，
    /// 这样切完那一帧的落点与切前一帧完全连续；随后再用 `.smooth(0.3)` 平滑归位。
    /// 浏览是纯跟手的，不播飞出动画——只有删除 / 存入相簿才走 `playTakeOff`。
    func commitSwipe(forward: Bool) {
        let next = forward ? index + 1 : index - 1
        guard photos.indices.contains(next) else { return springBack() }

        let spacing = neighborSpacing()
        lastSelfIndex = next
        index = next
        dragOffset += forward ? spacing : -spacing
        dragAngle = 0
        frontLift = .zero
        // 隔一拍再归零：保证动画起点就是补偿后的连续位置，
        // 否则两次赋值被合进同一帧，切张瞬间会看到位置跳一下。
        Task { @MainActor in
            withAnimation(.smooth(duration: 0.3)) { dragOffset = 0 }
        }
    }

    /// 外部改游标时让新卡从指定方向滑进来。
    func enter(from side: CGFloat) {
        withoutAnimation { dragOffset = side * 170 }
        withAnimation(.smooth(duration: 0.3)) { dragOffset = 0 }
    }

    func springBack() {
        withAnimation(.snappy(duration: 0.32)) {
            dragOffset = 0
            dragAngle = 0
            frontLift = .zero
        }
    }
}

// MARK: - 播放

private extension PolaroidDeck {
    func play(_ cmd: DeckCommand) {
        guard !isPlaying else { return }
        switch cmd.move {
        case .delete:
            playTakeOff(.delete)
        case .album:
            playTakeOff(.album)
        case .favorite:
            playFavorite()
        case .next:
            finish(.next)
        case .undo:
            playUndo(cmd)
        }
    }

    /// 摘下：相纸**原地**碎成约 1500 粒沙向上飘散，同时卡片从下往上被擦掉。
    func playTakeOff(_ move: SortMove) {
        isPlaying = true
        withoutAnimation {
            frontLift = .zero
            dragOffset = 0
            dragAngle = 0
        }
        if let photo = currentPhoto, deckSize != .zero {
            let metrics = PolaroidMetrics.make(for: photo, bounds: deckSize, paperScale: CGFloat(paperScale))
            sand = SandSampler.burst(for: photo, targetSize: metrics.photo)
        }
        withAnimation(.smooth(duration: 0.78)) { eraseProgress = 1 }
        Task {
            try? await Task.sleep(for: .seconds(0.82))
            finish(move)
        }
    }

    /// 收藏：不摘下，弹回原位。
    func playFavorite() {
        isPlaying = true
        withAnimation(.bouncy(duration: 0.3, extraBounce: 0.22)) { frontLift = .zero }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            finish(.favorite)
        }
    }

    func playUndo(_ cmd: DeckCommand) {
        isPlaying = true
        if let incoming = cmd.incoming,
           cmd.reverseOf == .delete || cmd.reverseOf == .album {
            // 只让挂回来的那张出现，避免屏幕上同时两张
            withoutAnimation {
                ghost = incoming
                ghostLift = -340
                ghostOpacity = 0
            }
            withAnimation(.snappy(duration: 0.36)) {
                ghostLift = 0
                ghostOpacity = 1
            }
            Task {
                try? await Task.sleep(for: .seconds(0.36))
                finish(.undo)
            }
        } else {
            // 撤收藏没有照片要挂回，只让当前卡回弹一下
            withAnimation(.bouncy(duration: 0.28, extraBounce: 0.2)) { frontLift = .zero }
            Task {
                try? await Task.sleep(for: .seconds(0.28))
                finish(.undo)
            }
        }
    }

    func finish(_ move: SortMove) {
        let refill = move == .delete || move == .album
        withoutAnimation {
            reset()
            // 数据变更的同一帧把新卡先放到右边，再滑回中间（补位）
            if refill { dragOffset = 170 }
            isPlaying = false
            onFinished(move)
        }
        if refill {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(16))
                withAnimation(.smooth(duration: 0.3)) { dragOffset = 0 }
            }
        }
    }

    func reset() {
        dragOffset = 0
        dragAngle = 0
        frontLift = .zero
        ghost = nil
        ghostLift = 0
        ghostOpacity = 1
        sand = nil
        eraseProgress = 0
    }
}
