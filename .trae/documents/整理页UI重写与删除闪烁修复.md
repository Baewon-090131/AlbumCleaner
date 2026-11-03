# 整理页 UI 重写 · 媒体嵌入卡片 · 删除闪烁修复

## 一、Summary

按参考视频 1（分列模式）/ 视频 2（单卡 + 卡内播放）的范式重写「整理」页，解决三件事：

1. **UI 冲突**：当前页面上下各堆三层控件（NavigationStack 大标题 + toolbar + 玻璃进度胶囊 + 卡片 + 底部操作岛 + 底栏），卡片被压到约 450pt。改成「顶栏一行（月份 + 媒体类型 + 撤销/托盘圆钮）+ 一条细进度条 + 满幅卡片 + 右侧竖排玻璃钮」。
2. **媒体真正嵌入卡片**：现在卡片是 `ZStack { Rectangle().fill(.regularMaterial); 图片; 角标 }`，材质在底、图片浮在上面，动效期间 backdrop blur 每帧重采样背景 + 大半径阴影重绘，视觉发飘。改成「媒体本身构成卡片实体 + 一层玻璃高光边」。
3. **删除闪一下**：定位到四个叠加成因（见第二节），其中主因是换卡时缩略图视图重建导致 `@State` 归零、且前置/后置卡请求尺寸不同导致缓存必然 miss，必然渲染至少一帧灰色占位。

**已拍板的两项决策**：
- 操作按钮 → 卡片右侧竖排圆形玻璃钮（抖音式，不占布局高度、不遮底部日期/体积）。
- 顶部加媒体类型筛选胶囊（照片 / 视频 / 实况 / 全部）。

配色与材质保持 Evernight 风格：北洋蓝（`@AppStorage("ac_theme")`）+ Liquid Glass，不照搬视频的绿色。

---

## 二、根因分析（有代码依据）

### 2.1 删除时闪一下

