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
  'iconAccent',
  'iconAccentSurface',
  'selectionAccent',
  'selectionAccentSurface',
  'bgBase',
  'bgHeader',
  'cardSurface',
  'cardMuted',
  'textQuaternary',
  'glassBadge',
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

for (const misleadingToken of ['bgBlueGray', 'bgHeaderBlue', 'cardBlue', 'cardMint', 'brandCyan']) {
  mustNotInclude(tokens, tokenPath, misleadingToken);
}

for (const needle of ['#1D1D1F', '#000000', '#F5F5F7', '#F2F2F7', '#FFFFFF', '#0071E3', '#EAF3FE']) {
  mustInclude(tokens, tokenPath, needle);
}

for (const needle of ['蓝色选中', 'blue selection', '图片优先', 'image-first', '衣柜', '逛店', '穿搭']) {
  mustInclude(design, designPath, needle);
}

for (const forbidden of ['深玫瑰', '#B11B68', '#FFF2F8', '拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(design, designPath, forbidden);
}

for (const needle of ['衣不缺', '我的', '44', '48', 'profilePressed', '.scale({ x: this.profilePressed ? 0.96 : 1.0', 'YibuqueColor.textPrimary']) {
  mustInclude(topBar, topBarPath, needle);
}

for (const needle of ['衣柜', '逛店', '穿搭', '我的', "SymbolGlyph($r('sys.symbol.camera_fill'))", "SymbolGlyph($r('sys.symbol.shirt'))", "SymbolGlyph($r('sys.symbol.store_fill'))", "SymbolGlyph($r('sys.symbol.hanger_and_towels'))", "SymbolGlyph($r('sys.symbol.person'))", ".width('90%')", 'bottomNavigationSurface', 'bottomNavigation', 'onSelectOutfit', 'onOpenProfile', 'bottom: 0', 'linearGradient']) {
  mustInclude(nav, navPath, needle);
}
mustInclude(nav, navPath, '#4578FF');
mustInclude(nav, navPath, '#56D0FF');
mustNotInclude(nav, navPath, '#735A7CFF');

for (const needle of ['快捷录入', '衣柜', '逛店', '穿搭', 'onOpenWardrobe', 'onOpenStoreVisit', 'onOpenOutfit', "SymbolGlyph($r('sys.symbol.shirt'))", "SymbolGlyph($r('sys.symbol.store_fill'))", "SymbolGlyph($r('sys.symbol.hanger_and_towels'))", 'YibuqueColor.actionBlack', 'YibuqueColor.iconAccent', 'YibuqueColor.iconAccentSurface', 'YibuqueShadow.editorSheet']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}
mustInclude(quickSheet, quickSheetPath, '.backgroundColor(YibuqueColor.scrimMedium)');
mustInclude(quickSheet, quickSheetPath, ".height('100%')\n    .backgroundColor(YibuqueColor.scrimMedium)");
mustInclude(quickSheet, quickSheetPath, 'Column({ space: 14 })');
mustInclude(quickSheet, quickSheetPath, 'primary: boolean');
mustInclude(quickSheet, quickSheetPath, 'primary ? YibuqueColor.actionBlack : YibuqueColor.cardWhite');
mustInclude(quickSheet, quickSheetPath, '.borderRadius(YibuqueRadius.xxl)');
mustInclude(quickSheet, quickSheetPath, '.shadow(YibuqueShadow.editorSheet)');
mustNotInclude(quickSheet, quickSheetPath, 'Divider()');
mustNotInclude(quickSheet, quickSheetPath, 'Column({ space: 0 })');
mustNotInclude(quickSheet, quickSheetPath, '.margin({ bottom: 16 })');

for (const needle of ['#0071E3', '#1D1D1F', '#93C5FD', '#EAF3FE', 'feDropShadow']) {
  mustInclude(icon, iconPath, needle);
}

mustInclude(colors, colorPath, '#FFFFFF');

for (const oldRoseColor of ['#B11B68', '#8E1454', '#7A1048', '#FCE3EF', '#FFF2F8', '#FBE1F0', '#F8D4EF', '#D83E8E']) {
  mustNotInclude(tokens, tokenPath, oldRoseColor);
  mustNotInclude(icon, iconPath, oldRoseColor);
}

const etsFiles = [];
function collectEtsFiles(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const path = `${directory}/${entry.name}`;
    if (entry.isDirectory()) {
      collectEtsFiles(path);
    } else if (entry.name.endsWith('.ets')) {
      etsFiles.push(path);
    }
  }
}
collectEtsFiles('entry/src/main/ets');

for (const forbiddenBlue of ['#0071E3', '#005EB8', '#004E9A', '#EAF3FE', '#EAF4FF', '#EDF6FF', '#4578FF', '#56D0FF']) {
  for (const file of etsFiles) {
    if (file === navPath || file === tokenPath) {
      continue;
    }
    mustNotInclude(read(file), file, forbiddenBlue);
  }
}

for (const forbidden of ['拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(quickSheet, quickSheetPath, forbidden);
}

mustNotInclude(nav, navPath, "Text('拍照')");

for (const text of [topBar, nav, quickSheet]) {
  mustNotInclude(text, 'yibuque visual components', 'AppTheme.color.primary');
}

console.log('PASS');
