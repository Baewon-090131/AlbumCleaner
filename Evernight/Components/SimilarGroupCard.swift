import SwiftUI

/// 相似页的一组：横向滑动的缩略图行（最优绿框 ★，其余红框默认勾选）+ 组底删除条。
struct GroupCard: View {
    let group: SimilarGroup
    let unchecked: Set<String>
    let bytes: (PhotoItem) -> Int64
    let isChecked: (PhotoItem) -> Bool
    let onToggle: (PhotoItem) -> Void
    let onDelete: () -> Void

    private var checkedPhotos: [PhotoItem] {
        group.others.filter { !unchecked.contains($0.id) }
    }

    private var reclaimBytes: Int64 {
        checkedPhotos.reduce(into: Int64(0)) { $0 += bytes($1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(group.photos.count) 张相似")
                    .font(.headline)
                Spacer()
                Text("可释放 \(Format.bytes(reclaimBytes))")
                    .font(.footnote)
                    .foregroundStyle(Theme.accent)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(group.photos) { photo in
                        thumb(photo)
                    }
                }
            }

            Button(action: onDelete) {
                Text("删除选中 \(checkedPhotos.count) 张 · 释放 \(Format.bytes(reclaimBytes))（进待删除）")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(checkedPhotos.isEmpty ? Color.gray : Theme.accent,
                                in: RoundedRectangle(cornerRadius: 21, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(checkedPhotos.isEmpty)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous))
    }

    private func thumb(_ photo: PhotoItem) -> some View {
        let isBest = photo.id == group.bestID
        let checked = isChecked(photo)
        return Button {
            onToggle(photo)
        } label: {
            Rectangle()
                .fill(.quaternary)
                .frame(width: 84, height: 84)
                .overlay {
                    AsyncThumbnail(asset: photo.asset, targetSize: CGSize(width: 220, height: 220))
                }
                .overlay(alignment: .topLeading) {
                    if isBest {
                        Label("最优", systemImage: "star.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Theme.success, in: Capsule())
                            .padding(4)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if !isBest {
                        Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(checked ? Theme.danger : .white)
                            .shadow(color: Theme.ink.opacity(0.22), radius: 2)
                            .padding(4)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isBest ? Theme.success : (checked ? Theme.danger : .clear),
                                      lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isBest ? "最优，保留" : (checked ? "已勾选删除" : "未勾选"))
    }
}
