// v3.0 我的页：使用数据卡 + 整理偏好 + 播放开关 + 主题色 + 通用
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
const PANEL_STYLE = {
  background: 'var(--glass-solid)',
  borderRadius: 'var(--r-panel)',
  boxShadow: 'var(--edge-panel-soft)',
  margin: '0 16px',
  overflow: 'hidden'
};
function formatBytes(bytes) {
  if (!bytes || bytes <= 0) return '0 KB';
  const mb = bytes / (1024 * 1024);
  if (mb >= 1024) return (mb / 1024).toFixed(1) + ' GB';
  if (mb >= 1) return mb.toFixed(1) + ' MB';
  return Math.max(1, Math.round(bytes / 1024)) + ' KB';
}
function formatGB(bytes) {
  if (!bytes || bytes <= 0) return '0 GB';
  return Math.round(bytes / (1024 * 1024 * 1024)) + ' GB';
}

// v3.0.1：开关用原生 checkbox + role="switch"。
// iOS 17.4+ 的 WebKit 会把它渲染成系统 UISwitch（`html[data-native-controls]` 由 main.jsx 置位），
// 桌面和旧系统走 .ios-switch 里那套同造型的液态玻璃回退。
function GlassSwitch({
  value,
  onChange,
  disabled = false,
  label
}) {
  return /*#__PURE__*/React.createElement("input", {
    type: "checkbox",
    role: "switch",
    className: "ios-switch",
    checked: !!value,
    disabled: disabled,
    "aria-label": label,
    onClick: e => e.stopPropagation(),
    onChange: e => {
      if (!disabled && onChange) onChange(e.target.checked);
    }
  });
}
function SectionLabel({
  children
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      padding: '0 32px 6px',
      letterSpacing: -0.08,
      fontWeight: 500
    }
  }, children);
}
function MineRow({
  label,
  value,
  isLast = false,
  onPress,
  disabled = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: disabled ? undefined : 'ios-row',
    onClick: disabled ? undefined : onPress,
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 46,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 16,
      color: '#000',
      letterSpacing: -0.3,
      cursor: disabled ? 'default' : 'pointer'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, label), value && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'rgba(60,60,67,0.5)',
      fontSize: 15,
      marginRight: 6
    }
  }, value), /*#__PURE__*/React.createElement(ChevronRightIcon, {
    size: 13,
    color: "rgba(60,60,67,0.28)",
    weight: 2.4
  }), !isLast && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      left: 16,
      right: 0,
      height: 0.5,
      background: 'rgba(60,60,67,0.12)'
    }
  }));
}
function MineSwitchRow({
  label,
  value,
  onChange,
  isLast = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "ios-row",
    onClick: () => onChange && onChange(!value),
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 52,
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
  }, label), /*#__PURE__*/React.createElement(GlassSwitch, {
    value: value,
    onChange: onChange,
    label: label
  }), !isLast && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      left: 16,
      right: 0,
      height: 0.5,
      background: 'rgba(60,60,67,0.12)'
    }
  }));
}
function MinePage({
  themeColor = '#002FA7',
  onThemeChange,
  autoPlayLive = true,
  autoPlayVideo = true,
  onAutoLiveChange,
  onAutoVideoChange,
  trashPhotos = [],
  storage = null,
  onClearCache,
  trashCount = 0,
  onTrashClick
}) {
  const [batchSize, setBatchSize] = React.useState(30);
  const cleanedCount = trashPhotos.length;
  const cleanedBytes = trashPhotos.reduce((sum, photo) => sum + (photo.fileSize || 0), 0);
  const usedRatio = storage && storage.total > 0 ? storage.used / storage.total : 0;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      background: 'transparent'
    }
  }, /*#__PURE__*/React.createElement(TopBar, {
    trashCount: trashCount,
    onTrashClick: onTrashClick
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      WebkitOverflowScrolling: 'touch',
      paddingBottom: 24
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 20px 14px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "sf-title",
    style: {
      fontSize: 34,
      color: '#000',
      lineHeight: 1.05,
      letterSpacing: '-1.2px'
    }
  }, "\u6211\u7684")), /*#__PURE__*/React.createElement("div", {
    style: {
      ...PANEL_STYLE,
      marginBottom: 26,
      padding: '18px 18px 16px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.55)',
      fontWeight: 500
    }
  }, "\u7D2F\u8BA1\u5DF2\u6E05\u7406"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      gap: 8,
      marginTop: 2
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 52,
      fontWeight: 700,
      color: '#34C759',
      lineHeight: 1.05,
      fontFamily: '-apple-system, "SF Pro Display", system-ui',
      letterSpacing: -2
    }
  }, cleanedCount), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 16,
      color: 'rgba(60,60,67,0.6)'
    }
  }, "\xB7 \u91CA\u653E ", formatBytes(cleanedBytes))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      marginTop: 18,
      paddingTop: 16,
      borderTop: '0.5px solid rgba(60,60,67,0.12)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement(HeartIcon, {
    size: 20,
    color: "#FF3B30"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 600,
      marginTop: 2
    }
  }, "0"), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 12,
      color: 'rgba(60,60,67,0.55)'
    }
  }, "\u5DF2\u6536\u85CF")), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 0.5,
      height: 40,
      background: 'rgba(60,60,67,0.14)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement(TrashIcon, {
    size: 20,
    color: "#34C759",
    weight: 1.8
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 600,
      marginTop: 2
    }
  }, trashCount), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 12,
      color: 'rgba(60,60,67,0.55)'
    }
  }, "\u5F85\u6E05\u7406")), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 0.5,
      height: 40,
      background: 'rgba(60,60,67,0.14)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement(EyeIcon, {
    size: 20,
    color: "rgba(60,60,67,0.65)"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 600,
      marginTop: 2
    }
  }, "0"), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 12,
      color: 'rgba(60,60,67,0.55)'
    }
  }, "\u672C\u8F6E\u5DF2\u770B"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 15,
      color: '#000',
      fontWeight: 500
    }
  }, "\u624B\u673A\u5B58\u50A8"), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 15,
      color: 'rgba(60,60,67,0.6)'
    }
  }, storage ? `剩余 ${formatGB(storage.free)} / ${formatGB(storage.total)}` : '读取中…')), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 8,
      borderRadius: 4,
      marginTop: 8,
      background: 'rgba(60,60,67,0.14)',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      width: `${Math.round(usedRatio * 100)}%`,
      background: '#34C759',
      borderRadius: 4
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      marginTop: 6
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "sf-body",
    style: {
      fontSize: 12.5,
      color: 'rgba(60,60,67,0.45)'
    }
  }, storage ? `已用 ${formatGB(storage.used)}（${Math.round(usedRatio * 100)}%）` : ''), /*#__PURE__*/React.createElement("span", {
    className: "sf-body",
    style: {
      fontSize: 12.5,
      color: 'rgba(60,60,67,0.45)'
    }
  }, storage ? `可用 ${formatGB(storage.free)}` : '')))), /*#__PURE__*/React.createElement("div", {
    style: {
      paddingBottom: 22
    }
  }, /*#__PURE__*/React.createElement(SectionLabel, null, "\u6574\u7406"), /*#__PURE__*/React.createElement("div", {
    style: {
      ...PANEL_STYLE,
      padding: '14px 16px 16px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      fontSize: 16,
      letterSpacing: -0.3
    }
  }, "\u6BCF\u8F6E\u6570\u91CF"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 600,
      fontVariantNumeric: 'tabular-nums'
    }
  }, batchSize)), /*#__PURE__*/React.createElement("input", {
    type: "range",
    className: "ios-range",
    min: "10",
    max: "300",
    step: "10",
    value: batchSize,
    "aria-label": "\u6BCF\u8F6E\u6570\u91CF",
    style: {
      '--range-pct': (batchSize - 10) / 290 * 100 + '%',
      marginTop: 12
    },
    onChange: e => setBatchSize(Number(e.target.value))
  }), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 12.5,
      color: 'rgba(60,60,67,0.45)',
      marginTop: 12
    }
  }, "\u5355\u8F6E\u6700\u9AD8\u53EF\u6574\u7406 300 \u9879"))), /*#__PURE__*/React.createElement("div", {
    style: {
      paddingBottom: 22
    }
  }, /*#__PURE__*/React.createElement(SectionLabel, null, "\u6574\u7406\u504F\u597D"), /*#__PURE__*/React.createElement("div", {
    style: PANEL_STYLE
  }, /*#__PURE__*/React.createElement(MineRow, {
    label: "\u6ED1\u52A8\u65B9\u5411",
    value: "\u5DE6\u6ED1\u8DF3\u8FC7 / \u4E0A\u6ED1\u5220\u9664",
    disabled: true
  }), /*#__PURE__*/React.createElement(MineRow, {
    label: "\u5C55\u793A\u987A\u5E8F",
    value: "\u6700\u65B0\u4F18\u5148",
    disabled: true
  }), /*#__PURE__*/React.createElement(MineRow, {
    label: "\u7167\u7247\u663E\u793A",
    value: "\u663E\u793A\u5168\u56FE",
    disabled: true
  }), /*#__PURE__*/React.createElement(MineRow, {
    label: "\u8BED\u8A00",
    value: "\u7B80\u4F53\u4E2D\u6587",
    isLast: true,
    disabled: true
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      paddingBottom: 22
    }
  }, /*#__PURE__*/React.createElement(SectionLabel, null, "\u64AD\u653E\u4E0E\u663E\u793A"), /*#__PURE__*/React.createElement("div", {
    style: PANEL_STYLE
  }, /*#__PURE__*/React.createElement(MineSwitchRow, {
    label: "Live \u56FE\u81EA\u52A8\u64AD\u653E",
    value: autoPlayLive,
    onChange: onAutoLiveChange
  }), /*#__PURE__*/React.createElement(MineSwitchRow, {
    label: "\u89C6\u9891\u81EA\u52A8\u64AD\u653E",
    value: autoPlayVideo,
    onChange: onAutoVideoChange
  }), /*#__PURE__*/React.createElement(MineRow, {
    label: "HDR \u663E\u793A",
    value: "\u5173\u95ED",
    disabled: true
  }), /*#__PURE__*/React.createElement(MineRow, {
    label: "\u89C6\u9891\u58F0\u97F3",
    value: "\u5173\u95ED",
    isLast: true,
    disabled: true
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      paddingBottom: 22
    }
  }, /*#__PURE__*/React.createElement(SectionLabel, null, "\u5916\u89C2"), /*#__PURE__*/React.createElement("div", {
    style: {
      ...PANEL_STYLE,
      padding: '18px 20px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      flexWrap: 'wrap',
      gap: 12
    }
  }, THEME_COLORS.map(item => {
    const selected = item.color === themeColor;
    return /*#__PURE__*/React.createElement("button", {
      key: item.id,
      onClick: () => onThemeChange(item.color),
      className: "ios-btn",
      style: {
        width: 40,
        height: 40,
        borderRadius: '50%',
        background: item.color,
        border: 'none',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        boxShadow: selected ? `0 0 0 2.5px #fff, 0 0 0 4.5px ${item.color}, 0 0 0 6px rgba(255,255,255,0.9)` : 'inset 0 1px 0 rgba(255,255,255,0.4), 0 1px 3px rgba(0,0,0,0.15)'
      }
    }, selected && /*#__PURE__*/React.createElement("svg", {
      width: "18",
      height: "18",
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
      paddingBottom: 20
    }
  }, /*#__PURE__*/React.createElement(SectionLabel, null, "\u901A\u7528"), /*#__PURE__*/React.createElement("div", {
    style: PANEL_STYLE
  }, /*#__PURE__*/React.createElement(MineRow, {
    label: "\u5173\u4E8E",
    value: "Evernight 3.0.1",
    disabled: true
  }), /*#__PURE__*/React.createElement(MineRow, {
    label: "\u64CD\u4F5C\u6307\u5F15",
    disabled: true
  }), /*#__PURE__*/React.createElement(MineRow, {
    label: "\u6E05\u7406\u7F13\u5B58",
    value: formatBytes(cleanedBytes),
    onPress: onClearCache,
    isLast: true
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      padding: '4px 0 10px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 13,
      color: 'var(--accent)',
      fontWeight: 500
    }
  }, "\u7528\u6237\u534F\u8BAE \xB7 \u9690\u79C1\u653F\u7B56"), /*#__PURE__*/React.createElement("div", {
    className: "sf-body",
    style: {
      fontSize: 12,
      color: 'rgba(60,60,67,0.4)',
      marginTop: 6
    }
  }, "Evernight 3.0.1 (12)"))));
}
Object.assign(window, {
  MinePage,
  GlassSwitch,
  SectionLabel,
  MineRow,
  MineSwitchRow,
  THEME_COLORS,
  formatBytes
});