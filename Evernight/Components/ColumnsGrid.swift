import SwiftUI

/// 分列浏览（整理页双指收拢进入）：等宽不等高的瀑布流，2 或 3 列。
/// 任意一张左右滑过阈值即标记删除——飞出后汇入「待删除」。
struct ColumnsGrid: View {
    let photos: [PhotoItem]
    let columns: Int
    let onMarkDelete: (PhotoItem) -> Void

    /// 把照片按「最短列优先」分到各列，列高用纵横比估算，避免长图把一列拉得过长。
    private var lanes: [[PhotoItem]] {
        var heights = Array(repeating: 0.0, count: columns)
        var result = Array(repeating: [PhotoItem](), count: columns)
        for photo in photos {
            let lane = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            result[lane].append(photo)
            heights[lane] += 1 / min(max(photo.ratio, 0.3), 3.2)
        }
        return result
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 6) {
                ForEach(0..<columns, id: \.self) { lane in
                    LazyVStack(spacing: 6) {
                        ForEach(lanes[lane]) { photo in
                            ColumnCell(photo: photo, onMarkDelete: onMarkDelete)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ColumnCell: View {
    let photo: PhotoItem
    let onMarkDelete: (PhotoItem) -> Void

    @State private var offset: CGFloat = 0
    @State private var flying = false

    private let threshold: CGFloat = 70

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .aspectRatio(min(max(photo.ratio, 0.3), 3.2), contentMode: .fit)
            .overlay {
                AsyncThumbnail(asset: photo.asset,
                               targetSize: CGSize(width: 420, height: 420))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .offset(x: offset)
            .opacity(1 - min(0.85, abs(offset) / 500))
            // 与滚动共存：只有横向占优时才接管位移
            .simultaneousGesture(dragGesture)
            .accessibilityLabel("照片，左右滑动标记删除")
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard !flying else { return }
                let t = value.translation
                if abs(t.width) > abs(t.height) * 1.2 {
                    offset = t.width
                }
            }
            .onEnded { _ in
                guard !flying else { return }
                if abs(offset) > threshold {
                    flying = true
                    let target: CGFloat = offset > 0 ? 600 : -600
                    withAnimation(.smooth(duration: 0.22)) { offset = target }
                    // 飞出播完再真正改数据，和卡片区的「先动效后数据」保持一致
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        onMarkDelete(photo)
                    }
                } else {
                    withAnimation(.snappy(duration: 0.3)) { offset = 0 }
                }
            }
    }
}
