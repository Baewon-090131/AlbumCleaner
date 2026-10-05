# Album Cleaner · 项目记忆

> 本文件是项目的长期记忆，写给后续的协作者与 AI 会话。改动项目前先读这一份。
> 最近更新：2026-10-05（**v3.0 未提交**：三 tab 重构、目录由 `Slidebox/` 改名为 `Evernight/`；上一个已提交版本是 `7f12987 v2.7`）

## 1. 这是什么

一款 iOS 相册整理应用，交互参考 Slidebox：

- **信息架构（v3.0）**：三个 tab——整理 / 相簿 / 我的，顶部统一是 app 标题「Evernight」+ 档案箱入口，底部是液态玻璃 tab 栏。
- **形态**：原生 Swift 外壳（`WKWebView`）+ 内嵌 React 网页 UI。网页资源全部离线内置，运行时不需要网络、不需要 Babel。
- **已接入真实照片库**（Photos framework）。无原生桥接时自动降级为模拟数据，因此网页部分可以脱离 iOS 单独在浏览器里跑。
- **核心手势**：上滑删除 / 左滑下一张 / 右滑撤回 / 下滑收藏；删除先进应用内回收站。
- **构建**：GitHub Actions 出 IPA（`.github/workflows/build.yml`），或本地 `xcodegen generate` + Xcode。最低 iOS 14.0。

## 2. 目录结构

```
Evernight/
  AppDelegate.swift              应用入口
  ViewController.swift           WKWebView 配置、photo:// 与 video:// scheme、photoApp JS 桥
  PhotoLibraryManager.swift      权限 / 相册 / 缩略图缓存 / 删除与收藏 / 预取
  LivePhotoViewController.swift  Live Photo 播放
  Info.plist                     权限文案、状态栏样式、仅竖屏（iPad 允许横屏）
  WebContent/
    index.html                   入口：<style> 里的 --wall 壁纸、NativeBridge、按序加载 build/*.js
    data.js                      DataLoader（原生优先）+ MockData（模拟月份/相簿/渐变图）
    vendor/                      React 18 UMD（离线）
    components/*.jsx             **源码，改这里**
    build/*.js                   **编译产物，入库；必须与 components 同步**
compile-jsx.js                   JSX → build 的预编译器
project.yml / package.json / .github/  构建与 CI 配置
Previews/                        预览产物（已 gitignore，见第 6 节）
```

网页侧组件分工（v3.0）：`App`（tab 状态机 + 页内推入转场 + 数据流）、`TopBar`（标题 / 月份胶囊 / 档案箱）、`BottomTabBar`（整理 · 相簿 · 我的）、`Icons`（按 SF Symbols 线条规格绘制的图标集）、`SortPage`（整理页，相簿详情复用它）、`SwipeCardStack`（单卡 + 手势 + 日期体积角标）、`SortBottomBar`（四按钮操作岛 / 相簿展开态）、`AlbumsPage`（两列相簿网格）、`TrashPage`（回收站）、`MinePage`（数据卡 + 偏好 + 主题色）、`main`（全局令牌与关键帧 + 错误边界 + 挂载）。

v2.x 的 `HomePage`（月份列表）和 `SettingsPage` 已在 v3.0 删除：月份改由顶部胶囊弹层选择，设置并入「我的」。

## 3. 改代码的流程（必须遵守）

1. 只改 `WebContent/components/*.jsx`。
2. 跑 `node compile-jsx.js` 生成 `WebContent/build/*.js`（首次需 `npm i`；只依赖 `@babel/core` 与 `@babel/preset-react`）。
3. 跑 `node --check` 校验 8 个产物。
4. **`build/` 是入库文件**：忘记重编译，应用跑的就是旧代码。

静态自检命令（应全部为空或符合预期）：

```powershell
rg -n "transition: all" Evernight\WebContent
rg -n "pagePushEnter|pagePopLeave" Evernight\WebContent   # 废弃的转场关键帧，应为空
rg -n --fixed-strings "background: '#000'" Evernight\WebContent\components
```

## 4. 设计系统（iOS 27「液态玻璃 2.0」· 仅浅色）

