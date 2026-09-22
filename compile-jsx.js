// 编译 WebContent/components/*.jsx → WebContent/build/*.js（预编译，无运行时 Babel）
// 运行：npm install && node compile-jsx.js
const fs = require('fs');
const path = require('path');
const { transformSync } = require('@babel/core');

const componentsDir = path.join(__dirname, 'Slidebox', 'WebContent', 'components');
const buildDir = path.join(__dirname, 'Slidebox', 'WebContent', 'build');

if (!fs.existsSync(buildDir)) fs.mkdirSync(buildDir, { recursive: true });

const files = fs.readdirSync(componentsDir).filter(f => f.endsWith('.jsx')).sort();
if (files.length === 0) {
  console.error('ERROR: no .jsx files found in ' + componentsDir);
  process.exit(1);
}

let compiled = 0;
for (const file of files) {
  const srcPath = path.join(componentsDir, file);
  const outPath = path.join(buildDir, file.replace(/\.jsx$/, '.js'));
  const source = fs.readFileSync(srcPath, 'utf8');
  try {
    const result = transformSync(source, {
      filename: file,
      presets: [['@babel/preset-react', { runtime: 'classic' }]],
    });
    fs.writeFileSync(outPath, result.code, 'utf8');
    console.log('compiled: ' + file + ' -> build/' + file.replace(/\.jsx$/, '.js') + ' (' + (result.code.length / 1024).toFixed(1) + ' KB)');
    compiled++;
  } catch (e) {
    console.error('COMPILE ERROR in ' + file + ': ' + (e && e.message));
    process.exit(1);
  }
}
console.log('All ' + compiled + ' components compiled.');
