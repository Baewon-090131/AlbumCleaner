// v2.6 全局动画样式 + 错误边界 + 主入口（预编译版本）
// 依据 apple-design / animate 规范：iOS 转场曲线、系统色、材质分层

const globalAnimations = `
  :root {
    /* iOS 系统色（Apple HIG） */
    --ac-blue: #007AFF;
    --ac-green: #34C759;
    --ac-red: #FF3B30;
    --ac-orange: #FF9500;
    --ac-yellow: #FFCC00;
    --ac-indigo: #5856D6;
    --ac-teal: #30B0C7;
    --ac-purple: #AF52DE;
    --ac-pink: #FF2D92;
    --ac-gray: #8E8E93;
    --ac-gray2: #AEAEB2;
    --ac-gray3: #C7C7CC;
    --ac-gray4: #D1D1D6;
    --ac-gray5: #E5E5EA;
    --ac-gray6: #F2F2F7;
    --ac-label: #000000;
    --ac-label-2: rgba(60,60,67,0.6);
    --ac-label-3: rgba(60,60,67,0.3);
    --ac-sep: rgba(60,60,67,0.09);
    /* 动画曲线 tokens（animate skill 规范值） */
    --ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);
    --ease-out: cubic-bezier(0.23, 1, 0.32, 1);
    --ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);
    --press-ms: 110ms;
    --page-transition-ms: 360ms;

    /* ===== iOS 27「液态玻璃 2.0」分层材质令牌 =====
       分层原则（apple-design §12 材质重量表达层级）：
       浮动的操作层用轻玻璃，承载文字的卡片/分组用厚玻璃 */
    --accent: #002FA7;
    --accent-soft: rgba(0,47,167,.16);
    --glass-float: rgba(255,255,255,.38);
    --glass-float-strong: rgba(255,255,255,.50);
    --glass-panel: rgba(255,255,255,.60);
    --glass-inner: rgba(255,255,255,.30);
    --blur-float: blur(14px) saturate(155%) brightness(1.02);
    --blur-panel: blur(30px) saturate(190%) brightness(1.05);
    --edge-float:
      inset 0 1px 0 rgba(255,255,255,.66),
      inset 0 0 0 .5px rgba(255,255,255,.30),
      0 8px 22px rgba(22,32,72,.09),
      0 1px 4px rgba(22,32,72,.05);
    --edge-panel:
      inset 0 1px 0 rgba(255,255,255,.95),
      inset 0 0 0 .5px rgba(255,255,255,.55),
      inset 0 -1px 0 rgba(255,255,255,.22),
      0 12px 32px rgba(22,32,72,.12),
      0 2px 8px rgba(22,32,72,.05);
    --edge-panel-soft:
      inset 0 1px 0 rgba(255,255,255,.88),
      inset 0 0 0 .5px rgba(255,255,255,.40),
      0 6px 20px rgba(22,32,72,.08);
    --edge-inner:
      inset 0 1px 0 rgba(255,255,255,.75),
      inset 0 0 0 .5px rgba(255,255,255,.45),
      0 4px 14px rgba(22,32,72,.10);
    --r-island: 28px;
    --r-panel: 28px;
    --r-tile: 20px;
    --r-plate: 34px;
  }

  /* ===== 页面转场（iOS push/pop，双页同框由 App.jsx 状态机驱动）=====
     每个页面拆成两层：外层是「不透明壁纸背板 + 裁切揭示」，内层是页面内容（负责位移）。
     外层不透明 → 旧页面不会透过新页面显示；两层同曲线同时长 → 观感仍是一次推入。
     壁纸背板不做位移，才能与 body 的壁纸逐像素对齐。 */
  @keyframes pageRevealIn {
    from { clip-path: inset(0 0 0 100%); }
    to { clip-path: inset(0 0 0 0); }
  }
  @keyframes pageSlideIn {
    from { transform: translateX(100%); }
    to { transform: translateX(0); }
  }
  @keyframes pageRevealOut {
    from { clip-path: inset(0 0 0 0); }
    to { clip-path: inset(0 0 0 100%); }
  }
  @keyframes pageSlideOut {
    from { transform: translateX(0); }
    to { transform: translateX(100%); }
  }

  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  @keyframes fadeInScale {
    from { opacity: 0; transform: translate(-50%, -50%) scale(0.88); }
    to { opacity: 1; transform: translate(-50%, -50%) scale(1); }
  }
  /* iOS 模态缩放：从 1.1 收拢到 1（alert） */
  @keyframes alertScaleIn {
    from { transform: scale(1.12); opacity: 0; }
    to { transform: scale(1); opacity: 1; }
  }
  /* iOS action sheet 底部滑入 */
  @keyframes sheetSlideUp {
    from { transform: translateY(100%); }
    to { transform: translateY(0); }
  }
  @keyframes slideUpBar {
    from { transform: translateY(24px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  /* 顶部导航岛入场（此前被三个页面引用但没有定义，这里补上） */
  @keyframes slideDownBar {
    from { transform: translateY(-24px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  @keyframes cardIn {
    from { opacity: 0; transform: scale(0.94) translateY(14px); }
    to { opacity: 1; transform: scale(1) translateY(0); }
  }
  /* 照片切换：原生 iOS 相册式淡入（轻微上移+缩放，0.22s 内完成） */
  @keyframes photoFadeIn {
    from { opacity: 0; transform: translateY(8px) scale(0.985); }
    to { opacity: 1; transform: translateY(0) scale(1); }
  }
  /* 玻璃面板浮现 */
  @keyframes glassIn {
    from { opacity: 0; transform: translateY(10px) scale(0.985); }
    to { opacity: 1; transform: translateY(0) scale(1); }
  }
  /* 全屏观看层进入（iOS 相册：暗场淡入） */
  @keyframes fullscreenIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  /* 顶部横幅 toast（iOS banner） */
  @keyframes toastBanner {
    from { opacity: 0; transform: translateY(-12px) scale(0.97); }
    to { opacity: 1; transform: translateY(0) scale(1); }
  }
  /* Live 图自动播放模拟（缓慢推拉） */
  @keyframes liveKenBurns {
    0% { transform: scale(1) translate(0, 0); }
    50% { transform: scale(1.07) translate(-1.5%, -1%); }
    100% { transform: scale(1.03) translate(1%, 1%); }
  }
  /* 视频自动播放模拟（进度扫描条：scaleX 合成层动画，避免 width 每帧 layout） */
  @keyframes progressScan {
    from { transform: scaleX(0); }
    to { transform: scaleX(1); }
  }
  /* 加载进度圈 */
  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  /* ===== 无障碍：系统「减弱动态效果」（apple-design §14 / animate §7）=====
     降级而非清零：保留淡入淡出与颜色变化，去掉位移、缩放与循环动效。
     进度条（progressScan）与加载圈（spin）属于状态指示，保留。
     JS 直驱的手势动效在 SwipeCardStack / App 内按同一条件降级。 */
  @media (prefers-reduced-motion: reduce) {
    @keyframes cardIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes fadeInScale {
      from { opacity: 0; transform: translate(-50%, -50%); }
      to { opacity: 1; transform: translate(-50%, -50%); }
    }
    @keyframes photoFadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes glassIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes slideUpBar {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes slideDownBar {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes sheetSlideUp {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes toastBanner {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes alertScaleIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes pageRevealIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes pageRevealOut {
      from { opacity: 1; }
      to { opacity: 0; }
    }
    /* 内容层在减弱动态效果下不做位移 */
    @keyframes pageSlideIn {
      from { transform: none; }
      to { transform: none; }
    }
    @keyframes pageSlideOut {
      from { transform: none; }
      to { transform: none; }
    }
    @keyframes fullscreenIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    /* 循环推拉（Ken Burns）在减弱动态效果下不播放 */
    @keyframes liveKenBurns {
      from { transform: none; }
      to { transform: none; }
    }
  }

  ::-webkit-scrollbar { display: none; }
  * { -webkit-tap-highlight-color: transparent; }

  /* iOS 列表按压高亮（transition 驱动，pointer 触发） */
  .ios-row {
    transition: background-color 0.15s ease;
  }
  .ios-row:active {
    background-color: rgba(0,0,0,0.06);
  }
  /* iOS 按钮按压反馈：110ms 缩放 */
  .ios-btn {
    transition: transform var(--press-ms) var(--ease-out), opacity 0.15s ease, background-color 0.15s ease;
  }
  .ios-btn:active {
    transform: scale(0.96);
  }
  /* 大标题（SF Pro Display 风格：负字距 + 紧凑行高） */
  .sf-title {
    font-family: -apple-system, "SF Pro Display", "SF Pro", system-ui, sans-serif;
    letter-spacing: -0.03em;
    font-weight: 700;
  }
  .sf-body {
    font-family: -apple-system, "SF Pro", system-ui, sans-serif;
    letter-spacing: -0.01em;
  }

  /* ---------- v3.0.1 原生表单控件 ---------- */
  /* 开关：iOS 17.4+ 交给 WebKit 渲染成系统 UISwitch，其余环境回退到同造型的自绘 */
  .ios-switch {
    -webkit-appearance: none;
    appearance: none;
    width: 51px; height: 31px; border-radius: 15.5px;
    position: relative; flex-shrink: 0; cursor: pointer;
    border: 0; padding: 0; margin: 0;
    background: linear-gradient(180deg, rgba(255,255,255,0.78) 0%, rgba(120,120,128,0.34) 100%);
    box-shadow: inset 0 1px 0 rgba(255,255,255,0.9), 0 2px 6px rgba(22,32,72,0.12);
    transition: background 0.22s var(--ease-drawer);
  }
  .ios-switch::after {
    content: '';
    position: absolute; top: 2px; left: 2px;
    width: 27px; height: 27px; border-radius: 50%;
    background: #fff;
    box-shadow: 0 1px 4px rgba(0,0,0,0.26), 0 0 0 0.5px rgba(0,0,0,0.04);
    transition: left 0.22s var(--ease-drawer);
  }
  .ios-switch:checked {
    background: linear-gradient(180deg, rgba(62,206,102,0.98) 0%, rgba(38,164,72,0.9) 100%);
    box-shadow: inset 0 1px 0 rgba(255,255,255,0.6), 0 2px 8px rgba(20,80,40,0.24);
  }
  .ios-switch:checked::after { left: 22px; }
  html[data-native-controls="1"] .ios-switch {
    -webkit-appearance: auto;
    appearance: auto;
    background: none; box-shadow: none;
    width: auto; height: auto; border-radius: 0;
  }
  html[data-native-controls="1"] .ios-switch::after { content: none; }

  /* 滑块：同一个套路，iOS 上是系统 UISlider */
  .ios-range {
    -webkit-appearance: none;
    appearance: none;
    width: 100%; height: 28px; margin: 0;
    background: transparent; cursor: pointer;
  }
  .ios-range::-webkit-slider-runnable-track {
    height: 8px; border-radius: 4px;
    background: linear-gradient(to right,
      #34C759 0%, #34C759 var(--range-pct, 10%),
      rgba(60,60,67,0.14) var(--range-pct, 10%), rgba(60,60,67,0.14) 100%);
  }
  .ios-range::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 28px; height: 28px; border-radius: 50%;
    background: #fff; margin-top: -10px; border: 0;
    box-shadow: 0 2px 8px rgba(22,32,72,0.22);
  }
  html[data-native-controls="1"] .ios-range {
    -webkit-appearance: auto;
    appearance: auto;
    width: 100%; height: auto;
  }
  html[data-native-controls="1"] .ios-range::-webkit-slider-runnable-track {
    background: none;
  }

  /* 月份选择：外观是玻璃胶囊，选项面板交给系统（iOS 上是原生选择器） */
  .month-select {
    -webkit-appearance: none;
    appearance: none;
    height: 34px; border: 0; margin: 0;
    border-radius: 17px; padding: 0 30px 0 13px;
    background: var(--glass-float-strong);
    backdrop-filter: var(--blur-float);
    -webkit-backdrop-filter: var(--blur-float);
    box-shadow: var(--edge-float);
    font-family: -apple-system, "SF Pro", system-ui, sans-serif;
    font-size: 15px; font-weight: 500; letter-spacing: -0.2px;
    color: #000;
  }
`;
const styleEl = document.createElement('style');
styleEl.textContent = globalAnimations;
document.head.appendChild(styleEl);

