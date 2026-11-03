import SwiftUI

/// 「我的」面板。从底部栏的圆钮扩散到全屏（`fullScreenCover` + zoom 转场），
/// 退出用右上角 ×，交互就是入场动画的倒放。
struct MineScreen: View {
    /// iOS 26 走全屏 cover，需要右上角 ×；iOS 17–25 是普通 tab，不需要关闭按钮。
    var showsCloseButton = true

    @Environment(PhotoLibraryService.self) private var library
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss

    @AppStorage("ac_theme_v2") private var themeHex = "#2B4A6F"
    @AppStorage("ac_autoLive") private var autoPlayLive = true
    @AppStorage("ac_autoVideo") private var autoPlayVideo = true
    @AppStorage("ac_videoMuted") private var videoMuted = true
    @AppStorage("ac_batchSize") private var batchSize = 30.0

    @State private var showCacheCleared = false
    @State private var showFavorites = false
    @State private var favoriteCount = 0

    var body: some View {
        list
            .navigationTitle("我的")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("关闭")
                    }
                }
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

    private var list: some View {
        List {
            Section {
                UsageCard(cleanedCount: library.totalCleaned,
                          freedBytes: library.totalFreedBytes,
                          favoriteCount: favoriteCount,
                          pendingCount: library.trash.count,
                          storage: library.storage,
                          onShowFavorites: { showFavorites = true },
                          onShowTrash: { openTrash() })
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
                            .foregroundStyle(Theme.ink2)
                    }
                    Slider(value: $batchSize, in: 10...300, step: 10) {
                        Text("每轮数量")
                    }
                    Text("单轮最高可整理 300 项")
                        .font(.footnote)
                        .foregroundStyle(Theme.ink2)
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
                        .foregroundStyle(Theme.ink2)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    /// 「待清理」：先关掉我的，等转场收尾再开待删除 sheet，避免同时呈现两个 presentation。
    private func openTrash() {
        ui.showMine = false
        Task {
            try? await Task.sleep(for: .milliseconds(360))
            ui.showTrash = true
        }
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
        .background(Theme.dark,
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
        ("#2B4A6F", Color(hex: "#2B4A6F"), "深靛"),
        ("#A9432F", Color(hex: "#A9432F"), "砖红"),
        ("#5B7350", Color(hex: "#5B7350"), "橄榄"),
        ("#B07A2E", Color(hex: "#B07A2E"), "赭黄"),
        ("#4E6577", Color(hex: "#4E6577"), "灰蓝"),
        ("#7A5B45", Color(hex: "#7A5B45"), "栗棕"),
        ("#6B4A5C", Color(hex: "#6B4A5C"), "梅紫"),
        ("#8A6D3B", Color(hex: "#8A6D3B"), "古金"),
        ("#3F5E5A", Color(hex: "#3F5E5A"), "松绿"),
        ("#9C5B3E", Color(hex: "#9C5B3E"), "陶土"),
        ("#5A5566", Color(hex: "#5A5566"), "烟紫"),
        ("#2B2620", Color(hex: "#2B2620"), "墨黑"),
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
