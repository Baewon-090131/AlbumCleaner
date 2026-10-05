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
  const [pickerOpen, setPickerOpen] = React.useState(false);
  const pickerRef = React.useRef(null);
  React.useEffect(() => {
    if (!pickerOpen) return undefined;
    const onDocPointer = e => {
      if (pickerRef.current && !pickerRef.current.contains(e.target)) setPickerOpen(false);
    };
    document.addEventListener('pointerdown', onDocPointer);
    return () => document.removeEventListener('pointerdown', onDocPointer);
  }, [pickerOpen]);
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
      lineHeight: 1.1
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
    ref: pickerRef,
    style: {
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: () => setPickerOpen(v => !v),
    className: "ios-btn",
    style: {
      height: 34,
      borderRadius: 17,
      padding: '0 12px',
      display: 'flex',
      alignItems: 'center',
      gap: 5,
      background: 'var(--glass-float-strong)',
      backdropFilter: 'var(--blur-float)',
      WebkitBackdropFilter: 'var(--blur-float)',
      boxShadow: 'var(--edge-float)',
      border: 'none',
      cursor: 'pointer',
      color: '#000',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 15,
      fontWeight: 500,
      letterSpacing: -0.2,
      whiteSpace: 'nowrap'
    }
  }, /*#__PURE__*/React.createElement("span", null, monthLabel), /*#__PURE__*/React.createElement(ChevronDownIcon, {
    size: 12,
    color: "rgba(60,60,67,0.6)"
  })), pickerOpen && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 42,
      right: 0,
      width: 200,
      maxHeight: 330,
      overflowY: 'auto',
      WebkitOverflowScrolling: 'touch',
      borderRadius: 22,
      padding: 6,
      background: 'var(--glass-float-strong)',
      backdropFilter: 'var(--blur-panel)',
      WebkitBackdropFilter: 'var(--blur-panel)',
      boxShadow: 'var(--edge-panel)',
      animation: 'fadeInScale 0.16s var(--ease-out)',
      zIndex: 120
    }
  }, (months || []).map(month => {
    const selected = month.id === currentMonthId;
    return /*#__PURE__*/React.createElement("div", {
      key: month.id,
      className: "ios-row",
      onClick: () => {
        setPickerOpen(false);
        if (onMonthSelect) onMonthSelect(month);
      },
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        height: 44,
        padding: '0 12px',
        borderRadius: 14,
        cursor: 'pointer',
        background: selected ? 'var(--accent-soft)' : 'transparent',
        fontFamily: '-apple-system, "SF Pro", system-ui',
        fontSize: 15,
        color: '#000'
      }
    }, /*#__PURE__*/React.createElement("span", null, month.title), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 12,
        color: 'rgba(60,60,67,0.45)',
        marginRight: selected ? 6 : 0
      }
    }, (month.photos || []).length), selected && /*#__PURE__*/React.createElement(CheckIcon, {
      size: 16,
      color: "var(--accent)",
      weight: 2.4
    }));
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