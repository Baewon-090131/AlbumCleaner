const THEME_COLORS = [{
  id: 'blue',
  name: '蓝色',
  color: '#007AFF'
}, {
  id: 'purple',
  name: '紫色',
  color: '#AF52DE'
}, {
  id: 'green',
  name: '绿色',
  color: '#34C759'
}, {
  id: 'orange',
  name: '橙色',
  color: '#FF9500'
}, {
  id: 'red',
  name: '红色',
  color: '#FF3B30'
}, {
  id: 'pink',
  name: '粉色',
  color: '#FF2D92'
}, {
  id: 'beiyang',
  name: '北洋蓝',
  color: '#002FA7'
}, {
  id: 'indigo',
  name: '靛蓝',
  color: '#5856D6'
}, {
  id: 'cyan',
  name: '青色',
  color: '#32ADE6'
}, {
  id: 'teal',
  name: '湖绿',
  color: '#30B0C7'
}, {
  id: 'gold',
  name: '金色',
  color: '#FFCC00'
}, {
  id: 'graphite',
  name: '石墨',
  color: '#636366'
}];
function SettingsPage({
  themeColor,
  onThemeChange,
  onBack
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      background: '#F2F2F7',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 100,
      padding: 'var(--ios-safe-top) 12px 6px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      height: 50,
      borderRadius: 25,
      background: 'rgba(255,255,255,0.58)',
      backdropFilter: 'blur(35px) saturate(180%)',
      WebkitBackdropFilter: 'blur(35px) saturate(180%)',
      border: '0.5px solid rgba(255,255,255,0.8)',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), 0 6px 20px rgba(0,0,0,0.06)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 8px'
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4,
      background: 'none',
      border: 'none',
      padding: '6px 10px',
      cursor: 'pointer',
      color: themeColor,
      fontSize: 17,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 400,
      transition: 'transform 0.16s cubic-bezier(0.32, 0.72, 0, 1)'
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
  }, /*#__PURE__*/React.createElement("svg", {
    width: "12",
    height: "20",
    viewBox: "0 0 12 20"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M10 2L2 10l8 8",
    stroke: themeColor,
    strokeWidth: "2.5",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), /*#__PURE__*/React.createElement("span", null, "\u7167\u7247")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      top: '50%',
      transform: 'translate(-50%, -50%)',
      fontSize: 17,
      fontWeight: 600,
      color: '#000',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      letterSpacing: -0.4
    }
  }, "\u8BBE\u7F6E"), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 60
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '28px 0 10px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      textTransform: 'uppercase',
      letterSpacing: -0.08,
      fontWeight: 500,
      padding: '0 32px 6px'
    }
  }, "\u4E3B\u9898\u989C\u8272"), /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'rgba(255,255,255,0.62)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      border: '0.5px solid rgba(255,255,255,0.7)',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)',
      borderRadius: 20,
      margin: '0 16px',
      padding: '16px 20px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      flexWrap: 'wrap',
      gap: 12
    }
  }, THEME_COLORS.map(t => {
    const isSelected = t.color === themeColor;
    return /*#__PURE__*/React.createElement("button", {
      key: t.id,
      onClick: () => onThemeChange(t.color),
      style: {
        width: 44,
        height: 44,
        borderRadius: '50%',
        background: t.color,
        border: 'none',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        boxShadow: isSelected ? `0 0 0 3px #fff, 0 0 0 5.5px ${t.color}, 0 0 0 7px rgba(255,255,255,0.9)` : 'inset 0 1px 0 rgba(255,255,255,0.4), 0 1px 3px rgba(0,0,0,0.15)',
        transition: 'all 0.2s ease'
      }
    }, isSelected && /*#__PURE__*/React.createElement("svg", {
      width: "20",
      height: "20",
      viewBox: "0 0 20 20"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M5 10l3.5 3.5L15 7",
      stroke: "#fff",
      strokeWidth: "2.5",
      fill: "none",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    })));
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '20px 0 10px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      textTransform: 'uppercase',
      letterSpacing: -0.08,
      fontWeight: 500,
      padding: '0 32px 6px'
    }
  }, "\u901A\u7528"), /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'rgba(255,255,255,0.62)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      border: '0.5px solid rgba(255,255,255,0.7)',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)',
      borderRadius: 18,
      margin: '0 16px',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement(SettingRow, {
    iconColor: themeColor,
    title: "\u5173\u4E8E",
    detail: "Album Cleaner 2.4"
  }), /*#__PURE__*/React.createElement(SettingRow, {
    iconColor: themeColor,
    title: "\u64CD\u4F5C\u6307\u5F15",
    detail: ""
  }), /*#__PURE__*/React.createElement(SettingRow, {
    iconColor: themeColor,
    title: "\u6E05\u7406\u7F13\u5B58",
    detail: "0 KB",
    isLast: true
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '20px 0 24px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      textTransform: 'uppercase',
      letterSpacing: -0.08,
      fontWeight: 500,
      padding: '0 32px 6px'
    }
  }, "\u6574\u7406\u504F\u597D"), /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'rgba(255,255,255,0.62)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      border: '0.5px solid rgba(255,255,255,0.7)',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)',
      borderRadius: 18,
      margin: '0 16px',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement(SettingRow, {
    iconColor: themeColor,
    title: "\u6574\u7406\u987A\u5E8F",
    detail: "\u4ECE\u65B0\u5230\u65E7"
  }), /*#__PURE__*/React.createElement(SettingRow, {
    iconColor: themeColor,
    title: "\u663E\u793A\u89C6\u9891\u65F6\u957F",
    detail: "\u5F00\u542F",
    isLast: true
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 'var(--ios-safe-bottom)'
    }
  })));
}
function SettingRow({
  iconColor,
  title,
  detail,
  isLast = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 44,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 16,
      color: '#000',
      letterSpacing: -0.3
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, title), detail && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'rgba(60,60,67,0.5)',
      fontSize: 15,
      marginRight: 6
    }
  }, detail), /*#__PURE__*/React.createElement("svg", {
    width: "7",
    height: "12",
    viewBox: "0 0 7 12"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M1 1l5 5-5 5",
    stroke: "rgba(60,60,67,0.3)",
    strokeWidth: "1.5",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), !isLast && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      right: 0,
      left: 16,
      height: 0.5,
      background: 'rgba(60,60,67,0.09)'
    }
  }));
}
window.SettingsPage = SettingsPage;