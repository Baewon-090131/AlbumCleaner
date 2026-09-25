// 全屏观看层（v2.3：支持捏合缩放 / 双击放大 / 平移 / 单击退出）
// mode: 'photo' 静态照片全屏 | 'video' 模拟视频播放 | 'live' 模拟 Live Photo
function MediaFullscreenOverlay({ mode, photo, themeColor, onClose }) {
  const [playing, setPlaying] = React.useState(false);
  const imgRef = React.useRef(null);
  const touchRef = React.useRef({
    pointers: new Map(),
    startDist: 0,
    startZoom: 1,
    sx: 0, sy: 0,
    startPanX: 0, startPanY: 0,
    moved: false,
    lastTap: 0,
    zoom: 1,
    pan: { x: 0, y: 0 },
  });

  const applyTransform = () => {
    const img = imgRef.current;
    if (!img) return;
    const t = touchRef.current;
    img.style.transform = `translate(${t.pan.x}px, ${t.pan.y}px) scale(${t.zoom})`;
  };

  const onPointerDown = (e) => {
    const t = touchRef.current;
    if (t.pointers.size === 0) {
      t.sx = e.clientX; t.sy = e.clientY;
      t.startPanX = t.pan.x; t.startPanY = t.pan.y;
      t.moved = false;
    }
    t.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (t.pointers.size === 2) {
      const pts = [...t.pointers.values()];
      t.startDist = Math.max(1, Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y));
      t.startZoom = t.zoom;
    }
    if (imgRef.current) {
      imgRef.current.style.transition = 'none';
      try { imgRef.current.setPointerCapture(e.pointerId); } catch (_) {}
    }
  };

  const onPointerMove = (e) => {
    const t = touchRef.current;
    if (!t.pointers.has(e.pointerId)) return;
    const prev = t.pointers.get(e.pointerId);
    const cur = { x: e.clientX, y: e.clientY };
    t.pointers.set(e.pointerId, cur);

    if (t.pointers.size === 2) {
      // 双指捏合缩放（以屏幕中心为缩放原点）
      const pts = [...t.pointers.values()];
      const dist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
      let nextZoom = t.startZoom * (dist / t.startDist);
      nextZoom = Math.min(5, Math.max(1, nextZoom));
      t.zoom = nextZoom;
      if (nextZoom <= 1) t.pan = { x: 0, y: 0 };
      applyTransform();
      t.moved = true;
    } else if (t.pointers.size === 1 && t.zoom > 1) {
      // 单指平移（仅放大状态下）
      const p = t.pointers.get(e.pointerId);
      t.pan = { x: t.startPanX + (p.x - t.sx), y: t.startPanY + (p.y - t.sy) };
      applyTransform();
      if (Math.abs(p.x - t.sx) > 8 || Math.abs(p.y - t.sy) > 8) t.moved = true;
    }
  };

  const onPointerUp = (e) => {
    const t = touchRef.current;
    if (!t.pointers.has(e.pointerId)) return;
    t.pointers.delete(e.pointerId);

    // 单击 / 双击判定（仅无位移时）
    if (!t.moved) {
      const now = Date.now();
      if (now - t.lastTap < 300) {
        // 双击：切换放大/还原
        t.lastTap = 0;
        t.zoom = t.zoom > 1 ? 1 : 2.5;
        if (t.zoom <= 1) t.pan = { x: 0, y: 0 };
        const img = imgRef.current;
        if (img) {
          img.style.transition = 'transform 0.22s cubic-bezier(0.32, 0.72, 0, 1)';
          applyTransform();
          setTimeout(function() { if (img) img.style.transition = 'none'; }, 240);
        }
        return;
      }
      t.lastTap = now;
      setTimeout(function() {
        if (t.lastTap === now) {
          // 单击 → 退出全屏
          t.lastTap = 0;
          onClose();
        }
      }, 300);
    } else {
      t.moved = false;
    }
  };

  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 500,
      background: '#000',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      animation: 'fadeIn 0.25s ease',
      overflow: 'hidden',
      touchAction: 'none',
    }}>
      {/* 媒体主体（contain 完整显示，支持缩放/平移） */}
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        overflow: 'hidden',
      }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
      >
        <img
          ref={imgRef}
          src={photo.thumbnailUrl} alt="" draggable={false}
          onClick={(e) => e.stopPropagation()}
          style={{
            maxWidth: '100%', maxHeight: '100%', objectFit: 'contain', display: 'block',
            willChange: 'transform',
            transformOrigin: 'center center',
            cursor: 'grab',
          }}
        />
      </div>

      {/* 视频模拟播放器控件 */}
      {mode === 'video' && (
        <div onClick={(e) => e.stopPropagation()} style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: 'linear-gradient(to top, rgba(0,0,0,0.8), transparent)',
          padding: '40px 20px 24px',
          display: 'flex', flexDirection: 'column', gap: 12,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <button onClick={() => setPlaying(!playing)} style={{
              width: 44, height: 44, borderRadius: '50%',
              background: 'rgba(255,255,255,0.15)', border: 'none',
              display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
            }}>
              {playing ? (
                <svg width="16" height="16" viewBox="0 0 16 16">
                  <rect x="2" y="2" width="4.5" height="12" rx="1" fill="#fff"/>
                  <rect x="9.5" y="2" width="4.5" height="12" rx="1" fill="#fff"/>
                </svg>
              ) : (
                <svg width="16" height="16" viewBox="0 0 16 16">
                  <polygon points="3,1 14,8 3,15" fill="#fff"/>
                </svg>
              )}
            </button>
            <div style={{ flex: 1, height: 4, background: 'rgba(255,255,255,0.25)', borderRadius: 2, overflow: 'hidden' }}>
              <div style={{
                width: playing ? '100%' : '35%', height: '100%',
                background: themeColor, borderRadius: 2,
                transition: playing ? 'width 6s linear' : 'none',
              }} />
            </div>
            <span style={{ color: 'rgba(255,255,255,0.8)', fontSize: 13, fontFamily: '-apple-system, "SF Pro", system-ui' }}>
              {photo.duration || '0:05'}
            </span>
          </div>
          <div style={{
            color: 'rgba(255,255,255,0.6)', fontSize: 12, textAlign: 'center',
            fontFamily: '-apple-system, "SF Pro", system-ui',
          }}>模拟器演示 · 真机将调用系统播放器全屏播放</div>
        </div>
      )}

      {/* LIVE 标识（Live Photo 演示） */}
      {mode === 'live' && (
        <div style={{
          position: 'absolute', top: 60,
          display: 'flex', alignItems: 'center', gap: 8,
          background: 'rgba(0,0,0,0.5)', padding: '6px 14px', borderRadius: 20,
        }}>
          <span style={{ color: '#fff', fontSize: 13, fontWeight: 600, letterSpacing: 1.5, fontFamily: '-apple-system, "SF Pro", system-ui' }}>LIVE</span>
          <span style={{
            width: 8, height: 8, borderRadius: '50%',
            background: '#FF453A', animation: 'livePulse 1.2s ease-in-out infinite',
          }} />
        </div>
      )}

      {/* 关闭提示 */}
      <div style={{
        position: 'absolute', bottom: mode === 'video' ? 120 : 48,
        color: 'rgba(255,255,255,0.5)', fontSize: 13,
        fontFamily: '-apple-system, "SF Pro", system-ui',
        pointerEvents: 'none',
      }}>
        {mode === 'video' ? '点击空白处退出' : '轻点退出全屏'}
      </div>

      <style>{`@keyframes livePulse { 0%,100% { opacity: 1; } 50% { opacity: 0.3; } }`}</style>
    </div>
  );
}

