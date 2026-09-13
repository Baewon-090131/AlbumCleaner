function PhotoCard({
  photo,
  onTap
}) {
  const hasRealImage = photo.thumbnailUrl && (photo.thumbnailUrl.startsWith('photo://') || photo.thumbnailUrl.startsWith('data:'));
  return React.createElement("div", {
    onClick: e => {
      e.stopPropagation();
      if (onTap) onTap(photo);
    },
    style: {
      position: 'absolute',
      inset: 0,
      background: '#000',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      overflow: 'hidden',
      cursor: 'pointer'
    }
  }, hasRealImage ? React.createElement("img", {
    src: photo.thumbnailUrl,
    alt: "",
    decoding: "async",
    draggable: false,
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'contain',
      display: 'block',
      pointerEvents: 'none'
    }
  }) : React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: photo.gradient || 'linear-gradient(135deg, #2c3e50 0%, #bdc3c7 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      pointerEvents: 'none'
    }
  }, React.createElement("span", {
    style: {
      fontSize: 56,
      color: 'rgba(255,255,255,0.75)',
      filter: 'drop-shadow(0 2px 8px rgba(0,0,0,0.3))',
      userSelect: 'none'
    }
  }, "\uD83D\uDDBC\uFE0F")), photo.isVideo && React.createElement("div", {
    style: {
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
      pointerEvents: 'none'
    }
  }, React.createElement("svg", {
    width: "11",
    height: "13",
    viewBox: "0 0 10 12"
  }, React.createElement("polygon", {
    points: "0,0 10,6 0,12",
    fill: "#fff"
  })), React.createElement("span", {
    style: {
      color: '#fff',
      fontSize: 12,
      fontWeight: 500,
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, photo.duration)), photo.isLivePhoto && React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 16,
      right: 16,
      display: 'flex',
      alignItems: 'center',
      background: 'rgba(0,0,0,0.5)',
      backdropFilter: 'blur(4px)',
      padding: '4px 10px',
      borderRadius: 9,
      pointerEvents: 'none'
    }
  }, React.createElement("span", {
    style: {
      color: '#fff',
      fontSize: 12,
      fontWeight: 600,
      letterSpacing: 1,
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, "LIVE")), React.createElement(SwipeHint, {
    photo: photo
  }));
}
function SwipeHint({
  photo
}) {
  const [hint, setHint] = React.useState(null);
  React.useEffect(() => {
    if (!window.__swipeHintBus) return undefined;
    const handler = h => {
      if (h && h.photoId === photo.id) setHint(h.direction);else if (!h) setHint(null);
    };
    window.__swipeHintBus.subscribe(handler);
    return () => {
      if (window.__swipeHintBus) window.__swipeHintBus.unsubscribe(handler);
    };
  }, [photo.id]);
  if (!hint) return null;
  const styles = {
    up: {
      top: '12%',
      left: '50%',
      transform: 'translateX(-50%)',
      background: 'rgba(255,59,48,0.16)',
      border: '1.5px solid rgba(255,59,48,0.75)',
      color: '#FF453A',
      text: '删除'
    },
    left: {
      top: '50%',
      left: '8%',
      transform: 'translateY(-50%)',
      background: 'rgba(52,199,89,0.16)',
      border: '1.5px solid rgba(52,199,89,0.75)',
      color: '#34C759',
      text: '下一张'
    },
    right: {
      top: '50%',
      right: '8%',
      transform: 'translateY(-50%)',
      background: 'rgba(255,159,10,0.16)',
      border: '1.5px solid rgba(255,159,10,0.75)',
      color: '#FF9F0A',
      text: '撤回'
    },
    down: {
      bottom: '12%',
      left: '50%',
      transform: 'translateX(-50%)',
      background: 'rgba(10,132,255,0.16)',
      border: '1.5px solid rgba(10,132,255,0.75)',
      color: '#0A84FF',
      text: '收藏'
    }
  }[hint];
  return React.createElement("div", {
    style: {
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
      ...styles
    }
  }, styles.text);
}
const SwipeCardStack = React.forwardRef(function SwipeCardStack({
  photos,
  currentIndex,
  onPhotoTap,
  onSwipeUp,
  onSwipeLeft,
  onSwipeRight,
  onSwipeDown
}, ref) {
  const cardRef = React.useRef(null);
  const animatingRef = React.useRef(false);
  const dragRef = React.useRef({
    active: false,
    pointerId: null,
    sx: 0,
    sy: 0,
    dx: 0,
    dy: 0,
    raf: 0,
    moved: false
  });
  const suppressClickRef = React.useRef(false);
  const playFly = (type, onComplete) => {
    const card = cardRef.current;
    if (animatingRef.current || !card) {
      if (onComplete) onComplete();
      return;
    }
    animatingRef.current = true;
    const EASE = 'cubic-bezier(0.32, 0.72, 0, 1)';
    if (type === 'in') {
      card.style.transition = 'none';
      card.style.transform = 'translateX(130vw)';
      card.style.opacity = '0';
      void card.offsetWidth;
      card.style.transition = `all 0.38s ${EASE}`;
      card.style.transform = 'translateX(0)';
      card.style.opacity = '1';
      setTimeout(function () {
        animatingRef.current = false;
        if (onComplete) onComplete();
      }, 360);
    } else {
      var transforms = {
        up: 'translateY(-130vh) rotate(0deg)',
        left: 'translateX(-130vw) rotate(-12deg)',
        right: 'translateX(130vw) rotate(12deg)',
        down: 'translateY(130vh) rotate(0deg)'
      };
      card.style.transition = `all 0.36s ${EASE}`;
      card.style.transform = transforms[type] || 'scale(0.7) rotate(0deg)';
      card.style.opacity = '0';
      setTimeout(function () {
        animatingRef.current = false;
        card.style.transition = 'none';
        card.style.transform = 'translateX(0) translateY(0) rotate(0deg)';
        card.style.opacity = '1';
        if (onComplete) onComplete();
      }, 340);
    }
  };
  React.useImperativeHandle(ref, () => ({
    playFly: playFly,
    isAnimating: function () {
      return animatingRef.current;
    }
  }));
  const currentPhoto = photos[currentIndex];
  const nextPhoto = photos[currentIndex + 1];
  const hintBus = React.useMemo(() => {
    const listeners = [];
    return {
      subscribe: fn => {
        listeners.push(fn);
        return fn;
      },
      unsubscribe: fn => {
        const i = listeners.indexOf(fn);
        if (i >= 0) listeners.splice(i, 1);
      },
      emit: h => listeners.forEach(fn => fn(h))
    };
  }, []);
  React.useEffect(() => {
    window.__swipeHintBus = hintBus;
    return () => {
      if (window.__swipeHintBus === hintBus) delete window.__swipeHintBus;
    };
  }, [hintBus]);
  const onPointerDown = e => {
    if (animatingRef.current) return;
    if (e.pointerType === 'mouse' && e.button !== 0) return;
    const drag = dragRef.current;
    drag.active = true;
    drag.pointerId = e.pointerId;
    drag.sx = e.clientX;
    drag.sy = e.clientY;
    drag.dx = 0;
    drag.dy = 0;
    drag.moved = false;
    const card = cardRef.current;
    if (card) {
      card.style.transition = 'none';
      card.style.willChange = 'transform';
    }
    try {
      e.currentTarget.setPointerCapture(e.pointerId);
    } catch (_) {}
  };
  const onPointerMove = e => {
    const drag = dragRef.current;
    if (!drag.active || e.pointerId !== drag.pointerId) return;
    const dx = e.clientX - drag.sx;
    const dy = e.clientY - drag.sy;
    if (Math.abs(dx) > 6 || Math.abs(dy) > 6) drag.moved = true;
    drag.dx = dx;
    drag.dy = dy;
    if (drag.moved) {
      const TH = 90;
      const hintDir = Math.abs(dx) > Math.abs(dy) ? dx < -TH * 0.4 ? 'left' : dx > TH * 0.4 ? 'right' : null : dy < -TH * 0.4 ? 'up' : dy > TH * 0.4 ? 'down' : null;
      hintBus.emit(hintDir ? {
        photoId: currentPhoto && currentPhoto.id,
        direction: hintDir
      } : null);
    }
    if (drag.raf) return;
    drag.raf = requestAnimationFrame(function () {
      drag.raf = 0;
      const card = cardRef.current;
      if (!card) return;
      card.style.transform = `translate(${drag.dx}px, ${drag.dy}px) rotate(${drag.dx * 0.04}deg)`;
    });
  };
  const onPointerUp = e => {
    const drag = dragRef.current;
    if (!drag.active || e.pointerId !== drag.pointerId) return;
    drag.active = false;
    hintBus.emit(null);
    if (drag.raf) {
      cancelAnimationFrame(drag.raf);
      drag.raf = 0;
    }
    const dx = drag.dx,
      dy = drag.dy;
    const TH = 90;
    if (drag.moved && (Math.abs(dx) > TH || Math.abs(dy) > TH)) {
      suppressClickRef.current = true;
      if (Math.abs(dx) > Math.abs(dy)) {
        if (dx < 0) {
          playFly('left', function () {
            if (onSwipeLeft) onSwipeLeft();
          });
        } else {
          playFly('right', function () {
            if (onSwipeRight) onSwipeRight();
            setTimeout(function () {
              playFly('in', function () {});
            }, 90);
          });
        }
      } else {
        if (dy < 0) {
          playFly('up', function () {
            if (onSwipeUp) onSwipeUp();
          });
        } else {
          playFly('down', function () {
            if (onSwipeDown) onSwipeDown();
          });
        }
      }
    } else {
      const card = cardRef.current;
      if (card) {
        card.style.transition = 'transform 0.28s cubic-bezier(0.32, 0.72, 0, 1)';
        card.style.transform = 'translate(0, 0) rotate(0deg)';
        setTimeout(function () {
          if (card) card.style.willChange = 'auto';
        }, 320);
      }
    }
  };
  const onPointerCancel = e => {
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
  const handlePhotoTap = photo => {
    if (suppressClickRef.current) {
      suppressClickRef.current = false;
      return;
    }
    if (onPhotoTap) onPhotoTap(photo);
  };
  if (!currentPhoto) {
    return React.createElement("div", {
      style: {
        flex: 1,
        background: '#000',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        gap: 12,
        animation: 'fadeIn 0.4s ease'
      }
    }, React.createElement("div", {
      style: {
        fontSize: 52
      }
    }, "\uD83C\uDF89"), React.createElement("div", {
      style: {
        fontFamily: '-apple-system, "SF Pro", system-ui',
        fontSize: 17,
        color: 'rgba(255,255,255,0.7)'
      }
    }, "\u672C\u6708\u9879\u76EE\u5DF2\u6574\u7406\u5B8C\u6BD5"));
  }
  return React.createElement("div", {
    style: {
      flex: 1,
      position: 'relative',
      background: '#000',
      overflow: 'hidden',
      touchAction: 'none'
    }
  }, React.createElement("div", {
    key: currentPhoto.id,
    ref: cardRef,
    onPointerDown: onPointerDown,
    onPointerMove: onPointerMove,
    onPointerUp: onPointerUp,
    onPointerCancel: onPointerCancel,
    style: {
      position: 'absolute',
      inset: 0,
      willChange: 'transform, opacity',
      cursor: 'grab'
    }
  }, React.createElement(PhotoCard, {
    photo: currentPhoto,
    onTap: handlePhotoTap
  })), nextPhoto && nextPhoto.thumbnailUrl && React.createElement("img", {
    src: nextPhoto.thumbnailUrl,
    alt: "",
    "aria-hidden": "true",
    style: {
      position: 'absolute',
      width: 1,
      height: 1,
      opacity: 0,
      pointerEvents: 'none'
    }
  }));
});
Object.assign(window, {
  PhotoCard,
  SwipeCardStack
});