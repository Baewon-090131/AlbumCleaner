import SwiftUI

/// 整理页。`album` 为 nil 时是「整理」tab（按月整理），否则是某个相簿的整理页。
struct SortScreen: View {
    var album: AlbumItem? = nil

    @Environment(PhotoLibraryService.self) private var library
    @AppStorage("ac_theme") private var themeHex = "#002FA7"
    /// 操作岛的玻璃形态在「四按钮 ↔ 三按钮」之间变形时共用这个命名空间
    @Namespace private var actionNamespace

    @State private var selectedMonthID: String?
    @State private var index = 0
    /// 撤回栈：记住「上一步做了什么」，撤回就是完整倒做那一步（限深 50，切月清空）。
    @State private var undoStack: [UndoRecord] = []
    @State private var albumPhotos: [PhotoItem] = []
    @State private var toast: String?
    @State private var showTrash = false
    @State private var showAlbumPicker = false
    @State private var viewerPhoto: PhotoItem?
    /// 相簿按钮选完的目标，等动效播完才真正写入。
    @State private var pendingAlbum: AlbumItem?
    /// 交给卡片区播放的操作；`commandToken` 保证同一种动作也能被认出来。
    @State private var command: DeckCommand?
    @State private var commandToken = 0
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

    private var current: PhotoItem? {
        index < photos.count ? photos[index] : nil
    }

    /// 后方待命的那张：当前卡飞出后由它顶上。
    private var upcoming: PhotoItem? {
        let next = index + 1
        return next < photos.count ? photos[next] : nil
    }

    private var actions: [SortAction] {
        isAlbumMode ? [.undo, .delete, .next] : SortAction.allCases
    }

    var body: some View {
        VStack(spacing: 10) {
            ProgressHeader(
                processed: index,
                total: photos.count,
                remaining: max(0, photos.count - index),
                tint: Color(hex: themeHex)
            )

            SortDeck(
                photo: current,
                nextPhoto: upcoming,
                sizeLabel: current.map { Format.bytes(library.fileSize(of: $0)) } ?? "",
                nextSizeLabel: upcoming.map { Format.bytes(library.fileSize(of: $0)) } ?? "",
                command: command,
                isPlaying: $isPlaying,
                onSwipe: { request($0) },
                onFinished: finish,
                onTap: { viewerPhoto = $0 }
            )

            SortActionBar(
                actions: actions,
                canUndo: !undoStack.isEmpty,
                hasPhoto: current != nil,
                namespace: actionNamespace,
                onAction: handleAction
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .navigationTitle(isAlbumMode ? (album?.name ?? "相簿") : "Evernight")
        .navigationBarTitleDisplayMode(isAlbumMode ? .inline : .large)
        .toolbar { toolbarContent }
        .navigationDestination(isPresented: $showTrash) { TrashScreen() }
        .fullScreenCover(item: $viewerPhoto) { PhotoViewerScreen(photo: $0) }
        .confirmationDialog("存入相簿", isPresented: $showAlbumPicker, titleVisibility: .visible) {
            ForEach(library.albums) { target in
                Button(target.name) { addCurrentPhoto(to: target) }
            }
            Button("取消", role: .cancel) {}
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastBanner(text: toast)
                    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: toast)
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
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !isAlbumMode {
            ToolbarItem(placement: .topBarLeading) {
                MonthMenu(months: library.months,
                          selectedID: month?.id,
                          onSelect: selectMonth)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showTrash = true
            } label: {
                Image(systemName: "archivebox")
                    .overlay(alignment: .topTrailing) {
                        if !library.trash.isEmpty {
                            Text("\(min(library.trash.count, 99))")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.danger, in: Capsule())
                                .offset(x: 10, y: -8)
                        }
                    }
            }
            .accessibilityLabel("回收站")
        }
    }
}

// MARK: - 动作

private extension SortScreen {
    func selectMonth(_ candidate: MonthSection) {
        selectedMonthID = candidate.id
        index = 0
        undoStack.removeAll()
        command = nil
        pendingAlbum = nil
    }

    func handleAction(_ action: SortAction) {
        switch action {
        case .undo: request(.undo)
        case .delete: request(.delete)
        case .next: request(.next)
        case .album: showAlbumPicker = true
        }
    }

    /// 手势与按钮都走这里：只写 command，动效和数据变更都等卡片区播完再收尾。
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

    /// 卡片区播完动效后回调：这时才真正改数据，界面早就先动完了。
    func finish(_ move: SortMove) {
        command = nil
        withoutAnimation { apply(move) }
    }

    func apply(_ move: SortMove) {
        switch move {
        case .delete:
            guard let photo = current else { return }
            library.moveToTrash(photo)
            push(.deletion(photo: photo, index: index))
            show("已移到回收站")

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

    func addCurrentPhoto(to target: AlbumItem) {
        pendingAlbum = target
        request(.album)
    }

    func show(_ message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            guard toast == message else { return }
            withAnimation(.easeOut(duration: 0.2)) { toast = nil }
        }
    }
}
