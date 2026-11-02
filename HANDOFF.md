# HANDOFF · Evernight（Album Cleaner）

> 交接文档，给下一个接手这个项目的智能体或人。
> **先读这一份，再读 `AGENTS.md`（长期记忆，含设计令牌与历史沿革）。**
> 生成时间：2026-10-09 · 最近更新：2026-11-02（v0.1：更名 evernight + 移植「卡待删」能力——底栏 3+1、我的 sheet、卡内播放、分列删除、待删除结算页、相似页 pHash、相簿管理）

---

## 0. 三十秒了解

iOS 相册整理应用，交互参考 Slidebox 与「卡待删」。**SwiftUI 原生，纯本地，不联网**。
底栏四格：整理 / 相似 / 相簿收在玻璃胶囊里，「我的」是独立圆钮（点按从底部上滑覆盖）。
整理页四向滑动手势（上滑删除 / 左滑下一张 / 右滑撤回 / 下滑收藏）+ 双指收拢进分列瀑布流（左右滑直删）。

| 项 | 值 |
| --- | --- |
| 仓库 | `https://github.com/Baewon-090131/AlbumCleaner`（私有） |
| 分支 | `main` |
| 最新提交 | v0.1 移植「卡待删」能力（本次改动，hash 见 `git log -1`；上一条是整理页撤回与滑动分拣动效） |
| 版本 / 构建号 | 0.1 / 14（`project.yml`）；显示名 `evernight` |
| 最低系统 | iOS 17.0（`@Observable`、`ContentUnavailableView` 要求） |
| 构建 | GitHub Actions（macos-latest）出 IPA artifact |

---

## 1. 接手前必须知道的三件事

### 1.1 UI 是 v4.0 才从网页改成 SwiftUI 的

`Evernight/WebContent/` 是 v3 的 React 实现，**还在仓库里，但不参与构建**（`project.yml` 已移除引用）。
改 UI 一律改 `Evernight/` 下的 `.swift`，不要碰 WebContent——它只作设计基线与对照。

### 1.2 编译已通过，运行完全未验证

开发机是 **Windows，没有 Xcode / Swift 工具链 / iOS 模拟器，本地编译不了**。
但 CI 已经证明这份代码能编译：提交 `d745eb3`（v4.0.1）的 run **37791036942 结论 success**，
产出了 `AlbumCleaner-ipa`（1.95 MB）。也就是说 Swift 语法没问题，
`glassEffect` / `GlassEffectContainer` / `.glass` 这些 iOS 26 API 也能编过——runner 的 Xcode 版本够新。

**没验证的是运行时行为**：装到真机或模拟器里跑起来什么样、Liquid Glass 实际渲染成什么样、
Photos 权限弹窗流程顺不顺、卡片手势跟不跟手——这些一次都没看过。第一次装机要重点看这几处。

### 1.3 怎么查 CI 状态

```powershell
# 借用本地 git 凭据调 GitHub API（token 不会被打印出来）
$cred = "protocol=https`nhost=github.com`n" | git credential fill 2>$null
$token = ($cred | Select-String '^password=' | Select-Object -First 1) -replace '^password=',''
curl.exe --ssl-no-revoke -sS -H "Authorization: Bearer $token" `
  "https://api.github.com/repos/Baewon-090131/AlbumCleaner/actions/runs?per_page=5"
