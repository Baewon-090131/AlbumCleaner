// 首页 - 月份列表
function HomePage({ months, onMonthClick, onTrashClick, onSettingsClick, themeColor = '#007AFF', trashCount }) {
  return (
    <div style={{
      height: '100%',
      background: '#F2F2F7',
      display: 'flex',
      flexDirection: 'column',
    }}>
      {/* 顶部导航栏（v2.3 液态玻璃） */}
      <div style={{
        position: 'sticky',
        top: 0,
        zIndex: 100,
        paddingTop: 'var(--ios-safe-top)',
        background: 'rgba(250,250,252,0.72)',
        backdropFilter: 'blur(30px) saturate(200%)',
        WebkitBackdropFilter: 'blur(30px) saturate(200%)',
        borderBottom: '0.5px solid rgba(60,60,67,0.08)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.7)',
      }}>
        <div style={{
          position: 'relative',
          padding: '4px 20px 12px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-end',
        }}>
          <button
            onClick={onSettingsClick}
            style={{
              background: 'none',
              border: 'none',
              padding: 4,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: 3,
              transition: 'transform 0.15s ease',
            }}
            onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(0.85)'; }}
            onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="3" stroke={themeColor} strokeWidth="2"/>
              <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 01-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"
                stroke={themeColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>

          <h1 style={{
            margin: 0,
            fontSize: 28,
            fontWeight: 700,
            fontFamily: '-apple-system, "SF Pro Display", "SF Pro", system-ui',
            letterSpacing: -0.9,
            color: '#000',
            lineHeight: 1.1,
          }}>Album Cleaner</h1>

          <button
            onClick={onTrashClick}
            style={{
              background: 'none',
              border: 'none',
              padding: 4,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: 3,
              transition: 'transform 0.15s ease',
              position: 'relative',
            }}
            onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(0.85)'; }}
            onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
          >
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z"
                stroke={themeColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            {trashCount > 0 && (
              <div style={{
                position: 'absolute',
                top: -2,
                right: -4,
                background: '#FF3B30',
                color: '#fff',
                fontSize: 10,
                fontWeight: 600,
                minWidth: 16,
                height: 16,
                borderRadius: 8,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '0 4px',
              }}>{trashCount > 99 ? '99+' : trashCount}</div>
            )}
          </button>
        </div>
      </div>

      {/* 滚动内容区 */}
      <div style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', WebkitOverflowScrolling: 'touch' }}>
        <div style={{
          padding: '16px 20px 8px',
          fontSize: 13,
          color: 'rgba(60,60,67,0.6)',
          fontFamily: '-apple-system, "SF Pro", system-ui',
          textTransform: 'uppercase',
          letterSpacing: -0.08,
          fontWeight: 500,
        }}>
          月份
        </div>

        <div style={{ padding: '0 16px 24px', display: 'flex', flexDirection: 'column', gap: 16 }}>
          {months.map((month, idx) => (
            <MonthCard
              key={month.id}
              month={month}
              index={idx}
              onClick={() => onMonthClick(month)}
            />
          ))}
        </div>

        <div style={{ height: 'var(--ios-safe-bottom)' }} />
      </div>
    </div>
  );
}

// 月份卡片（v2.3：液态玻璃质感）
function MonthCard({ month, onClick, index = 0 }) {
  return (
    <div
      onClick={onClick}
      style={{
        background: 'rgba(255,255,255,0.62)',
        backdropFilter: 'blur(20px) saturate(180%)',
        WebkitBackdropFilter: 'blur(20px) saturate(180%)',
        borderRadius: 18,
        cursor: 'pointer',
        border: '0.5px solid rgba(255,255,255,0.7)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)',
        animation: `cardIn 0.4s cubic-bezier(0.32, 0.72, 0, 1) ${index * 0.05}s both`,
        transition: 'transform 0.2s ease, box-shadow 0.2s ease',
        display: 'flex',
        alignItems: 'center',
        padding: '14px 16px',
      }}
      onMouseDown={(e) => {
        e.currentTarget.style.transform = 'scale(0.98)';
        e.currentTarget.style.boxShadow = 'inset 0 1px 0 rgba(255,255,255,0.8), 0 8px 20px rgba(0,0,0,0.09)';
      }}
      onMouseUp={(e) => {
        e.currentTarget.style.transform = 'scale(1)';
        e.currentTarget.style.boxShadow = 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'scale(1)';
        e.currentTarget.style.boxShadow = 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)';
      }}
    >
      {/* 月份色块（玻璃化） */}
      <div style={{
        width: 48,
        height: 48,
        borderRadius: 12,
        background: 'linear-gradient(135deg, rgba(242,242,247,0.9) 0%, rgba(229,229,234,0.8) 100%)',
        border: '0.5px solid rgba(255,255,255,0.7)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
      }}>
        <span style={{
          fontSize: 18,
          fontWeight: 600,
          color: 'rgba(60,60,67,0.7)',
          fontFamily: '-apple-system, "SF Pro", system-ui',
        }}>{month.shortTitle}</span>
      </div>

      <div style={{ flex: 1, marginLeft: 14, minWidth: 0 }}>
        <div style={{
          fontSize: 17,
          fontWeight: 600,
          color: '#000',
          fontFamily: '-apple-system, "SF Pro", system-ui',
          letterSpacing: -0.4,
        }}>{month.title}</div>
        <div style={{
          fontSize: 13,
          color: 'rgba(60,60,67,0.6)',
          fontFamily: '-apple-system, "SF Pro", system-ui',
          marginTop: 2,
        }}>{month.photos.length} 个项目</div>
      </div>
      <svg width="8" height="14" viewBox="0 0 8 14" style={{ flexShrink: 0 }}>
        <path d="M1 1l6 6-6 6" stroke="rgba(60,60,67,0.3)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </div>
  );
}

Object.assign(window, { HomePage, MonthCard });
