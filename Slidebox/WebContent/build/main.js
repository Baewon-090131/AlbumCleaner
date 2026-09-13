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
  ::-webkit-scrollbar { display: none; }
  * { -webkit-tap-highlight-color: transparent; }
`;
const styleEl = document.createElement('style');
styleEl.textContent = globalAnimations;
document.head.appendChild(styleEl);
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
      return React.createElement("div", {
        style: {
          padding: 40,
          fontFamily: '-apple-system, system-ui',
          fontSize: 15,
          color: '#333',
          background: '#F2F2F7',
          minHeight: '100vh'
        }
      }, React.createElement("div", {
        style: {
          fontWeight: 600,
          marginBottom: 10
        }
      }, "\u9875\u9762\u51FA\u9519"), React.createElement("div", {
        style: {
          fontSize: 13,
          lineHeight: 1.5
        }
      }, this.state.error.message || String(this.state.error)), React.createElement("pre", {
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
function RootApp() {
  return React.createElement("div", {
    style: {
      width: '100vw',
      height: '100vh',
      position: 'relative',
      '--ios-safe-top': 'env(safe-area-inset-top, 47px)',
      '--ios-safe-bottom': 'env(safe-area-inset-bottom, 34px)',
      background: '#F2F2F7',
      overflow: 'hidden'
    }
  }, React.createElement(ErrorBoundary, null, React.createElement(App, null)));
}
const root = document.getElementById('root');
ReactDOM.createRoot(root).render(React.createElement(RootApp, null));