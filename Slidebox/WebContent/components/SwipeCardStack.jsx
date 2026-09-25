// 照片卡片组件 - v2.3：原生相册式完整显示 + 点击全屏/LIVE标识
function PhotoCard({ photo, onTap }) {
  const hasRealImage = photo.thumbnailUrl && (
    photo.thumbnailUrl.startsWith('photo://') || photo.thumbnailUrl.startsWith('data:')
  );

  // v2.3.2：图片加载完成前保持透明，加载完成后 0.18s 淡入。
  // 删除/切换照片时新图就绪前不再长时间露出纯黑（配合原生 PNG 缓存秒显）
  const imgRef = React.useRef(null);
  const [imgLoaded, setImgLoaded] = React.useState(false);
  React.useEffect(() => {
    setImgLoaded(false);
    const img = imgRef.current;
    // 已加载完成（如缓存命中）直接显示，不闪不淡
    if (img && img.complete && img.naturalWidth > 0) setImgLoaded(true);
  }, [photo.id]);

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
            // 原生相册模式：contain 完整显示整张照片，任意比例不变形不丢内容（黑边补齐）
            objectFit: 'contain',
            display: 'block',
            pointerEvents: 'none',
            opacity: imgLoaded ? 1 : 0,
            transition: 'opacity 0.18s ease',
          }}
        />
      ) : (
        // 模拟数据占位：渐变色块 + 图片符号（网页模拟器可见）
        <div style={{
          position: 'absolute',
          inset: 0,
          background: photo.gradient || 'linear-gradient(135deg, #2c3e50 0%, #bdc3c7 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          pointerEvents: 'none',
        }}>
          <span style={{
            fontSize: 56,
            color: 'rgba(255,255,255,0.75)',
            filter: 'drop-shadow(0 2px 8px rgba(0,0,0,0.3))',
            userSelect: 'none',
          }}>🖼️</span>
        </div>
      )}

      {/* 视频标识 */}
      {photo.isVideo && (
        <div style={{
          position: 'absolute',
          bottom: 16,
          right: 16,
          display: 'flex',
          alignItems: 'center',
          gap: 5,
          background: 'rgba(0,0,0,0.5)',
          backdropFilter: 'blur(4px)',
          padding: '4px 10px',
          borderRadius: 9,
          pointerEvents: 'none',
        }}>
          <svg width="11" height="13" viewBox="0 0 10 12">
            <polygon points="0,0 10,6 0,12" fill="#fff"/>
          </svg>
          <span style={{
            color: '#fff',
            fontSize: 12,
            fontWeight: 500,
            fontFamily: '-apple-system, "SF Pro", system-ui',
          }}>{photo.duration}</span>
        </div>
      )}

      {/* LIVE 标识（原生相册风格） */}
      {photo.isLivePhoto && (
        <div style={{
          position: 'absolute',
          bottom: 16,
          right: 16,
          display: 'flex',
          alignItems: 'center',
          background: 'rgba(0,0,0,0.5)',
          backdropFilter: 'blur(4px)',
          padding: '4px 10px',
          borderRadius: 9,
          pointerEvents: 'none',
        }}>
          <span style={{
            color: '#fff',
            fontSize: 12,
            fontWeight: 600,
            letterSpacing: 1,
            fontFamily: '-apple-system, "SF Pro", system-ui',
          }}>LIVE</span>
        </div>
      )}

      {/* 滑动手势方向提示（v2.3） */}
      <SwipeHint photo={photo} />
    </div>
  );
}

