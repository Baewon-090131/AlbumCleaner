# Album Cleaner · 项目记忆

> 本文件是项目的长期记忆，写给后续的协作者与 AI 会话。改动项目前先读这一份。
> 最近更新：2026-11-02（v0.1：更名 evernight、底栏 3+1 与「我的」sheet、卡内播放、分列删除、待删除结算页、相似页 pHash、相簿管理；上一次是 2026-10-15 的整理页撤回收敛与滑动分拣动效）

## 1. 这是什么

一款 iOS 相册整理应用，交互参考 Slidebox 与「卡待删」：

- **形态（v4.0 起）**：**纯 SwiftUI 原生应用**，没有 WebView、没有 React。相册数据直接来自 Photos framework。
- **信息架构（v0.1 起）**：底栏是自定义的「3 栏玻璃胶囊（整理 / 相似 / 相簿）+ 独立圆形『我的』按钮」（`Components/AppTabBar.swift`），不再是系统 `TabView`；「我的」从底部上滑覆盖当前页（MainTabView 自绘 sheet，抓握条下拉关闭）。三个 tab 常驻只切显隐（`opacity` + `allowsHitTesting`），整理页游标与撤销栈、相似页扫描结果不因切换丢失。回收站改名「待删除」，由全局 `UIState.showTrash` 经 `fullScreenCover` 弹出。
- **核心手势**：整理页上滑删除 / 左滑下一张 / 右滑撤回 / 下滑收藏（`DragGesture`）；**双指收拢进分列模式**（2 / 3 列瀑布流），分列里任意一张左右滑即标记删除。删除先进应用内「待删除」，待删除里的「彻底删除」才动系统相册。
- **构建**：GitHub Actions 出 IPA（`.github/workflows/build.yml`），或本地 `xcodegen generate` + Xcode。**最低 iOS 17.0**（`@Observable`、`ContentUnavailableView` 等要求）。
- **`Evernight/WebContent/` 是 v3 的网页实现，不参与构建**（`project.yml` 已移除引用），保留只作对照。

## 2. 目录结构

```
Evernight/
  EvernightApp.swift             入口 + 权限门（RootView）+ 全局 UIState
  Info.plist                     权限文案、启动屏、方向、仅浅色（显示名 evernight）
  Models/
    LibraryModels.swift          PhotoItem / MonthSection / AlbumItem / StorageInfo / Format
    SortModels.swift             SortMove / DeckCommand / UndoRecord / SortAction
  Services/
    PhotoLibraryService.swift    @Observable 数据源：权限、按月分组、相簿、待删除、写入、累计战果
    SimilarityService.swift      相似检测：dHash 指纹 + 分桶候选 + 并查集分组（指纹存 UserDefaults）
    ThumbnailLoader.swift        缩略图异步加载 + NSCache（大卡原图级走独立 8 张缓存）
  Design/
    Theme.swift                  颜色 / 圆角令牌 + 壁纸 + Color(hex:)
    GlassSurface.swift           Liquid Glass 适配层 + ContentPanel（内容层材质）
  Components/
    SortDeck.swift               卡片区：跟手 / 飞出 / 下一张渐显入场 / 撤回倒放（动效编排）
    SortCard.swift               单张卡片视觉 + 空态 + badgeStyle（媒体内容走 MediaCardContent）
    MediaCardContent.swift       视频卡（AVPlayerLayer 静音循环）+ 实况卡（PHLivePhotoView）
    ColumnsGrid.swift            分列瀑布流：双指收拢进入，左右滑标记删除
    SortActionBar.swift          底部操作岛
    AppTabBar.swift              自定义底栏：3 栏玻璃胶囊 + 我的独立圆钮
    TrayButton.swift             待删除托盘（垃圾桶 + 红角标），各页右上共用
    SimilarGroupCard.swift       相似页的一组：缩略图行 + 勾选 + 组底删除条
    ProgressHeader.swift         整理页顶部进度胶囊
    MonthMenu.swift              整理页月份切换（系统 Menu）
    AsyncThumbnail.swift         缩略图视图（highQuality 开关给前置大卡）
    ToastBanner.swift            临时提示
  Screens/
    MainTabView.swift            自定义底栏 + 我的 sheet + 回收站 fullScreenCover
    SortScreen.swift             整理页（相簿详情复用）+ 撤销栈 + 分列模式 + 动作
    SimilarScreen.swift          相似页：年份筛选 + 智能清理 + 分组列表
    AlbumsScreen.swift           相簿管理：空相簿横幅 / 新建 / 排序 / 长按菜单
    MineScreen.swift             我的面板（sheet）：深色统计卡 + 设置
    TrashScreen.swift            待删除（结算页：全选 / 勾选 / 红色删除条）+ 全屏查看
    FavoritesScreen.swift        已喜欢网格（从我的进入）
  WebContent/                    v3 的网页实现，不参与构建（见第 1 节）
project.yml / .github/          构建与 CI 配置
compile-jsx.js / package.json   网页版遗留工具链，v4.0 起不再需要
Previews/                       预览产物（已 gitignore，见第 6 节）
```