**材质分层（v3.0 按 Apple HIG 校正）**：Liquid Glass 只用于浮在内容之上的功能层——顶部栏、进度条、操作岛、tab 栏、月份胶囊；照片卡片、相簿卡片、设置分组这些内容层改用更实的白色面板（新增令牌 `--glass-solid` = `rgba(255,255,255,.72)`）。**不要把浅色半透明叠在浅色半透明上**，可读性会塌，「我的」页分组发闷就是这个原因。

| 令牌 | 值 | 用途 |
| --- | --- | --- |
| `--glass-float` | `rgba(255,255,255,.38)` | 顶部导航岛、进度条、底部操作岛、图标按钮、相册展开岛 |
| `--glass-float-strong` | `rgba(255,255,255,.50)` | 相册展开岛、操作表「取消」 |
| `--glass-panel` | `rgba(255,255,255,.60)` | 月份卡片、设置分组、回收站网格、提示 pill |
| `--glass-inner` | `rgba(255,255,255,.30)` | 操作岛内的方块按钮 |
| `--blur-float` / `--blur-panel` | `blur(14px) saturate(155%) brightness(1.02)` / `blur(30px) saturate(190%) brightness(1.05)` | 对应两种材质的 `backdrop-filter` |
| `--edge-float` / `--edge-panel` / `--edge-panel-soft` / `--edge-inner` | 内顶高光 + 0.5px 内亮边 + 外投影 | 材质边缘 |

**圆角**：`--r-island` 28（浮岛）、`--r-panel` 28（卡片分组）、`--r-tile` 20（内层方块）、`--r-plate` 34（照片板）。

**强调色**：`--accent` = 北洋蓝 `#002FA7`，`--accent-soft` = 其 16% 透明版。`App.jsx` 的 `initialTheme` 默认值即北洋蓝；用户选择存于 localStorage `ac_theme`（**老用户会沿用存过的颜色，改默认值只影响新装**）。设置页仍提供 12 种主题色，`#007AFF` 蓝色是其中之一。

**壁纸**：`--wall`（四层柔光斑 + 线性底）**只在 `index.html` 的 `:root` 定义一次**，`body` 与页面转场背板都引用它。不要放进运行时注入的样式里，否则首帧会闪白。

**动效令牌**：`--ease-out` `cubic-bezier(.23,1,.32,1)`、`--ease-in-out`、`--ease-drawer` `cubic-bezier(.32,.72,0,1)`、`--press-ms` 110ms、`--page-transition-ms` 360ms。排版类：`.sf-title`（负字距大标题）、`.sf-body`、`.ios-btn`（按压缩放）、`.ios-row`（列表按压高亮）。

**无障碍**：`main.jsx` 内的 `@media (prefers-reduced-motion: reduce)` 块把位移类关键帧降级成纯透明度过渡（含转场的四组揭示/位移关键帧）；`SwipeCardStack` 与 `App` 里 JS 直驱的动效也各自做了同样判断。

## 5. 关键机制与坑

**页面转场（易错点）**：`App.jsx` 每个页面渲染成两层——外层是**不透明壁纸背板**并负责 `clip-path` 揭示，内层承载页面内容并负责位移，两者同曲线同 360ms，380ms 后收栈。

- 页面层**必须不透明**。曾经每层都是 `background: transparent`，导致入场页像透明薄膜盖在旧页上、新旧界面互相透出（已修复，别再改回去）。
- `clip-path` 会把 `box-shadow` 一起裁掉，所以原整页投影改成了贴在揭示边缘上的 26px 渐变贴片，放在内容层内部。
- 外层不做任何位移，才能让背板与 body 壁纸逐像素对齐；一旦位移，接缝会露出色差。
- 废弃的 `pagePushEnter` / `pagePopLeave` 已于 v2.7 全仓库清除（2026-10-01 核对为空）。现用 `pageRevealIn` / `pageSlideIn` / `pageRevealOut` / `pageSlideOut`；第 3 节的自检命令保留作回归检查。

**卡片手势**：`SwipeCardStack` 用 Pointer Events + `setPointerCapture` + rAF 跟手，`will-change` 仅在手势期间开；方向提示通过 `window.__swipeHintBus` 广播（避免拖动时触发 React 重渲染）。照片板是「悬浮圆角」形态，圆角与裁剪在**卡片自身**上（放父容器上会出现圆角外溢出）。

