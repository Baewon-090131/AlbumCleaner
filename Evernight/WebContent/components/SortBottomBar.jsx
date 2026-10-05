// v3.0 整理页底部操作岛
// - 常态：撤回（黄）/ 删除（红）/ 下一张（蓝）/ 相簿（深蓝）
// - 相簿模式：整行换成相簿列表，最右保留相簿按钮，左侧加分隔线
// - 相簿详情页只传三个动作，且不显示 tab 栏，所以底部安全区由这里收尾
const SORT_ACTIONS = {
  undo: { label: '撤回', color: '#FF9500', Icon: UndoIcon },
  delete: { label: '删除', color: '#FF3B30', Icon: TrashIcon },
  next: { label: '下一张', color: '#007AFF', Icon: NextIcon },
  album: { label: '相簿', color: 'var(--accent)', Icon: AlbumIcon },
};

function SortBottomBar({
  mode = 'buttons',
  actions = ['undo', 'delete', 'next', 'album'],
  albums = [],
  onUndo, onDelete, onNext, onAlbumMode, onBackToButtons, onAlbumAdd,
  canUndo = true, hasPhoto = true, animating = false,
  withTabBar = true,
}) {
  const padBottom = withTabBar ? 10 : 'calc(12px + var(--ios-safe-bottom))';

  const islandStyle = {
    background: 'var(--glass-float)',
    backdropFilter: 'var(--blur-float)',
    WebkitBackdropFilter: 'var(--blur-float)',
    borderRadius: 'var(--r-island)',
    boxShadow: 'var(--edge-float)',
  };

  if (mode === 'albums') {
    return (
      <div style={{ padding: `0 14px ${padBottom}px` }}>
        <div style={{
          ...islandStyle,
          display: 'flex', alignItems: 'center',
          padding: '8px 8px 8px 12px',
          animation: 'fadeIn 0.22s var(--ease-out)',
        }}>
          <div style={{
            flex: 1, minWidth: 0,
            display: 'flex', gap: 10,
            overflowX: 'auto', scrollbarWidth: 'none', msOverflowStyle: 'none',
            WebkitOverflowScrolling: 'touch',
          }}>
            {albums.map((album, index) => (
              <AlbumChip key={album.id} album={album} index={index}
                onClick={() => onAlbumAdd && onAlbumAdd(album)} />
            ))}
          </div>

          {/* 相簿按钮左侧的分隔线 */}
          <div style={{
            width: 0.5, height: 46, flexShrink: 0,
            margin: '0 6px 0 10px',
            background: 'rgba(60,60,67,0.18)',
            animation: 'fadeIn 0.24s ease',
          }} />

          <button
            onClick={onBackToButtons}
            className="ios-btn"
            style={{
              width: 66, height: 66, borderRadius: 22, flexShrink: 0,
              border: 'none', cursor: 'pointer',
              background: 'var(--accent-soft)',
              display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center', gap: 3,
              color: 'var(--accent)',
            }}>
            <AlbumIcon size={22} color="var(--accent)" weight={1.8} />
            <span style={{
              fontSize: 10.5, fontWeight: 500,
              fontFamily: '-apple-system, "SF Pro", system-ui', letterSpacing: -0.2,
            }}>相簿</span>
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: `0 14px ${padBottom}px` }}>
      <div style={{
        ...islandStyle,
        padding: '10px 12px',
        display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      }}>
        {actions.map((key, index) => {
          const item = SORT_ACTIONS[key];
          if (!item) return null;
          const enabled = key === 'undo' ? (canUndo && !animating) : (hasPhoto && !animating);
          const color = enabled ? item.color : 'rgba(60,60,67,0.32)';
          const onClick = key === 'undo' ? onUndo
            : key === 'delete' ? onDelete
            : key === 'next' ? onNext
            : onAlbumMode;
          return (
            <button
              key={key}
              onClick={enabled ? onClick : undefined}
              disabled={!enabled}
              className="ios-btn"
              style={{
                width: 72, height: 64, borderRadius: 22,
                background: 'transparent', border: 'none',
                display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center', gap: 3,
                cursor: enabled ? 'pointer' : 'not-allowed',
                opacity: enabled ? 1 : 0.4,
                color,
                animation: `cardIn 0.3s var(--ease-out) ${index * 0.04}s both`,
              }}>
              <div style={{
                width: 46, height: 46, borderRadius: 17,
                background: 'var(--glass-inner)',
                boxShadow: 'var(--edge-inner)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <item.Icon size={22} color={color} weight={1.8} />
              </div>
              <span style={{
                fontSize: 10.5, color,
                fontFamily: '-apple-system, "SF Pro", system-ui',
                fontWeight: 500, letterSpacing: -0.2,
              }}>{item.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function AlbumChip({ album, onClick, index = 0 }) {
  return (
    <div
      onClick={onClick}
      className="ios-btn"
      style={{
        width: 66, flexShrink: 0, cursor: 'pointer',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5,
        animation: `cardIn 0.26s var(--ease-out) ${index * 0.03}s both`,
      }}>
      <div style={{
        width: 60, height: 46, borderRadius: 16,
        background: album.gradient || 'var(--glass-inner)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 20,
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.45), 0 3px 10px rgba(22,32,72,0.12)',
        overflow: 'hidden',
      }}>
        {album.cover && album.cover.startsWith('photo://') ? (
          <img src={album.cover} alt="" draggable={false}
            style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
        ) : (
          <span style={{ opacity: 0.9 }}>{album.icon || '🖼'}</span>
        )}
      </div>
      <span style={{
        fontSize: 10.5, color: 'rgba(60,60,67,0.8)',
        fontFamily: '-apple-system, "SF Pro", system-ui',
        textAlign: 'center', lineHeight: 1.2,
        maxWidth: 66, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
      }}>{album.name}</span>
    </div>
  );
}

Object.assign(window, { SortBottomBar, AlbumChip, SORT_ACTIONS });
