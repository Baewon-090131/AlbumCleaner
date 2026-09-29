# Album Cleaner · 项目记忆

> 本文件是项目的长期记忆，写给后续的协作者与 AI 会话。改动项目前先读这一份。
> 最近更新：2026-09-29（版本号已统一为 **v2.7**；上一个已提交的版本是 `v2.6`）

## 1. 这是什么

一款 iOS 相册整理应用，交互参考 Slidebox：

- **形态**：原生 Swift 外壳（`WKWebView`）+ 内嵌 React 网页 UI。网页资源全部离线内置，运行时不需要网络、不需要 Babel。
- **已接入真实照片库**（Photos framework）。无原生桥接时自动降级为模拟数据，因此网页部分可以脱离 iOS 单独在浏览器里跑。
- **核心手势**：上滑删除 / 左滑下一张 / 右滑撤回 / 下滑收藏；删除先进应用内回收站。
- **构建**：GitHub Actions 出 IPA（`.github/workflows/build.yml`），或本地 `xcodegen generate` + Xcode。最低 iOS 14.0。

## 2. 目录结构

```
Slidebox/
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

网页侧组件分工：`App`（状态机 + 转场 + toast）、`HomePage`（月份列表）、`SortPage`（整理页 + 全屏观看）、`SwipeCardStack`（卡片与手势）、`SortBottomBar`（按钮/相簿双模式）、`TrashPage`（网格 + 弹窗 + 操作表）、`SettingsPage`（主题色与偏好）、`main`（全局令牌与关键帧 + 错误边界 + 挂载）。

## 3. 改代码的流程（必须遵守）

1. 只改 `WebContent/components/*.jsx`。
2. 跑 `node compile-jsx.js` 生成 `WebContent/build/*.js`（首次需 `npm i`；只依赖 `@babel/core` 与 `@babel/preset-react`）。
3. 跑 `node --check` 校验 8 个产物。
4. **`build/` 是入库文件**：忘记重编译，应用跑的就是旧代码。

静态自检命令（应全部为空或符合预期）：

```powershell
rg -n "transition: all" Slidebox\WebContent
rg -n "pagePushEnter|pagePopLeave" Slidebox\WebContent   # 已废弃的转场关键帧
rg -n --fixed-strings "background: '#000'" Slidebox\WebContent\components
```

## 4. 设计系统（iOS 27「液态玻璃 2.0」· 仅浅色）

**分层材质**（原则：浮动的操作层用轻玻璃，承载文字的卡片用厚玻璃）：

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
- `build/` 里遗留的 `pagePushEnter` / `pagePopLeave` 是废弃名，现用 `pageRevealIn` / `pageSlideIn` / `pageRevealOut` / `pageSlideOut`。

**卡片手势**：`SwipeCardStack` 用 Pointer Events + `setPointerCapture` + rAF 跟手，`will-change` 仅在手势期间开；方向提示通过 `window.__swipeHintBus` 广播（避免拖动时触发 React 重渲染）。照片板是「悬浮圆角」形态，圆角与裁剪在**卡片自身**上（放父容器上会出现圆角外溢出）。

**数据与原生桥**：`window.NativeBridge` 提供 `getData` / `deleteAssets` / `setFavorite` / `addToAlbum` / `playMedia` / `jsError`；消息处理器名 `photoApp`。Swift 侧用 `photo://` 取缩略图、`video://` 取视频与 Live 数据流。无桥时 `data.js` 生成模拟数据（照片是渐变 SVG 占位图，所以网页里看不到真实照片）。

**只做浅色**：系统处于深色时仍显示浅色 UI，深色模式尚未实现。

## 6. 预览工作流（Previews/）

约定：**先出预览图 → 使用者拍板 → 再改项目文件**。`Previews/` 已加入 `.gitignore`，只留本地。

```
Previews/
  app-shot.html      主交付物：上半实时预览（iframe 驱动真实应用，5 个页签），下半截图画廊
  capture.html       抓图夹具：定格动画抓静止态；hold=<毫秒> 把转场精确暂停在该进度
  shots/01-home.png … 05-settings.png   真实应用 5 屏
  preview.html       设计稿源（可切屏幕 / 玻璃材质 / 厚薄对比）
  00-glass-compare.png / 01-direction-split.png  设计阶段的对比板
```

`app-shot.html` 的实时预览需要 `chrome --allow-file-access-from-files Previews/app-shot.html`；直接双击打开时浏览器禁止跨源访问 file:// 的 iframe，页面会自动回退成截图。

用无头 Chrome 抓图的三个坑（都踩过）：

1. **最小窗口限制**：`--window-size` 小于约 500×760 会被 Chrome 强制放大，截图被裁切放大。做法是窗口给 786×1704，再用 iframe 的 `transform: scale(2)`（或 CSS `zoom`）拿 2 倍清晰度。
2. **虚拟时间下合成动画不推进**：`--virtual-time-budget` 抓不到中间态，会出现卡片半透明、按钮刚出现等假象。要抓转场中间帧就用「`animation-play-state: paused` + 负 `animation-delay`」把动画定格在指定毫秒；要抓静止态就注入把 duration 压到近乎 0、delay 设成负值（**负延迟**，设成 0 会漏渲染个别元素）。
3. **safe-area 在桌面浏览器恒为 0**：夹具要往 iframe 里注入 `--ios-safe-top: 59px / --ios-safe-bottom: 34px`，否则顶栏会贴到最上面。

## 7. 当前状态

- 最近提交 `e424509 v2.6`（含 iOS 27 视觉重构、转场修复、`.agents/skills` 与 `skills-lock.json`）。
- 当前未提交的改动：版本号统一为 v2.7（`project.yml` 的 MARKETING_VERSION、构建号 9→10、`package.json`、设置页「关于」行的显示文案）。
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
- `SortPage` 的进度条与全屏视频进度条仍动画 `width`（可改 `transform: scaleX()`，同期其它地方已用 `scaleX`）。
- `SwipeHint` 用关键帧入场（可改 transition，避免快速反复触发时从零重来）。
- 组件函数签名里的 `themeColor = '#007AFF'` 默认值仍是旧蓝，实际由 `App` 传入北洋蓝，仅作兜底。
- `App.jsx` 里 `--ac-*` 系统色令牌有一部分未被引用。

## 9. 工作习惯

- 视觉改动一律先出预览图，拍板后再动项目文件；预览产物只放 `Previews/`。
- 不新增依赖：网页侧只用内联样式 + 既有 CSS 令牌，不引入 CSS 框架或动效库。
- 信息架构、文案、手势逻辑与既有动效曲线不经要求不改。
- Swift 侧改动前先读 `.agents/skills/write-swift`；网页动效改动前先读 `animate` 与 `apple-design`。
