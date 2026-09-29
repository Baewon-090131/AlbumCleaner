// v2.6 首页：iOS 相册列表风格（大标题体系 + 玻璃月份卡片 + stagger 入场）
function HomePage({
  months,
  themeColor = '#007AFF',
  onMonthClick,
  onTrashClick,
  onSettingsClick,
  trashCount = 0
}) {
  // 统计：总照片数
  const totalPhotos = months.reduce((sum, m) => sum + m.photos.length, 0);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      background: 'transparent',
      display: 'flex',
      flexDirection: 'column',
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 50,
      padding: 'calc(var(--ios-safe-top) + 14px) 20px 10px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      paddingRight: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "sf-title",
    style: {
      fontSize: 34,
      color: '#000',
      lineHeight: 1.05,
      letterSpacing: '-1.2px'
    }
  }, "Album Cleaner"), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      marginTop: 5,
      fontSize: 14,
      color: 'rgba(60,60,67,0.60)',
      fontWeight: 500
    }
  }, months.length, " \u4E2A\u6708 \xB7 ", totalPhotos, " \u4E2A\u9879\u76EE")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(GlassIconButton, {
    themeColor: themeColor,
    onClick: onTrashClick,
    badge: trashCount,
    icon: /*#__PURE__*/React.createElement("svg", {
      width: "19",
      height: "19",
      viewBox: "0 0 24 24",
      fill: "none"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z",
      strokeWidth: "1.8",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    }))
  }), /*#__PURE__*/React.createElement(GlassIconButton, {
    themeColor: themeColor,
    onClick: onSettingsClick,
    icon: /*#__PURE__*/React.createElement("svg", {
      width: "19",
      height: "19",
      viewBox: "0 0 24 24",
      fill: "none"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M12 15.5a3.5 3.5 0 100-7 3.5 3.5 0 000 7z",
      strokeWidth: "1.8"
    }), /*#__PURE__*/React.createElement("path", {
      d: "M19.4 15a1.7 1.7 0 00.34 1.87l.06.06a2 2 0 11-2.83 2.83l-.06-.06a1.7 1.7 0 00-1.87-.34 1.7 1.7 0 00-1.03 1.56V21a2 2 0 11-4 0v-.09a1.7 1.7 0 00-1.11-1.56 1.7 1.7 0 00-1.87.34l-.06.06a2 2 0 11-2.83-2.83l.06-.06a1.7 1.7 0 00.34-1.87 1.7 1.7 0 00-1.56-1.03H3a2 2 0 110-4h.09a1.7 1.7 0 001.56-1.11 1.7 1.7 0 00-.34-1.87l-.06-.06a2 2 0 112.83-2.83l.06.06a1.7 1.7 0 001.87.34h.01a1.7 1.7 0 001.03-1.56V3a2 2 0 114 0v.09c0 .64.4 1.21 1.03 1.56.6.28 1.31.2 1.87-.34l.06-.06a2 2 0 112.83 2.83l-.06.06a1.7 1.7 0 00-.34 1.87v.01c.28.6.85 1 1.56 1.03H21a2 2 0 110 4h-.09a1.7 1.7 0 00-1.51 1.03z",
      strokeWidth: "1.6",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    }))
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      WebkitOverflowScrolling: 'touch',
      padding: '6px 16px calc(var(--ios-safe-bottom) + 24px)'
    }
  }, months.map((month, idx) => /*#__PURE__*/React.createElement(MonthCard, {
    key: month.id,
    month: month,
    themeColor: themeColor,
    onClick: () => onMonthClick(month),
    index: idx
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      padding: '18px 0 8px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 12,
      color: 'rgba(60,60,67,0.4)'
    }
  }, "\u957F\u6309\u53EF\u67E5\u770B\u66F4\u591A \xB7 \u7167\u7247\u4EC5\u5728\u672C\u673A\u6574\u7406"))));
}

