// v3.0 顶部栏：app 标题居左，右侧档案箱入口；整理页额外带月份胶囊
function TopBar({
  title = 'Evernight',
  monthLabel,
  months,
  currentMonthId,
  onMonthSelect,
  backLabel,
  centerTitle,
  onBack,
  trashCount = 0,
  onTrashClick
}) {
  const isDetail = !!backLabel;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 100,
      padding: 'calc(var(--ios-safe-top) + 10px) 20px 8px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      minHeight: 44,
      position: 'relative'
    }
  }, isDetail ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    className: "ios-btn",
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 3,
      background: 'none',
      border: 'none',
      padding: '6px 8px 6px 0',
      cursor: 'pointer',
      color: 'var(--accent)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 17,
      fontWeight: 400
    }
  }, /*#__PURE__*/React.createElement(ChevronLeftIcon, {
    size: 18,
    color: "var(--accent)"
  }), /*#__PURE__*/React.createElement("span", null, backLabel)), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: '50%',
      top: '50%',
      transform: 'translate(-50%, -50%)',
      fontSize: 17,
      fontWeight: 600,
      color: '#000',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      letterSpacing: -0.4,
      whiteSpace: 'nowrap'
    }
  }, centerTitle)) : /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 32,
      fontWeight: 700,
      color: '#000',
      letterSpacing: -1.1,
      lineHeight: 1.1,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: isDetail ? 1 : '0 0 auto',
      display: 'flex',
      justifyContent: 'flex-end',
      alignItems: 'center',
      gap: 10
    }
  }, monthLabel && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      display: 'flex',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("select", {
    className: "month-select",
    value: currentMonthId || '',
    "aria-label": "\u9009\u62E9\u6708\u4EFD",
    style: {
      maxWidth: 156
    },
    onChange: e => {
      const picked = (months || []).find(m => m.id === e.target.value);
      if (picked && onMonthSelect) onMonthSelect(picked);
    }
  }, (months || []).map(month => /*#__PURE__*/React.createElement("option", {
    key: month.id,
    value: month.id
  }, month.title))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: 12,
      display: 'flex',
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement(ChevronDownIcon, {
    size: 12,
    color: "rgba(60,60,67,0.6)"
  }))), /*#__PURE__*/React.createElement("button", {
    onClick: onTrashClick,
    className: "ios-btn",
    style: {
      width: 44,
      height: 44,
      borderRadius: '50%',
      flexShrink: 0,
      position: 'relative',
      border: 'none',
      cursor: 'pointer',
      background: 'var(--glass-float)',
      backdropFilter: 'var(--blur-float)',
      WebkitBackdropFilter: 'var(--blur-float)',
      boxShadow: 'var(--edge-float)',
      color: 'var(--accent)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(ArchiveIcon, {
    size: 22,
    color: "var(--accent)",
    weight: 1.7
  }), trashCount > 0 && /*#__PURE__*/React.createElement("span", {
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
  }, trashCount > 99 ? '99+' : trashCount)))));
}
window.TopBar = TopBar;