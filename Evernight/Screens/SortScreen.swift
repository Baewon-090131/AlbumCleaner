import SwiftUI

enum SwipeIntent {
    case delete, next, undo, favorite
}

enum SortAction: String, CaseIterable, Identifiable {
    case undo, delete, next, album

    var id: String { rawValue }

    var title: String {
        switch self {
        case .undo: "撤回"
        case .delete: "删除"
        case .next: "下一张"
        case .album: "相簿"
        }
    }

    var symbol: String {
        switch self {
        case .undo: "arrow.uturn.backward"
        case .delete: "trash"
        case .next: "forward.end"
        case .album: "photo.stack"
        }
    }

    var color: Color {
        switch self {
        case .undo: Theme.warning
        case .delete: Theme.danger
        case .next: Theme.info
        case .album: Theme.accent
        }
    }
}

/// 整理页。`album` 为 nil 时是「整理」tab（按月整理），否则是某个相簿的整理页。
struct SortScreen: View {
    var album: AlbumItem? = nil

    @Environment(PhotoLibraryService.self) private var library
    @AppStorage("ac_theme") private var themeHex = "#002FA7"
    /// 操作岛的玻璃形态在「四按钮 ↔ 三按钮」之间变形时共用这个命名空间
    @Namespace private var actionNamespace

    @State private var selectedMonthID: String?
    @State private var index = 0
    /// 撤回栈只记「删除」：把照片还回相册，再把游标退回去。
    @State private var undoStack: [(photo: PhotoItem, index: Int)] = []
    @State private var albumPhotos: [PhotoItem] = []
    @State private var toast: String?
    @State private var showTrash = false
    @State private var showAlbumPicker = false
    @State private var viewerPhoto: PhotoItem?

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
                sizeLabel: current.map { Format.bytes(library.fileSize(of: $0)) } ?? "",
                onSwipe: handleSwipe,
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
    }

    func handleSwipe(_ intent: SwipeIntent) {
        perform(intent)
    }

    func handleAction(_ action: SortAction) {
        switch action {
        case .undo: perform(.undo)
        case .delete: perform(.delete)
        case .next: perform(.next)
        case .album: showAlbumPicker = true
        }
    }

    func perform(_ intent: SwipeIntent) {
        switch intent {
        case .delete:
            guard let photo = current else { return }
            library.moveToTrash(photo)
            undoStack.append((photo, index))
            show("已移到回收站")

        case .next:
            guard current != nil else { return }
            index += 1

        case .undo:
            guard let last = undoStack.popLast() else { return }
            library.restore(last.photo)
            index = max(0, last.index)
            show("已撤回删除")

        case .favorite:
            guard let photo = current else { return }
            library.setFavorite(photo, true)
            index += 1
            show("已加入个人收藏")
        }
    }

    func addCurrentPhoto(to target: AlbumItem) {
        guard let photo = current else { return }
        library.add(photo, to: target)
        index += 1
        show("已存入「\(target.name)」")
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

// MARK: - 月份菜单

private struct MonthMenu: View {
    let months: [MonthSection]
    let selectedID: String?
    let onSelect: (MonthSection) -> Void

    var body: some View {
        Menu {
            ForEach(months) { candidate in
                Button {
                    onSelect(candidate)
                } label: {
                    if candidate.id == selectedID {
                        Label(candidate.title, systemImage: "checkmark")
                    } else {
                        Text(candidate.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(months.first { $0.id == selectedID }?.title ?? "选择月份")
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
        }
        .accessibilityLabel("选择月份")
    }
}
