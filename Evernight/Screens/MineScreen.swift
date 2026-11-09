import SwiftUI

/// 「我的」面板。从底部栏的圆钮扩散到全屏（`fullScreenCover` + zoom 转场），
/// 退出用右上角 ×，交互就是入场动画的倒放。
struct MineScreen: View {
    /// iOS 26 走全屏 cover，需要右上角 ×；iOS 17–25 是普通 tab，不需要关闭按钮。
    var showsCloseButton = true

    @Environment(PhotoLibraryService.self) private var library
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss

    @AppStorage("ac_autoLive") private var autoPlayLive = true
    @AppStorage("ac_autoVideo") private var autoPlayVideo = true
    @AppStorage("ac_videoMuted") private var videoMuted = true
    @AppStorage("ac_batchSize") private var batchSize = 30.0

    @State private var showCacheCleared = false
    @State private var showFavorites = false
    @State private var favoriteCount = 0

    var body: some View {
        list
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 「我的」是独立的全屏层，常驻标题在这里单独放一份，
                // 这样从底栏圆钮 zoom 进来时它跟着整页一起放大。
                ToolbarItem(placement: .topBarLeading) {
                    EvernightTitle(size: 24, color: Theme.text)
                }
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
                            .font(.typewriter(15, weight: .medium))
                            .foregroundStyle(Theme.text2)
                    }
                    Slider(value: $batchSize, in: 10...300, step: 10) {
                        Text("每轮数量")
                    }
                    Text("单轮最高可整理 300 项")
                        .font(.footnote)
                        .foregroundStyle(Theme.text2)
                }
                .padding(.vertical, 2)
            }

            Section("整理偏好") {
                LabeledContent("滑动方向", value: "左滑下一张 / 右滑撤回 / 上滑删除 / 下拉进相簿")
                LabeledContent("展示顺序", value: "最新优先")
                LabeledContent("照片显示", value: "显示全图")
                LabeledContent("语言", value: "简体中文")
            }

            Section("播放与显示") {
                Toggle("Live 图自动播放", isOn: $autoPlayLive)
                Toggle("视频自动播放", isOn: $autoPlayVideo)
                Toggle("视频默认静音", isOn: $videoMuted)
            }

            Section("通用") {
                LabeledContent("关于", value: "evernight 0.1")
                Button("操作指引") {}
                Button("清理缓存") { showCacheCleared = true }
            }

            Section("开发者") {
                NavigationLink {
                    CoarseDebugScreen()
                } label: {
                    Label("Debug 粗调", systemImage: "hand.draw")
                }
                NavigationLink {
                    DebugScreen()
                } label: {
                    Label("Debug 精调", systemImage: "slider.horizontal.3")
                }
            }

            Section {
                VStack(spacing: 8) {
                    Link("用户协议 · 隐私政策", destination: URL(string: "https://example.com")!)
                        .font(.footnote.weight(.medium))
                    Text("evernight 0.1 (14)")
                        .font(.caption)
                        .foregroundStyle(Theme.text2)
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
                .font(.pingFang(11))
                .foregroundStyle(Theme.text3)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(cleanedCount)")
                    .font(.typewriter(44, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text("· 释放 \(Format.bytes(freedBytes))")
                    .font(.typewriter(11))
                    .foregroundStyle(Theme.text2)
            }

            Divider().overlay(Theme.nightLine)

            HStack(spacing: 0) {
                Button(action: onShowFavorites) {
                    StatCell(symbol: "heart.fill", color: Theme.accent,
                             value: "\(favoriteCount)", title: "已喜欢")
                }
                .buttonStyle(.plain)
                Divider().frame(height: 34).overlay(Theme.nightLine)
                Button(action: onShowTrash) {
                    StatCell(symbol: "trash", color: Theme.text2,
                             value: "\(pendingCount)", title: "待清理")
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("手机存储").font(.pingFang(12))
                    Spacer()
                    Text("剩余 \(Format.gigabytes(storage.free)) / \(Format.gigabytes(storage.total))")
                        .font(.typewriter(11))
                        .foregroundStyle(Theme.text2)
                }
                ProgressView(value: storage.usedRatio)
                    .tint(Theme.accent)
                HStack {
                    Text("已用 \(Format.gigabytes(storage.used))（\(Int(storage.usedRatio * 100))%）")
                    Spacer()
                    Text("可用 \(Format.gigabytes(storage.free))")
                }
                .font(.typewriter(10))
                .foregroundStyle(Theme.text3)
            }
        }
        .padding(16)
        .foregroundStyle(Theme.text)
        .background(Theme.nightPanel,
                    in: RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerPanel, style: .continuous)
                .strokeBorder(Theme.nightLine, lineWidth: 0.5)
        }
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
                .font(.typewriter(15, weight: .medium))
            Text(title + " ›")
                .font(.pingFang(10))
                .foregroundStyle(Theme.text3)
        }
        .frame(maxWidth: .infinity)
    }
}
