import SwiftUI

/// 不带任何动画地改状态。动效复位必须这样走——
/// 否则卡片会在复位的那一帧重新播一遍过渡。
func withoutAnimation(_ work: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, work)
}

/// 整理页的卡片区：一排拍立得相纸挂在一条下垂的绳子上，中间那张就是当前照片。
///
/// 手势分工：
/// - **左右拖动**：拖绳子，相纸沿绳滑动并轻微摆动，松手吸附到最近的一张（只改浏览位置，不进撤销栈）。
/// - **上滑**：把当前那张从绳上摘下 —— 向上飞出、渐隐，其余相纸随数据变更收拢。
/// - **下滑**：收藏，弹回原位。
///
/// 与旧 `SortDeck` 一致的两条约定保留：**先动效后数据**（播完才回调 `onFinished`）、
/// **复位与数据变更在同一个无动画事务里**（否则会渲染出中间帧）。
struct PolaroidDeck: View {
    let photos: [PhotoItem]
    /// 当前中间那张在 `photos` 里的下标。拖动吸附结束后由这里写回。
    @Binding var index: Int
    let command: DeckCommand?
    @Binding var isPlaying: Bool
    let sizeLabel: (PhotoItem) -> String
    /// 手势判定结果；返回是否受理（撤回但栈空时返回 false，卡片归位）。
    let onSwipe: (SortMove) -> Bool
    let onFinished: (SortMove) -> Void
    let onTap: (PhotoItem) -> Void
    let onAddToAlbum: () -> Void

    /// 水平浏览偏移。正 = 内容向左走（看后面的照片）。
    @State private var lineOffset: CGFloat = 0
    @State private var lineStart: CGFloat?
    @State private var draggingLine = false
    /// 相纸绕木夹摆动的角度（弧度）。
    @State private var dragAngle: Double = 0
    /// 当前卡跟手的垂直位移。
    @State private var frontLift: CGSize = .zero
    /// 撤回删除 / 存入相簿时，临时挂回绳子上的那张。
    @State private var ghost: PhotoItem?
    @State private var ghostLift: CGFloat = 0
    @State private var ghostOpacity: Double = 1
    /// 自己写 `index` 时记下目标值，避免把吸附当成外部撤回再播一次镜头平移。
    @State private var lastSelfIndex: Int?

    /// 碎沙：当前卡被摘下时按像素拆成的约 2000 粒。
    @State private var sand: SandBurst?
    /// 相纸从下往上被擦掉的比例（0 → 1）。
    @State private var eraseProgress: CGFloat = 0
    /// 卡片区尺寸，采样时要用它算缩略图请求尺寸（必须与 `PolaroidCard` 一致才能命中缓存）。
    @State private var deckSize: CGSize = .zero

    /// 宽松的挂绳间隙：相纸之间留一点能看见绳子的空。
    private let gap: CGFloat = 24
    /// 绳子的挂高（从卡片区顶部算）。
    private let cordTop: CGFloat = 44
    /// 绳子中点的下垂量。
    private let sag: CGFloat = 26
    /// 窗口半径：只渲染当前前后各 3 张，整月照片不可能全量挂上去。
    private let windowRadius = 3
    private let deleteThreshold: CGFloat = 90
    private let favoriteThreshold: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            let list = visibleItems
            let xs = lineOffsets(list, bounds: geometry.size)

            ZStack(alignment: .topLeading) {
                ForEach(Array(list.enumerated()), id: \.element.id) { rel, item in
                    card(item, rel: rel, xs: xs, bounds: geometry.size)
                }

                if list.isEmpty {
                    EmptyDeckView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(alignment: .topLeading) {
                cord(width: geometry.size.width)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(xs: xs))
            .onAppear { deckSize = geometry.size }
            .onChange(of: geometry.size) { _, size in deckSize = size }
        }
        .onChange(of: command) { _, value in
            guard let value else { return }
            play(value)
        }
        .onChange(of: index) { old, new in
            if let pending = lastSelfIndex {
                if pending == new {
                    lastSelfIndex = nil
                    return
                }
            }
            guard old != new else { return }
            // 外部改游标（撤回）：让镜头从对应方向平移过去
            slideFrom(side: new > old ? -1 : 1)
        }
    }
}

// MARK: - 排布

