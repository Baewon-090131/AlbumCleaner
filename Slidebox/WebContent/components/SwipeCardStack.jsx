// v2.6 照片卡片 + 滑动卡片栈（slidebox 风格手势，Apple 化动效）
// - 原生相册式：照片 contain 完整显示，黑底
// - 手势：上滑删除 / 左滑下一张 / 右滑撤回 / 下滑收藏（可中断、跟手、回弹）
// - 右缘下一页预览条（iOS 相册翻页提示）
// - playFly(type, onComplete)：按钮操作共用飞出/滑入动效
// - onPhotoTap：点击进入全屏观看

function PhotoCard({ photo, onTap, autoPlayLive = true, autoPlayVideo = true }) {
  const hasRealImage = photo.thumbnailUrl && (
    photo.thumbnailUrl.startsWith('photo://') || photo.thumbnailUrl.startsWith('data:')
  );
  const isNative = !!(window.NativeBridge && window.NativeBridge.isNative());
  // 真机内嵌自动播放（视频 → video:// 数据流；Live Photo → 配对视频数据流）
  const autoPlayMedia = (photo.isVideo && autoPlayVideo) || (photo.isLivePhoto && autoPlayLive);
  const videoSrc = autoPlayMedia && isNative && photo.id && !photo.id.startsWith('mock_')
    ? 'video://' + photo.id
    : null;

  // 图片加载完成前保持透明，加载完成后 0.18s 淡入（防黑屏闪烁）
  const imgRef = React.useRef(null);
  const [imgLoaded, setImgLoaded] = React.useState(false);
  React.useEffect(() => {
    setImgLoaded(false);
    const img = imgRef.current;
    if (img && img.complete && img.naturalWidth > 0) setImgLoaded(true);
  }, [photo.id]);

  // 模拟器（无真实媒体文件）：Live 用 Ken Burns 微动模拟；视频用进度扫描模拟
  const mockLiveAnim = !isNative && photo.isLivePhoto && autoPlayLive;
  const mockVideoAnim = !isNative && photo.isVideo && autoPlayVideo;

  return (
    <div
      onClick={(e) => { e.stopPropagation(); if (onTap) onTap(photo); }}
      style={{
        position: 'absolute',
        inset: 0,
        background: '#000',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
        cursor: 'pointer',
      }}>
      {hasRealImage ? (
        videoSrc ? (
          <video
            key={photo.id}
            src={videoSrc}
            poster={photo.thumbnailUrl}
            muted
            autoPlay
            playsInline
            loop
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'contain',
              display: 'block',
              pointerEvents: 'none',
            }}
          />
        ) : (
          <img
            ref={imgRef}
            src={photo.thumbnailUrl}
            alt=""
            decoding="async"
            draggable={false}
            onLoad={() => setImgLoaded(true)}
            onError={() => setImgLoaded(true)}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'contain',
              display: 'block',
              pointerEvents: 'none',
              opacity: imgLoaded ? 1 : 0,
              transition: 'opacity 0.18s ease',
              animation: mockLiveAnim ? 'liveKenBurns 4.5s ease-in-out infinite alternate' : undefined,
            }}
          />
        )
      ) : (
        <div style={{
          position: 'absolute',
          inset: 0,
          background: photo.gradient || 'linear-gradient(135deg, #2c3e50 0%, #bdc3c7 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          pointerEvents: 'none',
          animation: mockLiveAnim ? 'liveKenBurns 4.5s ease-in-out infinite alternate' : undefined,
          overflow: 'hidden',
        }}>
          <span style={{
            fontSize: 56,
            color: 'rgba(255,255,255,0.75)',
            filter: 'drop-shadow(0 2px 8px rgba(0,0,0,0.3))',
            userSelect: 'none',
          }}>🖼️</span>
        </div>
      )}

      {/* 模拟器视频自动播放覆盖层：底部进度扫描条 */}
      {mockVideoAnim && (
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0, height: 14, zIndex: 2,
          background: 'rgba(0,0,0,0.45)',
        }}>
          <div style={{
            height: '100%',
            background: 'rgba(255,255,255,0.85)',
            animation: 'progressScan 3.2s linear infinite',
          }} />
        </div>
      )}
      {mockVideoAnim && (
        <div style={{
          position: 'absolute', top: 14, left: 14, zIndex: 2,
          display: 'flex', alignItems: 'center', gap: 6,
          background: 'rgba(0,0,0,0.5)', padding: '5px 10px', borderRadius: 18,
        }}>
          <svg width="9" height="11" viewBox="0 0 10 12">
            <polygon points="0,0 10,6 0,12" fill="#fff"/>
          </svg>
          <span style={{ color: '#fff', fontSize: 11, fontWeight: 600, fontFamily: '-apple-system, "SF Pro", system-ui' }}>自动播放</span>
        </div>
      )}

      {/* 视频标识 */}
      {photo.isVideo && (
        <div style={{
          position: 'absolute',
          bottom: 16, right: 16,
          display: 'flex', alignItems: 'center', gap: 5,
          background: 'rgba(0,0,0,0.5)',
          backdropFilter: 'blur(4px)',
          padding: '4px 10px', borderRadius: 9,
          pointerEvents: 'none',
        }}>
          <svg width="11" height="13" viewBox="0 0 10 12">
            <polygon points="0,0 10,6 0,12" fill="#fff"/>
          </svg>
          <span style={{
            color: '#fff', fontSize: 12, fontWeight: 500,
            fontFamily: '-apple-system, "SF Pro", system-ui',
          }}>{photo.duration}</span>
        </div>
      )}

      {/* LIVE 标识（原生相册风格） */}
      {photo.isLivePhoto && (
        <div style={{
          position: 'absolute',
          bottom: 16, right: 16,
          display: 'flex', alignItems: 'center',
          background: 'rgba(0,0,0,0.5)',
          backdropFilter: 'blur(4px)',
          padding: '4px 10px', borderRadius: 9,
          pointerEvents: 'none',
        }}>
          <span style={{
            color: '#fff', fontSize: 12, fontWeight: 600, letterSpacing: 1,
            fontFamily: '-apple-system, "SF Pro", system-ui',
          }}>LIVE</span>
        </div>
      )}

      <SwipeHint photo={photo} />
    </div>
  );
}

