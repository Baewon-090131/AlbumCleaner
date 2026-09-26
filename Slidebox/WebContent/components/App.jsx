function App() {
  const [themeColor, setThemeColor] = React.useState('#007AFF');
  const [pageStack, setPageStack] = React.useState(['home']);
  const [direction, setDirection] = React.useState('forward');
  const page = pageStack[pageStack.length - 1];

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

  const handleAutoLiveChange = (v) => {
    setAutoPlayLive(v);
    try { window.localStorage.setItem('ac_autoLive', v ? '1' : '0'); } catch (e) {}
  };
  const handleAutoVideoChange = (v) => {
    setAutoPlayVideo(v);
    try { window.localStorage.setItem('ac_autoVideo', v ? '1' : '0'); } catch (e) {}
  };

  // 加载数据
  React.useEffect(() => {
    if (window.DataLoader) {
      window.DataLoader.load(function(data) {
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

  const currentPhotos = currentMonth
    ? monthsData.find(m => m.id === currentMonth.id)?.photos || []
    : [];

  const navigateTo = (target, data = {}) => {
    setDirection('forward');
    if (data.month) {
      setCurrentMonth(data.month);
      setCurrentIndex(0);
      setHistoryStack([]);
      const monthData = monthsData.find(m => m.id === data.month.id);
      setInitialPhotoCount(monthData ? monthData.photos.length : 0);
      setProcessedCount(0);
    }
    setTimeout(() => { setPageStack(prev => [...prev, target]); }, 10);
  };

  const goBack = () => {
    if (pageStack.length <= 1) return;
    setDirection('backward');
    setTimeout(() => { setPageStack(prev => prev.slice(0, -1)); }, 10);
  };

  const showToast = (msg) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 1200);
  };

  const handleDelete = () => {
    if (!currentMonth || currentIndex >= currentPhotos.length) return;
    const photo = currentPhotos[currentIndex];
    setHistoryStack(prev => [...prev, { action: 'delete', photo, monthId: currentMonth.id }]);
    setMonthsData(prev => prev.map(m => {
      if (m.id !== currentMonth.id) return m;
      return { ...m, photos: m.photos.filter(p => p.id !== photo.id) };
    }));
    setTrashPhotos(prev => [photo, ...prev]);
    setProcessedCount(prev => prev + 1);
    showToast('已移到回收站');
  };

  const handleKeep = () => {
    if (!currentMonth || currentIndex >= currentPhotos.length) return;
    const photo = currentPhotos[currentIndex];
    setHistoryStack(prev => [...prev, { action: 'keep', photo, monthId: currentMonth.id }]);
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
        return { ...m, photos: newPhotos };
      }));
      showToast('已撤回删除');
    } else if (lastAction.action === 'keep') {
      setCurrentIndex(prev => Math.max(0, prev - 1));
    } else if (lastAction.action === 'favorite') {
      setMonthsData(prev => prev.map(m => {
        if (m.id !== lastAction.monthId) return m;
        const newPhotos = [...m.photos];
        newPhotos.splice(currentIndex, 0, lastAction.photo);
        return { ...m, photos: newPhotos };
      }));
      showToast('已撤回收藏');
    } else if (lastAction.action === 'addAlbum') {
      setMonthsData(prev => prev.map(m => {
        if (m.id !== lastAction.monthId) return m;
        const newPhotos = [...m.photos];
        newPhotos.splice(currentIndex, 0, lastAction.photo);
        return { ...m, photos: newPhotos };
      }));
    }
  };

  const handleFavorite = () => {
    if (!currentMonth || currentIndex >= currentPhotos.length) return;
    const photo = currentPhotos[currentIndex];
    const favPhoto = { ...photo, favorite: true };
    setHistoryStack(prev => [...prev, { action: 'favorite', photo: favPhoto, monthId: currentMonth.id }]);
    setMonthsData(prev => prev.map(m => {
      if (m.id !== currentMonth.id) return m;
      return { ...m, photos: m.photos.filter(p => p.id !== photo.id) };
    }));
    setProcessedCount(prev => prev + 1);
    // 调用原生桥接收藏
    if (window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
      window.NativeBridge.setFavorite(photo.id, true);
    }
    showToast('已加入个人收藏');
  };

  const handleAlbumAdd = (album) => {
    if (!currentMonth || currentIndex >= currentPhotos.length) return;
    const photo = currentPhotos[currentIndex];
    setHistoryStack(prev => [...prev, { action: 'addAlbum', photo, monthId: currentMonth.id, albumId: album.id }]);
    setMonthsData(prev => prev.map(m => {
      if (m.id !== currentMonth.id) return m;
      return { ...m, photos: m.photos.filter(p => p.id !== photo.id) };
    }));
    setAddedFeedback(album.name);
    setTimeout(() => setAddedFeedback(null), 1000);
    setProcessedCount(prev => prev + 1);
    // 调用原生桥接添加到相簿
    if (window.NativeBridge && window.NativeBridge.isNative() && !photo.id.startsWith('mock_')) {
      window.NativeBridge.addToAlbum(photo.id, album.id);
    }
  };

  const handleRestore = (photoId) => {
    const photo = trashPhotos.find(p => p.id === photoId);
    if (!photo) return;
    setTrashPhotos(prev => prev.filter(p => p.id !== photoId));
    setMonthsData(prev => prev.map((m, i) => i === 0 ? { ...m, photos: [...m.photos, photo] } : m));
  };

  const handleDeleteOne = (photoId) => {
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

  const handleThemeChange = (color) => { setThemeColor(color); };

  // 加载中状态
  if (isLoading) {
    return (
      <div style={{
        width: '100%', height: '100%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexDirection: 'column', gap: 16,
        background: '#F2F2F7',
      }}>
        <div style={{
          width: 40, height: 40,
          border: '3px solid rgba(0,122,255,0.2)',
          borderTopColor: '#007AFF',
          borderRadius: '50%',
          animation: 'spin 0.8s linear infinite',
        }} />
        <div style={{
          fontSize: 15, color: 'rgba(60,60,67,0.6)',
          fontFamily: '-apple-system, "SF Pro", system-ui',
        }}>正在加载照片库...</div>
        <style>{`@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }`}</style>
      </div>
    );
  }

  const renderPage = () => {
    switch (page) {
      case 'home':
        return (<HomePage months={monthsData} themeColor={themeColor}
          onMonthClick={(month) => navigateTo('sort', { month })}
          onTrashClick={() => navigateTo('trash')}
          onSettingsClick={() => navigateTo('settings')}
          trashCount={trashPhotos.length} />);
      case 'sort':
        return (<SortPage month={currentMonth || { title: '' }}
          photos={currentPhotos} currentIndex={currentIndex}
          totalCount={initialPhotoCount} processedCount={processedCount}
          themeColor={themeColor} historyLength={historyStack.length}
          addedFeedback={addedFeedback} toastMessage={toastMessage}
          albums={albumsData}
          autoPlayLive={autoPlayLive} autoPlayVideo={autoPlayVideo}
          onBack={goBack} onTrashClick={() => navigateTo('trash')}
          onAlbumAdd={handleAlbumAdd}
          onSwipeUp={handleDelete} onSwipeLeft={handleKeep}
          onSwipeRight={handleUndo} onSwipeDown={handleFavorite}
          onUndo={handleUndo} onDeleteButton={handleDelete} onKeepButton={handleKeep} />);
      case 'trash':
        return (<TrashPage trashPhotos={trashPhotos} themeColor={themeColor}
          onBack={goBack} onRestore={handleRestore}
          onDelete={handleDeleteOne} onDeleteAll={handleDeleteAll} />);
      case 'settings':
        return (<SettingsPage themeColor={themeColor}
          autoPlayLive={autoPlayLive} autoPlayVideo={autoPlayVideo}
          onAutoLiveChange={handleAutoLiveChange} onAutoVideoChange={handleAutoVideoChange}
          onThemeChange={handleThemeChange} onBack={goBack} />);
      default: return null;
    }
  };

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', overflow: 'hidden' }}>
      <div key={page} style={{
        position: 'absolute', inset: 0,
        animation: direction === 'backward'
          ? 'pageSlideRight 0.35s cubic-bezier(0.32, 0.72, 0, 1)'
          : 'pageSlideLeft 0.35s cubic-bezier(0.32, 0.72, 0, 1)',
      }}>
        {renderPage()}
      </div>
    </div>
  );
}

window.App = App;
