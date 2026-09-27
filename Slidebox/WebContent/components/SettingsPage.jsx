// v2.6 设置页：iOS inset grouped 分组列表 + 主题色 + 自动播放开关
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

const GROUP_GLASS = {
  background: 'rgba(255,255,255,0.6)',
  border: '0.5px solid rgba(255,255,255,0.75)',
  boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.85), inset 0 -1px 0 rgba(255,255,255,0.25), 0 4px 18px rgba(30,40,90,0.07)',
  borderRadius: 18,
  margin: '0 16px', overflow: 'hidden',
};

function SettingsPage({ themeColor, onThemeChange, onBack,
  autoPlayLive = true, autoPlayVideo = true,
  onAutoLiveChange, onAutoVideoChange }) {
  return (
    <div style={{ height: '100%', background: 'transparent', display: 'flex', flexDirection: 'column' }}>
      {/* v2.6 悬浮玻璃导航胶囊 */}
      <div style={{
        position: 'relative', zIndex: 100,
        padding: 'var(--ios-safe-top) 12px 6px',
      }}>
        <div style={{
          position: 'relative', height: 50,
          borderRadius: 25,
          background: 'rgba(255,255,255,0.58)',
          backdropFilter: 'blur(20px) saturate(180%)',
          WebkitBackdropFilter: 'blur(20px) saturate(180%)',
          border: '0.5px solid rgba(255,255,255,0.8)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), inset 0 -1px 0 rgba(255,255,255,0.3), 0 6px 24px rgba(30,40,90,0.09)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 8px',
          animation: 'slideDownBar 0.3s var(--ease-drawer)',
        }}>
          <button onClick={onBack} className="ios-btn" style={{
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

      <div style={{ flex: 1, overflowY: 'auto', WebkitOverflowScrolling: 'touch' }}>
        {/* 主题颜色 */}
        <div style={{ padding: '26px 0 8px', animation: 'glassIn 0.32s var(--ease-out)' }}>
          <GroupHeader title="主题颜色" />
          <div style={GROUP_GLASS}>
            <div style={{
              display: 'flex', justifyContent: 'space-between',
              alignItems: 'center', flexWrap: 'wrap', gap: 12,
              padding: '16px 20px',
            }}>
              {THEME_COLORS.map((t) => {
                const isSelected = t.color === themeColor;
                return (
                  <button key={t.id} onClick={() => onThemeChange(t.color)} className="ios-btn" style={{
                    width: 44, height: 44, borderRadius: '50%',
                    background: t.color, border: 'none', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    position: 'relative',
                    boxShadow: isSelected
                      ? `0 0 0 3px #fff, 0 0 0 5.5px ${t.color}, 0 0 0 7px rgba(255,255,255,0.9)`
                      : 'inset 0 1px 0 rgba(255,255,255,0.4), 0 1px 3px rgba(0,0,0,0.15)',
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

        {/* 通用 */}
        <div style={{ padding: '18px 0 8px', animation: 'glassIn 0.32s var(--ease-out) 0.05s both' }}>
          <GroupHeader title="通用" />
          <div style={GROUP_GLASS}>
            <SettingRow iconColor={themeColor} title="关于" detail="Album Cleaner 2.6" />
            <SettingRow iconColor={themeColor} title="操作指引" detail="" />
            <SettingRow iconColor={themeColor} title="清理缓存" detail="0 KB" isLast />
          </div>
        </div>

        {/* 整理偏好 */}
        <div style={{ padding: '18px 0 24px', animation: 'glassIn 0.32s var(--ease-out) 0.1s both' }}>
          <GroupHeader title="整理偏好" />
          <div style={GROUP_GLASS}>
            <SettingSwitchRow title="Live 图自动播放" value={autoPlayLive} onChange={onAutoLiveChange} />
            <SettingSwitchRow title="视频自动播放" value={autoPlayVideo} onChange={onAutoVideoChange} />
            <SettingRow iconColor={themeColor} title="整理顺序" detail="从新到旧" />
            <SettingRow iconColor={themeColor} title="显示视频时长" detail="开启" isLast />
          </div>
        </div>

        <div style={{ height: 'var(--ios-safe-bottom)' }} />
      </div>
    </div>
  );
}

function GroupHeader({ title }) {
  return (
    <div style={{
      fontSize: 13, color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      textTransform: 'uppercase', letterSpacing: -0.08, fontWeight: 500,
      padding: '0 32px 6px',
    }}>{title}</div>
  );
}

// iOS 原生开关行（UISwitch：绿开 / 灰关 + 白色滑块，0.22s drawer 曲线）
function SettingSwitchRow({ title, value, onChange }) {
  return (
    <div className="ios-row" style={{
      display: 'flex', alignItems: 'center', minHeight: 44,
      padding: '0 16px', position: 'relative',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 16, color: '#000', letterSpacing: -0.3,
      cursor: 'pointer',
    }}>
      <div style={{ flex: 1 }}>{title}</div>
      <button
        aria-pressed={!!value}
        onClick={(e) => { e.stopPropagation(); if (onChange) onChange(!value); }}
        style={{
          width: 51, height: 31, borderRadius: 16, border: 'none', cursor: 'pointer',
          background: value ? '#34C759' : 'rgba(120,120,128,0.32)',
          position: 'relative', flexShrink: 0,
          transition: 'background 0.22s var(--ease-drawer)',
          padding: 0,
        }}
      >
        <div style={{
          position: 'absolute', top: 2,
          left: value ? 22 : 2,
          width: 27, height: 27, borderRadius: '50%',
          background: '#fff',
          boxShadow: '0 1px 4px rgba(0,0,0,0.28)',
          transition: 'left 0.22s var(--ease-drawer)',
        }} />
      </button>
      <div style={{
        position: 'absolute', bottom: 0, right: 0, left: 16,
        height: 0.5, background: 'rgba(60,60,67,0.09)',
      }} />
    </div>
  );
}

function SettingRow({ iconColor, title, detail, isLast = false }) {
  return (
    <div className="ios-row" style={{
      display: 'flex', alignItems: 'center', minHeight: 44,
      padding: '0 16px', position: 'relative',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontSize: 16, color: '#000', letterSpacing: -0.3,
      cursor: 'pointer',
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
