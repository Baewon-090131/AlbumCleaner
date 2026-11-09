import SwiftUI

/// 整理页的单张照片卡。
///
/// 照片自己就是卡片：**没有白边、没有木夹**，圆角取 DESIGN 的 `rounded.lg`。
/// 顶部两枚胶囊角标（左：HDR / 实况 / 视频，右：日期 · 体积），
/// 拖动到删除阈值时整张卡外缘浮起一圈绯红光晕（`glow` 0 → 1）。
struct SwipePhotoCard: View {
    let photo: PhotoItem
    let cardSize: CGSize
    let sizeLabel: String
    /// 删除阈值光晕：0 = 无，1 = 到阈值。
    var glow: CGFloat = 0
    /// 碎沙擦拭：0 = 完整，1 = 消失。
    var erase: CGFloat = 0
    var onTap: () -> Void = {}

    /// DESIGN：内联卡片图像用 `rounded.lg`，全 App 只有照片用这一档圆角。
    private let radius = Theme.radiusCard

    var body: some View {
        AsyncThumbnail(asset: photo.asset,
                       targetSize: cardSize,
                       contentMode: .fill,
                       highQuality: true,
                       placeholderColor: Theme.nightPanel)
            .frame(width: cardSize.width, height: cardSize.height)
            .clipped()
            .overlay(alignment: .topLeading) { badge(leftLabel) }
            .overlay(alignment: .topTrailing) { badge(rightLabel) }
            .overlay(alignment: .topTrailing) {
                if photo.asset.isFavorite {
                    NightFlower(kind: .seal, angle: -8)
                        .frame(width: 34, height: 34)
                        .padding(42)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                // 夜里的发丝边：照片自己会没入夜底，需要一道极淡的轮廓
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.text.opacity(0.10), lineWidth: 0.5)
            }
            .overlay {
                // 阈值光晕：贴边一道绯红线，外侧再发光
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(0.92 * Double(glow)), lineWidth: 1.5)
            }
            .shadow(color: Theme.accent.opacity(0.55 * Double(glow)), radius: 22 * glow)
            // DESIGN：整个系统只有一道投影，且只给「照片落在台面上」这一种情况
            .shadow(color: .black.opacity(0.42), radius: 24, y: 12)
            .mask(eraseMask)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .onTapGesture { onTap() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("待整理的照片")
    }

    /// 底部先透明；`erase` 越大透明区越往上长。`erase` 为 0 时整张不透。
    private var eraseMask: LinearGradient {
        guard erase > 0.001 else {
            return LinearGradient(colors: [.black, .black],
                                  startPoint: .top, endPoint: .bottom)
        }
        let boundary = max(0, min(1, 1 - erase))
        return LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: max(0, boundary - 0.06)),
                .init(color: .clear, location: min(1, boundary + 0.02)),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var leftLabel: Text {
        Text(photo.isVideo ? "视频" : (photo.isLivePhoto ? "实况" : "HDR"))
    }

    private var rightLabel: Text {
        var text = Text(photo.creationText)
        if !sizeLabel.isEmpty { text = text + Text(" · ") + Text(sizeLabel) }
        return text + Text("  ›")
    }

    /// 角标：DESIGN 的 fine-print 尺寸，胶囊 + 极薄材质。
    private func badge(_ text: Text) -> some View {
        text
            .font(.typewriter(10.5, weight: .semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(Theme.text.opacity(0.10), lineWidth: 0.5) }
            .padding(12)
    }
}

/// 相簿轨道：下拉时从底部浮起的一块浮板，**始终在底栏之上**。
///
/// 命中判定不靠屏幕宽度：手指横向位移多少，就翻过多少格（`onPick` 也可以直接点一格）。
/// 选中那格永远停在轨道正中，两端的格子用渐隐收掉，所以相簿再多也能一路选到底。
struct AlbumDropTray: View {
    let albums: [AlbumItem]
    /// 当前命中的第几格。
    let selectedIndex: Int
    /// 0 = 完全收起，1 = 完全展开。
    let progress: CGFloat
    /// 直接点一格存进去。
    let onPick: (AlbumItem) -> Void

