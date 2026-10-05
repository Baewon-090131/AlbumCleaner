// v3.0 相簿页：两列玻璃卡片（名称 / 数量 / 封面），点进去是相簿整理页
const ALBUM_ACCENTS = ['#002FA7', '#34C759', '#AF52DE', '#FF9500', '#FF3B30', '#007AFF', '#30B0C7'];

function AlbumsPage({ albums = [], themeColor = '#002FA7', onAlbumClick, trashCount = 0, onTrashClick }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'transparent' }}>
      <TopBar trashCount={trashCount} onTrashClick={onTrashClick} />

      <div style={{ padding: '0 20px 10px' }}>
        <div className="sf-title" style={{
          fontSize: 34, color: '#000', lineHeight: 1.05, letterSpacing: '-1.2px',
        }}>相簿</div>
        <div className="sf-body" style={{
          marginTop: 4, fontSize: 14, color: 'rgba(60,60,67,0.6)', fontWeight: 500,
        }}>{albums.length} 个相簿</div>
      </div>

      <div style={{
        flex: 1, overflowY: 'auto', WebkitOverflowScrolling: 'touch',
        padding: '6px 16px 16px',
      }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12,
        }}>
          {albums.map((album, index) => (
            <AlbumCard
              key={album.id}
              album={album}
              accent={ALBUM_ACCENTS[index % ALBUM_ACCENTS.length]}
              onClick={() => onAlbumClick && onAlbumClick(album)}
            />
          ))}
        </div>
        <div style={{ textAlign: 'center', padding: '18px 0 8px' }}>
          <div className="sf-body" style={{ fontSize: 12, color: 'rgba(60,60,67,0.4)' }}>
            照片仅在本机整理
          </div>
        </div>
      </div>
    </div>
  );
}

function AlbumCard({ album, accent, onClick }) {
  const hasCover = album.cover && album.cover.startsWith('photo://');

  return (
    <div
      onClick={onClick}
      className="ios-row"
      style={{
        position: 'relative',
        borderRadius: 'var(--r-panel)',
        padding: '12px 14px 14px',
        cursor: 'pointer',
        background: 'var(--glass-solid)',
        boxShadow: 'var(--edge-panel-soft)',
        display: 'flex', flexDirection: 'column', gap: 10,
        minHeight: 122,
      }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, minWidth: 0 }}>
        <div className="sf-title" style={{
          fontSize: 15, color: '#000', letterSpacing: -0.3,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          flex: 1, minWidth: 0,
        }}>{album.name}</div>
        <div style={{
          fontSize: 15, fontWeight: 700, color: accent,
          fontFamily: '-apple-system, "SF Pro", system-ui',
          flexShrink: 0,
        }}>{album.count}</div>
      </div>

      <div style={{
        flex: 1, borderRadius: 18, overflow: 'hidden',
        background: album.gradient || 'linear-gradient(135deg,#d1d1d6,#e5e5ea)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.5)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        minHeight: 62,
      }}>
        {hasCover ? (
          <img
            src={album.cover}
            alt=""
            draggable={false}
            style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
          />
        ) : (
          <span style={{ fontSize: 24, opacity: 0.85 }}>{album.icon || '🖼'}</span>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { AlbumsPage, AlbumCard });