**数据与原生桥**：`window.NativeBridge` 提供 `getData` / `deleteAssets` / `setFavorite` / `addToAlbum` / `playMedia` / `jsError`；消息处理器名 `photoApp`。Swift 侧用 `photo://` 取缩略图、`video://` 取视频与 Live 数据流。无桥时 `data.js` 生成模拟数据（照片是渐变 SVG 占位图，所以网页里看不到真实照片）。

**只做浅色**：系统处于深色时仍显示浅色 UI，深色模式尚未实现。

**v3.0 三 tab 与页内推入**：`App.jsx` 的 `stack` 是导航栈，`TAB_PAGES = ['sort','albums','mine']` 决定底部是否显示 tab 栏；tab 切换用 `dir='fade'`（只淡入不位移），回收站与相簿详情用 `dir='forward'/'backward'` 走 v2.6 的双层揭示转场。`index.html#sort|#albums|#mine` 可直接落到某个 tab（无头 Chrome 截图用）。

**单卡适配媒体尺寸（v3.0）**：`SwipeCardStack` 一次只渲染当前一张卡，卡片用 `aspect-ratio` + `max-width/max-height` 按 `photo.ratio` 适配（横图撑满宽度、竖图撑满高度），底色是 `--glass-solid` 而不是纯黑。日期与体积角标贴卡片下缘，视频 / LIVE 标识移到右上角。

**相簿详情（v3.0）**：从相簿页点进相簿会推入 `SortPage`，用 `backLabel="相簿"` 走返回态、`actions={['undo','delete','next']}` 只留三个按钮、`withTabBar={false}` 隐藏底部 tab 栏。照片来自新桥接动作 `getAlbumAssets`。

**图标（v3.0）**：`Icons.jsx` 是唯一的图标来源，路径按 SF Symbols 的线条规格手写在 24×24 网格上，统一 round cap / round join。不要再往组件里塞一次性 `<svg>`。

## 6. 预览工作流（Previews/）

约定：**先出预览图 → 使用者拍板 → 再改项目文件**。`Previews/` 已加入 `.gitignore`，只留本地。

```
Previews/
  Evernight-V3-UI.pptx   v3.0 UI 稿（7 页，可编辑，元素都是原生形状与文本框）
  v3-shots/              上面那份稿子的逐页渲染图
  v3-app/                真实应用在无头 Chrome 里的三个 tab 截图
  _shot.html             截图夹具：iframe 390×844 + zoom 2，并注入 iOS safe-area
  _v3-build/             UI 稿的生成脚本（build-deck.mjs / pages.mjs / icons.mjs）与素材
```

`_shot.html` 用法：`chrome --headless=new --window-size=780,1688 --allow-file-access-from-files --screenshot=out.png "file:///D:/Desktop/AlbumCleaner/Previews/_shot.html?tab=albums"`。`tab` 取 `sort` / `albums` / `mine`。

⚠️ **无头 Chrome 的窗口不能小于约 500×760**：小窗口会被强制放大，截出来的图看起来像内容溢出视口——2026-10-05 踩过一次，白排查了半天布局。要么走 `_shot.html` 夹具，要么窗口给 780×1688。

用无头 Chrome 抓图的三个坑（都踩过）：

1. **最小窗口限制**：`--window-size` 小于约 500×760 会被 Chrome 强制放大，截图被裁切放大。做法是窗口给 786×1704，再用 iframe 的 `transform: scale(2)`（或 CSS `zoom`）拿 2 倍清晰度。
2. **虚拟时间下合成动画不推进**：`--virtual-time-budget` 抓不到中间态，会出现卡片半透明、按钮刚出现等假象。要抓转场中间帧就用「`animation-play-state: paused` + 负 `animation-delay`」把动画定格在指定毫秒；要抓静止态就注入把 duration 压到近乎 0、delay 设成负值（**负延迟**，设成 0 会漏渲染个别元素）。
3. **safe-area 在桌面浏览器恒为 0**：夹具要往 iframe 里注入 `--ios-safe-top: 59px / --ios-safe-bottom: 34px`，否则顶栏会贴到最上面。

## 7. 当前状态

