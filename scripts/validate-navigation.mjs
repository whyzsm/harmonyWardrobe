import fs from 'node:fs';

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const index = fs.readFileSync(indexPath, 'utf8');

for (const tab of ['TodayPage', 'WardrobePage', 'CalendarPage', 'ShoppingPage']) {
  if (!index.includes(tab)) {
    throw new Error(`Index missing ${tab}`);
  }
}

for (const label of ['首页', '衣橱', '日历', '逛街']) {
  if (!index.includes(label)) {
    throw new Error(`Index missing nav label ${label}`);
  }
}

if (!index.includes("Image($r('app.media.activePlus'))")) {
  throw new Error('Index missing center plus action image');
}

for (const forbidden of [".tabBar('今日')", ".tabBar('套装')"]) {
  if (index.includes(forbidden)) {
    throw new Error(`Index still contains forbidden nav tab ${forbidden}`);
  }
}

for (const action of ['添加衣服', '创建套装', '记录今日']) {
  if (!index.includes(action)) {
    throw new Error(`Index missing quick action ${action}`);
  }
}

for (const carouselNeedle of [
  'Swiper(this.recommendationSwiperController)',
  '.indicator(false)',
  '.autoPlay(this.activeRecommendationImages().length > 1)',
  'recommendationImageIndex',
  'this.activeRecommendation.imageUris',
  'ForEach(this.activeRecommendationImages()'
]) {
  if (!index.includes(carouselNeedle)) {
    throw new Error(`Index missing recommendation carousel detail ${carouselNeedle}`);
  }
}

for (const editor of ['ClothingEditPage', 'OutfitEditPage', 'WearLogEditPage']) {
  if (!index.includes(editor)) {
    throw new Error(`Index missing quick action editor ${editor}`);
  }
}

for (const styleNeedle of ['AppTheme.color.primary', 'AppTheme.color.surface', '.width(44)', '.height(40)', '.height(78)', ".height('100%')", '.fontSize(15)', ".backgroundColor('#00000000')", ".responseRegion({ x: 0, y: -6, width: '100%', height: 78 })"]) {
  if (!index.includes(styleNeedle)) {
    throw new Error(`Index missing center plus style ${styleNeedle}`);
  }
}

if (/BottomTabItem[\s\S]*?Text\(title\)[\s\S]*?\.fontSize\(1[0-3]\)/.test(index)) {
  throw new Error('Bottom tab text is too small');
}

if (!/BottomTabItem[\s\S]*?\.layoutWeight\(1\)[\s\S]*?\.height\('100%'\)[\s\S]*?\.onClick/.test(index)) {
  throw new Error('Bottom tab item must use the full bottom bar content height as its tap target');
}

if (!/BottomTabItem[\s\S]*?\.backgroundColor\('#00000000'\)[\s\S]*?\.responseRegion\(\{ x: 0, y: -6, width: '100%', height: 78 \}\)[\s\S]*?\.onClick/.test(index)) {
  throw new Error('Bottom tab item must expose the whole bottom bar as a transparent response region');
}

if (!/RudderActionTab[\s\S]*?\.layoutWeight\(1\)[\s\S]*?\.height\('100%'\)[\s\S]*?\.onClick/.test(index)) {
  throw new Error('Center action tab must use the full bottom bar content height as its tap target');
}

if (!/RudderActionTab[\s\S]*?\.backgroundColor\('#00000000'\)[\s\S]*?\.responseRegion\(\{ x: 0, y: -6, width: '100%', height: 78 \}\)[\s\S]*?\.onClick/.test(index)) {
  throw new Error('Center action tab must expose the whole bottom bar as a transparent response region');
}

for (const forbidden of [
  '.margin({ bottom: 30 })',
  '.height(64)',
  '.height(88)',
  '.height(92)',
  'Column()\n          .layoutWeight(1)',
  'bottom: 92',
  'bottom: 66'
]) {
  if (index.includes(forbidden)) {
    throw new Error(`Index still contains floating bottom nav pattern ${forbidden}`);
  }
}

for (const page of ['TodayPage', 'WardrobePage', 'OutfitsPage', 'CalendarPage', 'ShoppingPage']) {
  const pagePath = `entry/src/main/ets/pages/${page}.ets`;
  if (!fs.existsSync(pagePath)) {
    throw new Error(`Missing ${pagePath}`);
  }

  const pageText = fs.readFileSync(pagePath, 'utf8');
  if (!pageText.includes('@Component')) {
    throw new Error(`${page} must be an ArkUI component`);
  }
}

console.log('PASS');