```

两个坑：`curl` 必须带 `--ssl-no-revoke`（Windows 的 TLS 吊销检查会掐断连接）；
仓库是私有的，不带 token 匿名访问 API 一律 404。

---

## 2. 立刻该做的事（按优先级）

| 优先级 | 事项 | 备注 |
| --- | --- | --- |
| P0 | **真机 / 模拟器跑一次** | 编译已过（v4.0.1），但运行时行为全是空白：Liquid Glass 渲染、权限流程、手势、卡内播放、分列、相似扫描都要现场看 |
| P2 | 深色模式 | 当前一律浅色壁纸 |
| P2 | 清理 v3 遗留 | `WebContent/`、`compile-jsx.js`、`package.json` 都无用途了，确认后删 |
| 已做 | v0.1「卡待删」移植 | 2026-11-02：底栏 3+1、我的 sheet、卡内播放（AVPlayer/PHLivePhotoView）、原图画质、分列删除、待删除结算页、相似页 pHash、相簿管理（见 AGENTS.md 第 5 节） |
| 已做 | 视频 / Live Photo 播放 | v0.1 已接：卡内直接播，不再「点一下开新页面」 |
| 已做 | 版本号显示 | v0.1：MineScreen 与 project.yml 已对齐（0.1 / 14） |
| 已做 | 统计计数 | v0.1：累计已清理 / 释放落账 UserDefaults，已喜欢 / 待清理真实计数 |
| 已做 | 整理页撤回 + 滑动分拣动效 | 2026-10-15：通用撤销栈（限深 50、切月清空）；手势与按钮统一动效通道；下一张渐显入场 |
| 已做 | 相簿页 / 回收站网格排列 | 2026-10-14 统一为 iOS 原生相册式 |

---

## 3. 代码结构（v0.1）

```
Evernight/
  EvernightApp.swift             86   入口 + 权限门（RootView）+ 全局 UIState
  Info.plist                     52   权限文案、启动屏、方向（显示名 evernight）
  Models/
    LibraryModels.swift           74   PhotoItem / MonthSection / AlbumItem / StorageInfo / Format
    SortModels.swift              84   SortMove / DeckCommand / UndoRecord / SortAction
  Services/
    PhotoLibraryService.swift   346   @Observable 数据源：权限、按月分组、相簿增删改、待删除、写入、战果
    SimilarityService.swift     221   相似检测：dHash 指纹 + 分桶候选 + 并查集（指纹存 UserDefaults）
    ThumbnailLoader.swift        55   缩略图异步加载 + 双 NSCache（大卡原图级独立缓存）
  Design/
    Theme.swift                  57   颜色 / 圆角令牌 + 壁纸 + Color(hex:)
    GlassSurface.swift          109   Liquid Glass 入口（GlassGroup / glassSurface / glassButtonStyle）+ ContentPanel
  Components/
    SortDeck.swift              248   卡片区：跟手 / 飞出 / 下一张渐显入场 / 撤回倒放（动效编排）
    MediaCardContent.swift      248   视频卡（AVPlayerLayer 静音循环）+ 实况卡（PHLivePhotoView）
    SortCard.swift              111   单张卡片视觉 + 空态 + badgeStyle
    ColumnsGrid.swift            89   分列瀑布流 + 横向滑删
    AppTabBar.swift              65   底栏 3+1（胶囊 + 我的圆钮）
    SortActionBar.swift          63   底部操作岛（GlassEffectContainer）
    SimilarGroupCard.swift       97   相似页的一组卡片
    ProgressHeader.swift         46   整理页进度胶囊
    AsyncThumbnail.swift         39   缩略图视图（highQuality 开关）
    MonthMenu.swift              32   月份切换胶囊（系统 Menu）
    TrayButton.swift             30   待删除托盘（垃圾桶 + 红角标）
    ToastBanner.swift            17   临时提示
  Screens/
    SortScreen.swift            298   整理页（相簿详情复用）+ 撤销栈 + 分列模式 + 动作
    AlbumsScreen.swift          291   相簿管理：空相簿横幅 / 新建 / 排序 / 长按菜单
    MineScreen.swift            283   我的面板（sheet）：深色统计卡 + 设置
    SimilarScreen.swift         214   相似页：年份筛选 + 智能清理 + 分组列表
    TrashScreen.swift           166   待删除（结算页：全选 / 勾选 / 红色删除条）+ 全屏查看
    MainTabView.swift           100   自定义底栏 + 我的 sheet + 待删除 fullScreenCover
    FavoritesScreen.swift        51   已喜欢网格
  WebContent/                        v3 网页实现，不参与构建