- **v3.0（未提交）**：三 tab 重构；目录改名 `Evernight/`；`WebContent/components/` 重写为 11 个组件（删掉 `HomePage` 与 `SettingsPage`）；Swift 侧新增 `creationDate` / `fileSize` / 相簿 `cover` / `getAlbumAssets` / `getStorageInfo`；版本号四处升到 3.0（构建号 10→11）。`compile-jsx.js`、`project.yml`（含 `INFOPLIST_FILE`）、`README.md` 的路径已同步改为 `Evernight`。
- Swift 侧本机没有 Xcode，**未做编译验证**；网页侧已用无头 Chrome 实测三个 tab 的渲染。
- 最新提交 `7f12987 v2.7`：版本号统一（`project.yml` 2.7、构建号 9→10、`package.json`、设置页「关于」文案）、`.agents/skills/` 清空、新增 `skills-lock.json`。工作区干净，无未提交改动。
- 看 `git log` 别按版本号推断先后：`v2.6` 出现过两次，`v2.6.1` 夹在它们与 `v2.7` 之间。
- 技能全部放在**用户级**，项目里不再携带技能正文（`.agents/skills/` 已在 v2.7 清空并提交删除）：
  - `~/.codex/skills/`：animate / apple-design / emil-design-eng / mobile-native / write-swift / ponytail 系列 / image-to-editable-ppt
  - `~/.agents/skills/`：investigate-first / lean-build / migration / safe-refactor / surgical-patch / verify-and-stop
  - 根级 `skills-lock.json` 只记录安装来源与哈希（当前含 `emilkowalski/skills`、`remotion-dev/skills` 两批），不含技能正文。
- 版本号的**声明处**共四个，改版本时全部要动：`project.yml` 的 `MARKETING_VERSION` 与 `CURRENT_PROJECT_VERSION`（后者是 iOS 构建号，必须递增）、`package.json`、设置页「关于」那行 `detail`（改完记得重编译）。代码注释里的 `v2.6` / `v2.3.2` 是历史功能注记，**不要跟着改**。

## 8. 待办与未决

**用户已明确推迟的**
- 手势手感：动量投影、释放速度交接、边界橡皮筋阻尼（本轮只做视觉）。
- 触感反馈：Swift 侧完全没有 `UIImpactFeedbackGenerator`，滑动删除的提交/归位时刻是最该加的地方。
- 深色模式。
- `index.html` 的 `maximum-scale=1 / user-scalable=no` 是否放开——站内没有输入框，属产品决策，需要单独拍板。

**已知但未处理的摩擦点**
- `SortPage` 的顶部进度条与全屏视频进度条仍动画 `width`（可改 `transform: scaleX()`，同期其它地方已用 `scaleX`）。
- `SwipeHint` 用关键帧入场（可改 transition，避免快速反复触发时从零重来）。
- 组件函数签名里的 `themeColor = '#007AFF'` 默认值仍是旧蓝，实际由 `App` 传入北洋蓝，仅作兜底。
- `App.jsx` 里 `--ac-*` 系统色令牌有一部分未被引用。
- 「我的」页里没有后端支撑的项（滑动方向、展示顺序、照片显示、HDR、视频声音、语言）是静态行，点不动；每轮数量滑块也只做了展示。
- `PHAssetResource.assetResources` 读 `fileSize` 是逐张同步调用并缓存的，相册数量很大时会拖慢首次加载，后续可改后台索引。
- 「本轮已看」「已收藏」两个统计目前恒为 0，没有接真实计数。
- 待办：深色模式；相簿页缺空状态与「新建相簿」。

## 9. 工作习惯

- 视觉改动一律先出预览图，拍板后再动项目文件；预览产物只放 `Previews/`。
- 不新增依赖：网页侧只用内联样式 + 既有 CSS 令牌，不引入 CSS 框架或动效库。
- 信息架构、文案、手势逻辑与既有动效曲线不经要求不改。
- Swift 侧改动前先读 `.agents/skills/write-swift`；网页动效改动前先读 `animate` 与 `apple-design`。

## 10. 项目全景速查（2026-10-05 · v3.0）

