// v2.6 回收站：网格 + iOS 弹窗/操作表
function TrashPage({ trashPhotos, onBack, onRestore, onDelete, onDeleteAll, themeColor = '#007AFF' }) {
  const [showAlert, setShowAlert] = React.useState(false);
  const [selectedPhoto, setSelectedPhoto] = React.useState(null);
  const [showActionSheet, setShowActionSheet] = React.useState(false);

  const handlePhotoClick = (photo) => { setSelectedPhoto(photo); setShowActionSheet(true); };
  const handleRestore = () => { if (selectedPhoto) onRestore(selectedPhoto.id); setShowActionSheet(false); setSelectedPhoto(null); };
  const handleDeleteOne = () => { if (selectedPhoto) onDelete(selectedPhoto.id); setShowActionSheet(false); setSelectedPhoto(null); };

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
          background: 'rgba(255,255,255,0.50)',
          backdropFilter: 'blur(35px) saturate(200%)',
          WebkitBackdropFilter: 'blur(35px) saturate(200%)',
          border: '0.5px solid rgba(255,255,255,0.8)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), inset 0 -1px 0 rgba(255,255,255,0.3), 0 6px 24px rgba(30,40,90,0.09)',
          display: 'flex', alignItems: 'center',
          justifyContent: 'space-between', padding: '0 8px',
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
          }}>回收站</div>
          <div style={{ width: 60 }} />
        </div>
      </div>

      {/* 状态提示 */}
      <div style={{
        padding: '14px 24px', fontSize: 13,
        color: 'rgba(60,60,67,0.65)',
        fontFamily: '-apple-system, "SF Pro", system-ui', textAlign: 'center',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <span style={{
          background: 'rgba(255,255,255,0.42)',
          backdropFilter: 'blur(20px) saturate(200%)',
          WebkitBackdropFilter: 'blur(20px) saturate(200%)',
          border: '0.5px solid rgba(255,255,255,0.7)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.85)',
          borderRadius: 14, padding: '7px 16px',
          animation: 'glassIn 0.3s var(--ease-out)',
        }}>
          {trashPhotos.length > 0 ? `共 ${trashPhotos.length} 张照片将在 30 天后自动删除` : '回收站为空'}
        </span>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '0 10px', WebkitOverflowScrolling: 'touch' }}>
        {trashPhotos.length > 0 ? (
          <div style={{
            borderRadius: 20,
            background: 'rgba(255,255,255,0.42)',
            backdropFilter: 'blur(20px) saturate(200%)',
            WebkitBackdropFilter: 'blur(20px) saturate(200%)',
            border: '0.5px solid rgba(255,255,255,0.7)',
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.85), 0 4px 16px rgba(30,40,90,0.06)',
            padding: 4,
            overflow: 'hidden',
          }}>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 2 }}>
            {trashPhotos.map((photo, idx) => (
              <div key={photo.id} onClick={() => handlePhotoClick(photo)} className="ios-btn" style={{
                aspectRatio: '1',
                background: photo.thumbnailUrl && photo.thumbnailUrl.startsWith('photo://') ? '#1c1c1e' : photo.gradient,
                position: 'relative', cursor: 'pointer',
                overflow: 'hidden',
                animation: `cardIn 0.3s var(--ease-out) ${idx * 0.02}s both`,
              }}>
                {photo.thumbnailUrl && photo.thumbnailUrl.startsWith('photo://') && (
                  <img src={photo.thumbnailUrl} alt="" style={{
                    width: '100%', height: '100%', objectFit: 'cover', display: 'block',
                  }} draggable={false} />
                )}
                {photo.isVideo && (
                  <div style={{
                    position: 'absolute', bottom: 4, right: 4,
                    display: 'flex', alignItems: 'center', gap: 2,
                    background: 'rgba(0,0,0,0.4)', padding: '1px 4px', borderRadius: 3,
                  }}>
                    <svg width="6" height="7" viewBox="0 0 6 7"><polygon points="0,0 6,3.5 0,7" fill="#fff"/></svg>
                    <span style={{ color: '#fff', fontSize: 9, fontWeight: 500, fontFamily: '-apple-system, "SF Pro", system-ui' }}>{photo.duration}</span>
                  </div>
                )}
              </div>
            ))}
            </div>
          </div>
        ) : (
          <div style={{
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
            padding: '70px 20px', gap: 14,
            animation: 'fadeIn 0.4s ease',
          }}>
            <div style={{
              width: 88, height: 88, borderRadius: '50%',
              background: 'rgba(255,255,255,0.45)',
              backdropFilter: 'blur(25px) saturate(200%)',
              WebkitBackdropFilter: 'blur(25px) saturate(200%)',
              border: '0.5px solid rgba(255,255,255,0.8)',
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), 0 10px 30px rgba(30,40,90,0.12)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="36" height="36" viewBox="0 0 24 24" fill="none">
                <path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z"
                  stroke="rgba(60,60,67,0.35)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
            <div style={{ fontSize: 16, color: 'rgba(60,60,67,0.6)', fontFamily: '-apple-system, "SF Pro", system-ui', fontWeight: 500 }}>回收站没有照片</div>
            <div style={{ fontSize: 13, color: 'rgba(60,60,67,0.4)', fontFamily: '-apple-system, "SF Pro", system-ui' }}>删除的照片会先暂存在这里</div>
          </div>
        )}
        <div style={{ height: 80 }} />
      </div>

      {/* 浮动玻璃胶囊 + 红色删除按钮 */}
      <div style={{ padding: '0 12px calc(12px + var(--ios-safe-bottom))' }}>
        <div style={{
          borderRadius: 26,
          background: 'rgba(255,255,255,0.48)',
          backdropFilter: 'blur(35px) saturate(200%)',
          WebkitBackdropFilter: 'blur(35px) saturate(200%)',
          border: '0.5px solid rgba(255,255,255,0.8)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.9), inset 0 -1px 0 rgba(255,255,255,0.3), 0 6px 24px rgba(30,40,90,0.09)',
          padding: '8px',
          animation: 'slideUpBar 0.3s var(--ease-drawer)',
        }}>
          <button onClick={() => trashPhotos.length > 0 && setShowAlert(true)} disabled={trashPhotos.length === 0} className="ios-btn" style={{
            width: '100%', padding: '14px 20px',
            background: trashPhotos.length === 0 ? 'rgba(255,59,48,0.25)' : 'linear-gradient(135deg, #FF453A 0%, #FF3B30 100%)',
            color: '#fff', border: 'none', borderRadius: 20,
            fontSize: 17, fontWeight: 600,
            fontFamily: '-apple-system, "SF Pro", system-ui',
            cursor: trashPhotos.length === 0 ? 'not-allowed' : 'pointer', letterSpacing: -0.4,
            boxShadow: trashPhotos.length === 0 ? 'none' : '0 4px 14px rgba(255,59,48,0.35)',
          }}>删除全部</button>
        </div>
      </div>

      {showAlert && (
        <IOSAlert
          title="删除照片？"
          message={`将从回收站中永久删除 ${trashPhotos.length} 张照片，此操作不可撤销。`}
          actions={[
            { label: '取消', style: 'cancel', onClick: () => setShowAlert(false) },
            { label: '删除', style: 'destructive', onClick: () => { onDeleteAll(); setShowAlert(false); } },
          ]}
        />
      )}

      {showActionSheet && selectedPhoto && (
        <IOSActionSheet
          title={`#${selectedPhoto.id}`}
          message="选择操作"
          actions={[
            { label: '恢复', style: 'default', onClick: handleRestore },
            { label: '彻底删除', style: 'destructive', onClick: handleDeleteOne },
          ]}
          onCancel={() => { setShowActionSheet(false); setSelectedPhoto(null); }}
        />
      )}
    </div>
  );
}