原生化用到的系统控件：`NavigationStack`（大标题 + 工具栏）、`Menu`（月份、排序）、`Toggle`、`Slider`、`List(.insetGrouped)`、`ProgressView`、`ContentUnavailableView`、`confirmationDialog`（相簿与待删除操作）、`fullScreenCover`（待删除 / 全屏看照片 / 已喜欢）、`contextMenu`（相簿长按）。v0.1 起底部 tab 不再用系统 `TabView`，见第 1 节。

v3 的网页版组件（`TopBar` / `BottomTabBar` / `SortPage` / `SwipeCardStack` / `SortBottomBar` / `AlbumsPage` / `TrashPage` / `MinePage` / `Icons`）仍留在 `WebContent/components/`，只作对照与设计基线，不再被 App 加载。

## 3. 改代码的流程（必须遵守）

v4.0 起 UI 全在 Swift 里，改完直接编译：

1. 只改 `Evernight/` 下的 `.swift`。`WebContent/` 是 v3 遗留，改了不影响 App。
2. 新增文件不用改配置——`project.yml` 里 `sources: Evernight` 会整目录纳入。
3. 有 Xcode 时：`xcodegen generate` 然后 `xcodebuild -scheme AlbumCleaner -sdk iphonesimulator build`。
4. 没有 Xcode（比如 Windows）时：推到 GitHub 让 `.github/workflows/build.yml` 在 macos-latest 上编译，看 Actions 日志。
5. 单个视图文件超过约 300 行就拆成独立 `View` 类型（见第 9 节）。

静态自检（应全部为空或符合预期）：

```powershell
rg -n "WKWebView|evaluateJavaScript|photoApp" Evernight --glob "*.swift"   # 应为空：WebView 层已删除
rg -n "WebContent" project.yml                                             # 应为空：网页资源不再打包
rg -n "^import UIKit" Evernight --glob "*.swift"                           # 只允许缩略图相关的两个文件
```

网页版（v3）如果还要改：流程是改 `WebContent/components/*.jsx` → `node compile-jsx.js` → `node --check build/*.js`；`build/` 是入库文件，忘了重编译浏览器里跑的就是旧代码。

## 4. 设计系统（iOS 27「液态玻璃 2.0」· 仅浅色）

**v4.0 起这套令牌搬到了 Swift**：颜色与圆角在 `Design/Theme.swift`，壁纸是 `Theme.wall`；玻璃在 `Design/GlassSurface.swift`。下面这些 CSS 变量是 v3 网页版的对应实现，**数值仍是最新依据**，改设计时两边一起看。

**Liquid Glass 的用法（2026-10-08 修正过一次，别再退回旧写法）**：

