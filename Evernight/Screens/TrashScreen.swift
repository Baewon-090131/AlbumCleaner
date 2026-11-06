import SwiftUI

/// 待删除（作为 sheet 呈现）：分列滑删 / 单卡上滑删除都汇入这里。
/// 抓握条由系统 sheet 提供；顶部是系统导航栏（完成 / 全选），底部是一条「滑动删除」。
struct TrashScreen: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(\.dismiss) private var dismiss

    /// 默认全部勾选，这里只记被取消勾选的。
    @State private var unchecked: Set<String> = []
    @State private var isDeleting = false
    /// 删除完成的结果：滑轨据此收缩并显示「已删除 N 项 · 释放 …」。
    @State private var result: DeleteResult?
    /// 彩纸开始时刻；非 nil 时从滑轨中间向上喷。
    @State private var confettiStart: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 3)

    private var checkedItems: [PhotoItem] {
        library.trash.filter { !unchecked.contains($0.id) }
    }

    private var checkedBytes: Int64 {
        checkedItems.reduce(into: Int64(0)) { $0 += library.fileSize(of: $1) }
    }

    var body: some View {
        ScrollView {
            if library.trash.isEmpty {
                ContentUnavailableView("待删除为空", systemImage: "trash",
                                       description: Text("滑动删除的照片会先落到这里"))
                    .padding(.top, 60)
            } else {
                MixedType.text("本轮 \(library.trash.count) 项 · 预计释放 \(Format.bytes(library.trashByteCount))", size: 11)
                    .foregroundStyle(Theme.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(library.trash) { item in
                        cell(item)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 120)
            }
        }
        .background { Theme.wall }
        .navigationTitle("待删除")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("完成") { dismiss() }
            }
            if !library.trash.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(unchecked.isEmpty ? "取消全选" : "全选") {
                        unchecked = unchecked.isEmpty ? Set(library.trash.map(\.id)) : []
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) { deleteBar }
        // 彩纸铺满整屏：滑轨那点高度会让纸片还没落下就被裁掉
        .overlay {
            if let confettiStart {
                ConfettiBurst(start: confettiStart, originFromBottom: 96)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    private func cell(_ item: PhotoItem) -> some View {
        let checked = !unchecked.contains(item.id)
        return Button {
            if checked { unchecked.insert(item.id) } else { unchecked.remove(item.id) }
        } label: {
            Rectangle()
                .fill(.quaternary)
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    AsyncThumbnail(asset: item.asset,
                                   targetSize: CGSize(width: 300, height: 300))
                        .opacity(checked ? 1 : 0.45)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(checked ? Color.accentColor : .white)
                        .shadow(color: Color.black.opacity(0.55), radius: 2)
                        .padding(5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var deleteBar: some View {
        if !library.trash.isEmpty || result != nil {
            VStack(spacing: 6) {
                // 删除期间不显示转圈：滑轨保持满轨，等结果回来才收缩
                SwipeDeleteButton(count: checkedItems.count,
                                  bytes: checkedBytes,
                                  enabled: !checkedItems.isEmpty,
                                  isDeleting: isDeleting,
                                  result: result,
                                  onConfirm: confirmDeletion)

                Text("未勾选项将放回相册 · 删除项进入系统「最近删除」，30 天内可恢复")
                    .font(.caption2)
                    .foregroundStyle(Theme.text2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(.bar)
        }
    }

    private func confirmDeletion() {
        let targets = checkedItems
        guard !targets.isEmpty else { return }
        let totalCount = targets.count
        let totalBytes = checkedBytes
        isDeleting = true
        Task {
            let ok = await library.deleteFromSystem(targets)
            isDeleting = false
            guard ok else { return }
            // 参照参考稿语义：未勾选的项移出待清理、放回相册
            let restored = library.trash.filter { unchecked.contains($0.id) }
            for item in restored { library.restore(item) }
            unchecked.removeAll()

            withAnimation(.snappy(duration: 0.4)) {
                result = DeleteResult(count: totalCount, bytes: totalBytes)
            }
            confettiStart = .now

            // 彩纸播完再收场；待删除已空时直接退出
            try? await Task.sleep(for: .seconds(3.4))
            confettiStart = nil
            result = nil
            if library.trash.isEmpty { dismiss() }
        }
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
