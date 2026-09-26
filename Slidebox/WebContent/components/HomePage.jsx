// 首页 - 月份列表（v2.5 Liquid Glass：壁纸背景透出 + 大标题 + 悬浮玻璃工具按钮 + 主题色玻璃月份卡片）
function HomePage({ months, onMonthClick, onTrashClick, onSettingsClick, themeColor = '#007AFF', trashCount }) {
  const totalItems = months.reduce(function(acc, m) { return acc + (m.photos ? m.photos.length : 0); }, 0);
  return (
    <div style={{
      height: '100%',
      background: 'transparent',
      display: 'flex',
      flexDirection: 'column',
    }}>
      {/* iOS 26 大标题区（悬浮玻璃工具条） */}
      <div style={{
        paddingTop: 'var(--ios-safe-top)',
        paddingBottom: 10,
      }}>
        <div style={{
          padding: '6px 24px 2px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-end',
        }}>
          <div>
            <h1 style={{
              margin: 0,
              fontSize: 34,
              fontWeight: 700,
              fontFamily: '-apple-system, "SF Pro Display", "SF Pro", system-ui',
              letterSpacing: -1.2,
              color: '#000',
              lineHeight: 1.08,
            }}>Album Cleaner</h1>
            <div style={{
              marginTop: 5,
              fontSize: 13,
              color: 'rgba(60,60,67,0.55)',
              fontFamily: '-apple-system, "SF Pro", system-ui',
              letterSpacing: -0.2,
            }}>{months.length} 个月份 · {totalItems} 个媒体项目</div>
          </div>

          {/* 右侧悬浮玻璃工具按钮组 */}
          <div style={{ display: 'flex', gap: 10, marginBottom: 2 }}>
            <GlassIconButton onClick={onSettingsClick} color={themeColor} label="设置">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="3" stroke={themeColor} strokeWidth="2"/>
                <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 01-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"
                  stroke={themeColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </GlassIconButton>
            <GlassIconButton onClick={onTrashClick} color={themeColor} label="回收站" badge={trashCount}>
              <svg width="21" height="21" viewBox="0 0 24 24" fill="none">
                <path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z"
                  stroke={themeColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </GlassIconButton>
          </div>
        </div>
      </div>

      {/* 滚动内容区 */}
      <div style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', WebkitOverflowScrolling: 'touch' }}>
        <div style={{
          padding: '10px 28px 8px',
          fontSize: 13,
          color: 'rgba(60,60,67,0.6)',
          fontFamily: '-apple-system, "SF Pro", system-ui',
          textTransform: 'uppercase',
          letterSpacing: -0.08,
          fontWeight: 600,
        }}>
          月份
        </div>

        <div style={{ padding: '0 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
          {months.map((month, idx) => (
            <MonthCard
              key={month.id}
              month={month}
              index={idx}
              themeColor={themeColor}
              onClick={() => onMonthClick(month)}
            />
          ))}
        </div>

        <div style={{ height: 'var(--ios-safe-bottom)' }} />
      </div>
    </div>
  );
}

// 悬浮玻璃圆形工具按钮（iOS 26 Liquid Glass）
function GlassIconButton({ onClick, color, children, label, badge = 0 }) {
  return (
    <button
      onClick={onClick}
      aria-label={label}
      style={{
        position: 'relative',
        width: 46,
        height: 46,
        borderRadius: 23,
        border: '0.5px solid rgba(255,255,255,0.8)',
        background: 'rgba(255,255,255,0.45)',
        backdropFilter: 'blur(30px) saturate(200%)',
        WebkitBackdropFilter: 'blur(30px) saturate(200%)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), inset 0 -1px 0 rgba(255,255,255,0.35), 0 4px 18px rgba(30,40,90,0.10)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        transition: 'transform 0.16s cubic-bezier(0.32, 0.72, 0, 1), opacity 0.15s ease',
      }}
      onMouseDown={(e) => { e.currentTarget.style.transform = 'scale(0.86)'; }}
      onMouseUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
      onMouseLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
    >
      {children}
      {badge > 0 && (
        <div style={{
          position: 'absolute',
          top: -3,
          right: -3,
          minWidth: 18,
          height: 18,
          padding: '0 5px',
          borderRadius: 9,
          background: '#FF3B30',
          color: '#fff',
          fontSize: 11,
          fontWeight: 700,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          border: '1.5px solid #F2F2F7',
        }}>{badge > 99 ? '99+' : badge}</div>
      )}
    </button>
  );
}

// 月份卡片（v2.5 Liquid Glass：主题色玻璃图标 + 透出壁纸 + 按压动效）
function MonthCard({ month, onClick, index = 0, themeColor = '#007AFF' }) {
  const iconBg = `linear-gradient(145deg, ${themeColor} 0%, ${themeColor}CC 100%)`;
  return (
    <div
      onClick={onClick}
      style={{
        background: 'rgba(255,255,255,0.50)',
        backdropFilter: 'blur(25px) saturate(200%)',
        WebkitBackdropFilter: 'blur(25px) saturate(200%)',
        borderRadius: 24,
        cursor: 'pointer',
        border: '0.5px solid rgba(255,255,255,0.75)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), inset 0 -1px 0 rgba(255,255,255,0.3), 0 8px 24px rgba(30,40,90,0.08)',
        animation: `glassIn 0.45s cubic-bezier(0.32, 0.72, 0, 1) ${index * 0.05}s both`,
        transition: 'transform 0.2s cubic-bezier(0.32, 0.72, 0, 1), box-shadow 0.2s ease',
        display: 'flex',
        alignItems: 'center',
        padding: '14px 18px',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.boxShadow = 'inset 0 1px 0 rgba(255,255,255,0.9), 0 12px 30px rgba(30,40,90,0.12)';
      }}
      onMouseDown={(e) => {
        e.currentTarget.style.transform = 'scale(0.97)';
        e.currentTarget.style.boxShadow = 'inset 0 1px 0 rgba(255,255,255,0.9), 0 10px 26px rgba(30,40,90,0.12)';
      }}
      onMouseUp={(e) => {
        e.currentTarget.style.transform = 'scale(1)';
        e.currentTarget.style.boxShadow = 'inset 0 1px 0 rgba(255,255,255,0.9), 0 8px 24px rgba(30,40,90,0.08)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'scale(1)';
        e.currentTarget.style.boxShadow = 'inset 0 1px 0 rgba(255,255,255,0.9), 0 8px 24px rgba(30,40,90,0.08)';
      }}
    >
      {/* 月份色块（主题色玻璃渐变） */}
      <div style={{
        width: 50,
        height: 50,
        borderRadius: 16,
        background: iconBg,
        border: '0.5px solid rgba(255,255,255,0.6)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.4), 0 3px 10px rgba(30,40,90,0.15)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
      }}>
        <span style={{
          fontSize: 18,
          fontWeight: 700,
          color: '#fff',
          fontFamily: '-apple-system, "SF Pro", system-ui',
          letterSpacing: -0.3,
          textShadow: '0 1px 3px rgba(0,0,0,0.18)',
        }}>{month.shortTitle}</span>
      </div>

      <div style={{ flex: 1, marginLeft: 15, minWidth: 0 }}>
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
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        width: 26, height: 26, borderRadius: 13,
        background: 'rgba(120,120,128,0.10)',
        flexShrink: 0,
      }}>
        <svg width="8" height="14" viewBox="0 0 8 14">
          <path d="M1 1l6 6-6 6" stroke="rgba(60,60,67,0.45)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
    </div>
  );
}

Object.assign(window, { HomePage, MonthCard, GlassIconButton });