- 用系统的 `glassEffect(_:in:)`，不要自己拿 `.ultraThinMaterial` 拼。
- **多个玻璃元素要包在 `GlassGroup`（`GlassEffectContainer`）里**，相邻形状会自己融合成一整块。操作岛就是这么做的：每个按钮各自一块玻璃，靠容器合并成一条岛。
- **不要再给那组玻璃套一层玻璃外框**。玻璃叠玻璃既不符合 HIG，文字对比度也会塌——第一版就是这么写错的。
- 会变形的玻璃用 `glassSurface(cornerRadius:morphID:in:)`，同一个 `@Namespace` 下相同 id 的形状会平滑变形（操作岛四按钮 ↔ 相簿详情三按钮）。
- 可点的地方要 `.interactive()`；静态容器（加载页、进度条）不要加。
- 按钮优先 `.glassButtonStyle()`（内部是 `.glass` / `.glassProminent`），低版本自动退 `.bordered`。
- `.clear` 变体只在玻璃压在照片、视频这类视觉丰富的背景上时用；当前没有这种场景，所以没用。
- 内容层（照片卡片、分组、相簿网格）按 HIG **继续用 `ContentPanel` 的材质**，不要改成 Liquid Glass。

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

**v0.1 新机制**：

- **底栏 3+1 与「我的」sheet**：`MainTabView` 用 `ZStack(alignment: .bottom)` 叠「tab 内容 + 我的面板 + AppTabBar」。三个 tab 常驻（`opacity` 切显隐），不要用 switch 重建——会丢整理页撤销栈。「我的」面板顶部圆角 + 抓握条，抓握区的 `DragGesture` 实时写 `mineDrag`，松手超 110pt 关闭；手势只挂在抓握区，下面 List 滚动不受影响。
- **待删除托盘**：`UIState`（`@Observable`，RootView 创建经 environment 下传）持有 `showTrash` / `showMine`。各页右上角的 `TrayButton` 只写 `ui.showTrash = true`，`MainTabView` 用 `fullScreenCover` 弹出（盖住自定义底栏）。**别再用 `navigationDestination` 弹回收站**——自定义底栏不会随 push 隐藏。
- **卡内播放**：`SortCard` 按媒体类型换内容——视频走 `VideoCardContent`（UIViewRepresentable 包 `AVPlayerLayer`，`videoGravity = .resizeAspect`；静音默认开、可点喇叭切换；播到头回卷循环；底部细进度条），实况走 `LivePhotoCardContent`（`PHLivePhotoView`，载入后 `replayToken` 自增触发 `startPlayback(.full)`，点按重播）。**只有前置卡加载播放器**（`isFront`），后卡退化为缩略图。`UIViewRepresentable.Context.coordinator` 是只读属性，要记状态得用引用类型 coordinator。点按手势归属：媒体卡点按 = 播放控制，普通照片点按 = 全屏查看（`onOpenViewer`），都在 SortCard 内部，SortDeck 不再统一挂 onTap。
- **原图画质**：`AsyncThumbnail(highQuality: true)` 把请求尺寸乘 `displayScale × 1.5`（单边封顶 2800px），走 `ThumbnailLoader.fullCache`（只留 8 张，防内存爆）。网格缩略图别加这个开关。
- **分列删除**：`SortScreen.columnCount`（1/2/3），`MagnifyGesture().onEnded` 收拢 <0.82 加列、张开 >1.22 减列（相簿详情不支持分列——它的删除不走月份游标）。瀑布流在 `ColumnsGrid`：最短列优先分配；单元格用 `simultaneousGesture` 做横向滑删（|dx| > |dy|×1.2 才接管，70pt 过阈值，飞出 0.22s 后才调 `onMarkDelete`，与卡片区「先动效后数据」一致）。分列时操作岛隐藏，撤回挪到顶栏。
- **相似页**：`SimilarityService` 在 RootView 常驻（environment）。指纹 = 64×64 缩略图 → 9×8 灰度 → dHash；16 位分段分桶找候选对（桶 >60 跳过，防全白全黑误判风暴）；汉明 ≤ 7 并查集成组；组内最优按「像素数 + 文件MB」打分。指纹存 UserDefaults（`ac_similar_hash_v1`），增量扫描。视频不参与。删除一律进「待删除」，不直接动系统相册。
- **待删除结算页**：默认全勾（`unchecked` 集合记取消项），红条「彻底删除 N 项 · 释放 xx MB」。`deleteFromSystem` 返回 Bool：**成功后才把未勾选项 `restore` 放回相册**（参照「卡待删」语义）；用户取消系统弹窗则一切保持原样。删除成功时落账 `totalCleaned` / `totalFreedBytes`（UserDefaults），给「我的」统计卡。
- **相簿管理**：`AlbumItem.isUserAlbum` 区分自建 / 智能相簿（智能相簿不能重命名删除）。`createAlbum` / `renameAlbum` / `deleteAlbums` / `deleteAlbumWithPhotos` / `moveAllPhotos` 都是 async→Bool，成功后 `reloadAlbums()`。空相簿横幅只统计自建相簿。

