// v3.0 我的页：使用数据卡 + 整理偏好 + 播放开关 + 主题色 + 通用
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

const PANEL_STYLE = {
  background: 'var(--glass-solid)',
  borderRadius: 'var(--r-panel)',
  boxShadow: 'var(--edge-panel-soft)',
  margin: '0 16px',
  overflow: 'hidden',
};

function formatBytes(bytes) {
  if (!bytes || bytes <= 0) return '0 KB';
  const mb = bytes / (1024 * 1024);
  if (mb >= 1024) return (mb / 1024).toFixed(1) + ' GB';
  if (mb >= 1) return mb.toFixed(1) + ' MB';
  return Math.max(1, Math.round(bytes / 1024)) + ' KB';
}

function formatGB(bytes) {
  if (!bytes || bytes <= 0) return '0 GB';
  return Math.round(bytes / (1024 * 1024 * 1024)) + ' GB';
}

// iOS 液态玻璃开关：轨道上亮下暗，滑块带柔和阴影
function GlassSwitch({ value, onChange, disabled = false }) {
  return (
    <button
      aria-pressed={!!value}
      onClick={(e) => { e.stopPropagation(); if (!disabled && onChange) onChange(!value); }}
      style={{
        width: 51, height: 31, borderRadius: 15.5, border: 'none', padding: 0,
        cursor: disabled ? 'default' : 'pointer', flexShrink: 0, position: 'relative',
        opacity: disabled ? 0.5 : 1,
        background: value
          ? 'linear-gradient(180deg, rgba(62,206,102,0.98) 0%, rgba(38,164,72,0.9) 100%)'
          : 'linear-gradient(180deg, rgba(255,255,255,0.78) 0%, rgba(120,120,128,0.34) 100%)',
        boxShadow: value
          ? 'inset 0 1px 0 rgba(255,255,255,0.6), 0 2px 8px rgba(20,80,40,0.24)'
          : 'inset 0 1px 0 rgba(255,255,255,0.9), 0 2px 6px rgba(22,32,72,0.12)',
        transition: 'background 0.22s var(--ease-drawer)',
      }}>
      <div style={{
        position: 'absolute', top: 2, left: value ? 22 : 2,
        width: 27, height: 27, borderRadius: '50%',
        background: '#fff',
        boxShadow: '0 1px 4px rgba(0,0,0,0.26), 0 0 0 0.5px rgba(0,0,0,0.04)',
        transition: 'left 0.22s var(--ease-drawer)',
      }} />
    </button>
  );
}

function SectionLabel({ children }) {
  return (
    <div style={{
      fontSize: 13, color: 'rgba(60,60,67,0.6)',
      fontFamily: '-apple-system, "SF Pro", system-ui',
      padding: '0 32px 6px', letterSpacing: -0.08, fontWeight: 500,
    }}>{children}</div>
  );
}

function MineRow({ label, value, isLast = false, onPress, disabled = false }) {
  return (
    <div
      className={disabled ? undefined : 'ios-row'}
      onClick={disabled ? undefined : onPress}
      style={{
        display: 'flex', alignItems: 'center', minHeight: 46,
        padding: '0 16px', position: 'relative',
        fontFamily: '-apple-system, "SF Pro", system-ui',
        fontSize: 16, color: '#000', letterSpacing: -0.3,
        cursor: disabled ? 'default' : 'pointer',
      }}>
      <div style={{ flex: 1 }}>{label}</div>
      {value && (
        <span style={{ color: 'rgba(60,60,67,0.5)', fontSize: 15, marginRight: 6 }}>{value}</span>
      )}
      <ChevronRightIcon size={13} color="rgba(60,60,67,0.28)" weight={2.4} />
      {!isLast && (
        <div style={{
          position: 'absolute', bottom: 0, left: 16, right: 0,
          height: 0.5, background: 'rgba(60,60,67,0.12)',
        }} />
      )}
    </div>
  );
}

function MineSwitchRow({ label, value, onChange, isLast = false }) {
  return (
    <div
      className="ios-row"
      onClick={() => onChange && onChange(!value)}
      style={{
        display: 'flex', alignItems: 'center', minHeight: 52,
        padding: '0 16px', position: 'relative',
        fontFamily: '-apple-system, "SF Pro", system-ui',
        fontSize: 16, color: '#000', letterSpacing: -0.3,
        cursor: 'pointer',
      }}>
      <div style={{ flex: 1 }}>{label}</div>
      <GlassSwitch value={value} onChange={onChange} />
      {!isLast && (
        <div style={{
          position: 'absolute', bottom: 0, left: 16, right: 0,
          height: 0.5, background: 'rgba(60,60,67,0.12)',
        }} />
      )}
    </div>
  );
}

