import SwiftUI

/// 整理页。`album` 为 nil 时是「整理」tab（按月整理），否则是某个相簿的整理页。
/// 卡片是一排挂在绳上的拍立得相纸：左右拖绳子浏览，上滑摘下删除，下滑收藏。
/// 卡片上不放任何按钮；撤回的入口在顶栏（左右拖动只改浏览位置，不再承担「下一张 / 撤回」）。
struct SortScreen: View {
    var album: AlbumItem? = nil

    @Environment(PhotoLibraryService.self) private var library
    @AppStorage("ac_theme_v2") private var themeHex = "#2B4A6F"

    @State private var selectedMonthID: String?
    @State private var index = 0
    /// 撤回栈：记住「上一步做了什么」，撤回就是完整倒做那一步（限深 50，切月清空）。
    @State private var undoStack: [UndoRecord] = []
    @State private var albumPhotos: [PhotoItem] = []
    @State private var toast: String?
    @State private var showAlbumPicker = false
    @State private var viewerPhoto: PhotoItem?
    /// 分列模式：1 = 单卡，2 / 3 = 瀑布流分列（双指收拢切换）。相簿详情不支持分列。
    @State private var columnCount = 1
    /// 媒体类型筛选：照片 / 视频 / 实况 / 全部。相簿详情不显示。
    @State private var mediaFilter: MediaFilter = .all
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

    /// `.all` 走快路径（零拷贝）；只有筛选态才多一次 O(n) 扫描。
    private var photos: [PhotoItem] {
        let base = isAlbumMode ? albumPhotos : (month?.photos ?? [])
        guard mediaFilter != .all else { return base }
        return base.filter { mediaFilter.matches($0) }
    }

    private var current: PhotoItem? {
        index < photos.count ? photos[index] : nil
    }

    /// 整理主题：`rope` = 挂绳相纸，`glass` = 单张大相纸。
    @AppStorage("ac_sort_theme") private var sortTheme = "rope"

    var body: some View {
        // 用 ZStack 而不是 VStack：卡片区要能画到进度条上面去，
        // 否则绳子被往上调时会先被进度条盖住、再被裁掉。
        ZStack(alignment: .top) {
            ProgressHeader(
                processed: index,
                total: photos.count,
                remaining: max(0, photos.count - index),
                tint: Color(hex: themeHex)
            )

            if columnCount == 1 {
                if sortTheme == "glass" {
                    GlassDeck(
                        photos: photos,
                        index: $index,
                        sizeLabel: { Format.bytes(library.fileSize(of: $0)) },
                        onSwipe: { request($0) },
                        onFinished: finish,
                        onTap: { viewerPhoto = $0 },
                        onAddToAlbum: { showAlbumPicker = true }
                    )
                    .zIndex(1)
                } else {
                    PolaroidDeck(
                        photos: photos,
                        index: $index,
                        command: command,
                        isPlaying: $isPlaying,
                        sizeLabel: { Format.bytes(library.fileSize(of: $0)) },
                        onSwipe: { request($0) },
                        onFinished: finish,
                        onTap: { viewerPhoto = $0 },
                        onAddToAlbum: { showAlbumPicker = true }
                    )
                    .zIndex(1)
                }
            } else {
                ColumnsGrid(
                    photos: photos,
                    columns: columnCount,
                    onMarkDelete: markDeleteInColumns
                )
                .padding(.top, 28)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .gesture(
            // 双指收拢进分列（最多 3 列），张开退回单卡；相簿详情不分列
            MagnifyGesture()
                .onEnded { value in handlePinch(value.magnification) }
        )
        // 顶栏交给系统 toolbar（Liquid Glass 由系统绘制）；标题留空，相簿详情用相簿名
        .navigationTitle(isAlbumMode ? (album?.name ?? "相簿") : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            SortToolbar(months: library.months,
                        selectedMonthID: month?.id,
                        filter: mediaFilter,
                        showsMonth: !isAlbumMode,
                        canUndo: columnCount == 1 && !undoStack.isEmpty,
                        onSelectMonth: selectMonth,
                        onSelectFilter: selectFilter,
                        onUndo: { _ = request(.undo) })
        }
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
        selectedMonthID = candidate.id
        resetCursor()
    }

    /// 切筛选与切月同语义：游标回 0、清空撤销栈，避免跨筛选撤销导致游标指错。
    func selectFilter(_ next: MediaFilter) {
        guard next != mediaFilter else { return }
        mediaFilter = next
        resetCursor()
    }

    func resetCursor() {
        index = 0
        undoStack.removeAll()
        command = nil
        pendingAlbum = nil
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

    /// 卡片区播完动效后回调；复位与数据变更已在同一个无动画事务里（见 `PolaroidDeck.finish`）。
    func finish(_ move: SortMove) {
        command = nil
        apply(move)
    }

    func apply(_ move: SortMove) {
        switch move {
        case .delete:
            guard let photo = current else { return }
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
