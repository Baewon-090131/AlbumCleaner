import SwiftUI

/// 相簿管理：两列网格 + 空相簿一键清理 + 新建 / 排序 + 长按菜单。
/// 所有写操作直接落系统相册（PHPhotoLibrary），天然「自动同步」。
struct AlbumsScreen: View {
    @Environment(PhotoLibraryService.self) private var library

    @State private var sortOrder: SortOrder = .defaultOrder
    @State private var actionAlbum: AlbumItem?
    @State private var dialog: AlbumDialog?
    @State private var renameText = ""
    @State private var createText = ""
    @State private var toast: String?

    private enum SortOrder: String, CaseIterable {
        case defaultOrder = "默认"
        case count = "数量"
        case name = "名称"
    }

    /// 长按后要走哪种确认 / 输入框。
    private enum AlbumDialog: Identifiable {
        case rename, deleteOnly, deleteWithPhotos, moveTarget, create, deleteEmpty
        var id: Self { self }
    }

    private var sortedAlbums: [AlbumItem] {
        switch sortOrder {
        case .defaultOrder: return library.albums
        case .count: return library.albums.sorted { $0.count > $1.count }
        case .name: return library.albums.sorted { $0.name < $1.name }
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if !library.emptyUserAlbums.isEmpty {
                    emptyBanner
                }

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(sortedAlbums) { album in
                        NavigationLink {
                            SortScreen(album: album)
                        } label: {
                            AlbumCardView(album: album)
                        }
                        .buttonStyle(.plain)
                        .contextMenu { albumMenu(album) }
                    }
                }

                if library.albums.isEmpty {
                    NightEmptyState(title: "还没有相簿",
                                    message: "点右上角「+」新建一个",
                                    flowerSize: 132)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { Theme.wall }
        .navigationTitle("相簿")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            if order == sortOrder {
                                Label(order.rawValue, systemImage: "checkmark")
                            } else {
                                Text(order.rawValue)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("排序")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createText = ""
                    dialog = .create
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新建相簿")
            }
            ToolbarItem(placement: .topBarTrailing) {
                TrayButton()
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastBanner(text: toast)
                    .animation(.snappy(duration: 0.3), value: toast)
            }
        }
        .alert("新建相簿", isPresented: dialogBinding(for: .create)) {
            TextField("相簿名称", text: $createText)
            Button("创建") { runCreate() }
            Button("取消", role: .cancel) {}
        }
        .alert("重命名「\(actionAlbum?.name ?? "")」", isPresented: dialogBinding(for: .rename)) {
            TextField("新名称", text: $renameText)
            Button("保存") { runRename() }
            Button("取消", role: .cancel) {}
        }
        .confirmationDialog("删除「\(actionAlbum?.name ?? "")」？照片会保留在系统相册。",
                            isPresented: dialogBinding(for: .deleteOnly), titleVisibility: .visible) {
            Button("删除相簿", role: .destructive) { runDelete(withPhotos: false) }
            Button("取消", role: .cancel) {}
        }
        .confirmationDialog("删除「\(actionAlbum?.name ?? "")」和里面的 \(actionAlbum?.count ?? 0) 张照片？",
                            isPresented: dialogBinding(for: .deleteWithPhotos), titleVisibility: .visible) {
            Button("全部删除", role: .destructive) { runDelete(withPhotos: true) }
            Button("取消", role: .cancel) {}
        } message: {
            Text("照片会先进入系统「最近删除」，30 天内可恢复。")
        }
        .confirmationDialog("把「\(actionAlbum?.name ?? "")」里的全部照片移到…",
                            isPresented: dialogBinding(for: .moveTarget), titleVisibility: .visible) {
            ForEach(library.albums.filter { $0.isUserAlbum && $0.id != actionAlbum?.id }) { target in
                Button(target.name) { runMove(to: target) }
            }
            Button("取消", role: .cancel) {}
        }
        .confirmationDialog("一键删除 \(library.emptyUserAlbums.count) 个空相簿？",
                            isPresented: dialogBinding(for: .deleteEmpty), titleVisibility: .visible) {
            Button("一键删除", role: .destructive) { runDeleteEmpty() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("只删没有内容的自建相簿，智能相簿不受影响。")
        }
    }

    // MARK: - 子视图

    private var emptyBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title3)
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                MixedType.text("空相簿 \(library.emptyUserAlbums.count) 个", size: 13.5, weight: .medium)
                Text("没有内容，可直接清理")
                    .font(.caption)
                    .foregroundStyle(Theme.text2)
            }
            Spacer()
            Button("一键删除") { dialog = .deleteEmpty }
                .glassButtonStyle(prominent: true)
                .tint(Theme.accent)
        }
        .padding(14)
        .glassSurface(cornerRadius: Theme.cornerTile)
    }

    @ViewBuilder
    private func albumMenu(_ album: AlbumItem) -> some View {
        if album.isUserAlbum {
            Button {
                renameText = album.name
                actionAlbum = album
                dialog = .rename
            } label: {
                Label("重命名", systemImage: "pencil")
            }
            Button {
                actionAlbum = album
                dialog = .moveTarget
            } label: {
                Label("移动全部照片到…", systemImage: "arrow.right.doc.on.clipboard")
            }
            Divider()
            Button(role: .destructive) {
                actionAlbum = album
                dialog = .deleteOnly
            } label: {
                Label("删除相簿", systemImage: "trash")
            }
            Button(role: .destructive) {
                actionAlbum = album
                dialog = .deleteWithPhotos
            } label: {
                Label("删除相簿和照片", systemImage: "trash.fill")
            }
        }
    }

    // MARK: - 动作

    private func dialogBinding(for target: AlbumDialog) -> Binding<Bool> {
        Binding(get: { dialog == target },
                set: { if !$0 { dialog = nil } })
    }

    private func runCreate() {
        Task {
            if await library.createAlbum(named: createText) {
                show("已新建相簿")
            }
        }
    }

    private func runRename() {
        guard let album = actionAlbum else { return }
        Task {
            if await library.renameAlbum(album, to: renameText) {
                show("已重命名")
            }
        }
    }

    private func runDelete(withPhotos: Bool) {
        guard let album = actionAlbum else { return }
        Task {
            let ok = withPhotos
                ? await library.deleteAlbumWithPhotos(album)
                : await library.deleteAlbums([album])
            if ok { show(withPhotos ? "已删除相簿和照片" : "已删除相簿") }
        }
    }

    private func runMove(to target: AlbumItem) {
        guard let album = actionAlbum else { return }
        Task {
            if await library.moveAllPhotos(from: album, to: target) {
                show("已移到「\(target.name)」")
            }
        }
    }

    private func runDeleteEmpty() {
        Task {
            if await library.deleteAlbums(library.emptyUserAlbums) {
                show("已清理空相簿")
            }
        }
    }

    private func show(_ message: String) {
        withAnimation(.snappy(duration: 0.3)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            guard toast == message else { return }
            withAnimation(.smooth(duration: 0.2)) { toast = nil }
        }
    }
}

/// 单个相簿：正方形封面 + 名称/数量居中在封面下方，无卡片底（对齐 iOS 原生相册）。
struct AlbumCardView: View {
    let album: AlbumItem

    var body: some View {
        VStack(spacing: 6) {
            Rectangle()
                .fill(.quaternary)
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    if let cover = album.coverAsset {
                        AsyncThumbnail(asset: cover, targetSize: CGSize(width: 320, height: 320))
                    } else {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(Theme.text2)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(album.name)
                .font(.pingFang(15, weight: .medium))
                .lineLimit(1)

            Text("\(album.count)")
                .font(.typewriter(11))
                .foregroundStyle(Theme.text3)
        }
    }
}