// iOS 风格 Alert（居中缩放弹窗）
function IOSAlert({ title, message, actions }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 1000, padding: '0 40px', animation: 'fadeIn 0.2s ease',
    }}>
      <div style={{
        background: 'rgba(242,242,247,0.95)',
        backdropFilter: 'blur(30px) saturate(180%)',
        WebkitBackdropFilter: 'blur(30px) saturate(180%)',
        borderRadius: 14, width: '100%', maxWidth: 270, overflow: 'hidden',
        animation: 'alertScaleIn 0.28s var(--ease-drawer)',
      }}>
        <div style={{
          padding: '20px 16px 14px', textAlign: 'center',
          borderBottom: '0.5px solid rgba(60,60,67,0.15)',
        }}>
          {title && <div style={{ fontSize: 17, fontWeight: 600, color: '#000', fontFamily: '-apple-system, "SF Pro", system-ui', letterSpacing: -0.4, marginBottom: message ? 6 : 0 }}>{title}</div>}
          {message && <div style={{ fontSize: 13, color: 'rgba(60,60,67,0.8)', fontFamily: '-apple-system, "SF Pro", system-ui', lineHeight: 1.4 }}>{message}</div>}
        </div>
        <div style={{ display: 'flex', flexDirection: actions.length === 2 ? 'row' : 'column' }}>
          {actions.map((action, i) => (
            <button key={i} onClick={action.onClick} className="ios-btn" style={{
              flex: 1, padding: '12px 16px', background: 'transparent', border: 'none',
              borderRight: actions.length === 2 && i === 0 ? '0.5px solid rgba(60,60,67,0.15)' : 'none',
              borderTop: i > 0 && actions.length !== 2 ? '0.5px solid rgba(60,60,67,0.15)' : 'none',
              color: action.style === 'destructive' ? '#FF3B30' : '#007AFF',
              fontSize: 17, fontFamily: '-apple-system, "SF Pro", system-ui',
              fontWeight: action.style === 'cancel' ? 600 : 400, cursor: 'pointer', letterSpacing: -0.4,
            }}>{action.label}</button>
          ))}
        </div>
      </div>
    </div>
  );
}

