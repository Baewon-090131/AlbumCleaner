import SwiftUI

/// 整理页顶部：左上角常驻 EVERNIGHT 字标，下面一行是月份与「待删除 + 撤回」金属板，
/// 最下面一条占满整行的进度条。
///
/// 不用系统 toolbar：toolbar 只有一行，排不下「字标在上、操作在下」；
/// 字标还要在点开照片详情时跟着整页一起模糊，放在页面内容里才自然。
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
                    monthButton
                }
                Spacer(minLength: 8)
                if let undoHint {
                    Text(undoHint)
                        .font(.pingFang(11))
                        .foregroundStyle(Theme.text3)
                        .lineLimit(1)
                        .transition(.opacity)
                }
                actionPlate
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 30, height: 30)
                        .background(Theme.nightRaised, in: Circle())
                        .overlay {
                            Circle().strokeBorder(Theme.nightLine, lineWidth: 0.5)
                        }
                }
                .buttonStyle(PillPressStyle())
                .accessibilityLabel("返回")
            }

            EvernightTitle(size: 28)

            Spacer(minLength: 8)

            if let albumTitle {
                Text(albumTitle)
                    .font(.pingFang(12, weight: .medium))
                    .foregroundStyle(Theme.text2)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - 月份

    /// 月份不是胶囊，是书页上的一行字：汉字 PingFang、数字打字机，后面跟一个小箭头。
    private var monthButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.26)) { showMonthWheel.toggle() }
        } label: {
            HStack(spacing: 6) {
                MixedType.text(selectedTitle, size: 13, weight: .medium)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .rotationEffect(.degrees(showMonthWheel ? 180 : 0))
                    .opacity(0.55)
            }
            .foregroundStyle(Theme.text)
            .frame(height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(PillPressStyle())
        .accessibilityLabel("选择月份")
    }

    // MARK: - 待删除 + 撤回

    /// 两个按钮共用一块夜漆金属板，中间一道发丝线。
    private var actionPlate: some View {
        HStack(spacing: 0) {
            Button {
                ui.showTrash = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .regular))
                    .overlay(alignment: .topTrailing) {
                        if !library.trash.isEmpty {
                            Text("\(min(library.trash.count, 99))")
                                .font(.typewriter(8, weight: .semibold))
                                .foregroundStyle(Theme.paper)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.accent, in: Capsule())
                                .offset(x: 11, y: -8)
                        }
                    }
                    .frame(width: 48, height: 34)
            }
            .buttonStyle(PillPressStyle())
            .accessibilityLabel("待删除")

            Rectangle()
                .fill(Theme.nightLine)
                .frame(width: 0.5, height: 16)

            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .regular))
                    .frame(width: 48, height: 34)
            }
            .buttonStyle(PillPressStyle())
            .disabled(!canUndo)
            .opacity(canUndo ? 1 : 0.3)
            .accessibilityLabel("撤回")
        }
        .foregroundStyle(Theme.text)
        .background(Theme.nightRaised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.nightLine, lineWidth: 0.5)
        }
    }
}

/// 按钮按下时轻微缩一下：不改变布局，只给手感一个交代。
private struct PillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// 月份滚轮：交给系统 `Picker(.wheel)`，惯性、回弹、选中反馈都是原生手感。
/// 选中即切月；面板不会自动收起，点空白或再点月份才收，避免滚轮还在惯性时被打断。
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
                .font(.pingFang(11, weight: .medium))
                .foregroundStyle(Theme.text2)
                .padding(.top, 12)

            Picker("月份", selection: $selection) {
                ForEach(months) { month in
                    MixedType.text(month.title, size: 15)
                        .tag(month.id)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .frame(width: 208)
        .background(Theme.nightRaised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.nightLine, lineWidth: 0.5)
        }
        .shadow(color: Color.black.opacity(0.55), radius: 22, y: 12)
        .onChange(of: selection) { _, id in
            guard let month = months.first(where: { $0.id == id }) else { return }
            onSelect(month)
        }
    }
}

/// 左上角的 App 字标。英文走打字机、大写、宽字距——和素材里的 EVERNIGHT 小标同一种排版。
/// 「我的」是独立的全屏层，那里再放一份同样的字标，zoom 转场时它会跟着一起缩放。
struct EvernightTitle: View {
    var size: CGFloat = 28
    /// 夜桌上是骨白，深色底上可换成墨色。
    var color: Color = Theme.text

    var body: some View {
        Text("EVERNIGHT")
            .font(.typewriter(size * 0.5, weight: .medium))
            .tracking(size * 0.12)
            .fixedSize()
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
    }
}