**v4.0 SwiftUI 机制**：

- 数据源是 `PhotoLibraryService`（`@Observable` + `@MainActor`），在 `RootView` 用 `@State` 持有，往下用 `.environment(library)` 传；视图不自己存 PHAsset 列表副本。
- 缩略图走 `ThumbnailLoader`（NSCache + `withCheckedContinuation` 包 `PHImageManager`，`degraded` 中间帧直接丢弃），视图侧是 `AsyncThumbnail` + `.task(id:)`。
- 整理页**手势与按钮共用一条动效通道**：手势在 `SortDeck` 里跟手并按 90pt 判方向（下滑收藏只要 40pt），松手不自己改数据，只把结论交给外层；外层写 `SortScreen.command`（`DeckCommand`，带递增 token 以便 `.onChange` 认出同一种动作），`SortDeck.onChange(of: command)` 播完动效后先 `withoutAnimation { reset() }` 归位、再回调 `onFinished`，`SortScreen` 这时才改 `index` / 压栈 / 写 Photos。**顺序不能换**，否则会看到新卡从屏外飞回来。卡片尺寸按 `PhotoItem.ratio` 算并夹在 0.32–3.2。
- **`Transaction(disablesAnimations:)` 这个初始化器不存在**，复位动效状态一律走 `withoutAnimation`（`var transaction = Transaction(); transaction.disablesAnimations = true` + `withTransaction`）。
- 卡片区是**双层**：前置卡 + 后方 0.92 待命卡；前一卡飞出时后方卡用 `spring(0.42, 0.78)` 从 0.92 放大到 1.0 **并同步渐显**（待命时全透明，缩放与透明度共用同一个 Spring）。全程 `isPlaying` 期间不受理新操作。
- **撤回是通用撤销栈，不是只撤删除**：`UndoRecord` 记「操作类型 + 照片 + 操作前游标」，限深 50、切月清空。语义：删除→`restore` 按创建日期插回原月份原位且游标回到删除前；下一张→游标退一张；收藏→`setFavorite(false)` 且游标不动；存入相簿→`library.remove(_:from:)` 且游标退回上一张。动效上按 `UndoRecord.origin` **倒放**：当前卡从被拖到的位置退回后方 0.92 并渐隐，被撤那张从当初飞出去的方向飞回正面。
- 相簿详情复用 `SortScreen(album:)`：动作集只传 `[.undo, .delete, .next]`，标题用相簿名，`navigationBarTitleDisplayMode(.inline)`。
- 主题色走 `@AppStorage("ac_theme")` + `Color(hex:)`，`MainTabView` 用 `.tint` 应用；`@AppStorage` 直接落 UserDefaults，不再有 localStorage。
- 相簿照片只在 `.task(id: album?.id)` 里拉一次。**别把它写成计算属性**——那会让每次重绘都遍历整个相簿。
- 相簿页（2 列）与回收站（3 列）都是 `LazyVGrid`。**别把 `.aspectRatio(1, …)` 直接套在 `AsyncThumbnail` 上**：它的尺寸随图片比例浮动，排出来格子会参差。用 `Rectangle().fill(.quaternary)` 当底 + `.aspectRatio(1, contentMode: .fill)` 撑满列宽，缩略图放 `.overlay`，最后 `.clipShape` 裁圆角。相簿页封面 1:1 圆角 12、名称 / 数量居中在封面下方（无卡片底）；回收站 1:1 圆角 8、格间距 3 / 边距 12。

