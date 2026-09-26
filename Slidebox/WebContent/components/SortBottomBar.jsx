// 整理页面底部操作区 - 优化动效
function SortBottomBar({
  themeColor = '#007AFF',
  mode = 'buttons',
  onUndo, onDelete, onNext, onAlbumMode, onBackToButtons,
  onAlbumAdd, canUndo = true, hasPhoto = true, animating = false,
  albums = null,
}) {
  const albumList = albums && albums.length > 0 ? albums : window.MockData.albums;

  if (mode === 'albums') {
    return (
      <div style={{ padding: '0 14px calc(14px + var(--ios-safe-bottom))' }}>
        <div style={{
          // v2.5 液态玻璃面板（透出壁纸）
          background: 'rgba(255,255,255,0.48)',
          backdropFilter: 'blur(35px) saturate(200%)',
          WebkitBackdropFilter: 'blur(35px) saturate(200%)',
          borderRadius: 26,
          border: '0.5px solid rgba(255,255,255,0.75)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.85), inset 0 -1px 0 rgba(255,255,255,0.25), 0 8px 30px rgba(30,40,90,0.10)',
          padding: '10px 0 12px',
          animation: 'slideUpBar 0.3s cubic-bezier(0.32, 0.72, 0, 1)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', padding: '0 18px 10px', gap: 10 }}>
            <button onClick={onBackToButtons} style={{
              display: 'flex', alignItems: 'center', gap: 3,
              background: 'none', border: 'none', padding: 4, cursor: 'pointer',
              color: themeColor, fontSize: 15,
              fontFamily: '-apple-system, "SF Pro", system-ui', fontWeight: 500,
              transition: 'transform 0.15s ease, opacity 0.15s ease',
            }}
            onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(0.9)'; e.currentTarget.style.opacity = '0.6'; }}
            onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; e.currentTarget.style.opacity = '1'; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; e.currentTarget.style.opacity = '1'; }}
            >
              <svg width="14" height="14" viewBox="0 0 14 14">
                <path d="M8.5 2L3.5 7l5 5" stroke={themeColor} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              <span>返回</span>
            </button>
            <div style={{
              flex: 1, textAlign: 'center', fontSize: 14,
              color: 'rgba(60,60,67,0.7)',
              fontFamily: '-apple-system, "SF Pro", system-ui', fontWeight: 500, paddingRight: 50,
            }}>添加到相簿</div>
          </div>
          <div style={{
            display: 'flex', gap: 12, padding: '0 16px',
            overflowX: 'auto', scrollbarWidth: 'none', msOverflowStyle: 'none',
            WebkitOverflowScrolling: 'touch',
          }}>
            {albumList.map((album, idx) => (
              <div key={album.id} style={{ animation: `cardIn 0.3s ease ${idx * 0.04}s both`, flexShrink: 0 }}>
                <AlbumChip album={album} onClick={() => onAlbumAdd(album)} />
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  const buttons = [
    { id: 'undo', label: '撤回', color: canUndo ? themeColor : 'rgba(60,60,67,0.3)', enabled: canUndo && !animating, onClick: onUndo,
      icon: (<svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M9 14L4 9l5-5" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/><path d="M4 9h11a6 6 0 010 12h-3" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>) },
    { id: 'delete', label: '删除', color: '#FF3B30', enabled: hasPhoto && !animating, onClick: onDelete,
      icon: (<svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>) },
    { id: 'next', label: '下一张', color: '#34C759', enabled: hasPhoto && !animating, onClick: onNext,
      icon: (<svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M5 4v16M10 20l9-8-9-8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>) },
    { id: 'album', label: '相簿', color: themeColor, enabled: hasPhoto && !animating, onClick: onAlbumMode,
      icon: (<svg width="24" height="20" viewBox="0 0 24 20" fill="none"><rect x="1" y="2" width="22" height="16" rx="3" strokeWidth="2"/><path d="M1 6h22" strokeWidth="2" strokeLinecap="round"/><path d="M9 6L11 2h4" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>) },
  ];

  return (
    <div style={{ padding: '0 14px calc(14px + var(--ios-safe-bottom))' }}>
      <div style={{
        // v2.5 液态玻璃浮动胶囊（iOS 26 风格，透出壁纸）
        background: 'rgba(255,255,255,0.48)',
        backdropFilter: 'blur(35px) saturate(200%)',
        WebkitBackdropFilter: 'blur(35px) saturate(200%)',
        borderRadius: 28,
        border: '0.5px solid rgba(255,255,255,0.75)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.85), inset 0 -1px 0 rgba(255,255,255,0.25), 0 8px 30px rgba(30,40,90,0.10)',
        padding: '10px 16px',
        display: 'flex', justifyContent: 'space-around', alignItems: 'center',
        animation: 'slideUpBar 0.3s cubic-bezier(0.32, 0.72, 0, 1)',
      }}>
        {buttons.map((btn, idx) => (
          <button key={btn.id}
            onClick={btn.enabled ? btn.onClick : undefined}
            disabled={!btn.enabled}
            style={{
              width: 74, height: 62, borderRadius: 20,
              background: 'transparent',
              border: 'none',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: btn.enabled ? 'pointer' : 'not-allowed',
              opacity: btn.enabled ? 1 : 0.35,
              transition: 'transform 0.15s cubic-bezier(0.32, 0.72, 0, 1), opacity 0.15s ease',
              color: btn.color, flexDirection: 'column', gap: 4,
              animation: `cardIn 0.3s cubic-bezier(0.32, 0.72, 0, 1) ${idx * 0.05}s both`,
            }}
            onMouseDown={(e) => {
              if (btn.enabled) e.currentTarget.style.transform = 'scale(0.86)';
            }}
            onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
          >
            {/* v2.5：每个按钮带独立玻璃圆片（透出壁纸） */}
            <div style={{
              width: 46, height: 46, borderRadius: 16,
              background: 'rgba(255,255,255,0.42)',
              backdropFilter: 'blur(16px) saturate(200%)',
              WebkitBackdropFilter: 'blur(16px) saturate(200%)',
              border: '0.5px solid rgba(255,255,255,0.85)',
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), inset 0 -1px 0 rgba(255,255,255,0.3), 0 2px 12px rgba(30,40,90,0.08)',
              color: btn.color,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              transition: 'transform 0.15s cubic-bezier(0.32, 0.72, 0, 1)',
            }}>
              {React.cloneElement(btn.icon, { stroke: btn.color, strokeWidth: 1.8 })}
            </div>
            <span style={{
              fontSize: 10.5, color: btn.color,
              fontFamily: '-apple-system, "SF Pro", system-ui',
              fontWeight: 500, letterSpacing: -0.2,
            }}>{btn.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

function AlbumChip({ album, onClick }) {
  return (
    <div onClick={onClick} style={{
      width: 72, cursor: 'pointer',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
      transition: 'transform 0.15s ease',
    }}
    onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(0.9)'; }}
    onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
    onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
    >
      <div style={{
        width: 64, height: 64, borderRadius: 14,
        background: album.gradient,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 24, boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        transition: 'box-shadow 0.15s ease',
      }}>{album.icon}</div>
      <span style={{
        fontSize: 11, color: 'rgba(60,60,67,0.8)',
        fontFamily: '-apple-system, "SF Pro", system-ui',
        textAlign: 'center', lineHeight: 1.2, maxWidth: 72,
        overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
      }}>{album.name}</span>
    </div>
  );
}

Object.assign(window, { SortBottomBar, AlbumChip });