private extension PolaroidDeck {
    /// 只渲染当前附近的窗口；撤回时把临时挂回的那张插在 `index` 位置。
    var visibleItems: [PhotoItem] {
        guard !photos.isEmpty, photos.indices.contains(index) else { return [] }
        let upper = min(photos.count - 1, index + windowRadius)
        var list = Array(photos[windowStart...upper])
        if let ghost {
            list.insert(ghost, at: min(max(0, index - windowStart), list.count))
        }
        return list
    }

    var windowStart: Int {
        max(0, index - windowRadius)
    }

    /// 窗口内「当前」那张的位置。
    var currentRel: Int {
        index - windowStart
    }

    /// 每张相纸中心相对第一张的偏移（相纸宽窄不一，间距按半宽累加）。
    func lineOffsets(_ items: [PhotoItem], bounds: CGSize) -> [CGFloat] {
        guard !items.isEmpty else { return [] }
        var result: [CGFloat] = [0]
        var previous = PolaroidMetrics.make(for: items[0], bounds: bounds).paper.width
        for item in items.dropFirst() {
            let width = PolaroidMetrics.make(for: item, bounds: bounds).paper.width
            result.append(result[result.count - 1] + previous / 2 + gap + width / 2)
            previous = width
        }
        return result
    }

    /// 绳子上 x 处的挂点高度（二次曲线）。
    func cordY(_ x: CGFloat, width: CGFloat) -> CGFloat {
        let t = min(max(x / max(width, 1), 0), 1)
        return cordTop + 4 * sag * t * (1 - t)
    }

    func cord(width: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: cordTop))
            path.addQuadCurve(to: CGPoint(x: width, y: cordTop),
                              control: CGPoint(x: width / 2, y: cordTop + sag * 2))
        }
        .stroke(Theme.ink3, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        .frame(width: width, height: cordTop + sag * 2 + 4)
        .allowsHitTesting(false)
    }
}

// MARK: - 卡片

private extension PolaroidDeck {
    @ViewBuilder
    func card(_ item: PhotoItem, rel: Int, xs: [CGFloat], bounds: CGSize) -> some View {
        let metrics = PolaroidMetrics.make(for: item, bounds: bounds)
        let isCurrent = rel == currentRel
        let isGhost = ghost != nil && isCurrent
        let centerX = bounds.width / 2 + xs[rel] - xs[currentRel] - lineOffset
        let topY = cordY(centerX, width: bounds.width) - 6
        let lift: CGFloat = isGhost ? ghostLift : (isCurrent ? frontLift.height : 0)
        let opacity: Double = isGhost ? ghostOpacity : 1

        let base = PolaroidCard(photo: item,
                                metrics: metrics,
                                sizeLabel: sizeLabel(item),
                                isFront: isCurrent,
                                erase: isCurrent ? eraseProgress : 0,
                                onOpenViewer: { onTap(item) })
            .frame(width: metrics.paper.width, height: metrics.paper.height)
            .overlay(alignment: .topLeading) {
                if isCurrent, let sand {
                    SandCanvas(burst: sand)
                        .frame(width: metrics.photo.width, height: metrics.photo.height)
                        .offset(x: metrics.pad, y: metrics.pad)
                }
            }
            .scaleEffect(isCurrent ? 1 : 0.9, anchor: .top)
            .saturation(isCurrent ? 1 : 0.7)
            .brightness(isCurrent ? 0 : -0.04)
            .rotationEffect(.radians(isCurrent ? dragAngle : 0), anchor: .top)
            .offset(x: centerX - metrics.paper.width / 2, y: topY + lift)
            .opacity(opacity)
            .zIndex(isCurrent ? 20 : Double(10 - abs(rel - currentRel)))

        if isCurrent {
            base.contextMenu {
                Button {
                    onAddToAlbum()
                } label: {
                    Label("存入相簿", systemImage: "photo.stack")
                }
            }
        } else {
            base
        }
    }
}

// MARK: - 手势