以下为 **v3 网页版**机制，v4.0 起不再参与构建，保留作对照。

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

**原生表单控件（v3.0.1）**：能用系统控件的地方一律交回系统，不再自绘。

- 开关是 `<input type="checkbox" role="switch" class="ios-switch">`。iOS 17.4 起 WebKit 会把它渲染成系统 `UISwitch`；`main.jsx` 里的 `detectNativeControls()` 命中时给 `<html>` 加 `data-native-controls="1"`，CSS 随即把 `appearance` 交回系统。桌面与旧系统走 `.ios-switch` 里同造型的液态玻璃回退。
- 「每轮数量」滑块是 `<input type="range" class="ios-range">`，iOS 上是系统 `UISlider`，其它环境用 `--range-pct` 控制自绘填充。
- 顶部月份选择是原生 `<select class="month-select">`，外观仍是玻璃胶囊，选项面板交给系统（iOS 上是原生选择器）。
- 改这些控件时注意：`appearance: none` 会覆盖原生外观，回退样式必须写在**非** `data-native-controls` 分支里。

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

- **v0.1（2026-11-02）**：更名 evernight（`Info.plist` 显示名 + `project.yml` 0.1 / 构建号 14）。移植「卡待删」核心能力：底栏改自定义 3+1（整理 / 相似 / 相簿胶囊 + 我的独立圆钮，我的从底部上滑覆盖成 sheet）；整理页前置卡原图级画质 + 视频 / 实况卡内播放（AVPlayerLayer / PHLivePhotoView）；双指收拢进分列瀑布流，左右滑标记删除；回收站改「待删除」结算页（全选 / 勾选 / 红色删除条，未勾选项放回）；新增相似页（dHash 指纹 + 分桶 + 并查集，最优保留 / 智能清理）；相簿管理（空相簿一键删除 / 新建 / 排序 / 长按菜单）。改前出了可编辑预览 `Previews/Evernight-V5-Feature-Preview.pptx`（11 页）并经用户拍板。**本机无 Xcode，编译验证靠 CI。**
- **整理页交互与动效（2026-10-15）**：撤回从「只撤删除」收敛为通用撤销栈（删除 / 下一张 / 收藏 / 存入相簿，限深 50、切月清空，「下一张」后撤回会退回上一张）；手势与按钮统一为「滑动分拣」动效——跟手平移、90pt 飞出、下一张从 0.92 Spring 放大**并同步渐显**（v0.1 增补：缩放与透明度共用同一 Spring），撤回按原动作倒放。下滑收藏改为 40pt 判定后弹回原位、不推进，提示胶囊透明度降到 30%。改前先出了可编辑预览 `Previews/Evernight-Sort-Motion-Preview.pptx`（8 页）并经用户拍板。
- **网格统一（2026-10-14）**：相簿页与回收站统一为 iOS 原生相册排列——相簿页去掉 `ContentPanel` 卡片底，改 2 列 1:1 正方形封面（圆角 12），名称 / 数量居中在封面下方；回收站改 3 列 1:1（圆角 8）、格间距 3 / 左右边距 12，用形状底修掉了原来格子参差的尺寸链，顶部说明行改为左对齐。**整理页（`SortScreen`）未动，交互与数据流不变**。改前先出了可编辑预览 `Previews/Evernight-Grid-Preview.pptx` 并经用户拍板。
- **v4.0**：UI 层从 WKWebView + React 整体改成 SwiftUI（现为 19 个 Swift 文件、约 1900 行）。删掉了 `AppDelegate` / `ViewController` / `LivePhotoViewController` / `PhotoLibraryManager`；新增 `Models` / `Services` / `Design` / `Components` / `Screens`。`project.yml` 不再打包 `WebContent`，最低系统从 iOS 14 提到 **iOS 17**，版本号 4.0（构建号 13）。`Info.plist` 的显示名改成 Evernight，并去掉了已无必要的 `NSAllowsArbitraryLoads`。
- **本机验证限制**：开发机是 Windows、没有 Xcode 与 Swift 工具链，**Swift 代码没有编译过**，只做了结构与括号的人工复核。真正的编译验证要靠 CI（macos-latest）。
- **v3.0.1（2026-10-07）**：开关、滑块、月份选择三个控件改成原生表单元素（iOS 上由系统渲染，桌面走自绘回退）；`main.jsx` 增加 iOS 版本检测；卡片照片区域加了极浅底色，浅色 mock 图不再和卡片糊在一起。
- **待真机确认**：`role="switch"` 的系统渲染需要 iOS 17.4+ 的 WebKit 支持，本机只有无头 Chrome，验证方式是用 iPhone UA 跑一次确认 `data-native-controls` 命中（已确认命中）。真机上若看到的是蓝勾选框而不是系统开关，说明该 WebKit 没启用这套渲染，把 `detectNativeControls` 的判断收紧或退回自绘。
- **v3.0（已提交 `539b93b`）**：三 tab 重构；目录改名 `Evernight/`；`WebContent/components/` 重写为 11 个组件（删掉 `HomePage` 与 `SettingsPage`）；Swift 侧新增 `creationDate` / `fileSize` / 相簿 `cover` / `getAlbumAssets` / `getStorageInfo`。`compile-jsx.js`、`project.yml`（含 `INFOPLIST_FILE`）、`README.md` 的路径已同步改为 `Evernight`。
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
- **v0.1 已清**：视频 / Live Photo 卡内播放（`MediaCardContent`）；「已喜欢」「待清理」统计（真实计数 + 累计战果落账）；相簿新建与空相簿清理。
- 整理页的「本轮已看」统计仍是写死的 0（每轮数量滑块 v0.1 起存 `ac_batchSize`，但还没有地方消费它——「一轮 N 个」的回合制玩法没做）。
- 隐藏的 tab 内容常驻：被 `opacity(0)` 盖住的整理页里若有视频卡在播，不会自动暂停（静音循环，开销小但存在）。
- 相簿详情（`SortScreen(album:)`）里删除 / 存相簿不会更新 `albumPhotos` 列表——v4.0 就存在的已知限制，分列模式因此在相簿详情里禁用。
- 相似检测阈值固定 7、桶上限 60，没做用户可调；dHash 对旋转 / 大幅裁剪不敏感是算法固有边界。
- **v4.0 待办**：`WebContent/` 与 `compile-jsx.js` / `package.json` 已无用途，确认不再需要后可以删。
- **v4.0 待办**：深色模式仍未实现（当前一律浅色壁纸）。
- **v4.0 依赖**：`glassEffect` / `GlassEffectContainer` / `.glass` 按钮样式需要 **iOS 26 SDK 编译**（运行时已有 `#available` 降级）。CI 的 macos-latest 如果 Xcode 版本落后，会在这几个符号上编译失败——先看 Actions 日志里的 `xcodebuild -version`。
- `PHAssetResource.assetResources` 读 `fileSize` 是逐张同步调用并缓存的，相册数量很大时会拖慢首次加载，后续可改后台索引。

