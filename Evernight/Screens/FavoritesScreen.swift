import SwiftUI

/// 已喜欢：系统相册里所有收藏项的只读网格。从「我的 → 已喜欢」进来。
struct FavoritesScreen: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.dismiss) private var dismiss

    @State private var photos: [PhotoItem] = []
    @State private var viewerPhoto: PhotoItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 3)

    var body: some View {
        ScrollView {
            if photos.isEmpty {
                NightEmptyState(title: "还没有收藏",
                                message: "整理页下滑收藏的照片会出现在这里")
                    .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(photos) { item in
                        Button {
                            viewerPhoto = item
                        } label: {
                            Rectangle()
                                .fill(.quaternary)
                                .aspectRatio(1, contentMode: .fill)
                                .overlay {
                                    AsyncThumbnail(asset: item.asset,
                                                   targetSize: CGSize(width: 300, height: 300))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("已喜欢")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("完成") { dismiss() }
            }
        }
        .fullScreenCover(item: $viewerPhoto) { PhotoViewerScreen(photo: $0) }
        .task { photos = library.favoritePhotos() }
    }
}
