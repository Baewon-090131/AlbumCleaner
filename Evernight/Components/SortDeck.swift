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
    /// 翻过本月最后一张后，空绳上写的那句话。
    let endTitle: String
    /// 本次整理的删除结算：张数与释放体积。删过的才显示，没删就只留一句收尾。
    var endDeleted = 0
    var endFreed = ""
    let sizeLabel: (PhotoItem) -> String
    /// 手势判定结果；返回是否受理（撤回但栈空时返回 false，卡片归位）。
    let onSwipe: (SortMove) -> Bool
    let onFinished: (SortMove) -> Void
    let onTap: (PhotoItem, CGRect) -> Void
    let onAddToAlbum: () -> Void
    /// 翻过最后一张、进入「整理完毕」时回调一次（放烟花）。
    let onReachEnd: () -> Void
    /// 删除时的碎沙交给外层全屏渲染（沙子要飘出相纸、画满整屏）。
    let onSandBurst: (SandBurst) -> Void
    /// 详情页打开：两侧卡片向外抽走，当前卡交给详情层接管（避免两层重复）。
    var detailActive = false

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
    /// 相纸从下往上被擦掉的比例（0 → 1）。
    @State private var eraseProgress: CGFloat = 0
    /// 卡片区尺寸（采样缩略图时要用它算请求尺寸，必须与 `PolaroidCard` 一致才能命中缓存）。
    @State private var deckSize: CGSize = .zero
    /// 卡片区在屏幕上的原点（把碎沙换算到全屏坐标）。
    @State private var deckOrigin: CGPoint = .zero
    /// 自己写 `index` 时记下目标值，避免把切卡当成外部撤回再播一次入场。
    @State private var lastSelfIndex: Int?

    /// 以下五项是「我的 → Debug 模式」里可调的布局参数，直接落 UserDefaults，
    /// 整理页与调试面板读写同一组 key，滑钮一动卡片区立刻重绘。
    @AppStorage("ac_dbg_paper") private var paperScale: Double = 0.90
    @AppStorage("ac_dbg_shift") private var topShift: Double = 48
    @AppStorage("ac_dbg_cord") private var cordTopValue: Double = 26
    @AppStorage("ac_dbg_sag") private var sagValue: Double = 15
    @AppStorage("ac_dbg_peek") private var peekValue: Double = 0
    /// 矮相纸自动下移到卡片区中央，靠一根吊绳挂在绳子上（仅「挂绳相纸」主题可用）。
    @AppStorage("ac_dbg_hang") private var hangEnabled = true

    @Environment(\.displayScale) private var displayScale

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
            let origin = geometry.frame(in: .global).origin
            ZStack(alignment: .topLeading) {
                // 翻过最后一张：照片不再出现，绳子原地留着，只写一句话
                if currentPhoto == nil {
                    MonthDoneView(title: endTitle, deleted: endDeleted, freed: endFreed)
                        .frame(width: size.width, height: size.height, alignment: .top)
                        .offset(y: cordTop + sag + 52)
                        .transition(.opacity)
                } else {
                    // 前后各两张全部提前渲染：相邻两张可见（各露 peek），
                    // 再往外两张停在屏外，只为把图片和播放器先加载好，
                    // 切过去时不会再闪一帧。
                    // 只完整渲染 ±2 五张；更远的靠 prefetch 预取缓存，不挂视图
                    ForEach(-2...2, id: \.self) { offset in
                        if let photo = photo(at: offset) {
                            card(offset == 0 ? (ghost ?? photo) : photo,
                                 direction: offset,
                                 in: size,
                                 origin: origin)
                        }
                    }
                }

                cord(width: size.width)
                    .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 整组（绳子 + 木夹 + 相纸）一起上提，抵消上方多出来的留白
            .offset(y: -CGFloat(topShift))
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onAppear {
                deckSize = size
                deckOrigin = origin
                prefetch(in: size)
            }
            .onChange(of: size) { _, new in
                deckSize = new
                deckOrigin = origin
                prefetch(in: new)
            }
        }
        .onChange(of: command) { _, value in
            guard let value else { return }
            play(value)
        }
        .onChange(of: index) { old, new in
            prefetch(in: deckSize)
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

    /// 绳在 x 处的切线角：相纸绕木夹转这个角度就正好贴着绳弯。
    func cordTilt(_ x: CGFloat, width: CGFloat) -> Double {
        let t = min(max(x / max(width, 1), 0), 1)
        let slope = 4 * sag * (1 - 2 * t) / max(width, 1)
        return Double(atan(slope))
    }

    func cord(width: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: cordTop - sag))
            path.addQuadCurve(to: CGPoint(x: width, y: cordTop - sag),
                              control: CGPoint(x: width / 2, y: cordTop + sag))
        }
        .stroke(Theme.accent.opacity(0.55), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        .frame(width: width, height: max(0, cordTop + 4))
        .allowsHitTesting(false)
    }

    /// 邻卡在屏幕边缘露出的宽度。
    var peek: CGFloat { CGFloat(peekValue) }

    /// 相纸顶边的 y：邻卡贴着绳子；当前卡（开了吊绳时）落在
    /// 「绳中点 → tab 栏上边界」这条垂线段的中点。
    func cardTopY(centerX: CGFloat, photo: PhotoItem?, isCurrent: Bool, in size: CGSize) -> CGFloat {
        let attached = cordY(centerX, width: size.width) + cordGap
        guard hangEnabled, isCurrent, let photo else { return attached }
        let height = PolaroidMetrics.make(for: photo, bounds: size, paperScale: CGFloat(paperScale)).paper.height
        let middle = (cordY(size.width / 2, width: size.width) + size.height) / 2
        return max(attached, middle - height / 2)
    }

    /// - Parameters:
    ///   - direction: 0 = 当前卡，±1 = 左右邻卡（露出 peek），±2 = 屏外预热。
    ///   - origin: 卡片区在屏幕上的原点，详情页的锚点要用屏幕坐标。
    @ViewBuilder
    func card(_ photo: PhotoItem, direction: Int, in size: CGSize, origin: CGPoint) -> some View {
        let metrics = PolaroidMetrics.make(for: photo, bounds: size, paperScale: CGFloat(paperScale))
        let isCurrent = direction == 0
        let isGhost = isCurrent && ghost != nil
        // 五张按「相邻半宽和 − 露出」逐张累加，像一条真正的晾衣绳：
        // 间距一致、每张都在绳上完整挂着，只是超出屏幕的部分看不见。
        let baseX = size.width / 2 + centerOffset(direction, in: size)
        // 整组 1:1 跟手；切张时靠位移补偿保证落点连续
        let centerX = baseX + dragOffset
        // 相纸顶边落在绳子下方，木夹跨在绳上、下半截压在纸上
        let topY = cardTopY(centerX: centerX, photo: photo, isCurrent: isCurrent, in: size)

        // 详情打开时中间那张交给详情层接管（原地放大），两侧保持不动
        let detailShift: CGFloat = 0

        PolaroidCard(photo: photo,
                     metrics: metrics,
                     sizeLabel: isCurrent && !isGhost ? sizeLabel(photo) : "",
                     isFront: !isGhost,
                     erase: isCurrent ? eraseProgress : 0,
                     onOpenViewer: {
                         if isCurrent {
                             onTap(photo, CGRect(x: origin.x + centerX - metrics.paper.width / 2,
                                                 y: origin.y + topY - CGFloat(topShift),
                                                 width: metrics.paper.width,
                                                 height: metrics.paper.height))
                         }
                     })
            .frame(width: metrics.paper.width, height: metrics.paper.height)
            .overlay(alignment: .topLeading) {
                // 每张相纸都带自己的木夹；当前卡如果被吊绳垂下来，再补一段竖线
                ZStack(alignment: .topLeading) {
                    if hangEnabled, isCurrent {
                        let rope = topY - cordGap - cordY(centerX, width: size.width)
                        if rope > 4 {
                            Rectangle()
                                .fill(Theme.accent.opacity(0.55))
                                .frame(width: 1.2, height: rope)
                                .offset(x: metrics.paper.width / 2 - 0.6,
                                        y: -cordGap - rope)
                        }
                    }
                    PolaroidPeg()
                        .offset(x: metrics.paper.width / 2 - 5, y: -12)
                }
                .allowsHitTesting(false)
            }
            // 相纸与木夹一起贴着绳子弯曲，而不是固定左右歪
            .rotationEffect(.radians(cordTilt(centerX, width: size.width)), anchor: .top)
            .offset(x: centerX - metrics.paper.width / 2 + detailShift,
                    y: topY + (isGhost ? ghostLift : (isCurrent ? frontLift.height : 0)))
            .opacity(detailActive && isCurrent ? 0 : (isGhost ? ghostOpacity : 1))
            .animation(.smooth(duration: 0.32), value: detailActive)
            .zIndex(isCurrent ? 0 : -1)
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
                    // 上滑不跟手：松手直接原地消散
                    frontLift = .zero
                }
            }
            .onEnded { value in
                guard !isPlaying else { return }

                // 空绳（整理完毕）：只认「向右滑」，滑回去检查最后一张
                guard currentPhoto != nil else {
                    let translation = value.translation
                    if translation.width > swapThreshold,
                       abs(translation.width) > abs(translation.height) {
                        returnToLastPhoto()
                    }
                    return
                }

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
        centerOffset(1, in: deckSize)
    }

    /// 偏移 `offset` 张的那张相纸相对当前卡的中心位移。
    /// 逐张按「上一张半宽 + 这一张半宽 − 露出」累加，宽窄不一也能排得匀。
    func centerOffset(_ offset: Int, in size: CGSize) -> CGFloat {
        guard offset != 0, size.width > 0 else { return 0 }
        let step = offset > 0 ? 1 : -1
        var x: CGFloat = 0
        var i = 0
        while i != offset {
            let next = i + step
            x += CGFloat(step) * (paperWidth(at: i, in: size) / 2
                + paperWidth(at: next, in: size) / 2
                - peek)
            i = next
        }
        return x
    }

    func paperWidth(at offset: Int, in size: CGSize) -> CGFloat {
        guard let photo = photo(at: offset) else { return 0 }
        return PolaroidMetrics.make(for: photo, bounds: size, paperScale: CGFloat(paperScale)).paper.width
    }

    /// 把前 10 张、后 5 张的大图全部拉进缓存。视图虽然已经挂着，
    /// 但 `AsyncThumbnail` 的请求是异步的；这里主动把它们拉完，
    /// 滑过去时缓存必然命中，不会出现占位或拉伸。
    func prefetch(in size: CGSize) {
        guard size.width > 0 else { return }
        for offset in -10...5 {
            guard let photo = photo(at: offset) else { continue }
            let metrics = PolaroidMetrics.make(for: photo, bounds: size, paperScale: CGFloat(paperScale))
            let request = CGSize(
                width: min(metrics.photo.width * displayScale * 1.5, 2800),
                height: min(metrics.photo.height * displayScale * 1.5, 2800)
            )
            Task {
                _ = await ThumbnailLoader.shared.image(for: photo.asset,
                                                       targetSize: request,
                                                       highQuality: true)
            }
        }
    }

    /// 跟手切张：游标立刻改掉，同时把整组位移补偿一个「相邻中心距」，
    /// 这样切完那一帧的落点与切前一帧完全连续；随后再用 `.smooth(0.3)` 平滑归位。
    /// 浏览是纯跟手的，不播飞出动画——只有删除 / 存入相簿才走 `playTakeOff`。
    func commitSwipe(forward: Bool) {
        let next = forward ? index + 1 : index - 1
        // 游标可以停在 photos.count（空绳 = 本月整理完毕）
        guard next >= 0, next <= photos.count else { return springBack() }

        // 最后一张继续往前翻：卡片滑出屏幕，交给空绳上的收尾文案
        if forward, next == photos.count {
            finishMonth()
            return
        }

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

    /// 最后一张继续向前：相纸滑出屏幕，游标落到 `photos.count`，
    /// 绳子留在原地，收尾文案淡入，同时通知外层放烟花。
    func finishMonth() {
        isPlaying = true
        withAnimation(.smooth(duration: 0.26)) {
            dragOffset = -(deckSize.width + 80)
            dragAngle = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            lastSelfIndex = photos.count
            withAnimation(.smooth(duration: 0.3)) {
                index = photos.count
                dragOffset = 0
                dragAngle = 0
            }
            isPlaying = false
            onReachEnd()
        }
    }

    /// 空绳上向右滑：回到最后一张，卡片从左侧滑进来。
    func returnToLastPhoto() {
        guard photos.count > 0 else { return }
        lastSelfIndex = nil
        index = photos.count - 1
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
            // 缓存 key 必须与 `AsyncThumbnail` 用的一致（按 displayScale × 1.5 放大、单边封顶 2800），
            // 否则永远 miss，采不到颜色、一粒沙都不会出现。
            let request = CGSize(
                width: min(metrics.photo.width * displayScale * 1.5, 2800),
                height: min(metrics.photo.height * displayScale * 1.5, 2800)
            )
            // 照片窗口在屏幕上的位置：卡片区原点 + 卡片中心 + 白边，
            // 沙粒按这个矩形起飞，画布则是整屏。
            let centerX = deckSize.width / 2
            let topY = cardTopY(centerX: centerX, photo: photo, isCurrent: true, in: deckSize)
            let frameInScreen = CGRect(
                x: deckOrigin.x + centerX - metrics.paper.width / 2 + metrics.pad,
                y: deckOrigin.y + topY - CGFloat(topShift) + metrics.pad,
                width: metrics.photo.width,
                height: metrics.photo.height
            )
            if let burst = SandSampler.burst(for: photo,
                                             targetSize: request,
                                             frameInScreen: frameInScreen) {
                onSandBurst(burst)
            }
        }
        // 相纸自下而上被擦掉，沙粒也按同一个方向逐段生成（底部先走）
        withAnimation(.smooth(duration: 0.72)) { eraseProgress = 1 }
        Task {
            try? await Task.sleep(for: .seconds(1.0))
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
            // 1. 先倒做删除后的「下一张补位」：现在这张往右滑走
            withAnimation(.smooth(duration: 0.26)) { dragOffset = 170 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(260))
                // 2. 被撤的那张从上方渐显落下；同一帧把补位卡复位，
                //    避免屏幕上同时出现两张
                withoutAnimation {
                    ghost = incoming
                    ghostLift = -360
                    ghostOpacity = 0
                    dragOffset = 0
                }
                withAnimation(.snappy(duration: 0.36)) {
                    ghostLift = 0
                    ghostOpacity = 1
                }
                try? await Task.sleep(for: .milliseconds(360))
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
        eraseProgress = 0
    }
}

