// v3.0 底部 tab 栏：三个 tab（整理 / 相簿 / 我的），选中的项用强调色淡底胶囊
function BottomTabBar({ active = 'sort', onChange }) {
  const items = [
    { id: 'sort', label: '整理', Icon: SortIcon },
    { id: 'albums', label: '相簿', Icon: AlbumIcon },
    { id: 'mine', label: '我的', Icon: PersonIcon },
  ];

  return (
    <div style={{
      position: 'relative', zIndex: 100,
      padding: '0 14px calc(12px + var(--ios-safe-bottom))',
    }}>
      <div style={{
        height: 72, borderRadius: 36,
        background: 'var(--glass-float)',
        backdropFilter: 'var(--blur-float)',
        WebkitBackdropFilter: 'var(--blur-float)',
        boxShadow: 'var(--edge-float)',
        display: 'flex', alignItems: 'center',
        padding: '0 8px',
      }}>
        {items.map(({ id, label, Icon }) => {
          const isActive = id === active;
          const color = isActive ? 'var(--accent)' : 'rgba(60,60,67,0.6)';
          return (
            <button
              key={id}
              onClick={() => { if (!isActive && onChange) onChange(id); }}
              className="ios-btn"
              style={{
                flex: 1, height: 56, borderRadius: 28, border: 'none',
                cursor: 'pointer',
                background: isActive ? 'var(--accent-soft)' : 'transparent',
                display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center', gap: 3,
                color,
                transition: 'background-color 0.22s var(--ease-drawer)',
              }}>
              <Icon size={22} color={isActive ? 'var(--accent)' : color} weight={isActive ? 2 : 1.7} />
              <span style={{
                fontSize: 10.5, fontWeight: isActive ? 600 : 500,
                fontFamily: '-apple-system, "SF Pro", system-ui',
                letterSpacing: -0.2,
              }}>{label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

window.BottomTabBar = BottomTabBar;
