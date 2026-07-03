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
const designPath = 'docs/background/yibuque-design.md';

const tokens = read(tokenPath);
const topBar = read(topBarPath);
const nav = read(navPath);
const quickSheet = read(quickSheetPath);
read(designPath);

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

for (const needle of ['衣不缺', '我的', '44', '48', 'YibuqueColor.textPrimary']) {
  mustInclude(topBar, topBarPath, needle);
}

for (const needle of ['衣橱', '逛店', '+', 'actionBlack', '44', 'bottomSafe']) {
  mustInclude(nav, navPath, needle);
}

for (const needle of ['拍衣服', '拍搭配', '拍店铺', 'sheet', 'actionBlack', '56']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}

for (const text of [topBar, nav, quickSheet]) {
  mustNotInclude(text, 'yibuque visual components', 'AppTheme.color.primary');
}

console.log('PASS');
