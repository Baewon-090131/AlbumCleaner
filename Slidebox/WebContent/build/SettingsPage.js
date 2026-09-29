// v2.6 设置页：iOS inset grouped 分组列表 + 主题色 + 自动播放开关
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
const GROUP_GLASS = {
  background: 'var(--glass-panel)',
  backdropFilter: 'var(--blur-panel)',
  WebkitBackdropFilter: 'var(--blur-panel)',
  boxShadow: 'var(--edge-panel-soft)',
  borderRadius: 22,
  margin: '0 16px',
  overflow: 'hidden'
};
function SettingsPage({
  themeColor,
  onThemeChange,
  onBack,
  autoPlayLive = true,
  autoPlayVideo = true,
  onAutoLiveChange,
  onAutoVideoChange
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      background: 'transparent',
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
      height: 52,
      borderRadius: 'var(--r-island)',
      background: 'var(--glass-float)',
      backdropFilter: 'var(--blur-float)',
      WebkitBackdropFilter: 'var(--blur-float)',
      boxShadow: 'var(--edge-float)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 8px',
      animation: 'slideDownBar 0.3s var(--ease-drawer)'
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    className: "ios-btn",
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
      fontWeight: 400
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
      overflowY: 'auto',
      WebkitOverflowScrolling: 'touch'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '26px 0 8px',
      animation: 'glassIn 0.32s var(--ease-out)'
    }
  }, /*#__PURE__*/React.createElement(GroupHeader, {
    title: "\u4E3B\u9898\u989C\u8272"
  }), /*#__PURE__*/React.createElement("div", {
    style: GROUP_GLASS
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      flexWrap: 'wrap',
      gap: 12,
      padding: '16px 20px'
    }
  }, THEME_COLORS.map(t => {
    const isSelected = t.color === themeColor;
    return /*#__PURE__*/React.createElement("button", {
      key: t.id,
      onClick: () => onThemeChange(t.color),
      className: "ios-btn",
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
        boxShadow: isSelected ? `0 0 0 3px #fff, 0 0 0 5.5px ${t.color}, 0 0 0 7px rgba(255,255,255,0.9)` : 'inset 0 1px 0 rgba(255,255,255,0.4), 0 1px 3px rgba(0,0,0,0.15)'
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
      padding: '18px 0 8px',
      animation: 'glassIn 0.32s var(--ease-out) 0.05s both'
    }
  }, /*#__PURE__*/React.createElement(GroupHeader, {
    title: "\u901A\u7528"
  }), /*#__PURE__*/React.createElement("div", {
    style: GROUP_GLASS
  }, /*#__PURE__*/React.createElement(SettingRow, {
    iconColor: themeColor,
    title: "\u5173\u4E8E",
    detail: "Album Cleaner 2.6"
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
      padding: '18px 0 24px',
      animation: 'glassIn 0.32s var(--ease-out) 0.1s both'
    }
  }, /*#__PURE__*/React.createElement(GroupHeader, {
    title: "\u6574\u7406\u504F\u597D"
  }), /*#__PURE__*/React.createElement("div", {
    style: GROUP_GLASS
  }, /*#__PURE__*/React.createElement(SettingSwitchRow, {
    title: "Live \u56FE\u81EA\u52A8\u64AD\u653E",
    value: autoPlayLive,
    onChange: onAutoLiveChange
  }), /*#__PURE__*/React.createElement(SettingSwitchRow, {
    title: "\u89C6\u9891\u81EA\u52A8\u64AD\u653E",
    value: autoPlayVideo,
    onChange: onAutoVideoChange
  }), /*#__PURE__*/React.createElement(SettingRow, {
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
function GroupHeader({
  title
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      textTransform: 'uppercase',
      letterSpacing: -0.08,
      fontWeight: 500,
      padding: '0 32px 6px'
    }
  }, title);
}

// iOS 原生开关行（UISwitch：绿开 / 灰关 + 白色滑块，0.22s drawer 曲线）
function SettingSwitchRow({
  title,
  value,
  onChange
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "ios-row",
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 48,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 16,
      color: '#000',
      letterSpacing: -0.3,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, title), /*#__PURE__*/React.createElement("button", {
    "aria-pressed": !!value,
    onClick: e => {
      e.stopPropagation();
      if (onChange) onChange(!value);
    },
    style: {
      width: 53,
      height: 32,
      borderRadius: 16,
      border: 'none',
      cursor: 'pointer',
      background: value ? '#34C759' : 'rgba(120,120,128,0.32)',
      position: 'relative',
      flexShrink: 0,
      transition: 'background 0.22s var(--ease-drawer)',
      padding: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 2,
      left: value ? 23 : 2,
      width: 28,
      height: 28,
      borderRadius: '50%',
      background: '#fff',
      boxShadow: '0 1px 4px rgba(0,0,0,0.28)',
      transition: 'left 0.22s var(--ease-drawer)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      right: 16,
      left: 16,
      height: 0.5,
      background: 'rgba(60,60,67,0.09)'
    }
  }));
}
function SettingRow({
  iconColor,
  title,
  detail,
  isLast = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "ios-row",
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 48,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 16,
      color: '#000',
      letterSpacing: -0.3,
      cursor: 'pointer'
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
      right: 16,
      left: 16,
      height: 0.5,
      background: 'rgba(60,60,67,0.09)'
    }
  }));
}
window.SettingsPage = SettingsPage;