import SwiftUI

/// 整理页顶部：左上角常驻 Evernight 标题，下面一行是月份胶囊与「待删除 + 撤回」合体胶囊，
/// 最下面一条占满整行的进度条。
///
/// 不用系统 toolbar：toolbar 只有一行，排不下「标题在上、胶囊在下」；
/// 标题还要在点开照片详情时跟着整页一起模糊，放在页面内容里才自然。
struct SortHeader: View {
    /// 顶部总高：上边距 4 + 标题 36 + 间距 8 + 胶囊 34 + 间距 8 + 进度条 28。
    static let height: CGFloat = 118

    let months: [MonthSection]
    let selectedMonthID: String?
    let showsMonth: Bool
    /// 相簿详情时为相簿名，普通整理页为 nil。
    let albumTitle: String?
    let processed: Int
    let total: Int
    let canUndo: Bool
    /// 撤回会倒做哪一步。撤销栈是通用的，写清楚比一个光秃秃的箭头可信。
    let undoHint: String?
    let tint: Color
    @Binding var showMonthWheel: Bool
    let onUndo: () -> Void
    let onBack: (() -> Void)?

    @Environment(PhotoLibraryService.self) private var library
    @Environment(UIState.self) private var ui

    private var selectedTitle: String {
        months.first { $0.id == selectedMonthID }?.title ?? "选择月份"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleRow
                .frame(height: 36)
                .padding(.top, 4)

            HStack(spacing: 8) {
                if showsMonth {
                    monthPill
                }
                Spacer(minLength: 8)
                if let undoHint {
                    Text(undoHint)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.ink.opacity(0.68))
                        .lineLimit(1)
                        .transition(.opacity)
                }
                actionCapsule
            }
            .frame(height: 34)
            .padding(.top, 8)

            ProgressHeader(processed: processed, total: total, tint: tint)
                .padding(.top, 8)
        }
        .frame(height: Self.height, alignment: .top)
        .animation(.smooth(duration: 0.25), value: undoHint)
    }

    // MARK: - 标题

    private var titleRow: some View {
        HStack(spacing: 10) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.card)
                        .frame(width: 30, height: 30)
                        .background(Theme.ink.opacity(0.22), in: Circle())
                }
                .buttonStyle(PillPressStyle())
                .accessibilityLabel("返回")
            }

            EvernightTitle(size: 28)

            Spacer(minLength: 8)

            if let albumTitle {
                Text(albumTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink.opacity(0.72))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - 月份

    private var monthPill: some View {
        Button {
            withAnimation(.snappy(duration: 0.26)) { showMonthWheel.toggle() }
        } label: {
            HStack(spacing: 6) {
                Text(selectedTitle)
                    .font(.typewriter(13, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .rotationEffect(.degrees(showMonthWheel ? 180 : 0))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Theme.card, in: Capsule())
            .overlay {
                Capsule().strokeBorder(Theme.line.opacity(0.85), lineWidth: 0.8)
            }
            .shadow(color: Theme.ink.opacity(0.16), radius: 8, y: 3)
        }
        .buttonStyle(PillPressStyle())
        .accessibilityLabel("选择月份")
    }

    // MARK: - 待删除 + 撤回

    /// 两个按钮共用一块纸胶囊，中间一道发丝线。
    private var actionCapsule: some View {
        HStack(spacing: 0) {
            Button {
                ui.showTrash = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .medium))
                    .overlay(alignment: .topTrailing) {
                        if !library.trash.isEmpty {
                            Text("\(min(library.trash.count, 99))")
                                .font(.typewriter(9, weight: .semibold))
                                .foregroundStyle(Theme.card)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.danger, in: Capsule())
                                .overlay {
                                    Capsule().strokeBorder(Theme.card.opacity(0.65), lineWidth: 0.8)
                                }
                                .offset(x: 10, y: -8)
                        }
                    }
                    .frame(width: 48, height: 34)
            }
            .buttonStyle(PillPressStyle())
            .accessibilityLabel("待删除")

            Rectangle()
                .fill(Theme.line.opacity(0.9))
                .frame(width: 0.8, height: 16)

            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 48, height: 34)
            }
            .buttonStyle(PillPressStyle())
            .disabled(!canUndo)
            .opacity(canUndo ? 1 : 0.35)
            .accessibilityLabel("撤回")
        }
        .foregroundStyle(Theme.ink)
        .background(Theme.card, in: Capsule())
        .overlay {
            Capsule().strokeBorder(Theme.line.opacity(0.85), lineWidth: 0.8)
        }
        .shadow(color: Theme.ink.opacity(0.16), radius: 8, y: 3)
    }
}

/// 胶囊里的按钮按下时轻微缩一下：不改变布局，只给手感一个交代。
private struct PillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// 月份滚轮：交给系统 `Picker(.wheel)`，惯性、回弹、选中反馈都是原生手感。
/// 选中即切月；面板不会自动收起，点空白或再点胶囊才收，避免滚轮还在惯性时被打断。
struct MonthWheelPanel: View {
    let months: [MonthSection]
    let onSelect: (MonthSection) -> Void

    @State private var selection: String

    init(months: [MonthSection],
         currentID: String?,
         onSelect: @escaping (MonthSection) -> Void) {
        self.months = months
        self.onSelect = onSelect
        _selection = State(initialValue: currentID ?? months.first?.id ?? "")
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("选择月份")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.ink2)
                .padding(.top, 12)

            Picker("月份", selection: $selection) {
                ForEach(months) { month in
                    Text(month.title)
                        .font(.typewriter(15))
                        .tag(month.id)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .frame(width: 208)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.line.opacity(0.85), lineWidth: 0.8)
        }
        .shadow(color: Theme.ink.opacity(0.24), radius: 20, y: 10)
        .onChange(of: selection) { _, id in
            guard let month = months.first(where: { $0.id == id }) else { return }
            onSelect(month)
        }
    }
}

/// 左上角的 App 标题。英文走衬线斜体（「斜体花字」），压在木桌上时带一点投影。
/// 「我的」是独立的全屏层，那里再放一份同样的标题，zoom 转场时它会跟着一起缩放。
struct EvernightTitle: View {
    var size: CGFloat = 28
    /// 木桌上是墨色，深色底上可换成奶白。
    var color: Color = Theme.ink

    var body: some View {
        Text("Evernight")
            .font(.scriptItalic(size, weight: .semibold))
            .fixedSize()
            .foregroundStyle(color)
            .shadow(color: Theme.paper.opacity(0.45), radius: 1, y: 1)
            .accessibilityAddTraits(.isHeader)
    }
}