// 拖拽时显示的操作方向提示
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
      // 防御：页面卸载时父组件可能已删除全局总线
      if (window.__swipeHintBus) window.__swipeHintBus.unsubscribe(handler);
    };
  }, [photo.id]);

  if (!hint) return null;
  const styles = {
    up: { top: '12%', left: '50%', transform: 'translateX(-50%)', background: 'rgba(255,59,48,0.16)', border: '1.5px solid rgba(255,59,48,0.75)', color: '#FF453A', text: '删除' },
    left: { top: '50%', left: '8%', transform: 'translateY(-50%)', background: 'rgba(52,199,89,0.16)', border: '1.5px solid rgba(52,199,89,0.75)', color: '#34C759', text: '下一张' },
    right: { top: '50%', right: '8%', transform: 'translateY(-50%)', background: 'rgba(255,159,10,0.16)', border: '1.5px solid rgba(255,159,10,0.75)', color: '#FF9F0A', text: '撤回' },
    down: { bottom: '12%', left: '50%', transform: 'translateX(-50%)', background: 'rgba(10,132,255,0.16)', border: '1.5px solid rgba(10,132,255,0.75)', color: '#0A84FF', text: '收藏' },
  }[hint];

  return (
    <div style={{
      position: 'absolute',
      zIndex: 30,
      padding: '10px 18px',
      borderRadius: 14,
      backdropFilter: 'blur(10px)',
      WebkitBackdropFilter: 'blur(10px)',
      fontSize: 14,
      fontWeight: 600,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      letterSpacing: 0.5,
      pointerEvents: 'none',
      animation: 'fadeInScale 0.18s ease',
      ...styles,
    }}>{styles.text}</div>
  );
}

