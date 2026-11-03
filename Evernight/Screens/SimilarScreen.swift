import SwiftUI

/// 相似页：pHash 分组结果 + 最优保留 + 勾选删除（进「待删除」，不直接动系统相册）。
/// 扫描结果放在 environment 里的 SimilarityService，切 tab 回来不用重扫。
struct SimilarScreen: View {
    @Environment(PhotoLibraryService.self) private var library
    @Environment(SimilarityService.self) private var similar

    /// nil = 最近（全部）
    @State private var selectedYear: Int?
    /// 每组里被取消勾选的；「最优」永远不可勾选。
    @State private var uncheckedByGroup: [Int: Set<String>] = [:]
    @State private var showSmartConfirm = false
    @State private var toast: String?

    private var allPhotos: [PhotoItem] {
        library.months.flatMap(\.photos)
    }

    private var years: [Int] {
        Array(Set(similar.groups.compactMap(\.latestYear))).sorted(by: >)
    }

    private var visibleGroups: [SimilarGroup] {
        guard let selectedYear else { return similar.groups }
        return similar.groups.filter { $0.latestYear == selectedYear }
    }

    private var totalReclaimable: Int64 {
        visibleGroups.reduce(into: Int64(0)) { sum, group in
            for photo in group.others { sum += library.fileSize(of: photo) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if similar.isScanning {
                    scanningCard
                } else if similar.groups.isEmpty && similar.hasScanned {
                    ContentUnavailableView("没有发现相似照片", systemImage: "square.on.square",
                                           description: Text("库里的照片都不重复，很干净"))
                        .padding(.top, 60)
                } else {
                    yearFilter
                    summaryBanner
                    ForEach(visibleGroups) { group in
                        GroupCard(group: group,
                                  unchecked: uncheckedByGroup[group.id] ?? [],
                                  bytes: { bytes(of: $0) },
                                  isChecked: { isChecked(group, $0) },
                                  onToggle: { toggle(group, $0) },
                                  onDelete: { deleteChecked(group) })
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("相似")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { TrayButton() }
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastBanner(text: toast)
                    .animation(.snappy(duration: 0.3), value: toast)
            }
        }
        .confirmationDialog("智能清理", isPresented: $showSmartConfirm, titleVisibility: .visible) {
            Button("把 \(smartTargets.count) 张非最优全部移入待删除") { smartClean() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("每组保留「最优」一张，其余进待删除，可在待删除里反悔。")
        }
        .task {
            guard !similar.hasScanned, !similar.isScanning else { return }
            await similar.scan(photos: allPhotos) { library.fileSize(of: $0) }
        }
    }

    // MARK: - 子视图

    private var scanningCard: some View {
        VStack(spacing: 14) {
            ProgressView(value: similar.progress)
                .tint(Theme.accent)
            Text("正在分析照片 \(Int(similar.progress * 100))%")
                .font(.subheadline)
                .foregroundStyle(Theme.ink2)
            Text("首次扫描需要逐张计算指纹，之后只增量扫新照片")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassSurface(cornerRadius: Theme.cornerPanel)
        .padding(.top, 40)
    }

    private var yearFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                yearPill(nil, title: "最近")
                ForEach(years, id: \.self) { year in
                    yearPill(year, title: String(year))
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func yearPill(_ year: Int?, title: String) -> some View {
        let on = selectedYear == year
        return Button {
            selectedYear = year
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(on ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    if on {
                        Capsule().fill(Theme.accent)
                    }
                }
        }
        .buttonStyle(.plain)
        .glassSurface(cornerRadius: 18, interactive: !on)
    }

    private var summaryBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("最多可释放")
                    .font(.caption)
                    .foregroundStyle(Theme.ink2)
                Text(Format.bytes(totalReclaimable))
                    .font(.title3.bold())
                    .foregroundStyle(Theme.accent)
            }
            Spacer()
            Button {
                showSmartConfirm = true
            } label: {
                Label("智能清理", systemImage: "wand.and.stars")
                    .font(.subheadline.weight(.semibold))
            }
            .glassButtonStyle(prominent: true)
            .tint(Theme.accent)
            .disabled(smartTargets.isEmpty)
        }
        .padding(14)
        .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: Theme.cornerTile, style: .continuous))
    }

    // MARK: - 勾选与删除

    /// 组内「非最优」里当前被勾选的。
    private func checkedPhotos(_ group: SimilarGroup) -> [PhotoItem] {
        let skipped = uncheckedByGroup[group.id] ?? []
        return group.others.filter { !skipped.contains($0.id) }
    }

    private func isChecked(_ group: SimilarGroup, _ photo: PhotoItem) -> Bool {
        photo.id != group.bestID && !(uncheckedByGroup[group.id]?.contains(photo.id) ?? false)
    }

    private func toggle(_ group: SimilarGroup, _ photo: PhotoItem) {
        guard photo.id != group.bestID else { return }
        var set = uncheckedByGroup[group.id] ?? []
        if set.contains(photo.id) { set.remove(photo.id) } else { set.insert(photo.id) }
        uncheckedByGroup[group.id] = set
    }

    private func bytes(of photo: PhotoItem) -> Int64 {
        library.fileSize(of: photo)
    }

    private var smartTargets: [PhotoItem] {
        visibleGroups.flatMap { checkedPhotos($0) }
    }

    private func deleteChecked(_ group: SimilarGroup) {
        let targets = checkedPhotos(group)
        guard !targets.isEmpty else { return }
        sendToTrash(Set(targets.map(\.id)), count: targets.count)
    }

    private func smartClean() {
        let targets = smartTargets
        guard !targets.isEmpty else { return }
        sendToTrash(Set(targets.map(\.id)), count: targets.count)
    }

    private func sendToTrash(_ ids: Set<String>, count: Int) {
        let items = allPhotos.filter { ids.contains($0.id) }
        for item in items { library.moveToTrash(item) }
        similar.remove(ids)
        uncheckedByGroup = uncheckedByGroup.mapValues { $0.subtracting(ids) }
        show("已将 \(count) 张移入待删除")
    }

    private func show(_ message: String) {
        withAnimation(.snappy(duration: 0.3)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            guard toast == message else { return }
            withAnimation(.smooth(duration: 0.2)) { toast = nil }
        }
    }
}