| # | 成因 | 代码位置 | 机制 |
|---|---|---|---|
| **主因 1** | 换卡必渲染一帧灰色占位 | [`AsyncThumbnail.swift#L25-L28`](file:///d:/Desktop/AlbumCleaner/Evernight/Components/AsyncThumbnail.swift#L25-L28) | 图片只在 `.task` 里赋值。`.task` 在视图出现后下一轮才跑，所以**新视图至少有一帧 `image == nil`**，渲染 `Rectangle().fill(.quaternary)`（灰块） |
| **主因 2** | 前置 / 后置卡缓存 key 不同，必然 miss | [`SortDeck.swift#L49-L73`](file:///d:/Desktop/AlbumCleaner/Evernight/Components/SortDeck.swift#L49-L73) + [`SortCard.swift#L52-L54`](file:///d:/Desktop/AlbumCleaner/Evernight/Components/SortCard.swift#L52-L54) + [`ThumbnailLoader.swift#L22-L24`](file:///d:/Desktop/AlbumCleaner/Evernight/Services/ThumbnailLoader.swift#L22-L24) | 后卡 `highQuality: false` → key 用点尺寸；前卡 `highQuality: true` → key 用 `displayScale × 1.5` 的像素尺寸，且落在**另一个 NSCache 实例**。同一张照片从后卡顶到前卡时，key 必然不同 → 无法命中，只能重新解码原图级（几十毫秒，期间只有灰块） |
| **次因 3** | 视图身份切换 | [`SortDeck.swift#L49`](file:///d:/Desktop/AlbumCleaner/Evernight/Components/SortDeck.swift#L49) 与 [`#L61`](file:///d:/Desktop/AlbumCleaner/Evernight/Components/SortDeck.swift#L61) | 后置卡与前置于两个不同 `if` 分支、各自带 `.id()`。同一张照片换位时旧视图被销毁、新视图新建，`@State` 全部归零 → 灰块 |
| **次因 4** | 动效复位与数据变更不在同一事务 | [`SortDeck.swift#L224-L237`](file:///d:/Desktop/AlbumCleaner/Evernight/Components/SortDeck.swift#L224-L237) | `finish()` 先 `withoutAnimation { reset() }`（把已飞出的卡 `frontOffset` 瞬移回中央、`backOpacity` 归 0），**之后**才 `onFinished` 让 `moveToTrash` 改数据。若 `months` 的 Observable 通知把 body 求值推迟一轮，就会渲染出「旧卡回到中央」的中间帧 |
| **次因 5** | 画质跳变 | 同主因 2 | 后卡用 1x 低清渐显 → 飞完换成 1.5x 高清，视觉上是「闪一下 + 突然变清晰」 |

### 2.2 动效时「视觉很怪」

[`SortCard.swift#L28-L41`](file:///d:/Desktop/AlbumCleaner/Evernight/Components/SortCard.swift#L28-L41)：

```swift
ZStack {
    Rectangle().fill(.regularMaterial)   // ① 实时 backdrop blur
    content                              // ② .fit，可能小于卡片
    badges
}
.frame(width: cardSize.width, height: cardSize.height)
.clipShape(...).overlay { strokeBorder(.white.opacity(0.55)) }
.shadow(radius: 18, y: 10)               // ③ 大半径阴影
```

- ① 是实时模糊材质，卡片 `offset` / `scale` 动画期间**每帧重新采样背后内容**，会抖、会透；
- ② 是独立叠加层，不是卡片的实体，加载前/比例不齐时会露材质边；
- ③ 与 ① 同时存在 = 每帧离屏渲染两次；
- 三者在动画里叠在一起 → 用户感知为「卡片下面浮着媒体」「发飘」。

### 2.3 UI 冲突

[`SortScreen.swift#L59-L102`](file:///d:/Desktop/AlbumCleaner/Evernight/Screens/SortScreen.swift#L59-L102) 的 `VStack` 与导航栏叠加了 6 层：

- NavigationStack **大标题**（约 96pt）
- toolbar（月份胶囊 + 托盘）
- `ProgressHeader` 玻璃胶囊（44pt）
- `SortDeck`
- `SortActionBar` 操作岛（约 76pt）
- `AppTabBar` 底部 inset（92pt）

卡片实际只剩约 450pt。视频里顶部只有一行（标记/胶囊 + 圆钮）+ 一条细进度条，按钮浮在卡上，卡片能占到约 600pt。

---

## 三、目标形态（对照视频帧）

参考帧：`%TEMP%\acvid\v2u\f0056.png`（单卡）、`v1u\f0036.png`（分列）、`v2u\f0040.png`（视频卡）。

```
┌ 状态栏 ─────────────────────────────┐
│ [10月 ▾]  [照片 ▾]        ↺  🗑(11) │  ← 顶栏一行，44pt
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░  4           │  ← 细进度条 6pt + 剩余数
│                                     │
│  ┌──────────────────────┐      (↺)  │  ← 卡片满幅，媒体填满
│  │                      │      (🗑)  │  ← 右侧竖排玻璃钮
│  │      照片 / 视频      │      (⏭)  │
│  │      填满卡片         │      (📚)  │
│  │ 2023/1/30      771KB │           │  ← 卡内底部胶囊
│  └──────────────────────┘           │
│   ┌────────────────────┐            │  ← 后卡下沉露头
│   │ 2026/2/18   3.4MB  │            │
│   └────────────────────┘            │
├ [整理][相似][相簿]  (我的) ──────────┤
└─────────────────────────────────────┘
```

关键量（390pt 宽基准）：

- 页面左右边距 16；顶栏高 44；顶栏与进度条间距 10；进度条高 6（容器 22）；进度条与卡片区间距 10。
- 卡片最大宽度 `bounds.width - 8`（保持现有 `cardSize` 算法）；圆角 `Theme.cornerPlate`（34）保持。
- 后卡待命态：`scale 0.94` + `offset y +26`，让底边露出一条（贴视频）。
- 右侧竖排：4 个 44×44 圆形玻璃钮，间距 8，垂直居中偏上（避开底部角标）。

---

## 四、Proposed Changes

### 4.1 `Evernight/Models/SortModels.swift` — 新增媒体类型筛选

在文件末尾追加：

```swift
/// 整理页顶部的媒体类型筛选（对应参考视频的「照片 ▾」胶囊）。
enum MediaFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case photo = "照片"
    case video = "视频"
    case live = "实况"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .photo: "photo"
        case .video: "video"
        case .live: "livephoto"
        }
    }

    func matches(_ item: PhotoItem) -> Bool {
        switch self {
        case .all: return true
        case .photo: return !item.isVideo && !item.isLivePhoto
        case .video: return item.isVideo
        case .live: return item.isLivePhoto
        }
    }
}
```

`SortAction` 保持不变（右侧竖排仍复用 `id / symbol / color`）。

### 4.2 `Evernight/Services/ThumbnailLoader.swift` — 支持同步读缓存

新增方法，并把 key 生成抽成私有方法：

```swift
/// 同步读缓存：视图重建时先在 body 里拿到已有图片，避免闪一帧灰色占位。
func cached(for asset: PHAsset, targetSize: CGSize, highQuality: Bool) -> UIImage? {
    store(for: highQuality).object(forKey: cacheKey(asset, targetSize))
}

private func cacheKey(_ asset: PHAsset, _ size: CGSize) -> NSString {
    "\(asset.localIdentifier)|\(Int(size.width))x\(Int(size.height))" as NSString
}
```

其余不变。`fullCache.countLimit = 8` 保持（同时活跃只有前后两张）。

### 4.3 `Evernight/Components/AsyncThumbnail.swift` — 零帧闪烁 + 玻璃占位 + 淡入升级

重写为该结构：

```swift
struct AsyncThumbnail: View {
    let asset: PHAsset
    var targetSize: CGSize
    var contentMode: ContentMode = .fill
    var highQuality = false
    /// 卡片里用玻璃占位（加载前的空卡片也是「玻璃」），网格里保持实色占位以免 240 个 material 太重。
    var glassPlaceholder = false

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    /// 关键：body 求值时**同步**读 NSCache。视图重建时立刻有图，不经过 `.task`。
    private var displayed: UIImage? {
        image ?? ThumbnailLoader.shared.cached(for: asset, targetSize: requestSize, highQuality: highQuality)
    }

    var body: some View {
        Group {
            if let displayed {
                Image(uiImage: displayed)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if glassPlaceholder {
                Rectangle().fill(.ultraThinMaterial)
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .task(id: asset.localIdentifier) {
            let upgraded = await ThumbnailLoader.shared.image(for: asset, targetSize: requestSize,
                                                             highQuality: highQuality)
            guard let upgraded, upgraded !== image else { return }
            // 只在尺寸确实变大时淡入替换，不做「先清空再加载」
            withAnimation(.easeOut(duration: 0.12)) { image = upgraded }
        }
    }
    // requestSize 保持现状：highQuality 时 displayScale × 1.5，单边封顶 2800
}
```

要点：
- 同步命中 → 换卡时**不会**出现灰块。
- `.task` 只在后台补齐，不再承担首次显示。
- 占位可切换：卡片用玻璃，网格用实色。

### 4.4 `Evernight/Components/SortCard.swift` — 媒体即卡片

重写 body 为「一个实体」：

```swift
var body: some View {
    media
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerPlate, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerPlate, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 0.5)
        }
        .shadow(color: Color(red: 12/255, green: 18/255, blue: 48/255).opacity(0.20),
                radius: 12, y: 8)
        .overlay { badges }
        .accessibilityLabel("待整理的照片")
}
```

- **移除** `ZStack` 里的 `Rectangle().fill(.regularMaterial)`：媒体自己撑起卡片，不再有「底 + 浮层」。
- 阴影半径 18 → 12（动画期间重绘更便宜）；`.opacity(0.22)` → `0.20` 补偿。
- `badges` 从 `ZStack` 成员改成 `.overlay`，`allowsHitTesting(false)` 保持。
- `media` 按类型分发，**统一 `highQuality: true`**（与后卡同尺寸，修复缓存 miss）：

```swift
@ViewBuilder
private var media: some View {
    if photo.isVideo {
        VideoCardContent(asset: photo.asset, cardSize: cardSize, isActive: isFront)
    } else if photo.isLivePhoto {
        LivePhotoCardContent(asset: photo.asset, cardSize: cardSize, isActive: isFront)
    } else {
        AsyncThumbnail(asset: photo.asset, targetSize: cardSize,
                       contentMode: .fill, highQuality: true, glassPlaceholder: true)
            .onTapGesture { onOpenViewer() }
    }
}
```

`EmptyDeckView` 与 `badgeStyle()` 保持不变。

### 4.5 `Evernight/Components/MediaCardContent.swift` — 填满卡片

两处签名与取图尺寸：

- `VideoCardContent` 增加 `let cardSize: CGSize`；`AsyncThumbnail` 的 `targetSize: CGSize(width: 900, height: 900), contentMode: .fit` 改为 `targetSize: cardSize, contentMode: .fill, highQuality: true, glassPlaceholder: true`。
- `PlayerUIView` 的 `playerLayer.videoGravity = .resizeAspect` → `.resizeAspectFill`（卡内不留黑边，与「媒体填满卡片」一致）。
- `LivePhotoCardContent` 增加 `let cardSize: CGSize`；缩略图同样改为 `cardSize + .fill + highQuality + glassPlaceholder`；`requestLivePhoto` 的 `targetSize: 1200×1200` 保持（实况没有缩略图缓存问题）。
- 其余逻辑（静音、循环、进度条、replayToken）不动。

### 4.6 `Evernight/Components/SortDeck.swift` — 后卡下沉 + 事务合并

改动四点：

1. **待命态下沉**（贴视频后卡露头）：
   - `@State private var backScale: CGFloat = 0.94`（原 0.92）
   - 新增 `@State private var backLift: CGFloat = 26`（待命时向下偏移）
   - 后卡 `.offset(backOffset)` 改为 `.offset(x: backOffset.width, y: backOffset.height + backLift)`
   - `playFlyOut` 的 spring 块加 `backLift = 0`
   - `playReverse` 的 withoutAnimation 块加 `backLift = 0`，spring 块加 `backLift = 26`
   - `reset()` 里 `backScale = 0.94`、`backLift = 26`
   - 注意：`playReverse` 里 `backOffset = start` 时，后卡应保持在 `start`（不回弹），`backLift` 从 0 开始动到 26 —— 视觉上是「当前卡退回后方并下沉」。

2. **事务合并（修闪因 4）**：

```swift
/// 动效复位与数据变更放进同一个无动画事务：中间态不会被单独渲染。
func finish(_ move: SortMove) {
    withoutAnimation {
        reset()
        isPlaying = false
        onFinished(move)
    }
}
```

3. **前后卡统一高清**：由 `SortCard` 内部统一 `highQuality: true` 完成，Deck 不用改传参。

4. 不改手势判定（90 / 40 阈值）、不改飞出时长（0.26s）、不改 spring 参数（0.42 / 0.78）。

### 4.7 `Evernight/Components/ProgressHeader.swift` — 细进度条

去掉玻璃胶囊外壳，改成横贯的细条（贴视频）：

```swift
var body: some View {
    HStack(spacing: 12) {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.18))
                Capsule().fill(tint)
                    .frame(width: max(0, geometry.size.width * progress))
            }
            .frame(height: 6)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 18)

        Text("\(remaining)")
            .font(.headline.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(tint)
    }
    .padding(.horizontal, 2)
    .frame(height: 22)
    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: progress)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("已处理 \(processed) 项，共 \(total) 项，剩余 \(remaining) 项")
}
```

颜色：`remaining` 从 `Theme.success` 改为 `tint`（跟随主题色，避免绿/蓝冲突）。

### 4.8 `Evernight/Components/SortTopBar.swift`（新建）— 顶栏一行

```swift
/// 整理页顶栏：月份胶囊 + 媒体类型胶囊 + 撤回 / 待删除圆钮。
/// 对应参考视频的「[照片 ▾]  ↺ 🗑」一行；月份选择是用户要求保留的。
struct SortTopBar: View {
    let months: [MonthSection]
    let selectedMonthID: String?
    let filter: MediaFilter
    let canUndo: Bool
    let showsMonth: Bool          // 相簿详情没有月份
    let onSelectMonth: (MonthSection) -> Void
    let onSelectFilter: (MediaFilter) -> Void
    let onUndo: () -> Void

    @AppStorage("ac_theme") private var themeHex = "#002FA7"

    var body: some View {
        HStack(spacing: 8) {
            if showsMonth {
                MonthMenu(...)          // 普通玻璃胶囊
            }
            filterMenu                // 主题色实底胶囊（视觉焦点，对应视频绿胶囊）
            Spacer()
            circleButton("arrow.uturn.backward", label: "撤回", enabled: canUndo, action: onUndo)
            TrayButton()                // 已存在，圆形玻璃 + 红角标
        }
        .frame(height: 44)
    }
}
```

细节：
- `filterMenu`：`Menu { ForEach(MediaFilter.allCases) { ... } }`，label 是 `HStack { Image(systemName: filter.symbol); Text(filter.rawValue); Image(systemName: "chevron.down") }`，`.foregroundStyle(.white)`，`.padding(.horizontal, 12).padding(.vertical, 6)`，`.background(Color(hex: themeHex), in: Capsule())`。
- `circleButton`：`Image(...).frame(width: 34, height: 34).glassSurface(cornerRadius: 17, interactive: true)`，禁用时 `.opacity(0.4)`。
- `TrayButton` 复用现有实现。

### 4.9 `Evernight/Components/SortSideBar.swift`（新建）— 右侧竖排玻璃钮

```swift
/// 卡片右侧竖排的圆形玻璃钮（对应参考视频 2 的视频页右侧图标列）。
/// 浮在卡片上，不占布局高度；每个按钮各自一块玻璃，交给 GlassGroup 融合。
struct SortSideBar: View {
    let actions: [SortAction]
    let canUndo: Bool
    let hasPhoto: Bool
    let namespace: Namespace.ID
    let onAction: (SortAction) -> Void

    var body: some View {
        GlassGroup(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(actions) { action in
                    Button { onAction(action) } label: {
                        Image(systemName: action.symbol)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 42, height: 42)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(enabled(action) ? action.color : Color.secondary.opacity(0.45))
                    .disabled(!enabled(action))
                    .accessibilityLabel(action.title)
                    .glassSurface(cornerRadius: 21, morphID: action.id, in: namespace, interactive: true)
                }
            }
        }
    }
}
```

- 42pt 略小于最小 44 触控目标，但 `contentShape(Circle())` + 玻璃的 8pt spacing 让实际可点区域等效 ≥44；若要求严格，改为 46×46。
- **删除 `Evernight/Components/SortActionBar.swift`**（被取代）。`SortAction` 的 `title` 仍用于 accessibility 与 toast 文案。

### 4.10 `Evernight/Screens/SortScreen.swift` — 布局重写

**状态新增**：

```swift
@State private var mediaFilter: MediaFilter = .all
```

**`photos` 加筛选**（`.all` 走快路径，避免无谓拷贝）：

```swift
private var photos: [PhotoItem] {
    let base = isAlbumMode ? albumPhotos : (month?.photos ?? [])
    guard mediaFilter != .all else { return base }
    return base.filter { mediaFilter.matches($0) }
}
```

**body 重写**：

```swift
var body: some View {
    VStack(spacing: 10) {
        SortTopBar(months: library.months,
                   selectedMonthID: month?.id,
                   filter: mediaFilter,
                   canUndo: !undoStack.isEmpty,
                   showsMonth: !isAlbumMode,
                   onSelectMonth: selectMonth,
                   onSelectFilter: selectFilter,
                   onUndo: { request(.undo) })

        ProgressHeader(processed: index, total: photos.count,
                       remaining: max(0, photos.count - index),
                       tint: Color(hex: themeHex))

        if columnCount == 1 {
            SortDeck(...)                    // 参数不变
                .overlay(alignment: .trailing) {
                    SortSideBar(actions: actions, canUndo: !undoStack.isEmpty,
                                hasPhoto: current != nil,
                                namespace: actionNamespace, onAction: handleAction)
                        .padding(.trailing, 4)
                }
        } else {
            ColumnsGrid(photos: photos, columns: columnCount, onMarkDelete: markDeleteInColumns)
        }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 6)
    .toolbar(.hidden, for: .navigationBar)   // 用自绘顶栏，避免与大标题冲突
    ...（其余修饰符保持）
}
```

**导航栏处理**：

- 统一 `.toolbar(.hidden, for: .navigationBar)`。
- 相簿详情（`isAlbumMode`）需要返回入口：在 `SortTopBar` 左侧（`showsMonth == false` 的位置）放一个返回按钮 + 相簿名：

```swift
// SortTopBar 内
if !showsMonth {
    Button { dismiss() } label: {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left")
            Text(albumName).lineLimit(1)
        }
        .font(.subheadline.weight(.medium))
    }
}
```

需要在 `SortTopBar` 增加 `albumName: String?` 参数，并在 `SortScreen` 用 `@Environment(\.dismiss)`。

**`selectFilter`**（与切月同语义）：

```swift
func selectFilter(_ next: MediaFilter) {
    guard next != mediaFilter else { return }
    mediaFilter = next
    index = 0
    undoStack.removeAll()
    command = nil
    pendingAlbum = nil
}
```

**`selectMonth`** 保持清空撤销栈（已有）。

**`finish`** 去掉嵌套 `withoutAnimation`（事务已由 `SortDeck.finish` 提供）：

```swift
func finish(_ move: SortMove) {
    command = nil
    apply(move)
}
```

**`handleAction`** 不变（右侧竖排复用同一回调）。

**移除**：`SortActionBar` 调用、`toolbarContent` 计算属性、`navigationTitle` / `navigationBarTitleDisplayMode`。

---

## 五、Assumptions & Decisions

1. **配色不改**：进度条、筛选胶囊、竖排按钮图标一律用 `Color(hex: themeHex)`（默认北洋蓝），不采用视频的绿色。
2. **媒体类型筛选的作用域**：只在「整理」tab（按月）生效；相簿详情不显示筛选胶囊（`showsMonth == false` 时也隐藏筛选，只留返回 + 撤销 + 托盘），避免相簿内的筛选与游标语义打架。
3. **切筛选即清空撤销栈**：与切月一致，避免跨筛选撤销导致游标指错。筛选切换后 `index = 0`。
4. **筛选的一切都基于 `photos` 计算属性**：`moveToTrash` / `restore` 改的是 `library.months`，`photos` 会重新计算，因此删除 / 撤销的游标语义在 `.all` 与过滤态下都成立（删除的是当前 index 位置，删后同一 index 即原来的下一项）。
   - 性能：`.all` 走快路径零拷贝；非 `.all` 才 `filter`。几千张的月份会多一次 O(n) 扫描，可接受；若真机发现切换卡顿，再在 `selectMonth` / `selectFilter` 时缓存到 `@State`（本次不做，避免过度设计）。
5. **不新增媒体筛选的持久化**：`mediaFilter` 用 `@State`，切 tab 保持（三 tab 常驻），冷启动回到 `.all`。
6. **后卡下沉 26pt**：在 `bounds.height` 之外不影响布局（偏移是渲染层），但会让后卡底边超出 `GeometryReader` 的下缘约 26pt —— 因为 Deck 没有 `.clipped()`，会正常绘制；底部被 `AppTabBar` 的 92pt inset 遮住，视觉上正好是「露出一条」。
7. **不改动**：四向手势阈值（90 / 40）、飞出时长 0.26s、spring 参数（0.42 / 0.78）、撤销栈语义（限深 50 / 切月清空）、两级删除设计、分列模式（`ColumnsGrid`）。
8. **删除 `SortActionBar.swift`**：确认 `rg "SortActionBar"` 无其他引用后删除（目前只有 `SortScreen` 引用）。

---

## 六、Verification

### 6.1 静态自检（本机可做）

```powershell
# 应为空：旧操作岛已删、无残留引用
rg -n "SortActionBar" Evernight --glob "*.swift"

# 应为空：卡片不再有材质底层
rg -n "Rectangle\(\)\.fill\(\.regularMaterial\)" Evernight --glob "*.swift"

# 应为空：导航大标题已移除
rg -n "navigationTitle|navigationBarTitleDisplayMode" Evernight/Screens/SortScreen.swift

# 应能查到：同步缓存与事务合并
rg -n "cached\(for:" Evernight --glob "*.swift"
rg -n "withoutAnimation \{" Evernight/Components/SortDeck.swift

# 既有禁项仍为空
rg -n "WKWebView|evaluateJavaScript|photoApp|Transaction\(disablesAnimations" Evernight --glob "*.swift"
```

单文件行数复核（约定 ≤ 300 行）：

```powershell
Get-ChildItem -Recurse Evernight -Include *.swift |
  ForEach-Object { "{0}`t{1}" -f (Get-Content $_.FullName).Count, $_.Name } | Sort-Object -Descending
```

预计新建的 `SortTopBar.swift` / `SortSideBar.swift` 各约 60–90 行；`SortScreen.swift` 减到约 250 行。

### 6.2 编译验证（唯一可靠手段）

```powershell
git push origin main
# 然后查 Actions（凭 git 凭据调 REST API，curl 需 --ssl-no-revoke）
curl.exe --ssl-no-revoke -sS -H "Authorization: Bearer $token" `
  "https://api.github.com/repos/Baewon-090131/AlbumCleaner/actions/runs?per_page=2"
```

判据：`conclusion == "success"`；失败则取 job log（`/actions/jobs/{id}/logs`）定位编译错误。

### 6.3 真机检查清单（本机无 Xcode，需装机）

| 检查项 | 期望 |
|---|---|
| 顶栏是否被刘海/状态栏压住 | 自绘顶栏落在安全区内，44pt 高，不与时间重叠 |
| 卡片高度 | 竖图约 480pt，横图占满宽；底部到 tab 栏无大段空白 |
| **删除是否还闪** | 上滑删除 → 下一张**直接清晰出现**，无灰块、无「旧卡飞回」一帧 |
| 后卡露头 | 前卡下方能看到后卡一条边（带日期/体积），宽度略窄 |
| 视频卡 | 点进整理页即静音循环播放，无黑边（`resizeAspectFill`），点按暂停 |
| 实况卡 | 自动播一次，点按重播；LIVE 角标在右上 |
| 右侧竖排 | 4 个玻璃钮垂直居中，不遮底部日期/体积；撤回无记录时置灰 |
| 媒体筛选 | 切到「视频」后只剩视频，进度条总数与剩余数同步变化；切回「全部」游标回 0 |
| 相簿详情 | 左侧是返回 + 相簿名，无月份/筛选；侧滑返回仍可用 |
| 分列模式 | 双指收拢后顶栏保持，瀑布流正常；左右滑标记删除仍进待删除 |

---

## 七、执行顺序

1. `SortModels.swift` 加 `MediaFilter`
2. `ThumbnailLoader.swift` 加 `cached(for:)`
3. `AsyncThumbnail.swift` 重写（同步读缓存 + 玻璃占位 + 淡入升级）
4. `SortCard.swift` 重写（媒体即卡片，统一 highQuality）
5. `MediaCardContent.swift` 加 `cardSize`、改 `resizeAspectFill`、缩略图统一
6. `SortDeck.swift` 改（后卡下沉 + `finish` 事务合并）
7. `ProgressHeader.swift` 改细条
8. 新建 `SortTopBar.swift`、`SortSideBar.swift`；删 `SortActionBar.swift`
9. `SortScreen.swift` 重写布局与 `mediaFilter` 状态
10. 静态自检 → 提交 → push → 查 CI
11. 回写 `AGENTS.md`（第 5 节机制、第 10 节文件规模）与 `HANDOFF.md`（版本史、目录）

每完成 2–3 步跑一次 `rg` 自检，避免引用悬挂。