// 全幅卡片展示组件（v2.3）
// - 原生相册式：照片 contain 完整显示，黑底
// - 滑动手势（slidebox 风格）：上滑删除 / 左滑下一张 / 右滑撤回 / 下滑收藏
// - 底部按钮模式并存（撤回/删除/下一张/相簿）
// - 暴露 playFly(type, onComplete)：按钮操作时播放飞出/滑入动效
// - onPhotoTap：点击媒体项目进入全屏观看
const SwipeCardStack = React.forwardRef(function SwipeCardStack({
  photos, currentIndex, onPhotoTap,
  onSwipeUp, onSwipeLeft, onSwipeRight, onSwipeDown,
}, ref) {
  const cardRef = React.useRef(null);
  const animatingRef = React.useRef(false);
  const dragRef = React.useRef({ active: false, pointerId: null, sx: 0, sy: 0, dx: 0, dy: 0, raf: 0, moved: false });
  const suppressClickRef = React.useRef(false);

  // v2.4：照片切换淡入淡出（原生 iOS 相册观感）。
  // firstRenderRef：首次进入不播；enteringRef：右滑/按钮撤回的“滑入”路径已自带动画，跳过淡入防二次闪烁
  const firstRenderRef = React.useRef(true);
  const enteringRef = React.useRef(false);

  const currentPhoto = photos[currentIndex];
  const nextPhoto = photos[currentIndex + 1];

  // v2.4：当前照片变化 → 卡片轻微上移+缩放淡入（0.3s，iOS ease）
  React.useEffect(() => {
    if (firstRenderRef.current) { firstRenderRef.current = false; return; }
    if (enteringRef.current) { enteringRef.current = false; return; }
    const card = cardRef.current;
    if (!card) return;
    card.style.transition = 'none';
    card.style.opacity = '0.2';
    card.style.transform = 'translateY(10px) scale(0.985)';
    void card.offsetWidth;
    card.style.transition = 'opacity 0.26s ease, transform 0.3s cubic-bezier(0.32, 0.72, 0, 1)';
    card.style.opacity = '1';
    card.style.transform = 'translateY(0) scale(1)';
    const tid = setTimeout(function() { card.style.transition = 'none'; }, 340);
    return () => clearTimeout(tid);
  }, [currentPhoto && currentPhoto.id]);

  // 播放飞出/滑入动效（拖拽与按钮共用）
  const playFly = (type, onComplete) => {
    const card = cardRef.current;
    if (animatingRef.current || !card) { if (onComplete) onComplete(); return; }
    animatingRef.current = true;
    const EASE = 'cubic-bezier(0.32, 0.72, 0, 1)';

    if (type === 'in') {
      // 滑入（撤回后新卡片从右侧滑回）— 已自带动画，切换淡入需跳过
      enteringRef.current = true;
      card.style.transition = 'none';
      card.style.transform = 'translateX(100%)';
      card.style.opacity = '0';
      void card.offsetWidth; // 强制重排，确保过渡生效
      card.style.transition = `all 0.32s ${EASE}`;
      card.style.transform = 'translateX(0)';
      card.style.opacity = '1';
      setTimeout(function() {
        animatingRef.current = false;
        if (onComplete) onComplete();
      }, 300);
    } else {
      // 飞出：删除↑ / 下一张← / 撤回→ / 收藏↓（行程 105%，利落不拖沓）
      var transforms = {
        up: 'translateY(-105%) rotate(0deg)',
        left: 'translateX(-105%) rotate(-12deg)',
        right: 'translateX(105%) rotate(12deg)',
        down: 'translateY(105%) rotate(0deg)',
      };
      card.style.transition = `all 0.32s ${EASE}`;
      card.style.transform = transforms[type] || 'scale(0.7) rotate(0deg)';
      card.style.opacity = '0';
      setTimeout(function() {
        animatingRef.current = false;
        // 关键修复：飞出动画结束后必须复位卡片位置，
        // 否则残留的 translateX(-105%) 会让下一张照片渲染在屏幕外（黑屏）
        card.style.transition = 'none';
        card.style.transform = 'translateX(0) translateY(0) rotate(0deg)';
        card.style.opacity = '1';
        if (onComplete) onComplete();
      }, 300);
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

  // 手势：pointerdown/move/up（拖动跟手，rAF 节流，零 React 渲染）
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

    // 方向提示（超过阈值一半时显示）
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
      // 已达成操作阈值 → 飞出并执行对应操作
      suppressClickRef.current = true;
      if (Math.abs(dx) > Math.abs(dy)) {
        if (dx < 0) {
          // 左滑：保留并下一张
          playFly('left', function() { if (onSwipeLeft) onSwipeLeft(); });
        } else {
          // 右滑：撤回上一个操作，新卡从右侧滑回（缩短空窗，衔接更紧凑）
          playFly('right', function() {
            enteringRef.current = true; // 即将滑入，跳过淡入防闪烁
            if (onSwipeRight) onSwipeRight();
            setTimeout(function() { playFly('in', function() {}); }, 50);
          });
        }
      } else {
        if (dy < 0) {
          // 上滑：删除
          playFly('up', function() { if (onSwipeUp) onSwipeUp(); });
        } else {
          // 下滑：收藏
          playFly('down', function() { if (onSwipeDown) onSwipeDown(); });
        }
      }
    } else {
      // 未达阈值 → 回弹到原位
      const card = cardRef.current;
      if (card) {
        card.style.transition = 'transform 0.28s cubic-bezier(0.32, 0.72, 0, 1)';
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
      card.style.transition = 'transform 0.28s cubic-bezier(0.32, 0.72, 0, 1)';
      card.style.transform = 'translate(0, 0) rotate(0deg)';
    }
  };

  const handlePhotoTap = (photo) => {
    // 拖拽后浏览器会触发 click，用标志吞掉
    if (suppressClickRef.current) { suppressClickRef.current = false; return; }
    if (onPhotoTap) onPhotoTap(photo);
  };

  if (!currentPhoto) {
    return (
      <div style={{
        flex: 1,
        background: '#000',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        gap: 12,
        animation: 'fadeIn 0.4s ease',
      }}>
        <div style={{ fontSize: 52 }}>🎉</div>
        <div style={{
          fontFamily: '-apple-system, "SF Pro", system-ui',
          fontSize: 17,
          color: 'rgba(255,255,255,0.7)',
        }}>本月项目已整理完毕</div>
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
      {/* key 变化强制重建 DOM，清空动画残留样式（双保险，杜绝黑屏） */}
      <div
        key={currentPhoto.id}
        ref={cardRef}
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
        <PhotoCard photo={currentPhoto} onTap={handlePhotoTap} />
      </div>

      {/* 下一张预加载（v2.3：提前拉取缩略图，翻页即现） */}
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
