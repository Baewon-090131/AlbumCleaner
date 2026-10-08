import SwiftUI

/// 相簿页：两列网格，点进去是复用 SortScreen 的相簿整理页。
struct AlbumsScreen: View {
    @Environment(PhotoLibraryService.self) private var library
    @State private var showTrash = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
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

struct AlbumCardView: View {
    let album: AlbumItem

    var body: some View {
        ContentPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(album.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text("\(album.count)")
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.quaternary)
                    if let cover = album.coverAsset {
                        AsyncThumbnail(asset: cover, targetSize: CGSize(width: 260, height: 200))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 92)
            }
            .padding(12)
        }
    }
}
