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
  return React.createElement("div", {
    style: {
      height: '100%',
      background: '#F2F2F7',
      display: 'flex',
      flexDirection: 'column'
    }
  }, React.createElement("div", {
    style: {
      background: 'rgba(250,250,252,0.72)',
      backdropFilter: 'blur(30px) saturate(200%)',
      WebkitBackdropFilter: 'blur(30px) saturate(200%)',
      position: 'relative',
      zIndex: 100,
      paddingTop: 'var(--ios-safe-top)',
      borderBottom: '0.5px solid rgba(60,60,67,0.08)',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.7)'
    }
  }, React.createElement("div", {
    style: {
      height: 44,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 8px',
      position: 'relative'
    }
  }, React.createElement("button", {
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
      transition: 'transform 0.15s ease, opacity 0.15s ease'
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = 'scale(0.9)';
      e.currentTarget.style.opacity = '0.6';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
      e.currentTarget.style.opacity = '1';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
      e.currentTarget.style.opacity = '1';
    }
  }, React.createElement("svg", {
    width: "12",
    height: "20",
    viewBox: "0 0 12 20"
  }, React.createElement("path", {
    d: "M10 2L2 10l8 8",
    stroke: themeColor,
    strokeWidth: "2.5",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), React.createElement("span", null, "\u8FD4\u56DE")), React.createElement("div", {
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
  }, "\u56DE\u6536\u7AD9"), React.createElement("div", {
    style: {
      width: 60
    }
  }))), React.createElement("div", {
    style: {
      padding: '14px 20px',
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      textAlign: 'center'
    }
  }, trashPhotos.length > 0 ? `共 ${trashPhotos.length} 张照片将在 30 天后删除` : '回收站为空'), React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 2px',
      WebkitOverflowScrolling: 'touch'
    }
  }, trashPhotos.length > 0 ? React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(3, 1fr)',
      gap: 2
    }
  }, trashPhotos.map((photo, idx) => React.createElement("div", {
    key: photo.id,
    onClick: () => handlePhotoClick(photo),
    style: {
      aspectRatio: '1',
      background: photo.thumbnailUrl ? '#1c1c1e' : photo.gradient,
      position: 'relative',
      cursor: 'pointer',
      overflow: 'hidden',
      animation: `cardIn 0.3s ease ${idx * 0.02}s both`,
      transition: 'transform 0.15s ease'
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = 'scale(0.95)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
    }
  }, photo.thumbnailUrl && photo.thumbnailUrl.startsWith('photo://') && React.createElement("img", {
    src: photo.thumbnailUrl,
    alt: "",
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      display: 'block'
    },
    draggable: false
  }), photo.isVideo && React.createElement("div", {
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
  }, React.createElement("svg", {
    width: "6",
    height: "7",
    viewBox: "0 0 6 7"
  }, React.createElement("polygon", {
    points: "0,0 6,3.5 0,7",
    fill: "#fff"
  })), React.createElement("span", {
    style: {
      color: '#fff',
      fontSize: 9,
      fontWeight: 500,
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, photo.duration))))) : React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '60px 20px',
      gap: 10,
      animation: 'fadeIn 0.4s ease'
    }
  }, React.createElement("div", {
    style: {
      fontSize: 48,
      opacity: 0.3
    }
  }, "\uD83D\uDDD1"), React.createElement("div", {
    style: {
      fontSize: 16,
      color: 'rgba(60,60,67,0.5)',
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, "\u56DE\u6536\u7AD9\u6CA1\u6709\u7167\u7247")), React.createElement("div", {
    style: {
      height: 80
    }
  })), React.createElement("div", {
    style: {
      background: 'rgba(250,250,252,0.72)',
      backdropFilter: 'blur(30px) saturate(200%)',
      WebkitBackdropFilter: 'blur(30px) saturate(200%)',
      borderTop: '0.5px solid rgba(60,60,67,0.08)',
      boxShadow: 'inset 0 -1px 0 rgba(255,255,255,0.6)',
      padding: '12px 16px calc(12px + var(--ios-safe-bottom))',
      animation: 'slideUpBar 0.3s ease'
    }
  }, React.createElement("button", {
    onClick: () => trashPhotos.length > 0 && setShowAlert(true),
    disabled: trashPhotos.length === 0,
    style: {
      width: '100%',
      padding: '14px 20px',
      background: trashPhotos.length === 0 ? 'rgba(255,59,48,0.3)' : '#FF3B30',
      color: '#fff',
      border: 'none',
      borderRadius: 14,
      fontSize: 17,
      fontWeight: 600,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      cursor: trashPhotos.length === 0 ? 'not-allowed' : 'pointer',
      letterSpacing: -0.4,
      transition: 'transform 0.15s ease, background 0.15s ease'
    },
    onMouseDown: e => {
      if (trashPhotos.length > 0) {
        e.currentTarget.style.transform = 'scale(0.97)';
      }
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
    }
  }, "\u5220\u9664\u5168\u90E8")), showAlert && React.createElement(IOSAlert, {
    title: "\u5220\u9664\u7167\u7247\uFF1F",
    message: `将从回收站中永久删除 ${trashPhotos.length} 张照片，此操作不可撤销。`,
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
  }), showActionSheet && selectedPhoto && React.createElement(IOSActionSheet, {
    title: `#${selectedPhoto.id}`,
    message: "\u9009\u62E9\u64CD\u4F5C",
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
function IOSAlert({
  title,
  message,
  actions
}) {
  return React.createElement("div", {
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
  }, React.createElement("div", {
    style: {
      background: 'rgba(242,242,247,0.95)',
      backdropFilter: 'blur(30px) saturate(180%)',
      WebkitBackdropFilter: 'blur(30px) saturate(180%)',
      borderRadius: 14,
      width: '100%',
      maxWidth: 270,
      overflow: 'hidden',
      animation: 'alertScaleIn 0.25s cubic-bezier(0.32, 0.72, 0, 1)'
    }
  }, React.createElement("div", {
    style: {
      padding: '20px 16px 14px',
      textAlign: 'center',
      borderBottom: '0.5px solid rgba(60,60,67,0.15)'
    }
  }, title && React.createElement("div", {
    style: {
      fontSize: 17,
      fontWeight: 600,
      color: '#000',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      letterSpacing: -0.4,
      marginBottom: message ? 6 : 0
    }
  }, title), message && React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.8)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      lineHeight: 1.4
    }
  }, message)), React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: actions.length === 2 ? 'row' : 'column'
    }
  }, actions.map((action, i) => React.createElement("button", {
    key: i,
    onClick: action.onClick,
    style: {
      flex: 1,
      padding: '12px 16px',
      background: 'transparent',
      border: 'none',
      borderRight: actions.length === 2 && i === 0 ? '0.5px solid rgba(60,60,67,0.15)' : 'none',
      borderTop: i > 0 && actions.length !== 2 ? '0.5px solid rgba(60,60,67,0.15)' : 'none',
      color: action.style === 'destructive' ? '#FF3B30' : '#007AFF',
      fontSize: 17,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: action.style === 'cancel' ? 600 : 400,
      cursor: 'pointer',
      letterSpacing: -0.4,
      transition: 'background 0.15s ease'
    },
    onMouseDown: e => {
      e.currentTarget.style.background = 'rgba(0,0,0,0.05)';
    },
    onMouseUp: e => {
      e.currentTarget.style.background = 'transparent';
    },
    onMouseLeave: e => {
      e.currentTarget.style.background = 'transparent';
    }
  }, action.label)))));
}
function IOSActionSheet({
  title,
  message,
  actions,
  onCancel
}) {
  return React.createElement("div", {
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
  }, React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      padding: '8px 10px calc(8px + var(--ios-safe-bottom))',
      animation: 'slideUp 0.3s cubic-bezier(0.32, 0.72, 0, 1)'
    }
  }, React.createElement("div", {
    style: {
      background: 'rgba(242,242,247,0.95)',
      backdropFilter: 'blur(30px) saturate(180%)',
      WebkitBackdropFilter: 'blur(30px) saturate(180%)',
      borderRadius: 14,
      overflow: 'hidden',
      marginBottom: 8
    }
  }, title && React.createElement("div", {
    style: {
      padding: '14px 16px 10px',
      textAlign: 'center',
      borderBottom: '0.5px solid rgba(60,60,67,0.12)'
    }
  }, React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui'
    }
  }, title), message && React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      marginTop: 2
    }
  }, message)), actions.map((action, i) => React.createElement("button", {
    key: i,
    onClick: action.onClick,
    style: {
      width: '100%',
      padding: '16px 20px',
      background: 'transparent',
      border: 'none',
      borderTop: i > 0 || title ? '0.5px solid rgba(60,60,67,0.12)' : 'none',
      color: action.style === 'destructive' ? '#FF3B30' : '#007AFF',
      fontSize: 17,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 400,
      cursor: 'pointer',
      letterSpacing: -0.4,
      textAlign: 'center',
      transition: 'background 0.15s ease'
    },
    onMouseDown: e => {
      e.currentTarget.style.background = 'rgba(0,0,0,0.05)';
    },
    onMouseUp: e => {
      e.currentTarget.style.background = 'transparent';
    },
    onMouseLeave: e => {
      e.currentTarget.style.background = 'transparent';
    }
  }, action.label))), React.createElement("button", {
    onClick: onCancel,
    style: {
      width: '100%',
      padding: '16px 20px',
      background: 'rgba(255,255,255,0.95)',
      backdropFilter: 'blur(30px) saturate(180%)',
      WebkitBackdropFilter: 'blur(30px) saturate(180%)',
      border: 'none',
      borderRadius: 14,
      color: '#007AFF',
      fontSize: 17,
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 600,
      cursor: 'pointer',
      letterSpacing: -0.4,
      transition: 'background 0.15s ease'
    },
    onMouseDown: e => {
      e.currentTarget.style.background = 'rgba(0,0,0,0.05)';
    },
    onMouseUp: e => {
      e.currentTarget.style.background = 'rgba(255,255,255,0.95)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.background = 'rgba(255,255,255,0.95)';
    }
  }, "\u53D6\u6D88")));
}
Object.assign(window, {
  TrashPage,
  IOSAlert,
  IOSActionSheet
});