// 拖拽时显示的操作方向提示（v2.6：iOS 系统色 + 玻璃质感）
function SwipeHint({ photo }) {
  const [hint, setHint] = React.useState(null);
  React.useEffect(() => {
    if (!window.__swipeHintBus) return undefined;
    const handler = (h) => {
      if (h && h.photoId === photo.id) setHint(h.direction);
      else if (!h) setHint(null);
    };
    window.__swipeHintBus.subscribe(handler);
    return () => {
      if (window.__swipeHintBus) window.__swipeHintBus.unsubscribe(handler);
    };
  }, [photo.id]);

  if (!hint) return null;
  const styles = {
    up: { top: '11%', left: '50%', transform: 'translateX(-50%)', background: 'rgba(255,59,48,0.18)', border: '1.5px solid rgba(255,59,48,0.8)', color: '#FF453A', text: '删除' },
    left: { top: '50%', left: '7%', transform: 'translateY(-50%)', background: 'rgba(52,199,89,0.18)', border: '1.5px solid rgba(52,199,89,0.8)', color: '#34C759', text: '下一张' },
    right: { top: '50%', right: '7%', transform: 'translateY(-50%)', background: 'rgba(255,159,10,0.18)', border: '1.5px solid rgba(255,159,10,0.8)', color: '#FF9F0A', text: '撤回' },
    down: { bottom: '11%', left: '50%', transform: 'translateX(-50%)', background: 'rgba(10,132,255,0.18)', border: '1.5px solid rgba(10,132,255,0.8)', color: '#0A84FF', text: '收藏' },
  }[hint];

  return (
    <div style={{
      position: 'absolute',
      zIndex: 30,
      padding: '10px 18px',
      borderRadius: 14,
      backdropFilter: 'blur(12px)',
      WebkitBackdropFilter: 'blur(12px)',
      fontSize: 14, fontWeight: 600,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      letterSpacing: 0.5,
      pointerEvents: 'none',
      animation: 'fadeInScale 0.18s var(--ease-out)',
      ...styles,
    }}>{styles.text}</div>
  );
}

