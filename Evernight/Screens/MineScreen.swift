import SwiftUI

/// 「我的」页。整页用系统 List（insetGrouped），开关、滑块、导航行全是原生控件。
struct MineScreen: View {
    @Environment(PhotoLibraryService.self) private var library

    @AppStorage("ac_theme") private var themeHex = "#002FA7"
    @AppStorage("ac_autoLive") private var autoPlayLive = true
    @AppStorage("ac_autoVideo") private var autoPlayVideo = true

    @State private var batchSize = 30.0
    @State private var showTrash = false
    @State private var showCacheCleared = false

    var body: some View {
        List {
            Section {
                UsageCard(cleanedCount: library.trash.count,
                          freedBytes: library.trashByteCount,
                          pendingCount: library.trash.count,
                          storage: library.storage)
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
                Toggle("HDR 显示", isOn: .constant(false))
                    .disabled(true)
                Toggle("视频声音", isOn: .constant(false))
                    .disabled(true)
            }

            Section("外观") {
                ThemeColorGrid(selection: $themeHex)
                    .padding(.vertical, 4)
            }

            Section("通用") {
                LabeledContent("关于", value: "Evernight 4.0")
                Button("操作指引") {}
                Button("清理缓存") { showCacheCleared = true }
            }

            Section {
                VStack(spacing: 8) {
                    Link("用户协议 · 隐私政策", destination: URL(string: "https://example.com")!)
                        .font(.footnote.weight(.medium))
                    Text("Evernight 4.0 (1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle("我的")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showTrash = true
                } label: {
                    Image(systemName: "archivebox")
                }
                .accessibilityLabel("回收站")
            }
        }
        .navigationDestination(isPresented: $showTrash) { TrashScreen() }
        .alert("缓存已清理", isPresented: $showCacheCleared) {
            Button("好", role: .cancel) {}
        }
        .task { library.refreshStorage() }
    }
}

// MARK: - 使用数据卡

private struct UsageCard: View {
    let cleanedCount: Int
    let freedBytes: Int64
    let pendingCount: Int
    let storage: StorageInfo

    var body: some View {
        ContentPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("累计已清理")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(cleanedCount)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.success)
                    Text("· 释放 \(Format.bytes(freedBytes))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    StatCell(symbol: "heart.fill", color: Theme.danger, value: "0", title: "已收藏")
                    Divider().frame(height: 34)
                    StatCell(symbol: "trash", color: Theme.success, value: "\(pendingCount)", title: "待清理")
                    Divider().frame(height: 34)
                    StatCell(symbol: "eye", color: .secondary, value: "0", title: "本轮已看")
                }

                VStack(spacing: 6) {
                    HStack {
                        Text("手机存储").font(.subheadline)
                        Spacer()
                        Text("剩余 \(Format.gigabytes(storage.free)) / \(Format.gigabytes(storage.total))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: storage.usedRatio)
                        .tint(Theme.success)
                    HStack {
                        Text("已用 \(Format.gigabytes(storage.used))（\(Int(storage.usedRatio * 100))%）")
                        Spacer()
                        Text("可用 \(Format.gigabytes(storage.free))")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
    }
}

private struct StatCell: View {
    let symbol: String
    let color: Color
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 17))
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
