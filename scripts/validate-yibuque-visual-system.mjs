import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }

  return fs.readFileSync(file, 'utf8');
}

function mustInclude(text, file, needle) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustNotInclude(text, file, needle) {
  if (text.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

const tokenPath = 'entry/src/main/ets/theme/Tokens.ets';
const topBarPath = 'entry/src/main/ets/components/AppTopBar.ets';
const navPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const quickSheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';
const iconPath = 'entry/src/main/resources/base/media/app_icon.svg';
const colorPath = 'entry/src/main/resources/base/element/color.json';
const designPath = 'docs/background/yibuque-design.md';

const tokens = read(tokenPath);
const topBar = read(topBarPath);
const nav = read(navPath);
const quickSheet = read(quickSheetPath);
const icon = read(iconPath);
const colors = read(colorPath);
const design = read(designPath);

for (const needle of [
  'YibuqueColor',
  'actionBlack',
  'bgBlueGray',
  'cardBlue',
  'cardMint',
  'borderStrong',
  'YibuqueFontSize',
  'YibuqueLineHeight',
  'YibuqueSpacing',
  'YibuqueRadius',
  'full',
  'sheet',
  'YibuqueShadow'
]) {
  mustInclude(tokens, tokenPath, needle);
}

for (const needle of ['#B11B68', '#FBE1F0', '#F8D4EF', '#D83E8E', '#FFF2F8']) {
  mustInclude(tokens, tokenPath, needle);
}

for (const needle of ['rose', '深玫瑰', 'Photo-first capture', '拍照', '从相册选择']) {
  mustInclude(design, designPath, needle);
}

for (const forbidden of ['#000000', '黑色主按钮', '拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(design, designPath, forbidden);
}

for (const needle of ['衣不缺', '我的', '44', '48', 'profilePressed', '.scale({ x: this.profilePressed ? 0.96 : 1.0', 'YibuqueColor.textPrimary']) {
  mustInclude(topBar, topBarPath, needle);
}

for (const needle of ['衣橱', '逛店', "SymbolGlyph($r('sys.symbol.camera_fill'))", 'actionBlack', '46', 'bottomSafe', 'linearGradient']) {
  mustInclude(nav, navPath, needle);
}

for (const needle of ['拍照', '从相册选择', 'sheet', 'actionBlack', '64', 'linearGradient']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}

for (const needle of ['#B11B68', '#8E1454', '#D83E8E', '#F7C1DD', 'feDropShadow']) {
  mustInclude(icon, iconPath, needle);
}

mustInclude(colors, colorPath, '#FFF2F8');

for (const forbidden of ['拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(quickSheet, quickSheetPath, forbidden);
}

for (const text of [topBar, nav, quickSheet]) {
  mustNotInclude(text, 'yibuque visual components', 'AppTheme.color.primary');
}

console.log('PASS');