project.yml                      47   xcodegen 配置（0.1 / 构建号 14）
```

**用到的系统控件**（这就是"原生化"的实质）：
`NavigationStack`（大标题 + 工具栏）、`Menu`（月份 / 排序）、`Toggle`、`Slider`、
`List(.insetGrouped)`、`ProgressView`、`ContentUnavailableView`、
`confirmationDialog`（相簿与待删除操作）、`fullScreenCover`（待删除 / 全屏看图 / 已喜欢）、
`contextMenu`（相簿长按）。**v0.1 起底栏不再用系统 `TabView`**，媒体播放用
`UIViewRepresentable` 包 `AVPlayerLayer` / `PHLivePhotoView`。

---

## 4. 数据流

单一数据源：`PhotoLibraryService`（`@Observable` + `@MainActor`），在 `RootView` 用 `@State` 持有，
往下用 `.environment(library)` 传。视图不自己存 PHAsset 列表副本。

| 界面动作 | 落到哪里 |
| --- | --- |
| 上滑删除 / 分列滑删 | `moveToTrash` → 只进应用内「待删除」，**不动系统相册** |
| 待删除「彻底删除」 | `deleteFromSystem`（返 Bool）→ 成功后未勾选项放回相册；落账累计战果 |
| 下滑收藏 | `setFavorite` → `PHAssetChangeRequest.isFavorite` |
| 操作岛「相簿」 | 原生 `confirmationDialog` 列相簿 → `add(_:to:)` |
| 撤回（按钮 / 右滑 / 分列顶栏） | 按撤销栈顶记录倒做：删除 → `restore` 按创建日期插回原位；下一张 → 游标退一张；收藏 → `setFavorite(false)`；存入相簿 → `remove(_:from:)` |
| 手势与按钮触发动效 | 都写 `SortScreen.command`（`DeckCommand`，带 token）→ `SortDeck.onChange` 播放 → 播完回调 `onFinished` 才改数据 |
| 视频 / 实况卡内播放 | `MediaCardContent` → `requestAVAsset` / `requestLivePhoto` |
| 相似分组 | `SimilarityService.scan` → dHash 指纹 → 分桶 + 并查集 → 删除走 `moveToTrash` |
| 相簿管理 | `createAlbum` / `renameAlbum` / `deleteAlbums` / `deleteAlbumWithPhotos` / `moveAllPhotos` → 直写系统相册 |
| 待删除 / 我的弹出 | `TrayButton` / 底栏圆钮 → `UIState.showTrash` / `showMine` → `MainTabView` 弹出 |
| 缩略图 | `ThumbnailLoader` → `PHCachingImageManager.requestImage`，按 `identifier\|size` 缓存 |
| 存储占用 | `readStorage` → volumeTotalCapacity / volumeAvailableCapacityForImportantUsage |
| 主题色 | `@AppStorage("ac_theme")` + `Color(hex:)`，`MainTabView` 用 `.tint` 应用 |

**注意：删除是两级的。** 手势 / 分列删除只进应用内「待删除」；只有待删除里的「彻底删除」才真的从系统相册删。
这是刻意设计，别改。

---

## 5. 踩过的坑（照做能省几小时）

### 5.1 Liquid Glass 不要叠玻璃

第一版把操作岛写成「一层玻璃外框 + 里面 4 个 `.ultraThinMaterial` 方块」，这是错的：
HIG 明确说 Liquid Glass 只用于浮在内容之上的功能层，玻璃叠玻璃会让文字对比度塌掉。

正确做法（v4.0.1 已改成这样）：

- 每个按钮各自一块玻璃，用 `GlassGroup`（`GlassEffectContainer`）包住，相邻形状会**自己融合**成一整条岛；
- 不要再套外框；
- 会变形的玻璃用 `glassSurface(cornerRadius:morphID:in:)`，同一个 `@Namespace` 下相同 id 会平滑变形；
- 可点的地方加 `.interactive()`，静态容器（加载页、进度条）不加；
- 内容层（卡片、分组、网格）**继续用 `ContentPanel` 的材质**，不要改成 Liquid Glass。

### 5.2 相簿照片别写成计算属性

`SortScreen` 里 `photos` 如果是 `library.photos(in: album)` 直接调用，**每次重绘都会遍历整个相簿**。
正确做法：存在 `@State albumPhotos` 里，只在 `.task(id: album?.id)` 拉一次。

### 5.3 无头 Chrome 的小窗口会骗人

`--window-size` 小于约 500×760 时 Chrome 会强制放大，截图看起来像"布局溢出视口"。
用 `Previews/_shot.html`（iframe 390×844 + zoom 2 + 注入 safe-area）绕过，窗口给 780×1688。

### 5.4 网络：TLS 吊销检查会拦 curl / git

这台机器的代理不稳定。`curl` 报 `CRYPT_E_NO_REVOCATION_CHECK` 时加 `--ssl-no-revoke` 就能通。
`git push` 报 `Recv failure: Connection was reset` 是代理没开，不是仓库问题。

### 5.5 README.md 已经过时

`README.md` 仍然写着"使用 WKWebView 内嵌网页实现"，那是 v3 的描述。**以本文件和 `AGENTS.md` 为准。**

### 5.6 网格排列：别直接给缩略图套 aspectRatio

`AsyncThumbnail` 内部是 `.aspectRatio(contentMode: .fill)` 的 `Image`，尺寸会随图片比例浮动。
再给它套一层 `.aspectRatio(1, contentMode: .fill)` 并不保证正方形——没有确定的尺寸底时，
`LazyVGrid` 排出来的格子会高矮不齐。回收站原来的「乱」就是这么来的。

正确做法：拿形状当底（`Rectangle().fill(.quaternary)`），`.aspectRatio(1, contentMode: .fill)` 让它撑满列宽；
缩略图放进 `.overlay`，最后 `.clipShape` 统一裁圆角。相簿页与回收站现在都这么写。

### 5.7 整理页动效：动效先播，数据后改

手势和按钮**共用一条通道**，别让任何一条自己去改数据：

1. 手势在 `SortDeck` 里跟手并判定方向，松手只把结论交给外层（`onSwipe` 返回是否受理）；
2. 外层（按钮点击同理）写 `SortScreen.command = DeckCommand(token:move:incoming:reverseOf:)`——
   `token` 递增是为了让「同一个动作」也能被 `.onChange` 认出来；
3. `SortDeck.onChange(of: command)` 播放飞出 / 倒放；
4. 播完 `finish` 里**先归位动效状态**（`withoutAnimation { reset() }`），再回调 `onFinished`，
   `SortScreen` 这时才 `index += 1` / 压栈 / 写 Photos。

三步顺序不能换，否则会看到「新卡从屏外飞回来」或「旧卡拖着过渡重演」。
复位一律走 `withoutAnimation`：`Transaction(disablesAnimations:)` 这个初始化器**不存在**，
要 `var transaction = Transaction(); transaction.disablesAnimations = true` 再 `withTransaction`。

另外几个约定：`isPlaying` 期间不再受理新操作（`request` 直接返回 false）；
下滑收藏不飞出也不推进（40pt 判定后弹回原位）；撤回按 `UndoRecord.origin` 反着播——
当前卡从被拖到的位置退回后方 0.92 并渐隐，被撤那张从当初飞出去的方向飞回。

### 5.8 卡片区是双层，别把后方的卡省掉

`SortDeck` 同时渲染「前置卡 + 后置卡（0.92 缩放、待命时全透明）」。前卡飞出时后卡用
`spring(0.42, 0.78)` 从 0.92 放到 1.0 **并同步渐显**（缩放与透明度共用同一个 Spring）；撤回是这套的倒放
（缩回 0.92 并渐隐）。后置卡是新插入的视图时，
`AsyncThumbnail` 的占位会露一帧（`Rectangle().fill(.quaternary)`）——这是模型的固有代价，
换位时（前卡飞出、后卡顶上来）靠 `withoutAnimation` 让两层在同一帧交接，肉眼看不出来。

---

## 6. 版本号与自检

**改版本要动的地方**（v4.0 之后）：

1. `project.yml` 的 `MARKETING_VERSION`（4.0）与 `CURRENT_PROJECT_VERSION`（13，iOS 构建号必须递增）
2. `Evernight/Screens/MineScreen.swift` 的「关于」行与底部版本行
3. `package.json` 是网页版遗留，**不参与 App 版本**，可以不管

**静态自检**（应该全部为空或符合预期）：

```powershell
rg -n "WKWebView|evaluateJavaScript|photoApp" Evernight --glob "*.swift"   # 应为空：WebView 层已删
rg -n "WebContent" project.yml                                            # 应为空：网页资源不打包
```

**本地怎么编译**（需要 Mac）：

```bash
xcodegen generate
xcodebuild -scheme AlbumCleaner -sdk iphonesimulator build
```

本地没有 Mac 时不用干等——CI 已经在跑同一套 `xcodebuild`，push 上去看 Actions 就行（查法见 1.3）。

---

## 7. 版本史（知道个大概就行）

| 版本 | 提交 | 内容 |
| --- | --- | --- |
| v0.1 | 本次 | 更名 evernight（0.1 / 构建号 14）；移植「卡待删」能力：底栏 3+1 + 我的 sheet、卡内播放（视频 / 实况）、原图画质、分列删除（双指收拢 + 左右滑）、待删除结算页（未勾选项放回）、相似页 dHash pHash、相簿管理（空相簿 / 新建 / 长按菜单 / 排序）；新增 `AppTabBar` / `ColumnsGrid` / `MediaCardContent` / `TrayButton` / `SimilarScreen` / `SimilarityService` / `FavoritesScreen` / `SimilarGroupCard` |
| 整理页动效 | `fea71e8` | 撤回收敛为通用撤销栈（删除 / 下一张 / 收藏 / 存入相簿，限深 50、切月清空）；整理页手势与按钮统一为「滑动分拣」动效，撤回即整套倒放；`SortModels.swift` / `SortCard.swift` / `MonthMenu.swift` 拆出 |
| 网格统一 | `1631484` | 相簿页改 2 列正方形封面（名称 / 数量居中在下方，去掉卡片底）；回收站改 3 列 1:1 圆角 8（间距 3 / 边距 12）；整理页未动 |
| v4.0.1 | `d745eb3` | 按 Liquid Glass 规范重做玻璃层（GlassEffectContainer / interactive / morphing） |
| v4.0 | `d4cd8cc` | **UI 层从 WKWebView + React 整体改成 SwiftUI**，删除 4 个旧 Swift 文件，最低系统提到 iOS 17 |
| v3.0.1 | `0156ce2` | 网页版：开关 / 滑块 / 下拉改用原生表单元素 |
| v3.0 | `539b93b` | 网页版：三 tab 重构，目录改名 `Slidebox/` → `Evernight/` |
| v2.7 | `7f12987` | 版本号统一、技能移出仓库 |

`git log` 里的 `v2.6` 出现过两次、`v2.6.1` 夹在中间，别按版本号推断先后。

---

## 8. 环境与工具

| 项 | 情况 |
| --- | --- |
| 开发机 | Windows，**无 Xcode / Swift / iOS 模拟器** |
| 编译验证 | GitHub Actions（macos-latest）。`d745eb3` 已验证成功，产物 `AlbumCleaner-ipa` |
| CI 查询 | 见 1.3；`curl` 要带 `--ssl-no-revoke` |
| 网页版预览（v3，仅对照） | `node compile-jsx.js`，然后 `Previews/_shot.html?tab=sort\|albums\|mine` |
| 设计稿 | `Previews/Evernight-V3-UI.pptx`（7 页可编辑）+ `v3-shots/` |
| 网格改动预览 | `Previews/Evernight-Grid-Preview.pptx`（5 页可编辑，相簿 / 回收站方案，2026-10-14 已拍板；非 SwiftUI 渲染） |
| v0.1 功能移植预览 | `Previews/Evernight-V5-Feature-Preview.pptx`（11 页可编辑：底栏 3+1、我的 sheet、整理页托盘与画质、卡内播放、分列删除、待删除结算、相似页、相簿管理、我的统计卡、落地清单，2026-11-02 已拍板；生成脚本 `Previews/_v5-build/build.mjs`） |
| 整理页动效预览 | `Previews/Evernight-Sort-Motion-Preview.pptx`（8 页可编辑：滑动分拣关键帧、撤回倒放、语义与参数表，2026-10-15 已拍板；生成脚本 `Previews/_sort-build/build.mjs`） |
| v4 预览 | `Previews/v4-preview.png`（**注意：这是 HTML 画的示意图，不是 SwiftUI 渲染**） |
| 参考图 | 仓库根目录 `p1.jpg`–`p4.jpg`（用户提供的设计参考，已入库） |
| 项目记忆 | `AGENTS.md`（设计令牌、机制、坑的完整版） |

---

## 9. 深入阅读的入口

`AGENTS.md` 的章节索引：

- 第 1 节 — 项目定位与形态
- 第 2 节 — 目录结构与组件分工
- 第 3 节 — 改代码的流程与静态自检
- 第 4 节 — **设计系统**（颜色 / 圆角 / 材质令牌，以及 Liquid Glass 用法，最容易踩错的一节）
- 第 5 节 — 关键机制与坑（v4.0 SwiftUI 机制在前，v3 网页版细节在后）
- 第 6 节 — 预览工作流（Previews/ 目录怎么用）
- 第 7 / 8 节 — 当前状态与待办
- 第 9 节 — 工作习惯（视觉改动先出预览图等约定）
- 第 10 节 — 项目全景速查（文件规模、数据流、构建链路）
