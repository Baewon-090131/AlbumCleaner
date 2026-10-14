import SwiftUI

/// 回收站：网格 + 原生菜单操作。彻底删除才动系统相册。
struct TrashScreen: View {
    @Environment(PhotoLibraryService.self) private var library

    @State private var selected: PhotoItem?
    @State private var showDeleteAll = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 3)

    var body: some View {
        ScrollView {
            if library.trash.isEmpty {
                ContentUnavailableView("回收站为空", systemImage: "archivebox",
                                       description: Text("上滑删除的照片会先落到这里"))
                    .padding(.top, 60)
            } else {
                Text("共 \(library.trash.count) 张，彻底删除后无法恢复")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(library.trash) { item in
                        Button {
                            selected = item
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
        .navigationTitle("回收站")
        .toolbar {
            if !library.trash.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("清空", role: .destructive) { showDeleteAll = true }
                }
            }
        }
        .confirmationDialog(itemTitle, isPresented: selectionBinding, titleVisibility: .visible) {
            if let item = selected {
                Button("放回相册") {
                    library.restore(item)
                    selected = nil
                }
                Button("彻底删除", role: .destructive) {
                    Task {
                        await library.deleteFromSystem([item])
                        selected = nil
                    }
                }
            }
            Button("取消", role: .cancel) { selected = nil }
        }
        .confirmationDialog("清空回收站？", isPresented: $showDeleteAll, titleVisibility: .visible) {
            Button("彻底删除全部", role: .destructive) {
                Task { await library.deleteFromSystem(library.trash) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将同时从系统相册删除，无法恢复。")
        }
    }

    private var itemTitle: String {
        guard let selected else { return "" }
        return "这项目该怎么处理？"
    }

    private var selectionBinding: Binding<Bool> {
        Binding(get: { selected != nil },
                set: { if !$0 { selected = nil } })
    }
}

/// 全屏查看。点任意处关闭。
struct PhotoViewerScreen: View {
    let photo: PhotoItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncThumbnail(asset: photo.asset,
                           targetSize: CGSize(width: 1800, height: 1800),
                           contentMode: .fit)
                .padding(8)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .padding(16)
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
    }
}
