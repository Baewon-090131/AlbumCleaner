# Album Cleaner - iOS 相册整理应用

一款参考 Slidebox 交互逻辑的 iOS 相册整理应用，使用 WKWebView 内嵌网页实现，**已接入真实照片库**。

## 功能特性

- 按月份分组展示照片和视频
- Tinder 式卡片堆叠，四向滑动手势：
  - ↑ 上滑：删除（移入应用内回收站）
  - ← 左滑：保留并跳到下一张
  - → 右滑：撤回上一步操作
  - ↓ 下滑：收藏（加入系统个人收藏）
- 底部四按钮操作：撤回、删除、下一张、相簿
- 相簿归类：点击相簿按钮可将当前照片加入指定相簿
- 回收站：应用内置回收站，支持恢复和彻底删除（二次确认后从系统删除）
- 设置页：12 种主题颜色切换（含北洋蓝）
- 多尺寸媒体适配：横图/竖图/全景/Live Photo 完整显示
- 纯 iOS 原生风格 UI

## 项目结构

```
AlbumCleaner/
├── .github/workflows/build.yml   # GitHub Actions 自动编译配置
├── project.yml                   # xcodegen 配置（CI 中自动生成 Xcode 项目）
├── Evernight/
│   ├── AppDelegate.swift          # 应用入口
│   ├── ViewController.swift       # WKWebView 控制器 + photo:// 缩略图加载
│   ├── PhotoLibraryManager.swift  # Photos framework 封装（权限/相册/缩略图缓存）
│   ├── Info.plist                 # 应用配置
│   ├── Assets.xcassets/           # 应用图标资源
│   └── WebContent/                # 网页资源（内嵌到 App）
│       ├── index.html             # 主入口
│       ├── data.js                # 数据加载器（原生优先 + 模拟降级）
│       ├── build/                 # 预编译组件（普通JS，无运行时Babel）
│       ├── vendor/                # React（本地，离线可用）
│       └── components/            # React 组件源码（JSX，改这里）
└── README.md
```

## 构建方式

### 方式一：GitHub Actions 自动编译（推荐，无需 Mac）

1. 将本项目推送到 GitHub 仓库
2. 进入仓库的 Actions 页面
3. 等待 "Build iOS IPA" 工作流完成（约 3-5 分钟）
4. 在工作流详情页的 Artifacts 区域下载 `AlbumCleaner-ipa`
5. 解压得到 `AlbumCleaner.ipa`
6. 用 SideStore 签名并安装到手机

### 方式二：本地 Xcode 编译（需要 Mac）

1. 安装 xcodegen：`brew install xcodegen`
2. 在项目根目录执行 `xcodegen generate` 生成 `AlbumCleaner.xcodeproj`
3. 用 Xcode 打开，在 Signing & Capabilities 中选择你的开发者证书
4. 修改 Bundle Identifier 为你自己的（如 com.yourname.albumcleaner）
5. 菜单栏 → Product → Archive → Distribute App → 导出 IPA

## 注意事项

- 已接入真实照片库（Photos framework），首次启动需授权相册权限
- 删除操作先进应用内回收站，回收站中的"彻底删除"才会真正从系统相册删除
- 修改 JSX 组件后，需要运行 `npm i && node compile-jsx.js` 重新预编译
- 应用图标为空（使用系统默认），可在 Assets.xcassets 中替换
- 最低支持 iOS 14.0

## SideStore 安装说明

1. 确保 SideStore 已正确配置你的开发者证书
2. 在 SideStore 中选择 "Install IPA"
3. 选择下载的 `AlbumCleaner.ipa`
4. 等待签名和安装完成
5. 在手机上打开应用即可使用
