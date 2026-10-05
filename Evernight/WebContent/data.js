// 数据管理：优先从原生照片库获取，不可用时使用模拟数据

const GRADIENTS = [
  'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
  'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
  'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
  'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
  'linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)',
  'linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)',
  'linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)',
  'linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%)',
  'linear-gradient(135deg, #d299c2 0%, #fef9d7 100%)',
  'linear-gradient(135deg, #89f7fe 0%, #66a6ff 100%)',
  'linear-gradient(135deg, #fddb92 0%, #d1fdff 100%)',
  'linear-gradient(135deg, #fbc2eb 0%, #a6c1ee 100%)',
  'linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%)',
  'linear-gradient(135deg, #cc2b5e 0%, #753a88 100%)',
  'linear-gradient(135deg, #2c3e50 0%, #bdc3c7 100%)',
  'linear-gradient(135deg, #ee9ca7 0%, #ffdde1 100%)',
  'linear-gradient(135deg, #5ee7df 0%, #b490ca 100%)',
  'linear-gradient(135deg, #c471f5 0%, #fa71cd 100%)',
  'linear-gradient(135deg, #48c6ef 0%, #6f86d6 100%)',
];

const MONTH_NAMES = [
  '1月', '2月', '3月', '4月', '5月', '6月',
  '7月', '8月', '9月', '10月', '11月', '12月',
];

// 模拟媒体尺寸集合（覆盖各种常见比例，用于模拟器验证尺寸适配）
const MEDIA_SHAPES = [
  { w: 4, h: 3, label: '横图 4:3' },
  { w: 3, h: 4, label: '竖图 3:4' },
  { w: 1, h: 1, label: '正方形 1:1' },
  { w: 16, h: 9, label: '横图 16:9' },
  { w: 21, h: 9, label: '全景 21:9' },
  { w: 9, h: 16, label: '竖图 9:16' },
  { w: 9, h: 19, label: '长图 9:19' },
  { w: 2, h: 3, label: '竖图 2:3' },
];

// 从 CSS 渐变字符串提取第一个 hex 色值
function extractHex(css) {
  const m = String(css).match(/#[0-9a-fA-F]{6}/);
  return m ? m[0].slice(1) : '667eea';
}

// 生成 SVG 示例照片（模拟器专用：不同比例的渐变"照片"）
function makeSvgPhoto(w, h, label, gradientIndex) {
  const g = GRADIENTS[gradientIndex % GRADIENTS.length];
  const c1 = extractHex(g);
  const font = Math.max(14, Math.round(Math.min(w, h) * 0.09));
  const svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '">'
    + '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">'
    + '<stop offset="0%" stop-color="#' + c1 + '"/>'
    + '<stop offset="100%" stop-color="#1c1c1e"/>'
    + '</linearGradient></defs>'
    + '<rect width="100%" height="100%" fill="url(#g)"/>'
    + '<text x="50%" y="' + Math.round(h / 2) + '" text-anchor="middle" dominant-baseline="middle" font-family="-apple-system, sans-serif" font-size="' + font + '" font-weight="600" fill="rgba(255,255,255,0.92)">' + label + '</text>'
    + '<text x="50%" y="' + Math.round(h / 2 + font * 1.7) + '" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="' + Math.round(font * 0.7) + '" fill="rgba(255,255,255,0.6)">' + w + ' : ' + h + '</text>'
    + '</svg>';
  return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
}

function rand(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// 生成模拟照片（循环覆盖不同媒体尺寸比例；含视频与 Live Photo 示例）
function generateMockPhotos(count, startId = 0, year = 2025, month = 12) {
  const photos = [];
  for (let i = 0; i < count; i++) {
    const shape = MEDIA_SHAPES[(startId + i) % MEDIA_SHAPES.length];
    const isVideo = Math.random() < 0.15;
    const isLivePhoto = !isVideo && Math.random() < 0.15;
    const w = shape.w * 100;
    const h = shape.h * 100;
    photos.push({
      id: 'mock_' + (startId + i),
      gradient: GRADIENTS[(startId + i) % GRADIENTS.length],
      isVideo,
      isLivePhoto,
      duration: isVideo ? `${rand(1, 5)}:${String(rand(0, 59)).padStart(2, '0')}` : null,
      favorite: false,
      albums: [],
      ratio: shape.w / shape.h,
      creationDate: `${year}/${month}/${rand(1, 28)}`,
      fileSize: rand(800 * 1024, 4_500 * 1024),
      thumbnailUrl: makeSvgPhoto(w, h, shape.label, startId + i),
    });
  }
  return photos;
}

// 生成模拟月份数据
function generateMockMonths() {
  const months = [];
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth();

  for (let i = 0; i < 8; i++) {
    let monthIndex = currentMonth - i;
    let year = currentYear;
    while (monthIndex < 0) {
      monthIndex += 12;
      year -= 1;
    }
    const photoCount = rand(12, 20);
    const startId = months.reduce((sum, m) => sum + m.photos.length, 0);
    months.push({
      id: `${year}-${monthIndex + 1}`,
      year,
      month: monthIndex + 1,
      title: `${year}年${MONTH_NAMES[monthIndex]}`,
      shortTitle: MONTH_NAMES[monthIndex],
      photos: generateMockPhotos(photoCount, startId, year, monthIndex + 1),
    });
  }
  return months;
}

// 模拟相簿列表
const MOCK_ALBUMS = [
  { id: 'favorites', name: '个人收藏', icon: '❤︎', gradient: 'linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%)' },
  { id: 'recents', name: '最近项目', icon: '⏱', gradient: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)' },
  { id: 'travel', name: '旅行', icon: '✈', gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' },
  { id: 'food', name: '美食', icon: '🍔', gradient: 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)' },
  { id: 'family', name: '家人', icon: '👨‍👩‍👧', gradient: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)' },
  { id: 'selfie', name: '自拍', icon: '📸', gradient: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)' },
  { id: 'screenshot', name: '截屏', icon: '🖼', gradient: 'linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%)' },
  { id: 'work', name: '工作', icon: '💼', gradient: 'linear-gradient(135deg, #89f7fe 0%, #66a6ff 100%)' },
];

// 数据加载器
window.DataLoader = {
  load: function(callback) {
    // 检查是否有原生桥接
    if (window.NativeBridge && window.NativeBridge.isNative()) {
      window.NativeBridge.getData(function(data) {
        if (data && data.months && data.months.length > 0) {
          // 原生数据
          callback({
            months: data.months,
            albums: data.albums && data.albums.length > 0 ? data.albums : MOCK_ALBUMS,
            isRealData: true,
          });
        } else {
          // 原生数据为空，使用模拟数据
          callback({
            months: generateMockMonths(),
            albums: MOCK_ALBUMS,
            isRealData: false,
          });
        }
      });
    } else {
      // 无原生桥接，使用模拟数据
      setTimeout(function() {
        callback({
          months: generateMockMonths(),
          albums: MOCK_ALBUMS,
          isRealData: false,
        });
      }, 100);
    }
  }
};

// 保留兼容
window.MockData = {
  months: generateMockMonths(),
  albums: MOCK_ALBUMS,
  GRADIENTS: GRADIENTS,
};