function SortPage({
  month, photos, currentIndex, totalCount, processedCount,
  themeColor = '#007AFF', albums = null,
  onBack, onTrashClick, onAlbumAdd,
  onSwipeUp, onSwipeLeft, onSwipeRight, onSwipeDown,
  onUndo, onDeleteButton, onKeepButton,
  addedFeedback, toastMessage, historyLength,
}) {
  const [bottomMode, setBottomMode] = React.useState('buttons');
  const [animating, setAnimating] = React.useState(false);
  const [fullscreen, setFullscreen] = React.useState(null); // {mode:'photo'|'video'|'live', photo}
  const stackRef = React.useRef(null);
  const total = totalCount || photos.length;
  const remaining = Math.max(0, total - processedCount);
  const progress = total > 0 ? (processedCount / total) * 100 : 0;
  const displayCurrent = photos.length > 0 ? processedCount + 1 : total;
  const hasPhoto = photos.length > 0 && currentIndex < photos.length;

  // 按钮操作：先播放动效，动画完成后再执行实际逻辑（防止连点）
  const playThen = (type, fn) => {
    if (animating) return;
    if (!fn) return;
    setAnimating(true);
    if (stackRef.current && stackRef.current.playFly) {
      stackRef.current.playFly(type, () => { setAnimating(false); fn(); });
    } else {
      setAnimating(false);
      fn();
    }
  };
  // v2.4：撤回 = 当前卡片向右飞出 → 上一张从右侧滑回（与右滑手势一致的连贯动效，不再单卡横滑）
  const handleUndoClick = () => playThen('right', () => {
    if (onUndo) onUndo();
    setTimeout(function() {
      if (stackRef.current && stackRef.current.playFly) stackRef.current.playFly('in', function() {});
    }, 50);
  });
  const handleDeleteClick = () => playThen('up', onDeleteButton);
  const handleKeepClick = () => playThen('left', onKeepButton);
  const handleAlbumMode = () => { if (!hasPhoto) return; setBottomMode('albums'); };
  const handleBackToButtons = () => setBottomMode('buttons');
  const handleAlbumAdd = (album) => playThen('down', () => { onAlbumAdd(album); setBottomMode('buttons'); });

  // 点击媒体项目 → 全屏观看（v2.2.4）
  // 照片：前端全屏纯净模式；视频/Live：真机走原生播放器，模拟器演示
  const handlePhotoTap = (photo) => {
    if (!photo || animating) return;
    if (photo.isVideo || photo.isLivePhoto) {
      if (window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
        window.NativeBridge.playMedia(photo.id);
      } else {
        setFullscreen({ mode: photo.isVideo ? 'video' : 'live', photo });
      }
    } else {
      setFullscreen({ mode: 'photo', photo });
    }
  };

  return (
    <div style={{
      height: '100%', background: '#F2F2F7',
      display: 'flex', flexDirection: 'column', position: 'relative',
    }}>
      {/* v2.4 iOS 26 Liquid Glass：独立悬浮玻璃胶囊导航条 */}
      <div style={{
        position: 'relative', zIndex: 100,
        paddingTop: 'var(--ios-safe-top)',
        padding: 'var(--ios-safe-top) 12px 6px',
      }}>
        <div style={{
          position: 'relative', height: 50,
          borderRadius: 25,
          background: 'rgba(255,255,255,0.58)',
          backdropFilter: 'blur(35px) saturate(180%)',
          WebkitBackdropFilter: 'blur(35px) saturate(180%)',
          border: '0.5px solid rgba(255,255,255,0.8)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), 0 6px 20px rgba(0,0,0,0.06)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 8px',
        }}>
          <button onClick={onBack} style={{
            display: 'flex', alignItems: 'center', gap: 4,
            background: 'none', border: 'none', padding: '6px 10px', cursor: 'pointer',
            color: themeColor, fontSize: 17,
            fontFamily: '-apple-system, "SF Pro", system-ui', fontWeight: 400,
            transition: 'transform 0.16s cubic-bezier(0.32, 0.72, 0, 1)',
          }}
            onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(0.9)'; }}
            onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
          >
            <svg width="12" height="20" viewBox="0 0 12 20">
              <path d="M10 2L2 10l8 8" stroke={themeColor} strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <span>照片</span>
          </button>
          <div style={{
            position: 'absolute', left: '50%', top: '50%',
            transform: 'translate(-50%, -50%)',
            fontSize: 17, fontWeight: 600, color: '#000',
            fontFamily: '-apple-system, "SF Pro", system-ui', letterSpacing: -0.4,
          }}>{month.title}</div>
          <button onClick={onTrashClick} style={{
            background: 'none', border: 'none', padding: 6, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'transform 0.16s cubic-bezier(0.32, 0.72, 0, 1)',
          }}
            onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(0.86)'; }}
            onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
          >
            <svg width="21" height="21" viewBox="0 0 24 24" fill="none">
              <path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z"
                stroke={themeColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>
      </div>

      <SwipeCardStack
        ref={stackRef}
        photos={photos} currentIndex={currentIndex} themeColor={themeColor}
        onPhotoTap={handlePhotoTap}
        onSwipeUp={onSwipeUp} onSwipeLeft={onSwipeLeft}
        onSwipeRight={onSwipeRight} onSwipeDown={onSwipeDown}
      />

      {/* 全屏观看层 */}
      {fullscreen && (
        <MediaFullscreenOverlay
          mode={fullscreen.mode} photo={fullscreen.photo}
          themeColor={themeColor}
          onClose={() => setFullscreen(null)}
        />
      )}

      {toastMessage && (
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
          background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(10px)',
          color: '#fff', padding: '14px 20px', borderRadius: 14,
          fontSize: 15, fontFamily: '-apple-system, "SF Pro", system-ui',
          fontWeight: 500, zIndex: 200,
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
          animation: 'fadeInScale 0.25s ease', pointerEvents: 'none',
        }}>
          <svg width="28" height="28" viewBox="0 0 28 28">
            <circle cx="14" cy="14" r="12" fill="none" stroke="#34C759" strokeWidth="2.5"/>
            <path d="M8 14l4 4 8-8" stroke="#34C759" strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <span>{toastMessage}</span>
        </div>
      )}

      {addedFeedback && (
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
          background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(10px)',
          color: '#fff', padding: '14px 20px', borderRadius: 14,
          fontSize: 15, fontFamily: '-apple-system, "SF Pro", system-ui',
          fontWeight: 500, zIndex: 200,
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
          animation: 'fadeInScale 0.25s ease', pointerEvents: 'none',
        }}>
          <svg width="28" height="28" viewBox="0 0 28 28">
            <circle cx="14" cy="14" r="12" fill="none" stroke="#34C759" strokeWidth="2.5"/>
            <path d="M8 14l4 4 8-8" stroke="#34C759" strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          <span>已添加到「{addedFeedback}」</span>
        </div>
      )}

      <div style={{ padding: '0 12px 8px' }}>
        <div style={{
          borderRadius: 18,
          background: 'rgba(255,255,255,0.5)',
          backdropFilter: 'blur(20px) saturate(180%)',
          WebkitBackdropFilter: 'blur(20px) saturate(180%)',
          border: '0.5px solid rgba(255,255,255,0.7)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8), 0 2px 10px rgba(0,0,0,0.04)',
          padding: '8px 14px 10px',
        }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between',
            alignItems: 'center', marginBottom: 6,
          }}>
            <span style={{
              fontSize: 13, color: 'rgba(60,60,67,0.6)',
              fontFamily: '-apple-system, "SF Pro", system-ui',
            }}>{Math.min(displayCurrent, total)} / {total}</span>
            <span style={{
              fontSize: 13, color: 'rgba(60,60,67,0.6)',
              fontFamily: '-apple-system, "SF Pro", system-ui',
            }}>剩余 {remaining} 张</span>
          </div>
          <div style={{
            height: 4, background: 'rgba(60,60,67,0.12)',
            borderRadius: 2, overflow: 'hidden',
          }}>
            <div style={{
              height: '100%', width: `${progress}%`,
              background: themeColor, borderRadius: 2,
              transition: 'width 0.3s ease',
            }} />
          </div>
        </div>
      </div>

      <SortBottomBar
        themeColor={themeColor} mode={bottomMode} albums={albums}
        canUndo={historyLength > 0} hasPhoto={hasPhoto} animating={animating}
        onUndo={handleUndoClick} onDelete={handleDeleteClick} onNext={handleKeepClick}
        onAlbumMode={handleAlbumMode} onBackToButtons={handleBackToButtons}
        onAlbumAdd={handleAlbumAdd}
      />
    </div>
  );
}
window.SortPage = SortPage;