## 9. 工作习惯

- 视觉改动一律先出预览图，拍板后再动项目文件；预览产物只放 `Previews/`。
- 不新增依赖：网页侧只用内联样式 + 既有 CSS 令牌，不引入 CSS 框架或动效库。
- 信息架构、文案、手势逻辑与既有动效曲线不经要求不改。
- Swift 侧改动前先读 `.agents/skills/write-swift`；网页动效改动前先读 `animate` 与 `apple-design`。

## 10. 项目全景速查（2026-11-02 · v0.1）

**文件规模**（不含 `node_modules/` 与 `.git/`）

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `Evernight/Services/PhotoLibraryService.swift` | 346 | 权限、按月分组、相簿增删改、待删除、累计战果、写入 |
| `Evernight/Screens/SimilarScreen.swift` | 214 | 相似页：年份筛选 + 智能清理 + 分组列表 |
| `Evernight/Screens/SortScreen.swift` | 298 | 整理页（相簿详情复用）+ 撤销栈 + 分列模式 + 动作 |
| `Evernight/Screens/AlbumsScreen.swift` | 291 | 相簿管理：空相簿横幅 / 新建 / 排序 / 长按菜单 |
| `Evernight/Screens/MineScreen.swift` | 283 | 我的面板（sheet）：深色统计卡 + 设置 |
| `Evernight/Components/MediaCardContent.swift` | 248 | 视频卡 / 实况卡卡内播放 |
| `Evernight/Components/SortDeck.swift` | 248 | 卡片区：跟手 / 飞出 / 下一张渐显入场 / 撤回倒放 |
| `Evernight/Services/SimilarityService.swift` | 221 | dHash 指纹 + 分桶 + 并查集分组 |
| `Evernight/Screens/TrashScreen.swift` | 166 | 待删除结算页 + 全屏查看 |
| `Evernight/Components/SortCard.swift` | 111 | 单张卡片视觉 + 空态 + badgeStyle |
| `Evernight/Design/GlassSurface.swift` | 109 | Liquid Glass 适配 + ContentPanel |
| `Evernight/Screens/MainTabView.swift` | 100 | 自定义底栏 + 我的 sheet + 待删除 cover |
| `Evernight/Components/SimilarGroupCard.swift` | 97 | 相似页的一组卡片 |
| `Evernight/Components/ColumnsGrid.swift` | 89 | 分列瀑布流 + 横向滑删 |
| `Evernight/EvernightApp.swift` | 86 | 入口 + 权限门 + UIState |
| `Evernight/Models/SortModels.swift` | 84 | SortMove / DeckCommand / UndoRecord / SortAction |
| `Evernight/Models/LibraryModels.swift` | 74 | PhotoItem / MonthSection / AlbumItem / StorageInfo / Format |
| `Evernight/Components/AppTabBar.swift` | 65 | 底栏 3+1 |
| `Evernight/Components/SortActionBar.swift` | 63 | 底部操作岛 |
| `Evernight/Design/Theme.swift` | 57 | 颜色圆角令牌 + 壁纸 + Color(hex:) |
| `Evernight/Services/ThumbnailLoader.swift` | 55 | 缩略图加载 + 双缓存 |
| `Evernight/Screens/FavoritesScreen.swift` | 51 | 已喜欢网格 |
| `Evernight/Components/ProgressHeader.swift` | 46 | 整理页进度胶囊 |
| `Evernight/Components/AsyncThumbnail.swift` | 39 | 缩略图视图（highQuality 开关） |
| `Evernight/Components/MonthMenu.swift` | 32 | 月份切换（系统 Menu） |
| `Evernight/Components/TrayButton.swift` | 30 | 待删除托盘 |
| `Evernight/Components/ToastBanner.swift` | 17 | 临时提示 |
| `project.yml` | 47 | xcodegen 配置（部署目标 iOS 17，0.1 / 14） |
| `Evernight/Info.plist` | 52 | 权限文案、启动屏、方向（显示名 evernight） |

