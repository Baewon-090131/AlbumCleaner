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
                MixedType.text("\(group.photos.count) 张相似", size: 15, weight: .medium)
                Spacer()
                Text("可释放 \(Format.bytes(reclaimBytes))")
                    .font(.pingFang(11))
                    .foregroundStyle(Theme.accentText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(group.photos) { photo in
                        thumb(photo)
                    }
                }
            }

            Button(action: onDelete) {
                MixedType.text("删除选中 \(checkedPhotos.count) 张 · 释放 \(Format.bytes(reclaimBytes))（进待删除）", size: 12.5, weight: .medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
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
        .background(Theme.nightPanel, in: RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous)
                .strokeBorder(Theme.nightLine, lineWidth: 0.5)
        }
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
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Theme.paper, in: Capsule())
                            .padding(4)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if !isBest {
                        Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(checked ? Theme.danger : .white)
                            .shadow(color: Color.black.opacity(0.5), radius: 2)
                            .padding(4)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isBest ? Theme.text2 : (checked ? Theme.danger : .clear),
                                      lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isBest ? "最优，保留" : (checked ? "已勾选删除" : "未勾选"))
    }
}
