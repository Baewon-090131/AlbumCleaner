// v2.6 回收站：网格 + iOS 弹窗/操作表
function TrashPage({
  trashPhotos,
  onBack,
  onRestore,
  onDelete,
  onDeleteAll,
  themeColor = '#007AFF'
}) {
  const [showAlert, setShowAlert] = React.useState(false);
  const [selectedPhoto, setSelectedPhoto] = React.useState(null);
  const [showActionSheet, setShowActionSheet] = React.useState(false);
  const handlePhotoClick = photo => {
    setSelectedPhoto(photo);
    setShowActionSheet(true);
  };
  const handleRestore = () => {
    if (selectedPhoto) onRestore(selectedPhoto.id);
    setShowActionSheet(false);
    setSelectedPhoto(null);
  };
  const handleDeleteOne = () => {
    if (selectedPhoto) onDelete(selectedPhoto.id);
    setShowActionSheet(false);
    setSelectedPhoto(null);
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: '100%',
      background: 'transparent',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement(TopBar, {
    backLabel: "\u8FD4\u56DE",
    centerTitle: "\u56DE\u6536\u7AD9",
    onBack: onBack
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '14px 24px',
      fontSize: 13,
      color: 'rgba(60,60,67,0.65)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      textAlign: 'center',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      background: 'var(--glass-panel)',
      backdropFilter: 'var(--blur-panel)',
      WebkitBackdropFilter: 'var(--blur-panel)',
      boxShadow: 'var(--edge-panel-soft)',
      borderRadius: 16,
      padding: '8px 17px',
      animation: 'glassIn 0.3s var(--ease-out)'
    }
  }, trashPhotos.length > 0 ? `共 ${trashPhotos.length} 张照片将在 30 天后自动删除` : '回收站为空')), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 10px',
      WebkitOverflowScrolling: 'touch'
    }
  }, trashPhotos.length > 0 ? /*#__PURE__*/React.createElement("div", {
    style: {
      borderRadius: 'var(--r-panel)',
      background: 'var(--glass-panel)',
      backdropFilter: 'var(--blur-panel)',
      WebkitBackdropFilter: 'var(--blur-panel)',
      boxShadow: 'var(--edge-panel-soft)',
      padding: 5,
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(3, 1fr)',
      gap: 3,
      borderRadius: 20,
      overflow: 'hidden'
    }
  }, trashPhotos.map((photo, idx) => /*#__PURE__*/React.createElement("div", {
    key: photo.id,
    onClick: () => handlePhotoClick(photo),
    className: "ios-btn",
    style: {
      aspectRatio: '1',
      background: photo.thumbnailUrl && photo.thumbnailUrl.startsWith('photo://') ? '#1c1c1e' : photo.gradient,
      position: 'relative',
      cursor: 'pointer',
      overflow: 'hidden',
      animation: `cardIn 0.3s var(--ease-out) ${idx * 0.02}s both`
    }
  }, photo.thumbnailUrl && photo.thumbnailUrl.startsWith('photo://') && /*#__PURE__*/React.createElement("img", {
    src: photo.thumbnailUrl,
    alt: "",
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      display: 'block'
    },
    draggable: false
  }), photo.isVideo && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 4,
      right: 4,
      display: 'flex',
      alignItems: 'center',
      gap: 2,
      background: 'rgba(0,0,0,0.4)',
      padding: '1px 4px',
      borderRadius: 3
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "6",
    height: "7",
    viewBox: "0 0 6 7"
  }, /*#__PURE__*/React.createElement("polygon", {
    points: "0,0 6,3.5 0,7",
    fill: "#fff"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      color: '#fff',
      fontSize: 9,
      fontWeight: 500,
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, photo.duration)))))) : /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '70px 20px',
      gap: 14,
      animation: 'fadeIn 0.4s ease'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 88,
      height: 88,
      borderRadius: '50%',
      background: 'var(--glass-panel)',
      backdropFilter: 'var(--blur-panel)',
      WebkitBackdropFilter: 'var(--blur-panel)',
      boxShadow: 'var(--edge-panel-soft)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "36",
    height: "36",
    viewBox: "0 0 24 24",
    fill: "none"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z",
    stroke: "rgba(60,60,67,0.35)",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 16,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 500
    }
  }, "\u56DE\u6536\u7AD9\u6CA1\u6709\u7167\u7247"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.4)',
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, "\u5220\u9664\u7684\u7167\u7247\u4F1A\u5148\u6682\u5B58\u5728\u8FD9\u91CC")), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 80
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 12px calc(12px + var(--ios-safe-bottom))'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      borderRadius: 'var(--r-island)',
      background: 'var(--glass-float)',
      backdropFilter: 'var(--blur-float)',
      WebkitBackdropFilter: 'var(--blur-float)',
      boxShadow: 'var(--edge-float)',
      padding: '8px',
      animation: 'slideUpBar 0.3s var(--ease-drawer)'
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: () => trashPhotos.length > 0 && setShowAlert(true),
    disabled: trashPhotos.length === 0,
    className: "ios-btn",
    style: {
      width: '100%',
      padding: '14px 20px',
      background: trashPhotos.length === 0 ? 'rgba(255,59,48,0.25)' : 'linear-gradient(135deg, #FF453A 0%, #FF3B30 100%)',
      color: '#fff',
      border: 'none',
      borderRadius: 20,
      fontSize: 17,
      fontWeight: 600,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      cursor: trashPhotos.length === 0 ? 'not-allowed' : 'pointer',
      letterSpacing: -0.4,
      boxShadow: trashPhotos.length === 0 ? 'none' : '0 4px 14px rgba(255,59,48,0.35)'
    }
  }, "\u5220\u9664\u5168\u90E8"))), showAlert && /*#__PURE__*/React.createElement(IOSAlert, {
    title: "\u5220\u9664\u7167\u7247\uFF1F",
    message: `将从回收站中永久删除 ${trashPhotos.length} 张照片，此操作不可撤销。`,
    themeColor: themeColor,
    actions: [{
      label: '取消',
      style: 'cancel',
      onClick: () => setShowAlert(false)
    }, {
      label: '删除',
      style: 'destructive',
      onClick: () => {
        onDeleteAll();
        setShowAlert(false);
      }
    }]
  }), showActionSheet && selectedPhoto && /*#__PURE__*/React.createElement(IOSActionSheet, {
    title: `#${selectedPhoto.id}`,
    message: "\u9009\u62E9\u64CD\u4F5C",
    themeColor: themeColor,
    actions: [{
      label: '恢复',
      style: 'default',
      onClick: handleRestore
    }, {
      label: '彻底删除',
      style: 'destructive',
      onClick: handleDeleteOne
    }],
    onCancel: () => {
      setShowActionSheet(false);
      setSelectedPhoto(null);
    }
  }));
}

