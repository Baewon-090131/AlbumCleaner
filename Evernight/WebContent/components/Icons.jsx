// v3.0 图标集：按 SF Symbols 的线条规格绘制（24×24 网格、圆头圆角、统一描边）
function IconBase({ size = 22, color = '#000000', weight = 1.8, viewBox = '0 0 24 24', children }) {
  return (
    <svg width={size} height={size} viewBox={viewBox} fill="none"
      stroke={color} strokeWidth={weight} strokeLinecap="round" strokeLinejoin="round">
      {children}
    </svg>
  );
}

function ArchiveIcon(props) {
  return (
    <IconBase {...props}>
      <rect x="3" y="4" width="18" height="5.5" rx="1.5" />
      <path d="M5 9.5V19a2 2 0 002 2h10a2 2 0 002-2V9.5" />
      <path d="M10 14h4" />
    </IconBase>
  );
}

function UndoIcon(props) {
  return (
    <IconBase {...props}>
      <path d="M9 14L4 9l5-5" />
      <path d="M4 9h11a6 6 0 010 12h-3" />
    </IconBase>
  );
}

function TrashIcon(props) {
  return (
    <IconBase {...props}>
      <path d="M3 6h18" />
      <path d="M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2" />
      <path d="M6 6v13a2 2 0 002 2h8a2 2 0 002-2V6" />
    </IconBase>
  );
}

function NextIcon(props) {
  return (
    <IconBase {...props}>
      <path d="M5 4v16" />
      <path d="M10 20l9-8-9-8" />
    </IconBase>
  );
}

function AlbumIcon(props) {
  return (
    <IconBase {...props}>
      <rect x="1.5" y="2" width="21" height="16" rx="3" />
      <path d="M1.5 6.4h21" />
      <path d="M9 6.4L11 2h4" />
    </IconBase>
  );
}

function SortIcon(props) {
  return (
    <IconBase {...props}>
      <rect x="4" y="2.5" width="16" height="11.5" rx="2.5" />
      <path d="M6.5 17.5h11" />
      <path d="M9 20.5h6" />
    </IconBase>
  );
}

function PersonIcon(props) {
  return (
    <IconBase {...props}>
      <circle cx="12" cy="8" r="3.9" />
      <path d="M4.6 20.4a7.4 7.4 0 0114.8 0" />
    </IconBase>
  );
}

function HeartIcon({ size = 22, color = '#FF3B30' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24">
      <path
        d="M12 20.6C4.4 15.6 2.6 12.4 2.6 9.6 2.6 6.3 5.2 3.8 8.4 3.8c1.8 0 3 .9 3.6 2.2.6-1.3 1.8-2.2 3.6-2.2 3.2 0 5.8 2.5 5.8 5.8 0 2.8-1.8 6-9.4 11z"
        fill={color}
      />
    </svg>
  );
}

function EyeIcon({ size = 22, color = '#3C3C43', weight = 1.8 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke={color} strokeWidth={weight} strokeLinecap="round" strokeLinejoin="round">
      <path d="M2.4 12C6 6.6 18 6.6 21.6 12 18 17.4 6 17.4 2.4 12z" />
      <circle cx="12" cy="12" r="3.3" fill={color} stroke="none" />
    </svg>
  );
}

function ChevronDownIcon({ size = 14, color = '#3C3C43', weight = 2.2 }) {
  return (
    <IconBase size={size} color={color} weight={weight}>
      <path d="M6 9.5l6 5.5 6-5.5" />
    </IconBase>
  );
}

function ChevronLeftIcon({ size = 18, color = '#002FA7', weight = 2.4 }) {
  return (
    <IconBase size={size} color={color} weight={weight}>
      <path d="M15.5 4L7 12l8.5 8" />
    </IconBase>
  );
}

function ChevronRightIcon({ size = 14, color = '#B4B4B9', weight = 2.6 }) {
  return (
    <IconBase size={size} color={color} weight={weight}>
      <path d="M9.5 5l7 7-7 7" />
    </IconBase>
  );
}

function CheckIcon({ size = 22, color = '#34C759', weight = 2.2 }) {
  return (
    <IconBase size={size} color={color} weight={weight}>
      <path d="M20 6L9 17l-5-5" />
    </IconBase>
  );
}

Object.assign(window, {
  IconBase, ArchiveIcon, UndoIcon, TrashIcon, NextIcon, AlbumIcon, SortIcon,
  PersonIcon, HeartIcon, EyeIcon, ChevronDownIcon, ChevronLeftIcon,
  ChevronRightIcon, CheckIcon,
});
