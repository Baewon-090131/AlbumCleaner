import SwiftUI

/// 整理页。`album` 为 nil 时是「整理」tab（按月整理），否则是某个相簿的整理页。
/// 卡片区是一次一张的大照片：左滑下一张、右滑撤回、上滑删除、下拉拖到相簿。
/// 卡片上不放任何按钮；撤回的入口在顶栏，也可以右滑。
struct SortScreen: View {
    var album: AlbumItem? = nil

    @Environment(PhotoLibraryService.self) private var library
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMonthID: String?
    @State private var index = 0
    /// 撤回栈：记住「上一步做了什么」，撤回就是完整倒做那一步（限深 50，切月清空）。
    @State private var undoStack: [UndoRecord] = []
    @State private var albumPhotos: [PhotoItem] = []
    @State private var toast: String?
    @State private var columnCount = 1
    /// 月份滚轮面板是否展开。
    @State private var showMonthWheel = false
    /// 相簿按钮选完的目标，等动效播完才真正写入。
    @State private var pendingAlbum: AlbumItem?
    /// 交给卡片区播放的操作；`commandToken` 保证同一种动作也能被认出来。
    @State private var command: DeckCommand?
    @State private var commandToken = 0
    /// 本次整理（当前月份 / 当前相簿）的删除结算：翻过最后一张时收尾用。
    @State private var sessionDeleted = 0
    @State private var sessionFreedBytes: Int64 = 0
    /// 卡片区正在播动效：这期间不接新操作，避免动效播到一半被覆盖。
    @State private var isPlaying = false

    private let undoDepth = 50

    private var isAlbumMode: Bool { album != nil }

    private var month: MonthSection? {
        if let selectedMonthID, let match = library.months.first(where: { $0.id == selectedMonthID }) {
            return match
        }
        return library.months.first
    }

    private var photos: [PhotoItem] {
        isAlbumMode ? albumPhotos : (month?.photos ?? [])
    }

    /// 翻过最后一张时的收尾文案。
    private var endTitle: String {
        isAlbumMode ? "相簿整理完毕" : "本月整理完毕"
    }

    /// 撤回会倒做哪一步（撤销栈是通用的，光一个箭头看不出会撤什么）。
    private var undoHint: String? {
        guard let last = undoStack.last else { return nil }
        switch last {
        case .deletion: return "可撤回：删除"
        case .advance: return "可撤回：翻页"
        case .favorite: return "可撤回：收藏"
        case .albumAdd: return "可撤回：存入相簿"
        }
    }

    private var current: PhotoItem? {
        index < photos.count ? photos[index] : nil
    }

    @ViewBuilder
    private var content: some View {
        if columnCount == 1 {
            SwipeDeck(
                photos: photos,
                index: $index,
                command: command,
                isPlaying: $isPlaying,
                albums: library.albums,
                albumPick: pendingAlbum,
                endTitle: endTitle,
                endDeleted: sessionDeleted,
                endFreed: Format.bytes(sessionFreedBytes),
                sizeLabel: { Format.bytes(library.fileSize(of: $0)) },
                onSwipe: { request($0) },
                onFinished: finish,
                onTap: { photo, frame in ui.detailFrame = frame; ui.detailPhoto = photo },
                onAddToAlbum: { target in pickAlbum(target) },
                onReachEnd: { ui.celebrate() },
                onSandBurst: { ui.playSand($0) },
                detailActive: ui.detailPhoto != nil
            )
        } else {
            ColumnsGrid(
                photos: photos,
                columns: columnCount,
                onMarkDelete: markDeleteInColumns
            )
            .padding(.top, 8)
        }
    }

    var body: some View {
        // 用 ZStack 而不是 VStack：月份滚轮要能浮在内容之上。
        ZStack(alignment: .top) {
            SortHeader(months: library.months,
                       selectedMonthID: month?.id,
                       showsMonth: !isAlbumMode,
                       albumTitle: isAlbumMode ? (album?.name ?? "相簿") : nil,
                       processed: index,
                       total: photos.count,
                       canUndo: columnCount == 1 && !undoStack.isEmpty,
                       undoHint: columnCount == 1 ? undoHint : nil,
                       tint: Theme.accent,
                       showMonthWheel: $showMonthWheel,
                       onUndo: { _ = request(.undo) },
                       onBack: isAlbumMode ? { dismiss() } : nil)

            // 用 safeAreaInset 而不是 padding：padding 只是把内容整体下推，
            // 底部会溢出整整一个顶栏的高度（相簿轨道因此压到了底栏上）。
            // safeAreaInset 会让内容**少掉**这一段的可用高度。
            content
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear.frame(height: SortHeader.height)
                }
                .zIndex(1)

            if showMonthWheel {
                // 点空白收起；放在这一层是为了不挡住右上角的滚轮面板
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { collapseMonthWheel() }
                    .zIndex(2)

                MonthWheelPanel(months: library.months,
                                currentID: month?.id,
                                onSelect: selectMonth)
                    .padding(.top, 90)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .topTrailing)))
                    .zIndex(3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .background { Theme.wall }
        .gesture(
            // 双指收拢进分列（最多 3 列），张开退回单卡；相簿详情不分列
            MagnifyGesture()
                .onEnded { value in handlePinch(value.magnification) }
        )
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: ui.pendingTrash?.id) { _, _ in
            guard let target = ui.pendingTrash else { return }
            ui.pendingTrash = nil
            guard target.id == current?.id else { return }
            _ = request(.delete)
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastBanner(text: toast)
                    .padding(.top, SortHeader.height)
                    .animation(.snappy(duration: 0.3), value: toast)
            }
        }
        .task(id: album?.id) {
            // 相簿照片只拉一次；放在计算属性里会让每次重绘都遍历整个相簿
            guard let album else {
                albumPhotos = []
                return
            }
            albumPhotos = library.photos(in: album)
        }
        .onChange(of: photos.count) { _, new in
            // 删掉最后一张时游标会停在数组末尾之外，回退一格
            guard new > 0, index >= new else { return }
            index = new - 1
        }
    }
}