private extension PolaroidDeck {
    func dragGesture(xs: [CGFloat]) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard !isPlaying, !visibleItems.isEmpty else { return }
                if lineStart == nil {
                    lineStart = lineOffset
                    draggingLine = abs(value.translation.width) > abs(value.translation.height)
                }
                if draggingLine {
                    let start = lineStart ?? 0
                    lineOffset = clamped(start - value.translation.width, xs: xs)
                    dragAngle = min(max(-value.velocity.width * 0.0004, -0.055), 0.055)
                } else {
                    frontLift = CGSize(width: 0, height: value.translation.height)
                }
            }
            .onEnded { value in
                let start = lineStart ?? lineOffset
                lineStart = nil
                guard !isPlaying, !visibleItems.isEmpty else { return }

                if draggingLine {
                    draggingLine = false
                    snap(start: start, projected: value.predictedEndTranslation.width, xs: xs)
                    return
                }

                if value.translation.height < -deleteThreshold {
                    guard onSwipe(.delete) else { return springBack() }
                } else if value.translation.height > favoriteThreshold {
                    guard onSwipe(.favorite) else { return springBack() }
                } else {
                    springBack()
                }
            }
    }

    /// 两端的橡皮筋：越界只给 35% 位移。
    func clamped(_ value: CGFloat, xs: [CGFloat]) -> CGFloat {
        guard let last = xs.last else { return 0 }
        let lower = -xs[min(currentRel, xs.count - 1)]
        let upper = last - xs[min(currentRel, xs.count - 1)]
        if value < lower { return lower + (value - lower) * 0.35 }
        if value > upper { return upper + (value - upper) * 0.35 }
        return value
    }

    /// 松手：按「起点位移 + 惯性投影」找最近的一张，吸附过去。
    /// 吸附这 0.34s 也用 `isPlaying` 锁住，避免半路再拖一次把落点算歪。
    func snap(start: CGFloat, projected dx: CGFloat, xs: [CGFloat]) {
        guard !xs.isEmpty else { return }
        isPlaying = true
        let target = start - dx
        var best = 0
        for rel in xs.indices where abs(xs[rel] - target) < abs(xs[best] - target) {
            best = rel
        }
        let current = min(currentRel, xs.count - 1)
        let delta = xs[best] - xs[current]

        withAnimation(.snappy(duration: 0.34)) { lineOffset = delta }
        withAnimation(.bouncy(duration: 0.45, extraBounce: 0.1)) { dragAngle = 0 }
        Task {
            try? await Task.sleep(for: .seconds(0.34))
            jump(to: best)
        }
    }

    /// 吸附落定：游标与偏移在同一个无动画事务里换，视觉上卡片不会闪一下。
    func jump(to rel: Int) {
        let target = windowStart + rel
        guard photos.indices.contains(target) else {
            isPlaying = false
            return
        }
        guard target != index else {
            withoutAnimation {
                lineOffset = 0
                dragAngle = 0
                frontLift = .zero
                isPlaying = false
            }
            return
        }
        lastSelfIndex = target
        withoutAnimation {
            index = target
            lineOffset = 0
            dragAngle = 0
            frontLift = .zero
            isPlaying = false
        }
    }

    /// 外部改游标时让镜头平移：负值从右边进来，正值从左边进来。
    func slideFrom(side: CGFloat) {
        let step = CGFloat(190)
        withoutAnimation { lineOffset = side * step }
        withAnimation(.snappy(duration: 0.32)) { lineOffset = 0 }
    }

    func springBack() {
        withAnimation(.snappy(duration: 0.32)) { frontLift = .zero }
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

    /// 摘下：相纸按像素碎成约 2000 粒沙向上飘散，同时卡片从下往上被擦掉，
    /// 0.8s 后数据变更、下一张从右侧滑进中间（快-慢 300ms）。
    func playTakeOff(_ move: SortMove) {
        isPlaying = true
        let items = visibleItems
        if items.indices.contains(currentRel), deckSize != .zero {
            let photo = items[currentRel]
            let metrics = PolaroidMetrics.make(for: photo, bounds: deckSize)
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
            withoutAnimation {
                ghost = incoming
                ghostLift = -320
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
            // 撤收藏 / 撤浏览没有照片要挂回，只让当前卡回弹一下
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
            // 让步位动画有起点：数据变更的同一帧把整排先往右移一张
            if refill { lineOffset = -190 }
            isPlaying = false
            onFinished(move)
        }
        if refill {
            // 等一帧再归零，否则起点与终点会被合并在同一帧、看不到补位
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(16))
                withAnimation(.smooth(duration: 0.3)) { lineOffset = 0 }
            }
        }
    }

    func reset() {
        lineOffset = 0
        dragAngle = 0
        frontLift = .zero
        ghost = nil
        ghostLift = 0
        ghostOpacity = 1
        sand = nil
        eraseProgress = 0
    }
}