**文件规模**（不含 `node_modules/` 与 `.git/`）

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `Evernight/PhotoLibraryManager.swift` | 407 | 权限、按月份分组、相簿、缩略图缓存与预取、删除 / 收藏 / 加相簿、视频与 Live 播放、文件大小、存储信息 |
| `Evernight/ViewController.swift` | 264 | WKWebView 配置、`photo://` 与 `video://` scheme、`photoApp` 桥、JSON 回推、PNG 二级缓存（50MB） |
| `Evernight/WebContent/components/*.jsx` | 2837 合计 | 11 个源文件，见第 2 节分工表 |
| `Evernight/WebContent/build/*.js` | 4148 合计 | 11 个编译产物，入库 |
| `Evernight/WebContent/data.js` | 164 | DataLoader（原生优先）+ MockData |
| `Evernight/WebContent/index.html` | 153 | `--wall` 与 `--glass-solid`、`NativeBridge`（含 getAlbumAssets / getStorageInfo）、按序加载 `build/*.js` |
| `Evernight/Info.plist` | 59 | 权限文案、状态栏、方向 |
| `Evernight/LivePhotoViewController.swift` | 50 | Live Photo 播放控制器 |
| `project.yml` | 45 | xcodegen 配置 |
| `compile-jsx.js` | 32 | JSX 预编译（无运行时 Babel） |
| `Evernight/AppDelegate.swift` | 15 | 应用入口 |

**JS 与 Swift 的桥接对照**（消息处理器统一为 `photoApp`）

| JS 调用 | Swift 处理 | 回执 |
| --- | --- | --- |
| `getData` | `ViewController.injectPhotoData()` | 回推 `NativeBridge.receiveData(...)` |
| `getAlbumAssets(albumId, cb)` | `PhotoLibraryManager.fetchAlbumAssets` | 回推 `NativeBridge.receiveAlbumAssets(list)` |
| `getStorageInfo(cb)` | `PhotoLibraryManager.storageInfo()` | 回推 `NativeBridge.receiveStorage(info)` |
| `deleteAssets` | `PhotoLibraryManager.deleteAssets` | `onDeleteComplete(success)` |
| `setFavorite` | `PhotoLibraryManager.setFavorite` | `onFavoriteComplete(success)` |
| `addToAlbum` | `PhotoLibraryManager.addToAlbum` | `onAddToAlbumComplete(success)` |
| `playMedia` | `PhotoLibraryManager.playMedia`（视频 / Live 原生全屏） | 无 |
| `jsError` | `print("SLIDEBOX_JS: ...")` | 无 |
| `photo://` | 取缩略图，带 PNG 二级缓存 | 直接返回图像数据 |
| `video://` | 取视频数据与 Live 数据流 | 直接返回媒体数据 |

**构建链路**

| 步骤 | 命令 / 产物 |
| --- | --- |
| 1 | `xcodegen generate` 生成 `AlbumCleaner.xcodeproj`（源目录是 `Evernight/`） |
| 2 | `xcodebuild -scheme AlbumCleaner -configuration Release -sdk iphoneos`（CI 里不签名） |
| 3 | 把 `.app` 装进 `Payload/` 再压成 `AlbumCleaner.ipa` |
| 4 | Actions artifact `AlbumCleaner-ipa`（保留 30 天）；失败时上传 `build.log` |
| 网页侧 | `npm i` → `node compile-jsx.js` → `node --check build/*.js` |
| 截图夹具 | 无头 Chrome 窗口小于约 500px 会被强制放大，用 `Previews/_shot.html?tab=sort|albums|mine`（iframe 390×844 + zoom 2 + 注入 safe-area） |

**本轮核对结论**

| 项 | 状态 |
| --- | --- |
| `transition: all` | 全仓库为空 |
| `pagePushEnter` / `pagePopLeave` | 已清除 |
| `background: '#000'` | 1 处（`SortPage.jsx` 全屏播放底色），属预期 |
| 版本号四处 | `project.yml` 3.0 / 构建号 11、`package.json` 3.0、`MinePage.jsx` 的「关于」与版本行，`build/` 已同步 |
| `.agents/skills/` | 空目录，正文已由 v2.7 提交删除 |
| 触感反馈 / 深色模式 / 手势动量 | 均未实现，与第 8 节一致 |
| `SortPage` 进度条 | 仍动画 `width`，第 8 节的摩擦点仍存在 |
| Swift 编译 | 本机无 Xcode，未验证；网页侧已用无头 Chrome 实测三个 tab |
| `.gitignore` 生效项 | `Previews/`、`node_modules/`、`package-lock.json` |