    /// 单格宽 / 间距。
    static let chip: CGFloat = 76
    static let gap: CGFloat = 10
    static var step: CGFloat { chip + gap }

    /// 横向拖了多远 → 翻过几格。用相对位移，所以相簿再多也能选到底。
    static func index(forDrag dx: CGFloat, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let raw = Int((dx / step).rounded())
        return min(max(raw, 0), count - 1)
    }

    private var clampIndex: Int {
        min(max(selectedIndex, 0), max(albums.count - 1, 0))
    }

    var body: some View {
        VStack(spacing: Theme.spaceSM) {
            HStack(spacing: 6) {
                Text("拖到相簿")
                    .font(.pingFang(11))
                    .foregroundStyle(Theme.text3)

                Spacer(minLength: Theme.spaceXS)

                if let name = albums[safe: clampIndex]?.name {
                    Text("松手存入「\(name)」")
                        .font(.pingFang(11))
                        .foregroundStyle(Theme.accentText)
                        .lineLimit(1)
                }
            }

            rail
        }
        .padding(.horizontal, 14)
        .padding(.top, Theme.spaceSM)
        .padding(.bottom, Theme.spaceSM)
        .background(Theme.nightRaised,
                    in: RoundedRectangle(cornerRadius: Theme.radiusPlate, style: .continuous))
        .padding(.horizontal, 6)
        .padding(.bottom, Theme.spaceXS)
        .opacity(Double(progress))
        .offset(y: (1 - progress) * 150)
        .allowsHitTesting(progress > 0.5)
    }

    private var rail: some View {
        GeometryReader { geo in
            let width = geo.size.width
            HStack(spacing: Self.gap) {
                ForEach(Array(albums.enumerated()), id: \.element.id) { pair in
                    chipView(pair.element, isOn: pair.offset == clampIndex)
                }
            }
            .padding(.horizontal, max(0, width / 2 - Self.chip / 2))
            .offset(x: -CGFloat(clampIndex) * Self.step)
            .frame(width: width, alignment: .leading)
            .animation(.snappy(duration: 0.24), value: clampIndex)
        }
        .frame(height: Self.chip + 18)
        .clipped()
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.14),
                .init(color: .black, location: 0.86),
                .init(color: .clear, location: 1)
            ], startPoint: .leading, endPoint: .trailing)
        }
    }

    private func chipView(_ album: AlbumItem, isOn: Bool) -> some View {
        Button {
            onPick(album)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Rectangle().fill(Theme.nightPanel)
                    if let cover = album.coverAsset {
                        AsyncThumbnail(asset: cover,
                                       targetSize: CGSize(width: Self.chip * 2,
                                                          height: Self.chip * 2),
                                       contentMode: .fill)
                    }
                }
                .frame(width: Self.chip, height: Self.chip)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusInner,
                                            style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.radiusInner, style: .continuous)
                        .strokeBorder(isOn ? Theme.accent : Theme.nightLine,
                                      lineWidth: isOn ? 2 : 0.5)
                }
                .overlay(alignment: .topTrailing) {
                    Text("\(album.count)")
                        .font(.typewriter(10, weight: .semibold))
                        .foregroundStyle(Theme.text2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.night.opacity(0.72), in: Capsule())
                        .padding(5)
                }
                .scaleEffect(isOn ? 1.05 : 1)
                .animation(.snappy(duration: 0.2), value: isOn)

                Text(album.name)
                    .font(.pingFang(11))
                    .foregroundStyle(isOn ? Theme.text : Theme.text3)
                    .lineLimit(1)
                    .frame(width: Self.chip)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("存入「\(album.name)」")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