// MARK: - 动作

private extension SortScreen {
    func selectMonth(_ candidate: MonthSection) {
        guard candidate.id != month?.id else { return }
        selectedMonthID = candidate.id
        resetCursor()
    }

    func collapseMonthWheel() {
        withAnimation(.snappy(duration: 0.26)) { showMonthWheel = false }
    }

    func resetCursor() {
        index = 0
        undoStack.removeAll()
        command = nil
        pendingAlbum = nil
        sessionDeleted = 0
        sessionFreedBytes = 0
    }

    /// 手势是唯一入口：只写 command，动效和数据变更都等卡片区播完再收尾。
    /// 返回是否受理——撤回但没有可撤的步骤时不受理，卡片原地弹回。
    @discardableResult
    func request(_ move: SortMove) -> Bool {
        guard !isPlaying else { return false }

        var incoming: PhotoItem?
        var reverseOf: SortMove?
        if move == .undo {
            guard let last = undoStack.last else { return false }
            incoming = last.restorePhoto
            reverseOf = last.origin
        }

        commandToken += 1
        command = DeckCommand(token: commandToken,
                              move: move,
                              incoming: incoming,
                              reverseOf: reverseOf)
        return true
    }

    /// 卡片区播完动效后回调；复位与数据变更已在同一个无动画事务里（见 `SwipeDeck.finishNow`）。
    func finish(_ move: SortMove) {
        command = nil
        apply(move)
    }

    func apply(_ move: SortMove) {
        switch move {
        case .delete:
            guard let photo = current else { return }
            sessionDeleted += 1
            sessionFreedBytes += library.fileSize(of: photo)
            library.moveToTrash(photo)
            push(.deletion(photo: photo, index: index))
            show("已移到待删除")

        case .next:
            guard let photo = current else { return }
            push(.advance(photo: photo, index: index))
            index += 1

        case .favorite:
            guard let photo = current else { return }
            library.setFavorite(photo, true)
            push(.favorite(photo: photo))
            show("已收藏")

        case .album:
            guard let photo = current, let target = pendingAlbum else { return }
            pendingAlbum = nil
            library.add(photo, to: target)
            push(.albumAdd(photo: photo, album: target, index: index))
            index += 1
            show("已存入「\(target.name)」")

        case .undo:
            undo()
        }
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        switch last {
        case .deletion(let photo, let position):
            library.restore(photo)
            sessionDeleted = max(0, sessionDeleted - 1)
            sessionFreedBytes = max(0, sessionFreedBytes - library.fileSize(of: photo))
            index = max(0, position)
            show("已撤回删除")

        case .advance(_, let position):
            index = max(0, position)
            show("已回到上一张")

        case .favorite(let photo):
            library.setFavorite(photo, false)
            show("已取消收藏")

        case .albumAdd(let photo, let target, let position):
            library.remove(photo, from: target)
            index = max(0, position)
            show("已取消存入")
        }
    }

    func push(_ record: UndoRecord) {
        undoStack.append(record)
        if undoStack.count > undoDepth { undoStack.removeFirst() }
    }

    /// 下拉托盘松手 / 顶栏相簿按钮都会走到这里：先记下目标，再交给卡片区播动效。
    func addCurrentPhoto(to target: AlbumItem) {
        guard !isPlaying else { return }
        pendingAlbum = target
        _ = request(.album)
    }

    /// 托盘里点中一格：卡片当场播放落下动效，播完才真正写相册。
    func pickAlbum(_ target: AlbumItem) {
        addCurrentPhoto(to: target)
    }

    /// 双指收拢进分列、张开退回单卡。相簿详情不支持分列（它的删除不走月份游标）。
    func handlePinch(_ magnification: CGFloat) {
        guard !isAlbumMode else { return }
        withAnimation(.snappy(duration: 0.35)) {
            if magnification < 0.82, columnCount < 3 {
                columnCount += 1
            } else if magnification > 1.22, columnCount > 1 {
                columnCount -= 1
            }
        }
    }

    /// 分列模式里的滑删：飞出动画播完才走到这里，与卡片区「先动效后数据」一致。
    func markDeleteInColumns(_ photo: PhotoItem) {
        sessionDeleted += 1
        sessionFreedBytes += library.fileSize(of: photo)
        library.moveToTrash(photo)
        push(.deletion(photo: photo, index: index))
        show("已标记，进待删除")
    }

    func show(_ message: String) {
        withAnimation(.snappy(duration: 0.3)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            guard toast == message else { return }
            withAnimation(.smooth(duration: 0.2)) { toast = nil }
        }
    }
}