const SwipeCardStack = React.forwardRef(function SwipeCardStack({
  photos, currentIndex, onPhotoTap,
  onSwipeUp, onSwipeLeft, onSwipeRight, onSwipeDown,
  autoPlayLive = true, autoPlayVideo = true,
}, ref) {
  const cardRef = React.useRef(null);
  const animatingRef = React.useRef(false);
  const dragRef = React.useRef({ active: false, pointerId: null, sx: 0, sy: 0, dx: 0, dy: 0, raf: 0, moved: false });
  const suppressClickRef = React.useRef(false);

  // 照片切换淡入淡出：首次进入不播；右滑/按钮撤回的“滑入”路径自带动画，跳过淡入防二次闪烁
  const firstRenderRef = React.useRef(true);
  const enteringRef = React.useRef(false);

  const currentPhoto = photos[currentIndex];
  const nextPhoto = photos[currentIndex + 1];

  // v2.6：切换淡入（0.24s，iOS 相册式：轻微上移 + 缩放 + 淡入）
  React.useEffect(() => {
    if (firstRenderRef.current) { firstRenderRef.current = false; return; }
    if (enteringRef.current) { enteringRef.current = false; return; }
    const card = cardRef.current;
    if (!card) return;
    card.style.transition = 'none';
    card.style.opacity = '0.2';
    card.style.transform = 'translateY(8px) scale(0.985)';
    void card.offsetWidth;
    card.style.transition = 'opacity 0.22s ease, transform 0.24s var(--ease-out)';
    card.style.opacity = '1';
    card.style.transform = 'translateY(0) scale(1)';
    const tid = setTimeout(function() { card.style.transition = 'none'; }, 300);
    return () => clearTimeout(tid);
  }, [currentPhoto && currentPhoto.id]);

  // 播放飞出/滑入动效（拖拽与按钮共用；保留 v2.4 防闪回复位逻辑）
  const playFly = (type, onComplete) => {
    const card = cardRef.current;
    if (animatingRef.current || !card) { if (onComplete) onComplete(); return; }
    animatingRef.current = true;
    const EASE = 'cubic-bezier(0.32, 0.72, 0, 1)';

    if (type === 'in') {
      enteringRef.current = true;
      card.style.transition = 'none';
      card.style.transform = 'translateX(100%)';
      card.style.opacity = '0';
      void card.offsetWidth;
      card.style.transition = `all 0.32s ${EASE}`;
      card.style.transform = 'translateX(0)';
      card.style.opacity = '1';
      setTimeout(function() {
        animatingRef.current = false;
        if (onComplete) onComplete();
      }, 300);
    } else {
      const transforms = {
        up: 'translateY(-108%) rotate(0deg)',
        left: 'translateX(-108%) rotate(-10deg)',
        right: 'translateX(108%) rotate(10deg)',
        down: 'translateY(108%) rotate(0deg)',
      };
      card.style.transition = `all 0.3s ${EASE}`;
      card.style.transform = transforms[type] || 'scale(0.7) rotate(0deg)';
      card.style.opacity = '0';
      setTimeout(function() {
        animatingRef.current = false;
        card.style.transition = 'none';
        card.style.transform = 'translateX(0) translateY(0) rotate(0deg)';
        card.style.opacity = '0';
        if (onComplete) onComplete();
      }, 285);
    }
  };

  React.useImperativeHandle(ref, () => ({
    playFly: playFly,
    isAnimating: function() { return animatingRef.current; },
  }));

  // 拖拽方向提示总线（ref 直驱，零 React 渲染）
  const hintBus = React.useMemo(() => {
    const listeners = [];
    return {
      subscribe: (fn) => { listeners.push(fn); return fn; },
      unsubscribe: (fn) => { const i = listeners.indexOf(fn); if (i >= 0) listeners.splice(i, 1); },
      emit: (h) => listeners.forEach(fn => fn(h)),
    };
  }, []);
  React.useEffect(() => {
    window.__swipeHintBus = hintBus;
    return () => { if (window.__swipeHintBus === hintBus) delete window.__swipeHintBus; };
  }, [hintBus]);

  // 手势：pointerdown/move/up（跟手拖动 + rAF 节流 + 指针捕获）
  const onPointerDown = (e) => {
    if (animatingRef.current) return;
    if (e.pointerType === 'mouse' && e.button !== 0) return;
    const drag = dragRef.current;
    drag.active = true;
    drag.pointerId = e.pointerId;
    drag.sx = e.clientX; drag.sy = e.clientY;
    drag.dx = 0; drag.dy = 0; drag.moved = false;
    const card = cardRef.current;
    if (card) { card.style.transition = 'none'; card.style.willChange = 'transform'; }
    try { e.currentTarget.setPointerCapture(e.pointerId); } catch (_) {}
  };

  const onPointerMove = (e) => {
    const drag = dragRef.current;
    if (!drag.active || e.pointerId !== drag.pointerId) return;
    const dx = e.clientX - drag.sx;
    const dy = e.clientY - drag.sy;
    if (Math.abs(dx) > 6 || Math.abs(dy) > 6) drag.moved = true;
    drag.dx = dx; drag.dy = dy;

    if (drag.moved) {
      const TH = 90;
      const hintDir = Math.abs(dx) > Math.abs(dy)
        ? (dx < -TH * 0.4 ? 'left' : dx > TH * 0.4 ? 'right' : null)
        : (dy < -TH * 0.4 ? 'up' : dy > TH * 0.4 ? 'down' : null);
      hintBus.emit(hintDir ? { photoId: currentPhoto && currentPhoto.id, direction: hintDir } : null);
    }

    if (drag.raf) return;
    drag.raf = requestAnimationFrame(function() {
      drag.raf = 0;
      const card = cardRef.current;
      if (!card) return;
      card.style.transform = `translate(${drag.dx}px, ${drag.dy}px) rotate(${drag.dx * 0.04}deg)`;
    });
  };

  const onPointerUp = (e) => {
    const drag = dragRef.current;
    if (!drag.active || e.pointerId !== drag.pointerId) return;
    drag.active = false;
    hintBus.emit(null);
    if (drag.raf) { cancelAnimationFrame(drag.raf); drag.raf = 0; }
    const dx = drag.dx, dy = drag.dy;
    const TH = 90;

    if (drag.moved && (Math.abs(dx) > TH || Math.abs(dy) > TH)) {
      suppressClickRef.current = true;
      if (Math.abs(dx) > Math.abs(dy)) {
        if (dx < 0) {
          playFly('left', function() { if (onSwipeLeft) onSwipeLeft(); });
        } else {
          playFly('right', function() {
            enteringRef.current = true;
            if (onSwipeRight) onSwipeRight();
            setTimeout(function() { playFly('in', function() {}); }, 50);
          });
        }
      } else {
        if (dy < 0) {
          playFly('up', function() { if (onSwipeUp) onSwipeUp(); });
        } else {
          playFly('down', function() { if (onSwipeDown) onSwipeDown(); });
        }
      }
    } else {
      const card = cardRef.current;
      if (card) {
        card.style.transition = 'transform 0.28s var(--ease-drawer)';
        card.style.transform = 'translate(0, 0) rotate(0deg)';
        setTimeout(function() { if (card) card.style.willChange = 'auto'; }, 320);
      }
    }
  };

  const onPointerCancel = (e) => {
    const drag = dragRef.current;
    if (!drag.active || e.pointerId !== drag.pointerId) return;
    drag.active = false;
    hintBus.emit(null);
    const card = cardRef.current;
    if (card) {
      card.style.transition = 'transform 0.28s var(--ease-drawer)';
      card.style.transform = 'translate(0, 0) rotate(0deg)';
    }
  };

  const handlePhotoTap = (photo) => {
    if (suppressClickRef.current) { suppressClickRef.current = false; return; }
    if (onPhotoTap) onPhotoTap(photo);
  };

  // v2.6 完成态：iOS 风格空态
  if (!currentPhoto) {
    return (
      <div style={{
        flex: 1,
        background: '#000',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        gap: 14,
        animation: 'fadeIn 0.4s ease',
      }}>
        <div style={{
          width: 72, height: 72, borderRadius: '50%',
          background: 'rgba(255,255,255,0.1)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
            <path d="M20 6L9 17l-5-5" stroke="rgba(255,255,255,0.85)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{
          fontFamily: '-apple-system, "SF Pro", system-ui',
          fontSize: 18, fontWeight: 600, color: 'rgba(255,255,255,0.9)',
        }}>本月项目已整理完毕</div>
        <div style={{
          fontFamily: '-apple-system, "SF Pro", system-ui',
          fontSize: 13.5, color: 'rgba(255,255,255,0.45)',
        }}>删除的照片已移入回收站</div>
      </div>
    );
  }

  return (
    <div style={{
      flex: 1,
      position: 'relative',
      background: '#000',
      overflow: 'hidden',
      touchAction: 'none',
    }}>
      {/* v2.6 右缘下一页预览条（iOS 相册翻页提示：露出下一张一窄条 + 渐变遮罩） */}
      {nextPhoto && (
        <div style={{
          position: 'absolute', top: 0, bottom: 0, right: 0, width: 18, zIndex: 1,
          overflow: 'hidden',
        }}>
          <div style={{
            position: 'absolute', inset: 0, width: 120,
            left: -102, // 从预览条左侧开始显示（cover 右缘）
          }}>
            {nextPhoto.thumbnailUrl && nextPhoto.thumbnailUrl.startsWith('photo://') ? (
              <img src={nextPhoto.thumbnailUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} draggable={false} />
            ) : (
              <div style={{ width: '100%', height: '100%', background: nextPhoto.gradient || '#333' }} />
            )}
          </div>
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(to left, rgba(0,0,0,0.45) 0%, rgba(0,0,0,0) 60%)',
          }} />
          <div style={{
            position: 'absolute', left: 0, top: 0, bottom: 0, width: 0.5,
            background: 'rgba(255,255,255,0.28)',
          }} />
        </div>
      )}

      {/* 当前卡（key 变化强制重建 DOM，清空动画残留样式） */}
      <div
        key={currentPhoto.id}
        ref={cardRef}
        onClick={(e) => { e.stopPropagation(); handlePhotoTap(currentPhoto); }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerCancel}
        style={{
          position: 'absolute',
          inset: 0,
          willChange: 'transform, opacity',
          cursor: 'grab',
        }}
      >
        <PhotoCard photo={currentPhoto} onTap={handlePhotoTap}
          autoPlayLive={autoPlayLive} autoPlayVideo={autoPlayVideo} />
      </div>

      {/* 下一张预加载 */}
      {nextPhoto && nextPhoto.thumbnailUrl && (
        <img
          src={nextPhoto.thumbnailUrl}
          alt=""
          aria-hidden="true"
          style={{ position: 'absolute', width: 1, height: 1, opacity: 0, pointerEvents: 'none' }}
        />
      )}
    </div>
  );
});

Object.assign(window, { PhotoCard, SwipeCardStack });
