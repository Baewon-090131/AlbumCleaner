# HANDOFF · Evernight（Album Cleaner）

> 交接文档，给下一个接手这个项目的智能体或人。
> **先读这一份，再读 `AGENTS.md`（长期记忆，含设计令牌与历史沿革）。**
> 生成时间：2026-10-09

---

## 0. 三十秒了解

iOS 相册整理应用，交互参考 Slidebox。**SwiftUI 原生，纯本地，不联网**。
三个 tab：整理 / 相簿 / 我的。核心是四向滑动手势（上滑删除 / 左滑下一张 / 右滑撤回 / 下滑收藏）。

| 项 | 值 |
| --- | --- |
| 仓库 | `https://github.com/Baewon-090131/AlbumCleaner`（私有） |
| 分支 | `main`，工作区干净，与 origin 同步 |
| 最新提交 | `d745eb3 v4.0.1 按 Liquid Glass 规范重做玻璃层` |
| 版本 / 构建号 | 4.0 / 13（`project.yml`） |
| 最低系统 | iOS 17.0（`@Observable`、`ContentUnavailableView` 要求） |
| 构建 | GitHub Actions（macos-latest）出 IPA artifact |

---

## 1. 接手前必须知道的三件事

### 1.1 UI 是 v4.0 才从网页改成 SwiftUI 的

`Evernight/WebContent/` 是 v3 的 React 实现，**还在仓库里，但不参与构建**（`project.yml` 已移除引用）。
改 UI 一律改 `Evernight/` 下的 `.swift`，不要碰 WebContent——它只作设计基线与对照。

### 1.2 这份 Swift 代码从未编译过

开发机是 **Windows，没有 Xcode、没有 Swift 工具链、没有 iOS 模拟器**。
16 个 Swift 文件全靠人工复核（结构与括号配对），**一次都没有编译验证过**。
第一次真实编译发生在 GitHub Actions 上。

### 1.3 Liquid Glass 需要 iOS 26 SDK 编译

`glassEffect` / `GlassEffectContainer` / `.glass` 按钮样式这几个符号，只有 Xcode 26（iOS 26 SDK）才认。
运行时已经用 `#available(iOS 26, *)` 做了降级，但**编译期过不去就是过不去**。
先看 Actions 日志里的 `xcodebuild -version`——如果 runner 的 Xcode 落后，这几个文件会直接报 "cannot find in scope"。

---

## 2. 立刻该做的事（按优先级）

| 优先级 | 事项 | 备注 |
| --- | --- | --- |
| P0 | **确认 CI 编译结果** | 我查不到（私有仓库 + 无 token + 未装 gh）。打开 Actions 页面看最近一次 run |
| P0 | **真机跑一次** | Liquid Glass 实际长什么样，目前没人看过 |
| P1 | 补视频 / Live Photo 播放 | v4.0 只显示静态缩略图，v3 网页版有 `AVPlayer` 全屏播放，这块功能是退化的 |
| P1 | 修版本号显示 | `MineScreen.swift` 里写死了 `"Evernight 4.0 (1)"`，和构建号 13 对不上 |
| P2 | 「本轮已看」「已收藏」统计 | 目前恒为 0，没接真实计数 |
| P2 | 深色模式 | 当前一律浅色壁纸 |
| P2 | 清理 v3 遗留 | `WebContent/`、`compile-jsx.js`、`package.json` 都无用途了，确认后删 |

---

## 3. 代码结构（v4.0）

```
Evernight/
  EvernightApp.swift             73   入口 + 权限门（RootView）
  Info.plist                     54   权限文案、启动屏、方向
  Models/LibraryModels.swift     72   PhotoItem / MonthSection / AlbumItem / StorageInfo / Format
  Services/
    PhotoLibraryService.swift   222   @Observable 数据源：权限、按月分组、相簿、回收站、写入
    ThumbnailLoader.swift        46   缩略图异步加载 + NSCache
  Design/
    Theme.swift                  57   颜色 / 圆角令牌 + 壁纸 + Color(hex:)
    GlassSurface.swift          109   Liquid Glass 入口（GlassGroup / glassSurface / glassButtonStyle）+ ContentPanel
  Components/
    SortDeck.swift              179   卡片区 + 单卡 + DragGesture
    SortActionBar.swift          63   底部操作岛（GlassEffectContainer）
    ProgressHeader.swift         46   整理页进度胶囊
    AsyncThumbnail.swift         26   缩略图视图
    ToastBanner.swift            17   临时提示
  Screens/
    SortScreen.swift            260   整理页（相簿详情复用）+ 动作 + 月份菜单
    MineScreen.swift            235   我的：List / Toggle / Slider / 主题色
    TrashScreen.swift           115   回收站 + 全屏查看
    AlbumsScreen.swift           83   相簿网格
    MainTabView.swift            34   系统 TabView
  WebContent/                        v3 网页实现，不参与构建
project.yml                      47   xcodegen 配置
```

**用到的系统控件**（这就是"原生化"的实质）：
`NavigationStack`（大标题 + 工具栏）、`TabView`、`Menu`（月份）、`Toggle`、`Slider`、
`List(.insetGrouped)`、`ProgressView`、`ContentUnavailableView`、
`confirmationDialog`（回收站操作）、`fullScreenCover`（全屏看图）。

---

## 4. 数据流

单一数据源：`PhotoLibraryService`（`@Observable` + `@MainActor`），在 `RootView` 用 `@State` 持有，
往下用 `.environment(library)` 传。视图不自己存 PHAsset 列表副本。

| 界面动作 | 落到哪里 |
| --- | --- |
| 上滑删除 | `moveToTrash` → 只进应用内回收站，**不动系统相册** |
| 回收站「彻底删除」 | `deleteFromSystem` → `PHPhotoLibrary.performChanges` + `PHAssetChangeRequest.deleteAssets` |
| 下滑收藏 | `setFavorite` → `PHAssetChangeRequest.isFavorite` |
| 操作岛「相簿」 | 原生 `confirmationDialog` 列相簿 → `add(_:to:)` |
| 缩略图 | `ThumbnailLoader` → `PHCachingImageManager.requestImage`，按 `identifier\|size` 缓存 |
| 存储占用 | `readStorage` → volumeTotalCapacity / volumeAvailableCapacityForImportantUsage |
| 主题色 | `@AppStorage("ac_theme")` + `Color(hex:)`，`MainTabView` 用 `.tint` 应用 |

**注意：删除是两级的。** 手势删除只进应用内回收站；只有回收站里的「彻底删除」才真的从系统相册删。
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

---

## 7. 版本史（知道个大概就行）

| 版本 | 提交 | 内容 |
| --- | --- | --- |
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
| 编译验证 | 只能靠 GitHub Actions（macos-latest） |
| 网页版预览（v3，仅对照） | `node compile-jsx.js`，然后 `Previews/_shot.html?tab=sort\|albums\|mine` |
| 设计稿 | `Previews/Evernight-V3-UI.pptx`（7 页可编辑）+ `v3-shots/` |
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
