import SwiftUI

/// 「我的」面板。不再是 tab，而是从底部上滑覆盖的 sheet：
/// 顶部抓握条下拉关闭，内容仍是系统 List（insetGrouped）。
struct MineScreen: View {
    let onClose: () -> Void
    /// 抓握区跟手下拉：实时位移与松手判定都交给外层（MainTabView）。
    let onDrag: (CGFloat) -> Void
    let onDragEnd: (CGFloat) -> Void

    @Environment(PhotoLibraryService.self) private var library
    @Environment(UIState.self) private var ui

    @AppStorage("ac_theme") private var themeHex = "#002FA7"
    @AppStorage("ac_autoLive") private var autoPlayLive = true
    @AppStorage("ac_autoVideo") private var autoPlayVideo = true
    @AppStorage("ac_videoMuted") private var videoMuted = true
    @AppStorage("ac_batchSize") private var batchSize = 30.0

    @State private var showCacheCleared = false
    @State private var showFavorites = false
    @State private var favoriteCount = 0

    var body: some View {
        VStack(spacing: 0) {
            grabber
            list
        }
        .fullScreenCover(isPresented: $showFavorites) {
            NavigationStack { FavoritesScreen() }
        }
        .alert("缓存已清理", isPresented: $showCacheCleared) {
            Button("好", role: .cancel) {}
        }
        .task {
            library.refreshStorage()
            favoriteCount = library.favoritePhotos().count
        }
    }

    /// 抓握条 + 大标题；只有这一片响应下拉手势，下面 List 的滚动不受影响。
    private var grabber: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            HStack {
                Text("我的")
                    .font(.largeTitle.bold())
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 6)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { onDrag($0.translation.height) }
                .onEnded { onDragEnd($0.translation.height) }
        )
    }

    private var list: some View {
        List {
            Section {
                UsageCard(cleanedCount: library.totalCleaned,
                          freedBytes: library.totalFreedBytes,
                          favoriteCount: favoriteCount,
                          pendingCount: library.trash.count,
                          storage: library.storage,
                          onShowFavorites: { showFavorites = true },
                          onShowTrash: {
                              onClose()
                              ui.showTrash = true
                          })
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section("整理") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("每轮数量")
                        Spacer()
                        Text("\(Int(batchSize))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $batchSize, in: 10...300, step: 10) {
                        Text("每轮数量")
                    }
                    Text("单轮最高可整理 300 项")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Section("整理偏好") {
                LabeledContent("滑动方向", value: "左滑跳过 / 上滑删除")
                LabeledContent("展示顺序", value: "最新优先")
                LabeledContent("照片显示", value: "显示全图")
                LabeledContent("语言", value: "简体中文")
            }

            Section("播放与显示") {
                Toggle("Live 图自动播放", isOn: $autoPlayLive)
                Toggle("视频自动播放", isOn: $autoPlayVideo)
                Toggle("视频默认静音", isOn: $videoMuted)
            }

            Section("外观") {
                ThemeColorGrid(selection: $themeHex)
                    .padding(.vertical, 4)
            }

            Section("通用") {
                LabeledContent("关于", value: "evernight 0.1")
                Button("操作指引") {}
                Button("清理缓存") { showCacheCleared = true }
            }

            Section {
                VStack(spacing: 8) {
                    Link("用户协议 · 隐私政策", destination: URL(string: "https://example.com")!)
                        .font(.footnote.weight(.medium))
                    Text("evernight 0.1 (14)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        // 底部留位给悬浮底栏
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 92) }
    }
}

// MARK: - 使用数据卡（深色卡，对齐参考稿）

private struct UsageCard: View {
    let cleanedCount: Int
    let freedBytes: Int64
    let favoriteCount: Int
    let pendingCount: Int
    let storage: StorageInfo
    let onShowFavorites: () -> Void
    let onShowTrash: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("累计已清理")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.55))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(cleanedCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.success)
                Text("· 释放 \(Format.bytes(freedBytes))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Divider().overlay(.white.opacity(0.18))

            HStack(spacing: 0) {
                Button(action: onShowFavorites) {
                    StatCell(symbol: "heart.fill", color: Theme.danger,
                             value: "\(favoriteCount)", title: "已喜欢")
                }
                .buttonStyle(.plain)
                Divider().frame(height: 34).overlay(.white.opacity(0.18))
                Button(action: onShowTrash) {
                    StatCell(symbol: "trash", color: Theme.success,
                             value: "\(pendingCount)", title: "待清理")
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("手机存储").font(.subheadline)
                    Spacer()
                    Text("剩余 \(Format.gigabytes(storage.free)) / \(Format.gigabytes(storage.total))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                }
                ProgressView(value: storage.usedRatio)
                    .tint(Theme.success)
                HStack {
                    Text("已用 \(Format.gigabytes(storage.used))（\(Int(storage.usedRatio * 100))%）")
                    Spacer()
                    Text("可用 \(Format.gigabytes(storage.free))")
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255),
                    in: RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous))
    }
}

private struct StatCell: View {
    let symbol: String
    let color: Color
    let value: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .monospacedDigit()
            Text(title + " ›")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 主题色

private struct ThemeColorGrid: View {
    @Binding var selection: String

    private let colors: [(id: String, color: Color, name: String)] = [
        ("#007AFF", .blue, "蓝色"),
        ("#AF52DE", .purple, "紫色"),
        ("#34C759", .green, "绿色"),
        ("#FF9500", .orange, "橙色"),
        ("#FF3B30", .red, "红色"),
        ("#FF2D92", Color(red: 1, green: 0.176, blue: 0.573), "粉色"),
        ("#002FA7", Theme.accent, "北洋蓝"),
        ("#5856D6", .indigo, "靛蓝"),
        ("#32ADE6", .cyan, "青色"),
        ("#30B0C7", Color(red: 0.188, green: 0.69, blue: 0.78), "湖绿"),
        ("#FFCC00", .yellow, "金色"),
        ("#636366", .gray, "石墨"),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(colors, id: \.id) { item in
                Button {
                    selection = item.id
                } label: {
                    Circle()
                        .fill(item.color)
                        .frame(width: 34, height: 34)
                        .overlay {
                            if selection == item.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay {
                            if selection == item.id {
                                Circle().strokeBorder(.white, lineWidth: 2).padding(-4)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.name)
            }
        }
    }
}