// iOS 风格 Alert（居中缩放弹窗）
function IOSAlert({
  title,
  message,
  actions,
  themeColor = '#002FA7'
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(0,0,0,0.4)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 1000,
      padding: '0 40px',
      animation: 'fadeIn 0.2s ease'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--glass-panel)',
      backdropFilter: 'var(--blur-panel)',
      WebkitBackdropFilter: 'var(--blur-panel)',
      boxShadow: 'var(--edge-panel)',
      borderRadius: 24,
      width: '100%',
      maxWidth: 270,
      overflow: 'hidden',
      animation: 'alertScaleIn 0.28s var(--ease-drawer)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '20px 16px 14px',
      textAlign: 'center',
      borderBottom: '0.5px solid rgba(60,60,67,0.15)'
    }
  }, title && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 600,
      color: '#000',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      letterSpacing: -0.4,
      marginBottom: message ? 6 : 0
    }
  }, title), message && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.8)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      lineHeight: 1.4
    }
  }, message)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: actions.length === 2 ? 'row' : 'column'
    }
  }, actions.map((action, i) => /*#__PURE__*/React.createElement("button", {
    key: i,
    onClick: action.onClick,
    className: "ios-btn",
    style: {
      flex: 1,
      padding: '12px 16px',
      background: 'transparent',
      border: 'none',
      borderRight: actions.length === 2 && i === 0 ? '0.5px solid rgba(60,60,67,0.15)' : 'none',
      borderTop: i > 0 && actions.length !== 2 ? '0.5px solid rgba(60,60,67,0.15)' : 'none',
      color: action.style === 'destructive' ? '#FF3B30' : themeColor,
      fontSize: 17,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: action.style === 'cancel' ? 600 : 400,
      cursor: 'pointer',
      letterSpacing: -0.4
    }
  }, action.label)))));
}

// iOS 风格 Action Sheet（底部滑入）
function IOSActionSheet({
  title,
  message,
  actions,
  onCancel,
  themeColor = '#002FA7'
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(0,0,0,0.4)',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'flex-end',
      zIndex: 1000,
      animation: 'fadeIn 0.2s ease'
    },
    onClick: onCancel
  }, /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      padding: '8px 10px calc(8px + var(--ios-safe-bottom))',
      animation: 'sheetSlideUp 0.32s var(--ease-drawer)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--glass-panel)',
      backdropFilter: 'var(--blur-panel)',
      WebkitBackdropFilter: 'var(--blur-panel)',
      boxShadow: 'var(--edge-panel)',
      borderRadius: 'var(--r-island)',
      overflow: 'hidden',
      marginBottom: 9
    }
  }, title && /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '14px 16px 10px',
      textAlign: 'center',
      borderBottom: '0.5px solid rgba(60,60,67,0.12)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, title), message && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      marginTop: 2
    }
  }, message)), actions.map((action, i) => /*#__PURE__*/React.createElement("button", {
    key: i,
    onClick: action.onClick,
    className: "ios-btn",
    style: {
      width: '100%',
      padding: '16px 20px',
      background: 'transparent',
      border: 'none',
      borderTop: i > 0 || title ? '0.5px solid rgba(60,60,67,0.12)' : 'none',
      color: action.style === 'destructive' ? '#FF3B30' : themeColor,
      fontSize: 17,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 400,
      cursor: 'pointer',
      letterSpacing: -0.4,
      textAlign: 'center'
    }
  }, action.label))), /*#__PURE__*/React.createElement("button", {
    onClick: onCancel,
    className: "ios-btn",
    style: {
      width: '100%',
      padding: '16px 20px',
      background: 'var(--glass-float-strong)',
      backdropFilter: 'var(--blur-float)',
      WebkitBackdropFilter: 'var(--blur-float)',
      boxShadow: 'var(--edge-float)',
      border: 'none',
      borderRadius: 'var(--r-island)',
      color: themeColor,
      fontSize: 17,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 600,
      cursor: 'pointer',
      letterSpacing: -0.4
    }
  }, "\u53D6\u6D88")));
}
Object.assign(window, {
  TrashPage,
  IOSAlert,
  IOSActionSheet
});