function MinePage({
  themeColor = '#002FA7', onThemeChange,
  autoPlayLive = true, autoPlayVideo = true,
  onAutoLiveChange, onAutoVideoChange,
  trashPhotos = [], storage = null,
  onClearCache,
  trashCount = 0, onTrashClick,
}) {
  const cleanedCount = trashPhotos.length;
  const cleanedBytes = trashPhotos.reduce((sum, photo) => sum + (photo.fileSize || 0), 0);
  const usedRatio = storage && storage.total > 0 ? storage.used / storage.total : 0;

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'transparent' }}>
      <TopBar trashCount={trashCount} onTrashClick={onTrashClick} />

      <div style={{ flex: 1, overflowY: 'auto', WebkitOverflowScrolling: 'touch', paddingBottom: 24 }}>
        <div style={{ padding: '0 20px 14px' }}>
          <div className="sf-title" style={{
            fontSize: 34, color: '#000', lineHeight: 1.05, letterSpacing: '-1.2px',
          }}>我的</div>
        </div>

        {/* 使用数据 */}
        <div style={{ ...PANEL_STYLE, marginBottom: 26, padding: '18px 18px 16px' }}>
          <div className="sf-body" style={{
            fontSize: 13, color: 'rgba(60,60,67,0.55)', fontWeight: 500,
          }}>累计已清理</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 2 }}>
            <div style={{
              fontSize: 52, fontWeight: 700, color: '#34C759', lineHeight: 1.05,
              fontFamily: '-apple-system, "SF Pro Display", system-ui', letterSpacing: -2,
            }}>{cleanedCount}</div>
            <div className="sf-body" style={{ fontSize: 16, color: 'rgba(60,60,67,0.6)' }}>
              · 释放 {formatBytes(cleanedBytes)}
            </div>
          </div>

          <div style={{
            display: 'flex', alignItems: 'center',
            marginTop: 18, paddingTop: 16,
            borderTop: '0.5px solid rgba(60,60,67,0.12)',
          }}>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <HeartIcon size={20} color="#FF3B30" />
              <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2 }}>0</div>
              <div className="sf-body" style={{ fontSize: 12, color: 'rgba(60,60,67,0.55)' }}>已收藏</div>
            </div>
            <div style={{ width: 0.5, height: 40, background: 'rgba(60,60,67,0.14)' }} />
            <div style={{ flex: 1, textAlign: 'center' }}>
              <TrashIcon size={20} color="#34C759" weight={1.8} />
              <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2 }}>{trashCount}</div>
              <div className="sf-body" style={{ fontSize: 12, color: 'rgba(60,60,67,0.55)' }}>待清理</div>
            </div>
            <div style={{ width: 0.5, height: 40, background: 'rgba(60,60,67,0.14)' }} />
            <div style={{ flex: 1, textAlign: 'center' }}>
              <EyeIcon size={20} color="rgba(60,60,67,0.65)" />
              <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2 }}>0</div>
              <div className="sf-body" style={{ fontSize: 12, color: 'rgba(60,60,67,0.55)' }}>本轮已看</div>
            </div>
          </div>

          <div style={{ marginTop: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div className="sf-body" style={{ fontSize: 15, color: '#000', fontWeight: 500 }}>手机存储</div>
              <div className="sf-body" style={{ fontSize: 15, color: 'rgba(60,60,67,0.6)' }}>
                {storage ? `剩余 ${formatGB(storage.free)} / ${formatGB(storage.total)}` : '读取中…'}
              </div>
            </div>
            <div style={{
              height: 8, borderRadius: 4, marginTop: 8,
              background: 'rgba(60,60,67,0.14)', overflow: 'hidden',
            }}>
              <div style={{
                height: '100%', width: `${Math.round(usedRatio * 100)}%`,
                background: '#34C759', borderRadius: 4,
              }} />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
              <span className="sf-body" style={{ fontSize: 12.5, color: 'rgba(60,60,67,0.45)' }}>
                {storage ? `已用 ${formatGB(storage.used)}（${Math.round(usedRatio * 100)}%）` : ''}
              </span>
              <span className="sf-body" style={{ fontSize: 12.5, color: 'rgba(60,60,67,0.45)' }}>
                {storage ? `可用 ${formatGB(storage.free)}` : ''}
              </span>
            </div>
          </div>
        </div>

        {/* 整理 */}
        <div style={{ paddingBottom: 22 }}>
          <SectionLabel>整理</SectionLabel>
          <div style={{ ...PANEL_STYLE, padding: '14px 16px 16px' }}>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <div style={{ flex: 1, fontSize: 16, letterSpacing: -0.3 }}>每轮数量</div>
              <div style={{ fontSize: 17, fontWeight: 600 }}>30</div>
            </div>
            <div style={{
              position: 'relative', height: 8, borderRadius: 4, marginTop: 16,
              background: 'rgba(60,60,67,0.14)',
            }}>
              <div style={{ position: 'absolute', left: 0, width: '10%', height: 8, borderRadius: 4, background: '#34C759' }} />
              <div style={{
                position: 'absolute', left: '10%', top: -10, marginLeft: -14,
                width: 28, height: 28, borderRadius: '50%', background: '#fff',
                boxShadow: '0 2px 8px rgba(22,32,72,0.22)',
              }} />
            </div>
            <div className="sf-body" style={{ fontSize: 12.5, color: 'rgba(60,60,67,0.45)', marginTop: 12 }}>
              单轮最高可整理 300 项
            </div>
          </div>
        </div>

        {/* 整理偏好 */}
        <div style={{ paddingBottom: 22 }}>
          <SectionLabel>整理偏好</SectionLabel>
          <div style={PANEL_STYLE}>
            <MineRow label="滑动方向" value="左滑跳过 / 上滑删除" disabled />
            <MineRow label="展示顺序" value="最新优先" disabled />
            <MineRow label="照片显示" value="显示全图" disabled />
            <MineRow label="语言" value="简体中文" isLast disabled />
          </div>
        </div>

        {/* 播放与显示 */}
        <div style={{ paddingBottom: 22 }}>
          <SectionLabel>播放与显示</SectionLabel>
          <div style={PANEL_STYLE}>
            <MineSwitchRow label="Live 图自动播放" value={autoPlayLive} onChange={onAutoLiveChange} />
            <MineSwitchRow label="视频自动播放" value={autoPlayVideo} onChange={onAutoVideoChange} />
            <MineRow label="HDR 显示" value="关闭" disabled />
            <MineRow label="视频声音" value="关闭" isLast disabled />
          </div>
        </div>

        {/* 外观 */}
        <div style={{ paddingBottom: 22 }}>
          <SectionLabel>外观</SectionLabel>
          <div style={{ ...PANEL_STYLE, padding: '18px 20px' }}>
            <div style={{
              display: 'flex', justifyContent: 'space-between',
              alignItems: 'center', flexWrap: 'wrap', gap: 12,
            }}>
              {THEME_COLORS.map((item) => {
                const selected = item.color === themeColor;
                return (
                  <button key={item.id} onClick={() => onThemeChange(item.color)} className="ios-btn" style={{
                    width: 40, height: 40, borderRadius: '50%',
                    background: item.color, border: 'none', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    position: 'relative',
                    boxShadow: selected
                      ? `0 0 0 2.5px #fff, 0 0 0 4.5px ${item.color}, 0 0 0 6px rgba(255,255,255,0.9)`
                      : 'inset 0 1px 0 rgba(255,255,255,0.4), 0 1px 3px rgba(0,0,0,0.15)',
                  }}>
                    {selected && (
                      <svg width="18" height="18" viewBox="0 0 20 20">
                        <path d="M5 10l3.5 3.5L15 7" stroke="#fff" strokeWidth="2.5" fill="none"
                          strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* 通用 */}
        <div style={{ paddingBottom: 20 }}>
          <SectionLabel>通用</SectionLabel>
          <div style={PANEL_STYLE}>
            <MineRow label="关于" value="Evernight 3.0" disabled />
            <MineRow label="操作指引" disabled />
            <MineRow label="清理缓存" value={formatBytes(cleanedBytes)} onPress={onClearCache} isLast />
          </div>
        </div>

        <div style={{ textAlign: 'center', padding: '4px 0 10px' }}>
          <div className="sf-body" style={{
            fontSize: 13, color: 'var(--accent)', fontWeight: 500,
          }}>用户协议 · 隐私政策</div>
          <div className="sf-body" style={{ fontSize: 12, color: 'rgba(60,60,67,0.4)', marginTop: 6 }}>
            Evernight 3.0 (11)
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { MinePage, GlassSwitch, SectionLabel, MineRow, MineSwitchRow, THEME_COLORS, formatBytes });
