// v2.6 整理页：iOS 导航胶囊 + 进度 + 全屏观看（含下滑退出）+ 底部操作区
// 全屏观看层：捏合缩放 / 双击放大 / 平移 / 单击退出 / 下滑退出（iOS 相册式）

function MediaFullscreenOverlay({
  mode,
  photo,
  themeColor,
  onClose
}) {
  const [playing, setPlaying] = React.useState(false);
  const imgRef = React.useRef(null);
  const overlayRef = React.useRef(null);
  const touchRef = React.useRef({
    pointers: new Map(),
    startDist: 0,
    startZoom: 1,
    sx: 0,
    sy: 0,
    startPanX: 0,
    startPanY: 0,
    moved: false,
    lastTap: 0,
    zoom: 1,
    pan: {
      x: 0,
      y: 0
    },
    // v2.6 下滑退出跟踪
    startY: 0,
    overlayDy: 0,
    exitDrag: false
  });
  const applyTransform = () => {
    const img = imgRef.current;
    if (!img) return;
    const t = touchRef.current;
    img.style.transform = `translate(${t.pan.x}px, ${t.pan.y}px) scale(${t.zoom})`;
  };
  const applyOverlay = (dy, restoring) => {
    const ov = overlayRef.current;
    if (!ov) return;
    if (restoring) {
      ov.style.transition = 'transform 0.28s var(--ease-drawer), opacity 0.24s ease';
      ov.style.transform = 'translateY(0)';
      ov.style.opacity = '1';
      return;
    }
    ov.style.transition = 'none';
    ov.style.transform = `translateY(${dy}px)`;
    // 越往下拉越透明（iOS 相册下滑退出反馈）
    ov.style.opacity = String(Math.max(0, 1 - dy / 620));
  };
  const onPointerDown = e => {
    const t = touchRef.current;
    if (t.pointers.size === 0) {
      t.sx = e.clientX;
      t.sy = e.clientY;
      t.startPanX = t.pan.x;
      t.startPanY = t.pan.y;
      t.startY = e.clientY;
      t.moved = false;
      t.exitDrag = false;
    }
    t.pointers.set(e.pointerId, {
      x: e.clientX,
      y: e.clientY
    });
    if (t.pointers.size === 2) {
      const pts = [...t.pointers.values()];
      t.startDist = Math.max(1, Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y));
      t.startZoom = t.zoom;
      // 双指出现时取消下滑退出
      t.exitDrag = false;
      applyOverlay(0, true);
    }
    if (imgRef.current) {
      imgRef.current.style.transition = 'none';
      try {
        imgRef.current.setPointerCapture(e.pointerId);
      } catch (_) {}
    }
  };
  const onPointerMove = e => {
    const t = touchRef.current;
    if (!t.pointers.has(e.pointerId)) return;
    const prev = t.pointers.get(e.pointerId);
    const cur = {
      x: e.clientX,
      y: e.clientY
    };
    t.pointers.set(e.pointerId, cur);
    if (t.pointers.size === 2) {
      const pts = [...t.pointers.values()];
      const dist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
      let nextZoom = t.startZoom * (dist / t.startDist);
      nextZoom = Math.min(5, Math.max(1, nextZoom));
      t.zoom = nextZoom;
      if (nextZoom <= 1) t.pan = {
        x: 0,
        y: 0
      };
      applyTransform();
      t.moved = true;
    } else if (t.pointers.size === 1) {
      const p = t.pointers.get(e.pointerId);
      if (t.zoom > 1) {
        // 放大状态下：平移
        t.pan = {
          x: t.startPanX + (p.x - t.sx),
          y: t.startPanY + (p.y - t.sy)
        };
        applyTransform();
        if (Math.abs(p.x - t.sx) > 8 || Math.abs(p.y - t.sy) > 8) t.moved = true;
      } else {
        // 未放大：下滑跟手退出（iOS 相册式），轻微上滑也跟手（阻尼 0.5）
        const dy = p.y - t.startY;
        if (dy > 0) {
          t.exitDrag = true;
          t.moved = true;
          applyOverlay(dy * 0.55, false);
        } else if (dy < 0) {
          applyOverlay(dy * 0.18, false);
        }
      }
    }
  };
  const onPointerUp = e => {
    const t = touchRef.current;
    if (!t.pointers.has(e.pointerId)) return;
    t.pointers.delete(e.pointerId);

    // v2.6：下滑退出（未放大且下滑超过阈值）
    if (t.exitDrag && t.pointers.size === 0 && t.zoom <= 1) {
      const dy = t.pointers.size === 0 ? touchRef.current.sy ? t.overlayDy : 0 : 0;
      // 用最后一次记录的位移
      const ov = overlayRef.current;
      const lastDy = ov && ov.style.transform ? parseFloat((ov.style.transform.match(/translateY\(([-0-9.]+)px\)/) || [0, 0])[1]) || 0 : 0;
      if (lastDy > 110) {
        // 超过阈值：滑出退出
        ov.style.transition = 'transform 0.28s var(--ease-drawer), opacity 0.24s ease';
        ov.style.transform = 'translateY(100%)';
        ov.style.opacity = '0';
        setTimeout(onClose, 250);
        return;
      }
      // 未过阈值：回弹
      t.exitDrag = false;
      t.moved = false;
      applyOverlay(0, true);
      return;
    }

    // 单击 / 双击判定（仅无位移时）
    if (!t.moved) {
      const now = Date.now();
      if (now - t.lastTap < 300) {
        t.lastTap = 0;
        t.zoom = t.zoom > 1 ? 1 : 2.5;
        if (t.zoom <= 1) t.pan = {
          x: 0,
          y: 0
        };
        const img = imgRef.current;
        if (img) {
          img.style.transition = 'transform 0.22s var(--ease-drawer)';
          applyTransform();
          setTimeout(function () {
            if (img) img.style.transition = 'none';
          }, 240);
        }
        return;
      }
      t.lastTap = now;
      setTimeout(function () {
        if (t.lastTap === now) {
          t.lastTap = 0;
          onClose();
        }
      }, 300);
    } else {
      t.moved = false;
      // 非退出路径结束时，若未放大则复位 overlay
      if (t.zoom <= 1 && t.pointers.size === 0) applyOverlay(0, true);
    }
  };
  const onPointerCancel = e => {
    const t = touchRef.current;
    if (!t.pointers.has(e.pointerId)) return;
    t.pointers.delete(e.pointerId);
    t.exitDrag = false;
    if (t.zoom <= 1) applyOverlay(0, true);
  };
  return /*#__PURE__*/React.createElement("div", {
    ref: overlayRef,
    style: {
      position: 'fixed',
      inset: 0,
      zIndex: 500,
      background: '#000',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      animation: 'fullscreenIn 0.22s ease',
      overflow: 'hidden',
      touchAction: 'none'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      overflow: 'hidden'
    },
    onPointerDown: onPointerDown,
    onPointerMove: onPointerMove,
    onPointerUp: onPointerUp,
    onPointerCancel: onPointerCancel
  }, /*#__PURE__*/React.createElement("img", {
    ref: imgRef,
    src: photo.thumbnailUrl,
    alt: "",
    draggable: false,
    onClick: e => e.stopPropagation(),
    style: {
      maxWidth: '100%',
      maxHeight: '100%',
      objectFit: 'contain',
      display: 'block',
      willChange: 'transform',
      transformOrigin: 'center center',
      cursor: 'grab'
    }
  })), mode === 'video' && /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      position: 'absolute',
      left: 0,
      right: 0,
      bottom: 0,
      background: 'linear-gradient(to top, rgba(0,0,0,0.8), transparent)',
      padding: '40px 20px 24px',
      display: 'flex',
      flexDirection: 'column',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: () => setPlaying(!playing),
    style: {
      width: 44,
      height: 44,
      borderRadius: '50%',
      background: 'rgba(255,255,255,0.15)',
      border: 'none',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer',
      transition: 'transform 0.12s ease, background-color 0.15s ease'
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = 'scale(0.88)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    }
  }, playing ? /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 16 16"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "2",
    y: "2",
    width: "4.5",
    height: "12",
    rx: "1",
    fill: "#fff"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "9.5",
    y: "2",
    width: "4.5",
    height: "12",
    rx: "1",
    fill: "#fff"
  })) : /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 16 16"
  }, /*#__PURE__*/React.createElement("polygon", {
    points: "3,1 14,8 3,15",
    fill: "#fff"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 4,
      background: 'rgba(255,255,255,0.25)',
      borderRadius: 2,
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: playing ? '100%' : '35%',
      height: '100%',
      background: themeColor,
      borderRadius: 2,
      transition: playing ? 'width 6s linear' : 'none'
    }
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'rgba(255,255,255,0.8)',
      fontSize: 13,
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, photo.duration || '0:05')), /*#__PURE__*/React.createElement("div", {
    style: {
      color: 'rgba(255,255,255,0.6)',
      fontSize: 12,
      textAlign: 'center',
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, "\u6A21\u62DF\u5668\u6F14\u793A \xB7 \u771F\u673A\u5C06\u8C03\u7528\u7CFB\u7EDF\u64AD\u653E\u5668\u5168\u5C4F\u64AD\u653E")), mode === 'live' && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 60,
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      background: 'rgba(0,0,0,0.5)',
      padding: '6px 14px',
      borderRadius: 20
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: '#fff',
      fontSize: 13,
      fontWeight: 600,
      letterSpacing: 1.5,
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, "LIVE"), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 8,
      height: 8,
      borderRadius: '50%',
      background: '#FF453A',
      animation: 'livePulse 1.2s ease-in-out infinite'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: mode === 'video' ? 120 : 48,
      color: 'rgba(255,255,255,0.5)',
      fontSize: 13,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      pointerEvents: 'none'
    }
  }, mode === 'video' ? '点击空白处退出 · 下滑也可退出' : '轻点或下滑退出全屏'), /*#__PURE__*/React.createElement("style", null, `@keyframes livePulse { 0%,100% { opacity: 1; } 50% { opacity: 0.3; } }`));
}
function SortPage({
  month,
  photos,
  currentIndex,
  totalCount,
  processedCount,
  themeColor = '#007AFF',
  albums = null,
  autoPlayLive = true,
  autoPlayVideo = true,
  onBack,
  backLabel,
  onTrashClick,
  onAlbumAdd,
  onSwipeUp,
  onSwipeLeft,
  onSwipeRight,
  onSwipeDown,
  onUndo,
  onDeleteButton,
  onKeepButton,
  addedFeedback,
  toastMessage,
  historyLength,
  trashCount = 0,
  months,
  currentMonthId,
  onMonthSelect,
  actions,
  withTabBar = true
}) {
  const [bottomMode, setBottomMode] = React.useState('buttons');
  const [animating, setAnimating] = React.useState(false);
  const [fullscreen, setFullscreen] = React.useState(null);
  const stackRef = React.useRef(null);
  const total = totalCount || photos.length;
  const remaining = Math.max(0, total - processedCount);
  const progress = total > 0 ? processedCount / total * 100 : 0;
  const displayCurrent = photos.length > 0 ? processedCount + 1 : total;
  const hasPhoto = photos.length > 0 && currentIndex < photos.length;

  // 按钮操作：先播放动效，动画完成后再执行实际逻辑（防止连点）
  const playThen = (type, fn) => {
    if (animating) return;
    if (!fn) return;
    setAnimating(true);
    if (stackRef.current && stackRef.current.playFly) {
      stackRef.current.playFly(type, () => {
        setAnimating(false);
        fn();
      });
    } else {
      setAnimating(false);
      fn();
    }
  };
  const handleUndoClick = () => playThen('right', () => {
    if (onUndo) onUndo();
    setTimeout(function () {
      if (stackRef.current && stackRef.current.playFly) stackRef.current.playFly('in', function () {});
    }, 50);
  });
  const handleDeleteClick = () => playThen('up', onDeleteButton);
  const handleKeepClick = () => playThen('left', onKeepButton);
  const handleAlbumMode = () => {
    if (!hasPhoto) return;
    setBottomMode('albums');
  };
  const handleBackToButtons = () => setBottomMode('buttons');
  const handleAlbumAdd = album => playThen('down', () => {
    onAlbumAdd(album);
    setBottomMode('buttons');
  });

  // 点击媒体项目 → 全屏观看
  const handlePhotoTap = photo => {
    if (!photo || animating) return;
    if (photo.isVideo || photo.isLivePhoto) {
      if (window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
        window.NativeBridge.playMedia(photo.id);
      } else {
        setFullscreen({
          mode: photo.isVideo ? 'video' : 'live',
          photo
        });
      }
    } else {
      setFullscreen({
        mode: 'photo',
        photo
      });
    }
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      background: 'transparent',
      display: 'flex',
      flexDirection: 'column',
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement(TopBar, {
    monthLabel: backLabel ? undefined : month && month.title,
    months: months,
    currentMonthId: currentMonthId,
    onMonthSelect: onMonthSelect,
    backLabel: backLabel,
    centerTitle: backLabel ? month && month.title : undefined,
    onBack: onBack,
    trashCount: trashCount,
    onTrashClick: onTrashClick
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 20px 10px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44,
      borderRadius: 22,
      background: 'var(--glass-float)',
      backdropFilter: 'var(--blur-float)',
      WebkitBackdropFilter: 'var(--blur-float)',
      boxShadow: 'var(--edge-float)',
      display: 'flex',
      alignItems: 'center',
      padding: '0 16px',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      position: 'relative',
      height: 6,
      borderRadius: 3,
      background: 'var(--accent-soft)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 0,
      top: 0,
      bottom: 0,
      width: `${progress}%`,
      background: themeColor,
      borderRadius: 3,
      transition: 'width 0.35s var(--ease-out)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: `calc(${progress}% - 8px)`,
      top: -5,
      width: 16,
      height: 16,
      borderRadius: '50%',
      background: '#fff',
      boxShadow: '0 1px 4px rgba(0,0,0,0.18)',
      transition: 'left 0.35s var(--ease-out)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 700,
      color: '#34C759',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      minWidth: 28,
      textAlign: 'right'
    }
  }, remaining))), /*#__PURE__*/React.createElement(SwipeCardStack, {
    ref: stackRef,
    photos: photos,
    currentIndex: currentIndex,
    themeColor: themeColor,
    autoPlayLive: autoPlayLive,
    autoPlayVideo: autoPlayVideo,
    onPhotoTap: handlePhotoTap,
    onSwipeUp: onSwipeUp,
    onSwipeLeft: onSwipeLeft,
    onSwipeRight: onSwipeRight,
    onSwipeDown: onSwipeDown
  }), fullscreen && /*#__PURE__*/React.createElement(MediaFullscreenOverlay, {
    mode: fullscreen.mode,
    photo: fullscreen.photo,
    themeColor: themeColor,
    onClose: () => setFullscreen(null)
  }), toastMessage && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 'calc(var(--ios-safe-top) + 122px)',
      left: '50%',
      transform: 'translateX(-50%)',
      background: 'rgba(28,28,30,0.88)',
      color: '#fff',
      padding: '10px 18px',
      borderRadius: 18,
      fontSize: 14,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 500,
      zIndex: 200,
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      animation: 'toastBanner 0.28s var(--ease-out)',
      pointerEvents: 'none',
      boxShadow: '0 6px 22px rgba(0,0,0,0.22)',
      whiteSpace: 'nowrap'
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "17",
    height: "17",
    viewBox: "0 0 28 28",
    style: {
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "14",
    cy: "14",
    r: "12",
    fill: "none",
    stroke: "#34C759",
    strokeWidth: "3"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M8 14l4 4 8-8",
    stroke: "#34C759",
    strokeWidth: "3",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), /*#__PURE__*/React.createElement("span", null, toastMessage)), addedFeedback && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 'calc(var(--ios-safe-top) + 122px)',
      left: '50%',
      transform: 'translateX(-50%)',
      background: 'rgba(28,28,30,0.88)',
      color: '#fff',
      padding: '10px 18px',
      borderRadius: 18,
      fontSize: 14,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 500,
      zIndex: 200,
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      animation: 'toastBanner 0.28s var(--ease-out)',
      pointerEvents: 'none',
      boxShadow: '0 6px 22px rgba(0,0,0,0.22)',
      whiteSpace: 'nowrap'
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "17",
    height: "17",
    viewBox: "0 0 28 28",
    style: {
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "14",
    cy: "14",
    r: "12",
    fill: "none",
    stroke: "#34C759",
    strokeWidth: "3"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M8 14l4 4 8-8",
    stroke: "#34C759",
    strokeWidth: "3",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), /*#__PURE__*/React.createElement("span", null, "\u5DF2\u6DFB\u52A0\u5230\u300C", addedFeedback, "\u300D")), /*#__PURE__*/React.createElement(SortBottomBar, {
    mode: bottomMode,
    albums: albums,
    actions: actions || ['undo', 'delete', 'next', 'album'],
    canUndo: historyLength > 0,
    hasPhoto: hasPhoto,
    animating: animating,
    withTabBar: withTabBar,
    onUndo: handleUndoClick,
    onDelete: handleDeleteClick,
    onNext: handleKeepClick,
    onAlbumMode: handleAlbumMode,
    onBackToButtons: handleBackToButtons,
    onAlbumAdd: handleAlbumAdd
  }));
}
window.SortPage = SortPage;