// v3.0.1：iOS 17.4 起 WebKit 会把 <input type="checkbox" role="switch"> 渲染成系统开关。
// 命中时交回系统绘制，其它环境继续用自绘的液态玻璃外观。
(function detectNativeControls() {
  try {
    const ua = navigator.userAgent || '';
    if (!/iPhone|iPad|iPod/.test(ua)) return;
    const match = ua.match(/OS (\d+)[_.](\d+)/);
    if (!match) return;
    const major = Number(match[1]);
    const minor = Number(match[2]);
    if (major > 17 || major === 17 && minor >= 4) {
      document.documentElement.dataset.nativeControls = '1';
    }
  } catch (e) {}
})();

// JS 全局错误上报（原生侧记录日志，便于排查）
window.addEventListener('error', function (e) {
  var msg = 'JS_ERROR: ' + (e.message || 'unknown');
  if (e.filename) msg += ' @ ' + e.filename + ':' + (e.lineno || 0);
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.photoApp) {
    try {
      window.webkit.messageHandlers.photoApp.postMessage({
        action: 'jsError',
        message: msg
      });
    } catch (err) {}
  }
});

// React 错误边界：渲染出错时显示具体信息，而不是白屏
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      error: null
    };
  }
  static getDerivedStateFromError(error) {
    return {
      error: error
    };
  }
  componentDidCatch(error, info) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.photoApp) {
      try {
        window.webkit.messageHandlers.photoApp.postMessage({
          action: 'jsError',
          message: 'REACT_ERROR: ' + (error && error.message)
        });
      } catch (err) {}
    }
  }
  render() {
    if (this.state.error) {
      return /*#__PURE__*/React.createElement("div", {
        style: {
          padding: 40,
          fontFamily: '-apple-system, system-ui',
          fontSize: 15,
          color: '#333',
          background: '#F2F2F7',
          minHeight: '100vh'
        }
      }, /*#__PURE__*/React.createElement("div", {
        style: {
          fontWeight: 600,
          marginBottom: 10
        }
      }, "\u9875\u9762\u51FA\u9519"), /*#__PURE__*/React.createElement("div", {
        style: {
          fontSize: 13,
          lineHeight: 1.5
        }
      }, this.state.error.message || String(this.state.error)), /*#__PURE__*/React.createElement("pre", {
        style: {
          fontSize: 11,
          whiteSpace: 'pre-wrap',
          marginTop: 12,
          color: '#888'
        }
      }, this.state.error.stack || ''));
    }
    return this.props.children;
  }
}

// 主入口
function RootApp() {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100vw',
      height: '100vh',
      position: 'relative',
      '--ios-safe-top': 'env(safe-area-inset-top, 47px)',
      '--ios-safe-bottom': 'env(safe-area-inset-bottom, 34px)',
      background: 'transparent',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement(ErrorBoundary, null, /*#__PURE__*/React.createElement(App, null)));
}
const root = document.getElementById('root');
ReactDOM.createRoot(root).render(/*#__PURE__*/React.createElement(RootApp, null));