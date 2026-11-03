import SwiftUI

/// 不带任何动画地改状态。复位卡片位移时必须这样走——
/// 否则新卡会从屏外「飞」回来，或者旧卡拖着过渡重演一遍。
func withoutAnimation(_ work: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, work)
}

/// 卡片区：当前卡跟手平移、超过阈值飞出屏幕；下一张卡先在后方 0.94 处、向下沉 40pt 透明待命，
/// 前一张飞出时用同一个 Spring 放大到 1.0、归位并同步渐显。撤回则把整套分拣动效倒着放一遍——
/// 当前卡缩回 0.94 并下沉、渐隐退场，被撤那张从它当初飞出去的方向飞回正面。
///
/// 手势与按钮共用一条通道：手势在卡上跟手并判定方向，松手只把结论交给外层；
/// 外层写入 `command` 再回到这里播动效，按钮点击同样只写 `command`。
/// 播完先复位动效状态、再回调 `onFinished` 让数据跟进——界面永远先动、数据后变，
/// 新卡因此不会出现从屏外飞回来的一帧。
struct SortDeck: View {
    let photo: PhotoItem?
    let nextPhoto: PhotoItem?
    let sizeLabel: String
    let nextSizeLabel: String
    let command: DeckCommand?
    @Binding var isPlaying: Bool
    /// 手势松手后的判定结果；返回是否受理（撤回但栈空时返回 false，卡片归位）。
    let onSwipe: (SortMove) -> Bool
    let onFinished: (SortMove) -> Void
    let onTap: (PhotoItem) -> Void

    @State private var frontOffset: CGSize = .zero
    @State private var frontScale: CGFloat = 1
    @State private var backOffset: CGSize = .zero
    @State private var backScale: CGFloat = 0.94
    /// 后卡待命时向下沉的量。必须大于「0.94 缩放导致的底边上收」（竖图约 28pt），
    /// 否则底边会被前卡盖住、露不出来。40pt 下露出约 12pt 的一条边。
    @State private var backLift: CGFloat = 40
    /// 后置卡的渐显：待命时全透明，顶上来时与放大同步显现。
    @State private var backOpacity: CGFloat = 0
    /// 撤回时前置的「飞回来」那张；其余时候为 nil。
    @State private var incoming: PhotoItem?

    /// 判方向：横竖谁大看谁，90pt 过阈值；下滑做收藏只要 40pt。
    private let threshold: CGFloat = 90
    private let favoriteThreshold: CGFloat = 40
    private let leaveDuration: TimeInterval = 0.26

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 下一张压在后方；撤回时后方的位置留给当前卡（它正缩回去）
                if let back = (incoming != nil ? photo : nextPhoto) {
                    SortCard(photo: back,
                             sizeLabel: incoming != nil ? sizeLabel : nextSizeLabel,
                             bounds: geometry.size,
                             isFront: false)
                        .id(back.id)
                        .offset(x: backOffset.width, y: backOffset.height + backLift)
                        .scaleEffect(backScale)
                        .opacity(backOpacity)
                }

                // 前置卡：平时是当前张，撤回时是被撤那张从屏外飞回来
                if let front = incoming ?? photo {
                    SortCard(photo: front,
                             // 飞回来那 0.26s 里体积还没算，标签先留空
                             sizeLabel: incoming != nil ? "" : sizeLabel,
                             bounds: geometry.size,
                             isFront: true,
                             onOpenViewer: { onTap(front) })
                        .id(front.id)
                        .offset(frontOffset)
                        .scaleEffect(frontScale)
                        .rotationEffect(.degrees(frontOffset.width / 26))
                        .gesture(dragGesture)
                }

                if photo == nil && incoming == nil {
                    EmptyDeckView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: command) { _, value in
            guard let value else { return }
            play(value.move, incoming: value.incoming, reverseOf: value.reverseOf)
        }
        .onChange(of: photo?.id) { _, _ in
            // 换照片时把动效状态归位；必须禁掉过渡，否则新卡会从屏外飞回来
            withoutAnimation { reset() }
        }
    }
}

// MARK: - 手势

