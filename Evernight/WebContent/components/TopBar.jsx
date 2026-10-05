// v3.0 顶部栏：app 标题居左，右侧档案箱入口；整理页额外带月份胶囊
function TopBar({
  title = 'Evernight',
  monthLabel, months, currentMonthId, onMonthSelect,
  backLabel, centerTitle, onBack,
  trashCount = 0, onTrashClick,
}) {
  const [pickerOpen, setPickerOpen] = React.useState(false);
  const pickerRef = React.useRef(null);

  React.useEffect(() => {
    if (!pickerOpen) return undefined;
    const onDocPointer = (e) => {
      if (pickerRef.current && !pickerRef.current.contains(e.target)) setPickerOpen(false);
    };
    document.addEventListener('pointerdown', onDocPointer);
    return () => document.removeEventListener('pointerdown', onDocPointer);
  }, [pickerOpen]);

  const isDetail = !!backLabel;

  return (
    <div style={{
      position: 'relative', zIndex: 100,
      padding: 'calc(var(--ios-safe-top) + 10px) 20px 8px',
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        minHeight: 44, position: 'relative',
      }}>
        {isDetail ? (
          <React.Fragment>
            <button onClick={onBack} className="ios-btn" style={{
              display: 'flex', alignItems: 'center', gap: 3,
              background: 'none', border: 'none', padding: '6px 8px 6px 0',
              cursor: 'pointer', color: 'var(--accent)',
              fontFamily: '-apple-system, "SF Pro", system-ui',
              fontSize: 17, fontWeight: 400,
            }}>
              <ChevronLeftIcon size={18} color="var(--accent)" />
              <span>{backLabel}</span>
            </button>
            <div style={{
              position: 'absolute', left: '50%', top: '50%',
              transform: 'translate(-50%, -50%)',
              fontSize: 17, fontWeight: 600, color: '#000',
              fontFamily: '-apple-system, "SF Pro", system-ui', letterSpacing: -0.4,
              whiteSpace: 'nowrap',
            }}>{centerTitle}</div>
          </React.Fragment>
        ) : (
          <div style={{
            flex: 1, minWidth: 0,
            fontFamily: '-apple-system, "SF Pro", system-ui',
            fontSize: 32, fontWeight: 700, color: '#000',
            letterSpacing: -1.1, lineHeight: 1.1,
          }}>{title}</div>
        )}

        <div style={{ flex: isDetail ? 1 : '0 0 auto', display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 10 }}>
          {monthLabel && (
            <div ref={pickerRef} style={{ position: 'relative' }}>
              <button
                onClick={() => setPickerOpen((v) => !v)}
                className="ios-btn"
                style={{
                  height: 34, borderRadius: 17, padding: '0 12px',
                  display: 'flex', alignItems: 'center', gap: 5,
                  background: 'var(--glass-float-strong)',
                  backdropFilter: 'var(--blur-float)',
                  WebkitBackdropFilter: 'var(--blur-float)',
                  boxShadow: 'var(--edge-float)',
                  border: 'none', cursor: 'pointer',
                  color: '#000',
                  fontFamily: '-apple-system, "SF Pro", system-ui',
                  fontSize: 15, fontWeight: 500, letterSpacing: -0.2,
                  whiteSpace: 'nowrap',
                }}>
                <span>{monthLabel}</span>
                <ChevronDownIcon size={12} color="rgba(60,60,67,0.6)" />
              </button>

              {pickerOpen && (
                <div style={{
                  position: 'absolute', top: 42, right: 0,
                  width: 200, maxHeight: 330, overflowY: 'auto',
                  WebkitOverflowScrolling: 'touch',
                  borderRadius: 22, padding: 6,
                  background: 'var(--glass-float-strong)',
                  backdropFilter: 'var(--blur-panel)',
                  WebkitBackdropFilter: 'var(--blur-panel)',
                  boxShadow: 'var(--edge-panel)',
                  animation: 'fadeInScale 0.16s var(--ease-out)',
                  zIndex: 120,
                }}>
                  {(months || []).map((month) => {
                    const selected = month.id === currentMonthId;
                    return (
                      <div
                        key={month.id}
                        className="ios-row"
                        onClick={() => { setPickerOpen(false); if (onMonthSelect) onMonthSelect(month); }}
                        style={{
                          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                          height: 44, padding: '0 12px', borderRadius: 14,
                          cursor: 'pointer',
                          background: selected ? 'var(--accent-soft)' : 'transparent',
                          fontFamily: '-apple-system, "SF Pro", system-ui',
                          fontSize: 15, color: '#000',
                        }}>
                        <span>{month.title}</span>
                        <span style={{
                          fontSize: 12, color: 'rgba(60,60,67,0.45)',
                          marginRight: selected ? 6 : 0,
                        }}>{(month.photos || []).length}</span>
                        {selected && <CheckIcon size={16} color="var(--accent)" weight={2.4} />}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          <button onClick={onTrashClick} className="ios-btn" style={{
            width: 44, height: 44, borderRadius: '50%', flexShrink: 0,
            position: 'relative', border: 'none', cursor: 'pointer',
            background: 'var(--glass-float)',
            backdropFilter: 'var(--blur-float)',
            WebkitBackdropFilter: 'var(--blur-float)',
            boxShadow: 'var(--edge-float)',
            color: 'var(--accent)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <ArchiveIcon size={22} color="var(--accent)" weight={1.7} />
            {trashCount > 0 && (
              <span style={{
                position: 'absolute', top: -3, right: -3,
                minWidth: 18, height: 18, borderRadius: 9,
                background: '#FF3B30',
                border: '2px solid rgba(255,255,255,0.95)',
                color: '#fff', fontSize: 11, fontWeight: 600,
                fontFamily: '-apple-system, "SF Pro", system-ui',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                padding: '0 4px',
              }}>{trashCount > 99 ? '99+' : trashCount}</span>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

window.TopBar = TopBar;
