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
  }

  /* ===== 页面转场（iOS push/pop，双页同框由 App.jsx 状态机驱动） ===== */
  @keyframes pagePushEnter {
    from { transform: translateX(100%); }
    to { transform: translateX(0); }
  }
  @keyframes pagePopLeave {
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
  /* 视频自动播放模拟（进度扫描条） */
  @keyframes progressScan {
    from { width: 0%; }
    to { width: 100%; }
  }
  /* 加载进度圈 */
  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
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
`;

const styleEl = document.createElement('style');
styleEl.textContent = globalAnimations;
document.head.appendChild(styleEl);

// JS 全局错误上报（原生侧记录日志，便于排查）
window.addEventListener('error', function(e) {
  var msg = 'JS_ERROR: ' + (e.message || 'unknown');
  if (e.filename) msg += ' @ ' + e.filename + ':' + (e.lineno || 0);
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.photoApp) {
    try {
      window.webkit.messageHandlers.photoApp.postMessage({ action: 'jsError', message: msg });
    } catch (err) {}
  }
});

// React 错误边界：渲染出错时显示具体信息，而不是白屏
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }
  static getDerivedStateFromError(error) {
    return { error: error };
  }
  componentDidCatch(error, info) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.photoApp) {
      try {
        window.webkit.messageHandlers.photoApp.postMessage({ action: 'jsError', message: 'REACT_ERROR: ' + (error && error.message) });
      } catch (err) {}
    }
  }
  render() {
    if (this.state.error) {
      return (
        <div style={{ padding: 40, fontFamily: '-apple-system, system-ui', fontSize: 15, color: '#333', background: '#F2F2F7', minHeight: '100vh' }}>
          <div style={{ fontWeight: 600, marginBottom: 10 }}>页面出错</div>
          <div style={{ fontSize: 13, lineHeight: 1.5 }}>{this.state.error.message || String(this.state.error)}</div>
          <pre style={{ fontSize: 11, whiteSpace: 'pre-wrap', marginTop: 12, color: '#888' }}>{this.state.error.stack || ''}</pre>
        </div>
      );
    }
    return this.props.children;
  }
}

// 主入口
function RootApp() {
  return (
    <div style={{
      width: '100vw',
      height: '100vh',
      position: 'relative',
      '--ios-safe-top': 'env(safe-area-inset-top, 47px)',
      '--ios-safe-bottom': 'env(safe-area-inset-bottom, 34px)',
      background: 'transparent',
      overflow: 'hidden',
    }}>
      <ErrorBoundary>
        <App />
      </ErrorBoundary>
    </div>
  );
}

const root = document.getElementById('root');
ReactDOM.createRoot(root).render(<RootApp />);