private extension SortDeck {
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isPlaying else { return }
                frontOffset = value.translation
            }
            .onEnded { value in
                guard !isPlaying else { return }
                let translation = value.translation
                var move: SortMove?

                if abs(translation.width) > abs(translation.height) {
                    if translation.width < -threshold { move = .next }
                    else if translation.width > threshold { move = .undo }
                } else {
                    if translation.height < -threshold { move = .delete }
                    else if translation.height > favoriteThreshold { move = .favorite }
                }

                // 没到阈值、或外层不受理（撤回但没有可撤的步骤）就弹回原位
                guard let move, onSwipe(move) else {
                    springBack()
                    return
                }
                // 受理了：等外层把 command 写回来，再由这里播动效
            }
    }
}

// MARK: - 播放

private extension SortDeck {
    func play(_ move: SortMove, incoming incomingPhoto: PhotoItem?, reverseOf origin: SortMove?) {
        guard !isPlaying else { return }
        isPlaying = true

        if move == .favorite {
            playFavorite()
        } else if move == .undo, origin == SortMove.favorite {
            playFavoriteUndo()
        } else if move == .undo {
            playReverse(origin ?? .next, incoming: incomingPhoto)
        } else {
            playFlyOut(move)
        }
    }

    /// 删除 / 下一张 / 存入相簿：当前卡飞出屏幕，下一张在同一个 Spring 里
    /// 从 0.94 缩小态放大到 1.0、从下沉位归位，并同步渐显。
    func playFlyOut(_ move: SortMove) {
        withAnimation(.easeOut(duration: leaveDuration)) {
            frontOffset = flyTarget(move)
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            backScale = 1
            backLift = 0
            backOpacity = 1
        }
        Task {
            try? await Task.sleep(for: .seconds(leaveDuration))
            finish(move)
        }
    }

    /// 收藏：只有下滑手势会走到这里——不飞出、不推进，弹回原位。
    func playFavorite() {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
            frontOffset = .zero
        }
        Task {
            try? await Task.sleep(for: .seconds(0.30))
            finish(.favorite)
        }
    }

    /// 撤回：当前卡从它被拖到的位置退回后方 0.92，被撤那张从当初飞出去的方向飞回正面。
    func playReverse(_ origin: SortMove, incoming incomingPhoto: PhotoItem?) {
        guard let incomingPhoto else {
            finish(.undo)
            return
        }
        let start = frontOffset
        withoutAnimation {
            incoming = incomingPhoto
            backOffset = start
            // 后置卡此刻就是被拖到 `start` 的那张当前卡，倒放时它要从可见缩回待命
            backLift = 0
            backOpacity = 1
            frontOffset = flyTarget(origin)
            frontScale = 1
            backScale = 1
        }
        withAnimation(.easeOut(duration: leaveDuration)) {
            frontOffset = .zero
            backOffset = .zero
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            backScale = 0.94
            backLift = 40
            backOpacity = 0
        }
        Task {
            try? await Task.sleep(for: .seconds(leaveDuration))
            finish(.undo)
        }
    }

    /// 撤「收藏」：它当初没有飞出，倒放就是让当前卡弹一下。
    func playFavoriteUndo() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) {
            frontScale = 0.94
        }
        Task {
            try? await Task.sleep(for: .seconds(0.14))
            withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
                frontScale = 1
            }
            try? await Task.sleep(for: .seconds(0.26))
            finish(.undo)
        }
    }

    // MARK: - 收尾

    func springBack() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            frontOffset = .zero
        }
    }

    /// 动效复位与数据变更放进同一个无动画事务：中间态不会被单独渲染，
    /// 从而不会出现「旧卡回到中央」或「刚顶上的卡瞬间消失」的一帧。
    func finish(_ move: SortMove) {
        withoutAnimation {
            reset()
            isPlaying = false
            onFinished(move)
        }
    }

    func reset() {
        frontOffset = .zero
        frontScale = 1
        backOffset = .zero
        backScale = 0.94
        backLift = 40
        backOpacity = 0
        incoming = nil
    }

    /// 各动作飞出屏幕的目标位移；撤回靠 `origin` 反着用，收藏不飞出。
    func flyTarget(_ move: SortMove) -> CGSize {
        switch move {
        case .delete: return CGSize(width: 0, height: -1300)
        case .next: return CGSize(width: -900, height: 0)
        case .album: return CGSize(width: 900, height: 0)
        case .undo, .favorite: return .zero
        }
    }
}