// iOS 风格 Action Sheet（底部滑入）
function IOSActionSheet({ title, message, actions, onCancel }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)',
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
      zIndex: 1000, animation: 'fadeIn 0.2s ease',
    }} onClick={onCancel}>
      <div onClick={(e) => e.stopPropagation()} style={{
        padding: '8px 10px calc(8px + var(--ios-safe-bottom))',
        animation: 'sheetSlideUp 0.32s var(--ease-drawer)',
      }}>
        <div style={{
          background: 'rgba(242,242,247,0.95)',
          backdropFilter: 'blur(30px) saturate(180%)',
          WebkitBackdropFilter: 'blur(30px) saturate(180%)',
          borderRadius: 14, overflow: 'hidden', marginBottom: 8,
        }}>
          {title && (
            <div style={{
              padding: '14px 16px 10px', textAlign: 'center',
              borderBottom: '0.5px solid rgba(60,60,67,0.12)',
            }}>
              <div style={{ fontSize: 13, color: 'rgba(60,60,67,0.6)', fontFamily: '-apple-system, "SF Pro", system-ui' }}>{title}</div>
              {message && <div style={{ fontSize: 13, color: 'rgba(60,60,67,0.6)', fontFamily: '-apple-system, "SF Pro", system-ui', marginTop: 2 }}>{message}</div>}
            </div>
          )}
          {actions.map((action, i) => (
            <button key={i} onClick={action.onClick} className="ios-btn" style={{
              width: '100%', padding: '16px 20px', background: 'transparent', border: 'none',
              borderTop: i > 0 || title ? '0.5px solid rgba(60,60,67,0.12)' : 'none',
              color: action.style === 'destructive' ? '#FF3B30' : '#007AFF',
              fontSize: 17, fontFamily: '-apple-system, "SF Pro", system-ui',
              fontWeight: 400, cursor: 'pointer', letterSpacing: -0.4, textAlign: 'center',
            }}>{action.label}</button>
          ))}
        </div>
        <button onClick={onCancel} className="ios-btn" style={{
          width: '100%', padding: '16px 20px',
          background: 'rgba(255,255,255,0.95)',
          backdropFilter: 'blur(30px) saturate(180%)',
          WebkitBackdropFilter: 'blur(30px) saturate(180%)',
          border: 'none', borderRadius: 14, color: '#007AFF',
          fontSize: 17, fontFamily: '-apple-system, "SF Pro", system-ui',
          fontWeight: 600, cursor: 'pointer', letterSpacing: -0.4,
        }}>取消</button>
      </div>
    </div>
  );
}

Object.assign(window, { TrashPage, IOSAlert, IOSActionSheet });
