import SwiftUI

/// 卡片区：一次只显示一张，尺寸按媒体比例算。
struct SortDeck: View {
    let photo: PhotoItem?
    let sizeLabel: String
    let onSwipe: (SwipeIntent) -> Void
    let onTap: (PhotoItem) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let photo {
                    SwipeCard(
                        photo: photo,
                        sizeLabel: sizeLabel,
                        bounds: geometry.size,
                        onSwipe: onSwipe,
                        onTap: onTap
                    )
                    .id(photo.id)
                } else {
                    EmptyDeckView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SwipeCard: View {
    let photo: PhotoItem
    let sizeLabel: String
    let bounds: CGSize
    let onSwipe: (SwipeIntent) -> Void
    let onTap: (PhotoItem) -> Void

    @State private var offset: CGSize = .zero
    @State private var isLeaving = false

    /// 横图占满宽度、竖图占满高度；比例夹在 0.32–3.2，避免超长图把卡片压成一条线。
    private var cardSize: CGSize {
        let ratio = min(max(photo.ratio, 0.32), 3.2)
        let maxWidth = max(0, bounds.width - 8)
        let maxHeight = max(0, bounds.height - 8)
        var width = maxWidth
        var height = maxWidth / ratio
        if height > maxHeight {
            height = maxHeight
            width = maxHeight * ratio
        }
        return CGSize(width: width, height: height)
    }

    var body: some View {
        ZStack {
            Rectangle().fill(.regularMaterial)
            AsyncThumbnail(asset: photo.asset, targetSize: cardSize, contentMode: .fit)
            badges
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerPlate, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerPlate, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 0.5)
        }
        .shadow(color: Color(red: 12 / 255, green: 18 / 255, blue: 48 / 255).opacity(0.22),
                radius: 18, y: 10)
        .offset(offset)
        .rotationEffect(.degrees(offset.width / 26))
        .gesture(dragGesture)
        .onTapGesture { onTap(photo) }
        .accessibilityLabel("待整理的照片")
    }

    private var badges: some View {
        VStack {
            HStack {
                Spacer()
                if photo.isVideo {
                    Label(Format.duration(photo.duration), systemImage: "play.fill").badgeStyle()
                } else if photo.isLivePhoto {
                    Text("LIVE").badgeStyle()
                }
            }
            Spacer()
            HStack {
                if !photo.creationText.isEmpty {
                    Text(photo.creationText).badgeStyle()
                }
                Spacer()
                if !sizeLabel.isEmpty {
                    Text(sizeLabel).badgeStyle()
                }
            }
        }
        .padding(12)
        .allowsHitTesting(false)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isLeaving else { return }
                offset = value.translation
            }
            .onEnded { value in
                guard !isLeaving else { return }
                let translation = value.translation
                let threshold: CGFloat = 90
                var intent: SwipeIntent?

                if abs(translation.width) > abs(translation.height) {
                    if translation.width < -threshold { intent = .next }
                    else if translation.width > threshold { intent = .undo }
                } else {
                    if translation.height < -threshold { intent = .delete }
                    else if translation.height > threshold { intent = .favorite }
                }

                if let intent {
                    flyOut(intent)
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        offset = .zero
                    }
                }
            }
    }

    private func flyOut(_ intent: SwipeIntent) {
        isLeaving = true
        let target: CGSize
        switch intent {
        case .next: target = CGSize(width: -900, height: 0)
        case .undo: target = CGSize(width: 900, height: 0)
        case .delete: target = CGSize(width: 0, height: -1300)
        case .favorite: target = CGSize(width: 0, height: 1300)
        }

        withAnimation(.easeOut(duration: 0.26)) { offset = target }
        Task {
            try? await Task.sleep(for: .seconds(0.26))
            onSwipe(intent)
            offset = .zero
            isLeaving = false
        }
    }
}

private struct EmptyDeckView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.success)
            Text("本月项目已整理完毕")
                .font(.headline)
            Text("删除的照片已移入回收站")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassSurface(cornerRadius: Theme.cornerPlate)
    }
}

extension View {
    /// 卡片角和右上角的小标签统一造型。
    func badgeStyle() -> some View {
        self
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(.black.opacity(0.42), in: Capsule())
    }
}
