// 全局动画样式 + 错误边界 + 主入口（预编译版本）

const globalAnimations = `
  @keyframes pageSlideLeft {
    from { transform: translateX(100%); }
    to { transform: translateX(0); }
  }
  @keyframes pageSlideRight {
    from { transform: translateX(-30%); opacity: 0.7; }
    to { transform: translateX(0); opacity: 1; }
  }
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  @keyframes fadeInScale {
    from { opacity: 0; transform: translate(-50%, -50%) scale(0.8); }
    to { opacity: 1; transform: translate(-50%, -50%) scale(1); }
  }
  @keyframes alertScaleIn {
    from { transform: scale(1.1); opacity: 0; }
    to { transform: scale(1); opacity: 1; }
  }
  @keyframes slideUp {
    from { transform: translateY(100%); }
    to { transform: translateY(0); }
  }
  @keyframes slideUpBar {
    from { transform: translateY(20px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  @keyframes slideDownBar {
    from { transform: translateY(-20px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }
  @keyframes buttonPress {
    0% { transform: scale(1); }
    50% { transform: scale(0.9); }
    100% { transform: scale(1); }
  }
  @keyframes cardIn {
    from { opacity: 0; transform: scale(0.9) translateY(20px); }
    to { opacity: 1; transform: scale(1) translateY(0); }
  }
  @keyframes shimmer {
    0% { background-position: -200% 0; }
    100% { background-position: 200% 0; }
  }
  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
  }
  /* v2.4 Liquid Glass：照片切换原生淡入淡出（轻微上移+缩放） */
  @keyframes fadeSlideIn {
    from { opacity: 0; transform: translateY(10px) scale(0.985); }
    to { opacity: 1; transform: translateY(0) scale(1); }
  }
  /* v2.4：玻璃面板浮现 */
  @keyframes glassIn {
    from { opacity: 0; transform: translateY(8px) scale(0.985); }
    to { opacity: 1; transform: translateY(0) scale(1); }
  }
  /* v2.5：Live 图自动播放模拟（缓慢推拉，模拟 Live Photo 动态） */
  @keyframes liveKenBurns {
    0% { transform: scale(1) translate(0, 0); }
    50% { transform: scale(1.07) translate(-1.5%, -1%); }
    100% { transform: scale(1.03) translate(1%, 1%); }
  }
  /* v2.5：视频自动播放模拟（进度扫描条） */
  @keyframes progressScan {
    from { width: 0%; }
    to { width: 100%; }
  }
  ::-webkit-scrollbar { display: none; }
  * { -webkit-tap-highlight-color: transparent; }
`;
const styleEl = document.createElement('style');
styleEl.textContent = globalAnimations;
document.head.appendChild(styleEl);

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