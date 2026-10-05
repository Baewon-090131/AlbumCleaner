// v3.0 App：三 tab（整理 / 相簿 / 我的）+ 页内推入（回收站、相簿详情）
// tab 之间淡入淡出；页内推入沿用 v2.6 的双层揭示转场
const GIGABYTE = 1024 * 1024 * 1024;
const TAB_PAGES = ['sort', 'albums', 'mine'];
function App() {
  // 主题色：从 localStorage 读取（与开关持久化一致），默认北洋蓝（iOS 27 强调色）
  let initialTheme = '#002FA7';
  try {
    const st = window.localStorage.getItem('ac_theme');
    if (st) initialTheme = st;
  } catch (e) {}
  const [themeColor, setThemeColor] = React.useState(initialTheme);

  // 允许用 #sort / #albums / #mine 直接落到某个 tab（预览与截图用）
  const initialTab = (() => {
    try {
      const hash = (window.location.hash || '').replace('#', '');
      return ['sort', 'albums', 'mine'].indexOf(hash) >= 0 ? hash : 'sort';
    } catch (e) {
      return 'sort';
    }
  })();
  const [stack, setStack] = React.useState([initialTab]);
  const [renderStack, setRenderStack] = React.useState([{
    key: initialTab,
    page: initialTab,
    id: 0
  }]);
  const [dir, setDir] = React.useState('forward');
  const page = stack[stack.length - 1];
  const [currentMonth, setCurrentMonth] = React.useState(null);
  const [currentAlbum, setCurrentAlbum] = React.useState(null);
  const [albumPhotos, setAlbumPhotos] = React.useState([]);
  const [currentIndex, setCurrentIndex] = React.useState(0);
  const [initialPhotoCount, setInitialPhotoCount] = React.useState(0);
  const [processedCount, setProcessedCount] = React.useState(0);
  const [monthsData, setMonthsData] = React.useState([]);
  const [albumsData, setAlbumsData] = React.useState([]);
  const [storage, setStorage] = React.useState(null);
  const [isLoading, setIsLoading] = React.useState(true);
  const [trashPhotos, setTrashPhotos] = React.useState([]);
  const [historyStack, setHistoryStack] = React.useState([]);
  const [addedFeedback, setAddedFeedback] = React.useState(null);
  const [toastMessage, setToastMessage] = React.useState(null);

  // v2.5：Live 图 / 视频 自动播放开关（localStorage 持久化，默认开启）
  const [autoPlayLive, setAutoPlayLive] = React.useState(true);
  const [autoPlayVideo, setAutoPlayVideo] = React.useState(true);
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

  // 机身存储（无原生桥时给一组示例值，方便浏览器里看布局）
  React.useEffect(() => {
    const bridge = window.NativeBridge;
    if (bridge && bridge.isNative() && bridge.getStorageInfo) {
      bridge.getStorageInfo(function (info) {
        if (info) setStorage(info);
      });
    } else {
      setStorage({
        total: 256 * GIGABYTE,
        free: 84 * GIGABYTE,
        used: 172 * GIGABYTE
      });
    }
  }, []);
  const currentPhotos = currentMonth ? monthsData.find(m => m.id === currentMonth.id)?.photos || [] : [];
  const isAlbumMode = page === 'album';
  const activePhotos = isAlbumMode ? albumPhotos : currentPhotos;
  const activeTotal = isAlbumMode ? albumPhotos.length : initialPhotoCount;
  const activeProgress = activeTotal > 0 ? Math.min(1, processedCount / activeTotal) * 100 : 100;
  const activeRemaining = Math.max(0, activeTotal - processedCount);

  // ===== 导航：tab 切换淡入，页内推入走揭示转场 =====
  const pushPage = (target, id, duration) => {
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
    }, duration);
  };
  const switchTab = target => {
    if (target === page) return;
    setDir('fade');
    const id = Date.now();
    setRenderStack(prev => [prev[prev.length - 1], {
      key: target,
      page: target,
      id
    }]);
    setTimeout(() => {
      setStack([target]);
      setRenderStack(prev => prev.slice(-1));
    }, 280);
  };
  const navigateTo = target => {
    setDir('forward');
    pushPage(target, Date.now(), 380);
  };
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
      setRenderStack(prev => [prev[0]]);
    }, 380);
  };
  const showToast = msg => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 1300);
  };

  // 打开某个月份（从顶部胶囊切换）
  const openMonth = month => {
    if (!month) return;
    setCurrentMonth(month);
    setCurrentIndex(0);
    setHistoryStack([]);
    const monthData = monthsData.find(m => m.id === month.id);
    setInitialPhotoCount(monthData ? monthData.photos.length : 0);
    setProcessedCount(0);
  };

  // 打开某个相簿 → 推入相簿整理页
  const openAlbum = album => {
    setCurrentAlbum(album);
    setCurrentIndex(0);
    setHistoryStack([]);
    setProcessedCount(0);
    const bridge = window.NativeBridge;
    if (bridge && bridge.isNative() && bridge.getAlbumAssets) {
      setAlbumPhotos([]);
      navigateTo('album');
      bridge.getAlbumAssets(album.id, function (list) {
        setAlbumPhotos(list || []);
      });
    } else {
      const pool = monthsData.flatMap(m => m.photos);
      setAlbumPhotos(pool.slice(0, Math.min(album.count || 12, 24)));
      navigateTo('album');
    }
  };
  const contextKey = () => isAlbumMode ? {
    type: 'album',
    id: currentAlbum && currentAlbum.id
  } : {
    type: 'month',
    id: currentMonth && currentMonth.id
  };
  const removeFromActive = photoId => {
    if (isAlbumMode) {
      setAlbumPhotos(prev => prev.filter(p => p.id !== photoId));
    } else {
      setMonthsData(prev => prev.map(m => m.id === currentMonth.id ? {
        ...m,
        photos: m.photos.filter(p => p.id !== photoId)
      } : m));
    }
  };
  const insertIntoContext = (context, photo) => {
    if (context.type === 'album') {
      setAlbumPhotos(prev => [photo, ...prev]);
    } else {
      setMonthsData(prev => prev.map(m => m.id === context.id ? {
        ...m,
        photos: [photo, ...m.photos]
      } : m));
    }
  };

  // 首次进入整理页时选最近的一个月
  React.useEffect(() => {
    if (!currentMonth && monthsData.length > 0) openMonth(monthsData[0]);
  }, [monthsData]);
  const handleDelete = () => {
    if (currentIndex >= activePhotos.length) return;
    const photo = activePhotos[currentIndex];
    setHistoryStack(prev => [...prev, {
      action: 'delete',
      photo,
      context: contextKey()
    }]);
    removeFromActive(photo.id);
    setTrashPhotos(prev => [photo, ...prev]);
    setProcessedCount(prev => prev + 1);
    showToast('已移到回收站');
  };
  const handleKeep = () => {
    if (currentIndex >= activePhotos.length) return;
    const photo = activePhotos[currentIndex];
    setHistoryStack(prev => [...prev, {
      action: 'keep',
      photo,
      context: contextKey()
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
      insertIntoContext(lastAction.context, lastAction.photo);
      showToast('已撤回删除');
    } else if (lastAction.action === 'keep') {
      setCurrentIndex(prev => Math.max(0, prev - 1));
    } else if (lastAction.action === 'favorite') {
      insertIntoContext(lastAction.context, lastAction.photo);
      showToast('已撤回收藏');
    } else if (lastAction.action === 'addAlbum') {
      insertIntoContext(lastAction.context, lastAction.photo);
    }
  };
  const handleFavorite = () => {
    if (currentIndex >= activePhotos.length) return;
    const photo = activePhotos[currentIndex];
    const favPhoto = {
      ...photo,
      favorite: true
    };
    setHistoryStack(prev => [...prev, {
      action: 'favorite',
      photo: favPhoto,
      context: contextKey()
    }]);
    removeFromActive(photo.id);
    setProcessedCount(prev => prev + 1);
    if (window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
      window.NativeBridge.setFavorite(photo.id, true);
    }
    showToast('已加入个人收藏');
  };
  const handleAlbumAdd = album => {
    if (currentIndex >= activePhotos.length) return;
    const photo = activePhotos[currentIndex];
    setHistoryStack(prev => [...prev, {
      action: 'addAlbum',
      photo,
      context: contextKey(),
      albumId: album.id
    }]);
    removeFromActive(photo.id);
    setAddedFeedback(album.name);
    setTimeout(() => setAddedFeedback(null), 1100);
    setProcessedCount(prev => prev + 1);
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
      photos: [photo, ...m.photos]
    } : m));
  };
  const handleDeleteOne = photoId => {
    const photo = trashPhotos.find(p => p.id === photoId);
    setTrashPhotos(prev => prev.filter(p => p.id !== photoId));
    if (photo && window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
      window.NativeBridge.deleteAssets([photo.id]);
    }
  };
  const handleDeleteAll = () => {
    const realIds = trashPhotos.filter(p => !p.id.startsWith('mock_')).map(p => p.id);
    setTrashPhotos([]);
    if (realIds.length > 0 && window.NativeBridge && window.NativeBridge.isNative()) {
      window.NativeBridge.deleteAssets(realIds);
    }
  };
  const handleClearCache = () => {
    showToast('缓存已清理');
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
        background: 'var(--glass-panel)',
        backdropFilter: 'var(--blur-panel)',
        WebkitBackdropFilter: 'var(--blur-panel)',
        boxShadow: 'var(--edge-panel-soft)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 22,
        height: 22,
        border: '2.5px solid var(--accent-soft)',
        borderTopColor: themeColor,
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
      case 'sort':
        return /*#__PURE__*/React.createElement(SortPage, {
          month: currentMonth || {
            title: ''
          },
          months: monthsData,
          currentMonthId: currentMonth && currentMonth.id,
          onMonthSelect: openMonth,
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
          onTrashClick: () => navigateTo('trash'),
          trashCount: trashPhotos.length,
          onAlbumAdd: handleAlbumAdd,
          onSwipeUp: handleDelete,
          onSwipeLeft: handleKeep,
          onSwipeRight: handleUndo,
          onSwipeDown: handleFavorite,
          onUndo: handleUndo,
          onDeleteButton: handleDelete,
          onKeepButton: handleKeep,
          withTabBar: true
        });
      case 'albums':
        return /*#__PURE__*/React.createElement(AlbumsPage, {
          albums: albumsData,
          themeColor: themeColor,
          onAlbumClick: openAlbum,
          trashCount: trashPhotos.length,
          onTrashClick: () => navigateTo('trash')
        });
      case 'mine':
        return /*#__PURE__*/React.createElement(MinePage, {
          themeColor: themeColor,
          onThemeChange: handleThemeChange,
          autoPlayLive: autoPlayLive,
          autoPlayVideo: autoPlayVideo,
          onAutoLiveChange: handleAutoLiveChange,
          onAutoVideoChange: handleAutoVideoChange,
          trashPhotos: trashPhotos,
          storage: storage,
          onClearCache: handleClearCache,
          trashCount: trashPhotos.length,
          onTrashClick: () => navigateTo('trash')
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
      case 'album':
        return /*#__PURE__*/React.createElement(SortPage, {
          month: currentAlbum || {
            title: ''
          },
          backLabel: "\u76F8\u7C3F",
          photos: albumPhotos,
          currentIndex: currentIndex,
          totalCount: albumPhotos.length,
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
          onKeepButton: handleKeep,
          actions: ['undo', 'delete', 'next'],
          withTabBar: false
        });
      default:
        return null;
    }
  };

  // 双页转场渲染：转场期间两层同框。
  // 每页两层：外层是「不透明壁纸背板 + 裁切揭示」，内层是页面内容（负责位移）。
  // 只有外层不透明，旧页面才不会透过新页面显示（v2.7 修复切页重影）。
  const topIndex = renderStack.length - 1;
  const transitioning = renderStack.length > 1;
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
    const layer = {
      position: 'absolute',
      inset: 0,
      background: 'var(--wall)'
    };
    const content = {
      position: 'absolute',
      inset: 0
    };
    if (transitioning) {
      if (isTop) {
        if (dir === 'fade') {
          // tab 切换：只淡入，不做位移
          layer.animation = 'fadeIn 0.28s var(--ease-out) both';
        } else {
          layer.animation = dir === 'forward' ? 'pageRevealIn 0.36s var(--ease-drawer) both' : 'pageRevealOut 0.36s var(--ease-drawer) both';
          content.animation = dir === 'forward' ? 'pageSlideIn 0.36s var(--ease-drawer) both' : 'pageSlideOut 0.36s var(--ease-drawer) both';
          content.willChange = 'transform';
        }
        layer.zIndex = 2;
        if (dir !== 'fade') layer.willChange = 'clip-path';
      } else {
        // 下层页：push 内容左移变暗 / pop 复位（transition 驱动；壁纸背板保持不动）
        const reduceMotion = !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
        const under = dir === 'fade' ? {
          opacity: 1
        } : dir === 'forward' ? reduceMotion ? {
          opacity: 0.82
        } : {
          transform: 'translateX(-26%) scale(0.96)',
          opacity: 0.82
        } : reduceMotion ? {
          opacity: 1
        } : {
          transform: 'translateX(0) scale(1)',
          opacity: 1
        };
        Object.assign(content, under);
        content.transition = reduceMotion ? 'opacity 0.2s ease' : 'transform 0.36s var(--ease-drawer), opacity 0.36s ease';
        layer.zIndex = 1;
        if (dir !== 'fade') content.willChange = 'transform, opacity';
      }
    }
    return /*#__PURE__*/React.createElement("div", {
      key: item.id,
      style: layer
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        ...content,
        display: 'flex',
        flexDirection: 'column'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        minHeight: 0,
        position: 'relative'
      }
    }, renderPage(item.page)), TAB_PAGES.indexOf(item.page) >= 0 && /*#__PURE__*/React.createElement(BottomTabBar, {
      active: item.page,
      onChange: switchTab
    }), transitioning && isTop && dir !== 'fade' &&
    /*#__PURE__*/
    /* 揭示边缘的投影：跟着内容层左缘走，视觉上等价于「新页压在旧页上」的投影 */
    React.createElement("div", {
      style: {
        position: 'absolute',
        top: 0,
        bottom: 0,
        left: 0,
        width: 26,
        zIndex: 400,
        background: 'linear-gradient(to right, rgba(22,32,72,0.16), rgba(22,32,72,0))',
        pointerEvents: 'none'
      }
    })));
  }));
}
window.App = App;