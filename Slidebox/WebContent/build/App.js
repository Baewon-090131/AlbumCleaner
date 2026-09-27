// v2.6 App：双页 iOS push/pop 转场状态机 + 全局状态
// 转场规则（apple-design）：push 新页右滑入 + 旧页左移 28% 变暗；pop 反向对称
function App() {
  // 主题色：从 localStorage 读取（与开关持久化一致），默认 iOS 蓝
  let initialTheme = '#007AFF';
  try {
    const st = window.localStorage.getItem('ac_theme');
    if (st) initialTheme = st;
  } catch (e) {}
  const [themeColor, setThemeColor] = React.useState(initialTheme);
  const [stack, setStack] = React.useState(['home']);
  // 渲染栈：转场期间保留两层，平时一层
  const [renderStack, setRenderStack] = React.useState([{
    key: 'home',
    page: 'home',
    id: 0
  }]);
  const [dir, setDir] = React.useState('forward');
  const page = stack[stack.length - 1];
  const [currentMonth, setCurrentMonth] = React.useState(null);
  const [currentIndex, setCurrentIndex] = React.useState(0);
  const [initialPhotoCount, setInitialPhotoCount] = React.useState(0);
  const [processedCount, setProcessedCount] = React.useState(0);
  const [monthsData, setMonthsData] = React.useState([]);
  const [albumsData, setAlbumsData] = React.useState([]);
  const [isLoading, setIsLoading] = React.useState(true);
  const [trashPhotos, setTrashPhotos] = React.useState([]);
  const [historyStack, setHistoryStack] = React.useState([]);
  const [addedFeedback, setAddedFeedback] = React.useState(null);
  const [toastMessage, setToastMessage] = React.useState(null);

  // v2.5：Live 图 / 视频 自动播放开关（localStorage 持久化，默认开启）
  const [autoPlayLive, setAutoPlayLive] = React.useState(true);
  const [autoPlayVideo, setAutoPlayVideo] = React.useState(true);

  // 读取持久化开关
  React.useEffect(() => {
    try {
      const s = window.localStorage;
      if (s) {
        setAutoPlayLive(s.getItem('ac_autoLive') !== '0');
        setAutoPlayVideo(s.getItem('ac_autoVideo') !== '0');
      }
    } catch (e) {}
  }, []);
  const handleAutoLiveChange = v => {
    setAutoPlayLive(v);
    try {
      window.localStorage.setItem('ac_autoLive', v ? '1' : '0');
    } catch (e) {}
  };
  const handleAutoVideoChange = v => {
    setAutoPlayVideo(v);
    try {
      window.localStorage.setItem('ac_autoVideo', v ? '1' : '0');
    } catch (e) {}
  };

  // 加载数据
  React.useEffect(() => {
    if (window.DataLoader) {
      window.DataLoader.load(function (data) {
        setMonthsData(data.months);
        setAlbumsData(data.albums);
        setIsLoading(false);
      });
    } else {
      setMonthsData(window.MockData.months);
      setAlbumsData(window.MockData.albums);
      setIsLoading(false);
    }
  }, []);
  const currentPhotos = currentMonth ? monthsData.find(m => m.id === currentMonth.id)?.photos || [] : [];

  // ===== 双页转场（v2.6） =====
  // push：新页入栈（渲染栈保留旧页同框），360ms 后裁剪回单层
  const navigateTo = (target, data = {}) => {
    if (data.month) {
      setCurrentMonth(data.month);
      setCurrentIndex(0);
      setHistoryStack([]);
      const monthData = monthsData.find(m => m.id === data.month.id);
      setInitialPhotoCount(monthData ? monthData.photos.length : 0);
      setProcessedCount(0);
    }
    const id = Date.now();
    setDir('forward');
    setRenderStack(prev => {
      const top = prev[prev.length - 1];
      return [top, {
        key: target,
        page: target,
        id
      }];
    });
    setTimeout(() => {
      setStack(prev => [...prev, target]);
      setRenderStack(prev => prev.slice(-1));
    }, 380);
  };

  // pop：顶页右滑出，下页复位，360ms 后移除顶页
  const goBack = () => {
    if (stack.length <= 1) return;
    const prevPage = stack[stack.length - 2];
    setDir('backward');
    setRenderStack(prev => {
      const top = prev[prev.length - 1];
      return [{
        key: prevPage,
        page: prevPage,
        id: top.id - 1
      }, top];
    });
    setTimeout(() => {
      setStack(prev => prev.slice(0, -1));
      // 保留栈底页（home），而不是栈顶（要被移除的页）
      setRenderStack(prev => [prev[0]]);
    }, 380);
  };
  const showToast = msg => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 1300);
  };
  const handleDelete = () => {
    if (!currentMonth || currentIndex >= currentPhotos.length) return;
    const photo = currentPhotos[currentIndex];
    setHistoryStack(prev => [...prev, {
      action: 'delete',
      photo,
      monthId: currentMonth.id
    }]);
    setMonthsData(prev => prev.map(m => {
      if (m.id !== currentMonth.id) return m;
      return {
        ...m,
        photos: m.photos.filter(p => p.id !== photo.id)
      };
    }));
    setTrashPhotos(prev => [photo, ...prev]);
    setProcessedCount(prev => prev + 1);
    showToast('已移到回收站');
  };
  const handleKeep = () => {
    if (!currentMonth || currentIndex >= currentPhotos.length) return;
    const photo = currentPhotos[currentIndex];
    setHistoryStack(prev => [...prev, {
      action: 'keep',
      photo,
      monthId: currentMonth.id
    }]);
    setCurrentIndex(prev => prev + 1);
    setProcessedCount(prev => prev + 1);
  };
  const handleUndo = () => {
    if (historyStack.length === 0) return;
    const lastAction = historyStack[historyStack.length - 1];
    setHistoryStack(prev => prev.slice(0, -1));
    setProcessedCount(prev => Math.max(0, prev - 1));
    if (lastAction.action === 'delete') {
      setTrashPhotos(prev => prev.filter(p => p.id !== lastAction.photo.id));
      setMonthsData(prev => prev.map(m => {
        if (m.id !== lastAction.monthId) return m;
        const newPhotos = [...m.photos];
        newPhotos.splice(currentIndex, 0, lastAction.photo);
        return {
          ...m,
          photos: newPhotos
        };
      }));
      showToast('已撤回删除');
    } else if (lastAction.action === 'keep') {
      setCurrentIndex(prev => Math.max(0, prev - 1));
    } else if (lastAction.action === 'favorite') {
      setMonthsData(prev => prev.map(m => {
        if (m.id !== lastAction.monthId) return m;
        const newPhotos = [...m.photos];
        newPhotos.splice(currentIndex, 0, lastAction.photo);
        return {
          ...m,
          photos: newPhotos
        };
      }));
      showToast('已撤回收藏');
    } else if (lastAction.action === 'addAlbum') {
      setMonthsData(prev => prev.map(m => {
        if (m.id !== lastAction.monthId) return m;
        const newPhotos = [...m.photos];
        newPhotos.splice(currentIndex, 0, lastAction.photo);
        return {
          ...m,
          photos: newPhotos
        };
      }));
    }
  };
  const handleFavorite = () => {
    if (!currentMonth || currentIndex >= currentPhotos.length) return;
    const photo = currentPhotos[currentIndex];
    const favPhoto = {
      ...photo,
      favorite: true
    };
    setHistoryStack(prev => [...prev, {
      action: 'favorite',
      photo: favPhoto,
      monthId: currentMonth.id
    }]);
    setMonthsData(prev => prev.map(m => {
      if (m.id !== currentMonth.id) return m;
      return {
        ...m,
        photos: m.photos.filter(p => p.id !== photo.id)
      };
    }));
    setProcessedCount(prev => prev + 1);
    // 调用原生桥接收藏
    if (window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
      window.NativeBridge.setFavorite(photo.id, true);
    }
    showToast('已加入个人收藏');
  };
  const handleAlbumAdd = album => {
    if (!currentMonth || currentIndex >= currentPhotos.length) return;
    const photo = currentPhotos[currentIndex];
    setHistoryStack(prev => [...prev, {
      action: 'addAlbum',
      photo,
      monthId: currentMonth.id,
      albumId: album.id
    }]);
    setMonthsData(prev => prev.map(m => {
      if (m.id !== currentMonth.id) return m;
      return {
        ...m,
        photos: m.photos.filter(p => p.id !== photo.id)
      };
    }));
    setAddedFeedback(album.name);
    setTimeout(() => setAddedFeedback(null), 1100);
    setProcessedCount(prev => prev + 1);
    // 调用原生桥接添加到相簿
    if (window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
      window.NativeBridge.addToAlbum(photo.id, album.id);
    }
  };
  const handleRestore = photoId => {
    const photo = trashPhotos.find(p => p.id === photoId);
    if (!photo) return;
    setTrashPhotos(prev => prev.filter(p => p.id !== photoId));
    setMonthsData(prev => prev.map((m, i) => i === 0 ? {
      ...m,
      photos: [...m.photos, photo]
    } : m));
  };
  const handleDeleteOne = photoId => {
    const photo = trashPhotos.find(p => p.id === photoId);
    setTrashPhotos(prev => prev.filter(p => p.id !== photoId));
    // 调用原生桥接彻底删除
    if (photo && window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
      window.NativeBridge.deleteAssets([photo.id]);
    }
  };
  const handleDeleteAll = () => {
    const realIds = trashPhotos.filter(p => !p.id.startsWith('mock_')).map(p => p.id);
    setTrashPhotos([]);
    // 调用原生桥接彻底删除
    if (realIds.length > 0 && window.NativeBridge && window.NativeBridge.isNative()) {
      window.NativeBridge.deleteAssets(realIds);
    }
  };
  const handleThemeChange = color => {
    setThemeColor(color);
    try {
      window.localStorage.setItem('ac_theme', color);
    } catch (e) {}
  };

  // 加载中状态（v2.6：iOS 风格动态模糊加载页）
  if (isLoading) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        width: '100%',
        height: '100%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        gap: 18,
        background: 'transparent'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 46,
        height: 46,
        borderRadius: '50%',
        background: 'rgba(255,255,255,0.55)',
        backdropFilter: 'blur(25px) saturate(200%)',
        WebkitBackdropFilter: 'blur(25px) saturate(200%)',
        border: '0.5px solid rgba(255,255,255,0.8)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), 0 6px 20px rgba(30,40,90,0.10)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 22,
        height: 22,
        border: '2.5px solid rgba(0,122,255,0.2)',
        borderTopColor: '#007AFF',
        borderRadius: '50%',
        animation: 'spin 0.8s linear infinite'
      }
    })), /*#__PURE__*/React.createElement("div", {
      className: "sf-body",
      style: {
        fontSize: 14,
        color: 'rgba(60,60,67,0.55)'
      }
    }, "\u6B63\u5728\u52A0\u8F7D\u7167\u7247\u5E93\u2026"));
  }
  const renderPage = key => {
    switch (key) {
      case 'home':
        return /*#__PURE__*/React.createElement(HomePage, {
          months: monthsData,
          themeColor: themeColor,
          onMonthClick: month => navigateTo('sort', {
            month
          }),
          onTrashClick: () => navigateTo('trash'),
          onSettingsClick: () => navigateTo('settings'),
          trashCount: trashPhotos.length
        });
      case 'sort':
        return /*#__PURE__*/React.createElement(SortPage, {
          month: currentMonth || {
            title: ''
          },
          photos: currentPhotos,
          currentIndex: currentIndex,
          totalCount: initialPhotoCount,
          processedCount: processedCount,
          themeColor: themeColor,
          historyLength: historyStack.length,
          addedFeedback: addedFeedback,
          toastMessage: toastMessage,
          albums: albumsData,
          autoPlayLive: autoPlayLive,
          autoPlayVideo: autoPlayVideo,
          onBack: goBack,
          onTrashClick: () => navigateTo('trash'),
          trashCount: trashPhotos.length,
          onAlbumAdd: handleAlbumAdd,
          onSwipeUp: handleDelete,
          onSwipeLeft: handleKeep,
          onSwipeRight: handleUndo,
          onSwipeDown: handleFavorite,
          onUndo: handleUndo,
          onDeleteButton: handleDelete,
          onKeepButton: handleKeep
        });
      case 'trash':
        return /*#__PURE__*/React.createElement(TrashPage, {
          trashPhotos: trashPhotos,
          themeColor: themeColor,
          onBack: goBack,
          onRestore: handleRestore,
          onDelete: handleDeleteOne,
          onDeleteAll: handleDeleteAll
        });
      case 'settings':
        return /*#__PURE__*/React.createElement(SettingsPage, {
          themeColor: themeColor,
          autoPlayLive: autoPlayLive,
          autoPlayVideo: autoPlayVideo,
          onAutoLiveChange: handleAutoLiveChange,
          onAutoVideoChange: handleAutoVideoChange,
          onThemeChange: handleThemeChange,
          onBack: goBack
        });
      default:
        return null;
    }
  };

  // 双页转场渲染：转场期间两层同框
  const topIndex = renderStack.length - 1;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      width: '100%',
      height: '100%',
      overflow: 'hidden',
      background: 'transparent'
    }
  }, renderStack.map((item, i) => {
    const isTop = i === topIndex;
    const style = {
      position: 'absolute',
      inset: 0,
      background: 'transparent'
    };
    if (renderStack.length > 1) {
      if (isTop) {
        // 顶页：push 右滑入 / pop 右滑出（对称路径）
        style.animation = dir === 'forward' ? 'pagePushEnter 0.36s var(--ease-drawer)' : 'pagePopLeave 0.36s var(--ease-drawer)';
        style.zIndex = 2;
        style.boxShadow = '-10px 0 28px rgba(0,0,0,0.10)';
        style.willChange = 'transform, opacity';
      } else {
        // 下层页：push 左移变暗 / pop 复位（transition 驱动）
        const under = dir === 'forward' ? {
          transform: 'translateX(-26%) scale(0.96)',
          opacity: 0.82
        } : {
          transform: 'translateX(0) scale(1)',
          opacity: 1
        };
        Object.assign(style, under);
        style.transition = 'transform 0.36s var(--ease-drawer), opacity 0.36s ease';
        style.zIndex = 1;
        style.willChange = 'transform, opacity';
      }
    }
    return /*#__PURE__*/React.createElement("div", {
      key: item.id,
      style: style
    }, renderPage(item.page));
  }));
}
window.App = App;