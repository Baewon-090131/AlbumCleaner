import SwiftUI

/// 相簿页：两列网格，点进去是复用 SortScreen 的相簿整理页。
struct AlbumsScreen: View {
    @Environment(PhotoLibraryService.self) private var library
    @State private var showTrash = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(library.albums) { album in
                    NavigationLink {
                        SortScreen(album: album)
                    } label: {
                        AlbumCardView(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)

            if library.albums.isEmpty {
                ContentUnavailableView("还没有相簿", systemImage: "photo.on.rectangle",
                                       description: Text("在系统相册里新建相簿后会出现在这里"))
                    .padding(.top, 40)
            }
        }
        .navigationTitle("相簿")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showTrash = true
                } label: {
                    Image(systemName: "archivebox")
                }
                .accessibilityLabel("回收站")
            }
        }
        .navigationDestination(isPresented: $showTrash) { TrashScreen() }
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
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(album.name)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)

            Text("\(album.count)")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
