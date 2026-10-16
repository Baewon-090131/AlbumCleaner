# HANDOFF · Evernight（Album Cleaner）

> 交接文档，给下一个接手这个项目的智能体或人。
> **先读这一份，再读 `AGENTS.md`（长期记忆，含设计令牌与历史沿革）。**
> 生成时间：2026-10-09 · 最近更新：2026-10-15（整理页：撤回收敛为通用撤销栈 + 全操作统一为「滑动分拣」动效）

---

## 0. 三十秒了解

iOS 相册整理应用，交互参考 Slidebox。**SwiftUI 原生，纯本地，不联网**。
三个 tab：整理 / 相簿 / 我的。核心是四向滑动手势（上滑删除 / 左滑下一张 / 右滑撤回 / 下滑收藏）。

| 项 | 值 |
| --- | --- |
| 仓库 | `https://github.com/Baewon-090131/AlbumCleaner`（私有） |
| 分支 | `main`，工作区干净，与 origin 同步 |
| 最新提交 | 整理页撤回与滑动分拣动效（本次改动，hash 见 `git log -1`；上一条是相簿 / 回收站网格统一） |
| 版本 / 构建号 | 4.0 / 13（`project.yml`） |
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
| P0 | **真机 / 模拟器跑一次** | 编译已过，但运行时行为完全是空白：Liquid Glass 实际渲染、Photos 权限流程、手势手感都要现场看 |
| P1 | 补视频 / Live Photo 播放 | v4.0 只显示静态缩略图，v3 网页版有 `AVPlayer` 全屏播放，这块功能是退化的 |
| P1 | 修版本号显示 | `MineScreen.swift` 里写死了 `"Evernight 4.0 (1)"`，和构建号 13 对不上 |
| P2 | 「本轮已看」「已收藏」统计 | 目前恒为 0，没接真实计数 |
| P2 | 深色模式 | 当前一律浅色壁纸 |
| P2 | 清理 v3 遗留 | `WebContent/`、`compile-jsx.js`、`package.json` 都无用途了，确认后删 |
| 已做 | 整理页撤回 + 滑动分拣动效 | 2026-10-15：撤回不再只撤删除，收敛为通用撤销栈（限深 50、切月清空）；手势与按钮统一走同一条动效通道（见 5.7） |
| 已做 | 相簿页 / 回收站网格排列 | 2026-10-14 统一为 iOS 原生相册式：相簿 2 列正方形封面、回收站 3 列 1:1（见第 7 节版本史与 5.6） |

---

## 3. 代码结构（v4.0）

```
Evernight/
  EvernightApp.swift             73   入口 + 权限门（RootView）
  Info.plist                     54   权限文案、启动屏、方向
  Models/
    LibraryModels.swift           72   PhotoItem / MonthSection / AlbumItem / StorageInfo / Format
    SortModels.swift              84   SortMove / DeckCommand / UndoRecord / SortAction
  Services/
    PhotoLibraryService.swift   231   @Observable 数据源：权限、按月分组、相簿、回收站、写入
    ThumbnailLoader.swift        46   缩略图异步加载 + NSCache
  Design/
    Theme.swift                  57   颜色 / 圆角令牌 + 壁纸 + Color(hex:)
    GlassSurface.swift          109   Liquid Glass 入口（GlassGroup / glassSurface / glassButtonStyle）+ ContentPanel
  Components/
    SortDeck.swift              246   卡片区：跟手 / 飞出 / 下一张渐显入场 / 撤回倒放（动效编排）
    SortCard.swift               93   单张卡片视觉 + 空态 + badgeStyle
    SortActionBar.swift          63   底部操作岛（GlassEffectContainer）
    ProgressHeader.swift         46   整理页进度胶囊
    MonthMenu.swift              32   月份切换胶囊（系统 Menu）
    AsyncThumbnail.swift         26   缩略图视图
    ToastBanner.swift            17   临时提示
  Screens/
    SortScreen.swift            269   整理页（相簿详情复用）+ 撤销栈 + 动作
    MineScreen.swift            235   我的：List / Toggle / Slider / 主题色
    TrashScreen.swift           121   回收站（3 列正方形网格）+ 全屏查看
    AlbumsScreen.swift           79   相簿网格（2 列正方形封面，iOS 原生式）
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
| 撤回（按钮 / 右滑） | 按撤销栈顶记录倒做：删除 → `restore` 按创建日期插回原位；下一张 → 游标退一张；收藏 → `setFavorite(false)`；存入相簿 → `remove(_:from:)` |
| 手势与按钮触发动效 | 都写 `SortScreen.command`（`DeckCommand`，带 token）→ `SortDeck.onChange` 播放 → 播完回调 `onFinished` 才改数据 |
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
| 整理页动效 | 本次 | 撤回收敛为通用撤销栈（删除 / 下一张 / 收藏 / 存入相簿，限深 50、切月清空）；整理页手势与按钮统一为「滑动分拣」动效，撤回即整套倒放；`SortModels.swift` / `SortCard.swift` / `MonthMenu.swift` 拆出 |
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
