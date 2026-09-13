const THEME_COLORS = [
  { id: 'blue', name: '蓝色', color: '#007AFF' },
  { id: 'purple', name: '紫色', color: '#AF52DE' },
  { id: 'green', name: '绿色', color: '#34C759' },
  { id: 'orange', name: '橙色', color: '#FF9500' },
  { id: 'red', name: '红色', color: '#FF3B30' },
  { id: 'pink', name: '粉色', color: '#FF2D92' },
  { id: 'beiyang', name: '北洋蓝', color: '#002FA7' },
  { id: 'indigo', name: '靛蓝', color: '#5856D6' },
  { id: 'cyan', name: '青色', color: '#32ADE6' },
  { id: 'teal', name: '湖绿', color: '#30B0C7' },
  { id: 'gold', name: '金色', color: '#FFCC00' },
  { id: 'graphite', name: '石墨', color: '#636366' },
];

function SettingsPage({ themeColor, onThemeChange, onBack }) {
  return (
    <div style={{ height: '100%', background: '#F2F2F7', display: 'flex', flexDirection: 'column' }}>
      <div style={{
        position: 'relative', zIndex: 100,
        paddingTop: 'var(--ios-safe-top)',
        // v2.3 液态玻璃
        background: 'rgba(250,250,252,0.72)',
        backdropFilter: 'blur(30px) saturate(200%)',
        WebkitBackdropFilter: 'blur(30px) saturate(200%)',
        borderBottom: '0.5px solid rgba(60,60,67,0.08)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.7)',
      }}>
        <div style={{
          position: 'relative', height: 44,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 8px',
        }}>
          <button onClick={onBack} style={{
            display: 'flex', alignItems: 'center', gap: 4,
            background: 'none', border: 'none', padding: '6px 10px', cursor: 'pointer',
            color: themeColor, fontSize: 17,
            fontFamily: '-apple-system, "SF Pro", system-ui', fontWeight: 400,
          }}>
            <svg width="12" height="20" viewBox="0 0 12 20">
              <path d="M10 2L2 10l8 8" stroke={themeColor} strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <span>照片</span>
          </button>
          <div style={{
            position: 'absolute', left: '50%', top: '50%',
            transform: 'translate(-50%, -50%)',
            fontSize: 17, fontWeight: 600, color: '#000',
            fontFamily: '-apple-system, "SF Pro", system-ui', letterSpacing: -0.4,
          }}>设置</div>
          <div style={{ width: 60 }} />
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto' }}>
        <div style={{ padding: '28px 0 10px' }}>
          <div style={{
            fontSize: 13, color: 'rgba(60,60,67,0.6)',
            fontFamily: '-apple-system, "SF Pro", system-ui',
            textTransform: 'uppercase', letterSpacing: -0.08, fontWeight: 500,
            padding: '0 32px 6px',
          }}>主题颜色</div>
          <div style={{
            background: 'rgba(255,255,255,0.62)',
            backdropFilter: 'blur(20px) saturate(180%)',
            WebkitBackdropFilter: 'blur(20px) saturate(180%)',
            border: '0.5px solid rgba(255,255,255,0.7)',
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)',
            borderRadius: 18,
            margin: '0 16px', padding: '16px 20px',
          }}>
            <div style={{
              display: 'flex', justifyContent: 'space-between',
              alignItems: 'center', flexWrap: 'wrap', gap: 12,
            }}>
              {THEME_COLORS.map((t) => {
                const isSelected = t.color === themeColor;
                return (
                  <button key={t.id} onClick={() => onThemeChange(t.color)} style={{
                    width: 44, height: 44, borderRadius: '50%',
                    background: t.color, border: 'none', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    position: 'relative',
                    boxShadow: isSelected ? `0 0 0 3px #fff, 0 0 0 5px ${t.color}` : '0 1px 3px rgba(0,0,0,0.15)',
                    transition: 'all 0.2s ease',
                  }}>
                    {isSelected && (
                      <svg width="20" height="20" viewBox="0 0 20 20">
                        <path d="M5 10l3.5 3.5L15 7" stroke="#fff" strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        <div style={{ padding: '20px 0 10px' }}>
          <div style={{
            fontSize: 13, color: 'rgba(60,60,67,0.6)',
            fontFamily: '-apple-system, "SF Pro", system-ui',
            textTransform: 'uppercase', letterSpacing: -0.08, fontWeight: 500,
            padding: '0 32px 6px',
          }}>通用</div>
          <div style={{
            background: 'rgba(255,255,255,0.62)',
            backdropFilter: 'blur(20px) saturate(180%)',
            WebkitBackdropFilter: 'blur(20px) saturate(180%)',
            border: '0.5px solid rgba(255,255,255,0.7)',
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)',
            borderRadius: 18,
            margin: '0 16px', overflow: 'hidden',
          }}>
            <SettingRow iconColor={themeColor} title="关于" detail="Album Cleaner 2.3" />
            <SettingRow iconColor={themeColor} title="操作指引" detail="" />
            <SettingRow iconColor={themeColor} title="清理缓存" detail="0 KB" isLast />
          </div>
        </div>

        <div style={{ padding: '20px 0 24px' }}>
          <div style={{
            fontSize: 13, color: 'rgba(60,60,67,0.6)',
            fontFamily: '-apple-system, "SF Pro", system-ui',
            textTransform: 'uppercase', letterSpacing: -0.08, fontWeight: 500,
            padding: '0 32px 6px',
          }}>整理偏好</div>
          <div style={{
            background: 'rgba(255,255,255,0.62)',
            backdropFilter: 'blur(20px) saturate(180%)',
            WebkitBackdropFilter: 'blur(20px) saturate(180%)',
            border: '0.5px solid rgba(255,255,255,0.7)',
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.8), 0 4px 16px rgba(0,0,0,0.05)',
            borderRadius: 18,
            margin: '0 16px', overflow: 'hidden',
          }}>
            <SettingRow iconColor={themeColor} title="整理顺序" detail="从新到旧" />
            <SettingRow iconColor={themeColor} title="显示视频时长" detail="开启" isLast />
          </div>
        </div>

        <div style={{ height: 'var(--ios-safe-bottom)' }} />
      </div>
    </div>
  );
}

function SettingRow({ iconColor, title, detail, isLast = false }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', minHeight: 44,
      padding: '0 16px', position: 'relative',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 16, color: '#000', letterSpacing: -0.3,
    }}>
      <div style={{ flex: 1 }}>{title}</div>
      {detail && <span style={{ color: 'rgba(60,60,67,0.5)', fontSize: 15, marginRight: 6 }}>{detail}</span>}
      <svg width="7" height="12" viewBox="0 0 7 12">
        <path d="M1 1l5 5-5 5" stroke="rgba(60,60,67,0.3)" strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
      {!isLast && (
        <div style={{
          position: 'absolute', bottom: 0, right: 0, left: 16,
          height: 0.5, background: 'rgba(60,60,67,0.09)',
        }} />
      )}
    </div>
  );
}

window.SettingsPage = SettingsPage;
