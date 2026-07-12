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

for (const needle of ['#0071E3', '#1D1D1F', '#F5F5F7', '#EAF3FE', '#FFFFFF']) {
  mustInclude(tokens, tokenPath, needle);
}

for (const needle of ['白灰蓝', 'white-gray-blue', '图片优先', 'image-first', '拍一张', '从相册选择']) {
  mustInclude(design, designPath, needle);
}

for (const forbidden of ['深玫瑰', '#B11B68', '#FFF2F8', '拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(design, designPath, forbidden);
}

for (const needle of ['衣不缺', '我的', '44', '48', 'profilePressed', '.scale({ x: this.profilePressed ? 0.96 : 1.0', 'YibuqueColor.textPrimary']) {
  mustInclude(topBar, topBarPath, needle);
}

for (const needle of ['衣柜', '逛店', '套装', '我的', "SymbolGlyph($r('sys.symbol.camera_fill'))", "SymbolGlyph($r('sys.symbol.shirt'))", "SymbolGlyph($r('sys.symbol.store_fill'))", "SymbolGlyph($r('sys.symbol.hanger_and_towels'))", "SymbolGlyph($r('sys.symbol.person'))", ".width('90%')", '#E62D2C2C', 'onSelectOutfit', 'onOpenProfile', 'bottom: 0', 'linearGradient']) {
  mustInclude(nav, navPath, needle);
}

for (const needle of ['快捷录入', '拍一张', '从相册选择', "SymbolGlyph($r('sys.symbol.camera_fill'))", "SymbolGlyph($r('sys.symbol.picture'))", '#1C1C1E', '#0071E3', '78']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}

for (const needle of ['#0071E3', '#1D1D1F', '#93C5FD', '#EAF3FE', 'feDropShadow']) {
  mustInclude(icon, iconPath, needle);
}

mustInclude(colors, colorPath, '#FFFFFF');

for (const oldRoseColor of ['#B11B68', '#8E1454', '#7A1048', '#FCE3EF', '#FFF2F8', '#FBE1F0', '#F8D4EF', '#D83E8E']) {
  mustNotInclude(tokens, tokenPath, oldRoseColor);
  mustNotInclude(icon, iconPath, oldRoseColor);
}

for (const forbidden of ['拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(quickSheet, quickSheetPath, forbidden);
}

mustNotInclude(nav, navPath, "Text('拍照')");

for (const text of [topBar, nav, quickSheet]) {
  mustNotInclude(text, 'yibuque visual components', 'AppTheme.color.primary');
}

console.log('PASS');