合计 26 个 Swift 文件、3519 行。

**数据流**（v0.1）

| 界面动作 | 落到哪里 |
| --- | --- |
| 上滑删除 / 分列滑删 | `PhotoLibraryService.moveToTrash` → 只进应用内「待删除」，不动系统相册 |
| 待删除「彻底删除」 | `deleteFromSystem`（返 Bool）→ 成功后未勾选项 `restore` 放回；落账 `totalCleaned` / `totalFreedBytes` |
| 下滑收藏 | `setFavorite` → `PHAssetChangeRequest.isFavorite` |
| 操作岛「相簿」 | 原生 `confirmationDialog` 列相簿 → `add(_:to:)` → `PHAssetCollectionChangeRequest` |
| 撤回（按钮 / 右滑 / 分列顶栏） | 按 `UndoRecord` 倒做：删除 → `restore` 插回原月份原位；下一张 → 游标退一张；收藏 → `setFavorite(_:false)`；存入相簿 → `remove(_:from:)` |
| 手势 / 按钮触发动效 | 都写 `SortScreen.command` → `SortDeck` 播完再回调改数据（见第 5 节「整理页手势与按钮共用一条动效通道」） |
| 视频 / 实况卡内播放 | `MediaCardContent` → `PHCachingImageManager.requestAVAsset` / `requestLivePhoto` |
| 相似分组 | `SimilarityService.scan` → dHash 指纹（UserDefaults 缓存）→ 分桶 + 并查集 → 删除走 `moveToTrash` |
| 相簿管理 | `createAlbum` / `renameAlbum` / `deleteAlbums` / `deleteAlbumWithPhotos` / `moveAllPhotos` → 全直写系统相册 |
| 待删除 / 我的弹出 | 各页 `TrayButton` / 底栏圆钮 → `UIState.showTrash` / `showMine` → `MainTabView` 全屏覆盖 / 上滑 sheet |
| 缩略图 | `ThumbnailLoader` → `PHCachingImageManager.requestImage`，按 `identifier\|size` 缓存；大卡 `highQuality` 走独立缓存 |
| 存储占用 | `readStorage` → volumeTotalCapacity / volumeAvailableCapacityForImportantUsage |