// v2.6：iOS 相册风格月份卡片（玻璃材质 + mini 缩略图封面 + chevron）
function MonthCard({
  month,
  themeColor,
  onClick,
  index = 0
}) {
  const photos = month.photos || [];
  const coverPhotos = photos.slice(0, 3);
  const count = photos.length;
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    className: "ios-row",
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '11px 14px',
      marginBottom: 10,
      borderRadius: 'var(--r-panel)',
      cursor: 'pointer',
      background: 'var(--glass-panel)',
      backdropFilter: 'var(--blur-panel)',
      WebkitBackdropFilter: 'var(--blur-panel)',
      boxShadow: 'var(--edge-panel-soft)',
      transition: 'transform 0.16s var(--ease-out), background-color 0.15s ease, box-shadow 0.16s ease',
      transform: 'scale(1)',
      animation: `cardIn 0.4s var(--ease-out) ${Math.min(index * 0.045, 0.5)}s both`
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = 'scale(0.975)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      width: 62,
      height: 62,
      flexShrink: 0
    }
  }, coverPhotos.slice(0, 2).reverse().map((p, i) => /*#__PURE__*/React.createElement("div", {
    key: 'bk' + i,
    style: {
      position: 'absolute',
      top: 5 + i * 3,
      left: 6 + i * 3,
      width: 56,
      height: 56,
      borderRadius: 18,
      overflow: 'hidden',
      background: p.thumbnailUrl && p.thumbnailUrl.startsWith('photo://') ? '#1c1c1e' : p.gradient || '#eee',
      border: '0.5px solid rgba(255,255,255,0.9)',
      boxShadow: '0 2px 8px rgba(0,0,0,0.08)',
      opacity: 0.75
    }
  }, p.thumbnailUrl && p.thumbnailUrl.startsWith('photo://') && /*#__PURE__*/React.createElement("img", {
    src: p.thumbnailUrl,
    alt: "",
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      display: 'block'
    },
    draggable: false
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 0,
      left: 0,
      width: 62,
      height: 62,
      borderRadius: 18,
      overflow: 'hidden',
      background: coverPhotos[0] && coverPhotos[0].thumbnailUrl && coverPhotos[0].thumbnailUrl.startsWith('photo://') ? '#1c1c1e' : coverPhotos[0] ? coverPhotos[0].gradient : 'linear-gradient(135deg,#d1d1d6,#e5e5ea)',
      border: '0.5px solid rgba(255,255,255,0.95)',
      boxShadow: '0 3px 10px rgba(0,0,0,0.12)'
    }
  }, coverPhotos[0] && coverPhotos[0].thumbnailUrl && coverPhotos[0].thumbnailUrl.startsWith('photo://') && /*#__PURE__*/React.createElement("img", {
    src: coverPhotos[0].thumbnailUrl,
    alt: "",
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      display: 'block'
    },
    draggable: false
  }), coverPhotos[0] && coverPhotos[0].isVideo && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: 3,
      bottom: 3,
      width: 13,
      height: 13,
      borderRadius: 6,
      background: 'rgba(0,0,0,0.45)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "6",
    height: "6",
    viewBox: "0 0 6 6"
  }, /*#__PURE__*/React.createElement("polygon", {
    points: "0,0 6,3 0,6",
    fill: "#fff"
  }))))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "sf-title",
    style: {
      fontSize: 18,
      color: '#000',
      lineHeight: 1.2,
      letterSpacing: '-0.01em'
    }
  }, month.title), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      marginTop: 3,
      fontSize: 13.5,
      color: 'rgba(60,60,67,0.5)'
    }
  }, count, " \u4E2A\u9879\u76EE")), /*#__PURE__*/React.createElement("svg", {
    width: "9",
    height: "15",
    viewBox: "0 0 9 15",
    style: {
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M1.5 1.5L7 7.5l-5.5 6",
    stroke: themeColor,
    strokeWidth: "2",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round",
    opacity: "0.85"
  })));
}

// v2.6：iOS 26 悬浮玻璃圆钮（右上角操作，带可选红色角标）
function GlassIconButton({
  icon,
  onClick,
  themeColor = '#007AFF',
  badge = 0
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    className: "ios-btn",
    style: {
      width: 44,
      height: 44,
      borderRadius: '50%',
      cursor: 'pointer',
      position: 'relative',
      background: 'var(--glass-float)',
      backdropFilter: 'var(--blur-float)',
      WebkitBackdropFilter: 'var(--blur-float)',
      boxShadow: 'var(--edge-float)',
      color: themeColor,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = 'scale(0.9)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
    }
  }, React.cloneElement(icon, {
    stroke: themeColor
  }), badge > 0 && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: -3,
      right: -3,
      minWidth: 18,
      height: 18,
      borderRadius: 9,
      background: '#FF3B30',
      border: '2px solid rgba(255,255,255,0.95)',
      color: '#fff',
      fontSize: 11,
      fontWeight: 600,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '0 4px'
    }
  }, badge > 99 ? '99+' : badge));
}
Object.assign(window, {
  HomePage,
  MonthCard,
  GlassIconButton
});