**构建链路**

| 步骤 | 命令 / 产物 |
| --- | --- |
| 1 | `xcodegen generate` 生成 `AlbumCleaner.xcodeproj`（源目录是 `Evernight/`） |
| 2 | `xcodebuild -scheme AlbumCleaner -configuration Release -sdk iphoneos`（CI 里不签名） |
| 3 | 把 `.app` 装进 `Payload/` 再压成 `AlbumCleaner.ipa` |
| 4 | Actions artifact `AlbumCleaner-ipa`（保留 30 天）；失败时上传 `build.log` |
| 网页版（v3 遗留，仅预览用） | `node compile-jsx.js` + `Previews/_shot.html?tab=sort\|albums\|mine`（无头 Chrome 窗口小于 500px 会被强制放大，必须走夹具） |

**本轮核对结论**

| 项 | 状态 |
| --- | --- |
| v0.1 功能 | 底栏 3+1 / 我的 sheet / 卡内播放 / 原图画质 / 分列删除 / 待删除结算 / 相似 pHash / 相簿管理全部落地 |
| WebView 残留 | `Evernight/**/*.swift` 里已无 `WKWebView` / `photoApp` / `evaluateJavaScript` |
| 打包范围 | `project.yml` 不再引用 `WebContent`，网页资源不进 bundle |
| 版本号 | `project.yml` 0.1 / 构建号 14；显示名 evernight；`package.json` 是网页版遗留，不参与 App 版本 |
| Swift 编译 | **本机无 Xcode，未验证**；只做了结构与括号复核，编译要看 CI |
| `.gitignore` 生效项 | `Previews/`、`node_modules/`、`package-lock.json` |
