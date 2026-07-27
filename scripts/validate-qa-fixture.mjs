import fs from 'node:fs';

const seedPath = 'entry/src/main/ets/data/debug/SeedData.ets';
const qaPath = 'docs/qa/manual-test-script.md';

function sourceFiles(directory) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const path = `${directory}/${entry.name}`;
    if (entry.isDirectory()) {
      files.push(...sourceFiles(path));
    } else if (entry.name.endsWith('.ets')) {
      files.push(path);
    }
  }
  return files;
}

if (fs.existsSync(seedPath)) {
  throw new Error('Production source must not include debug seed data');
}

const productionSources = sourceFiles('entry/src/main/ets')
  .map((path) => fs.readFileSync(path, 'utf8'))
  .join('\n');

for (const forbidden of [
  'debug://',
  'offline seed',
  'designDemoResource',
  'designLookResource',
  'designFallbackPhoto',
  'DEFAULT_HISTORY_TERMS',
  'wardrobe_demo_',
  'wardrobe_look_',
  'store_visit_cover',
  "Text('22°')",
  '亮色外套，适合周末出门。',
  '牛仔短外套'
]) {
  if (productionSources.includes(forbidden)) {
    throw new Error(`Production source still contains test data marker: ${forbidden}`);
  }
}

for (const asset of [
  'store_visit_cover.png',
  'wardrobe_demo_1.png',
  'wardrobe_demo_2.png',
  'wardrobe_demo_3.png',
  'wardrobe_demo_4.png',
  'wardrobe_look_bag.jpg',
  'wardrobe_look_dress.jpg',
  'wardrobe_look_pants.jpg',
  'wardrobe_look_shirt.jpg'
]) {
  if (fs.existsSync(`entry/src/main/resources/base/media/${asset}`)) {
    throw new Error(`Production media still contains test asset: ${asset}`);
  }
}

const searchPage = fs.readFileSync('entry/src/main/ets/pages/SearchResultsPage.ets', 'utf8');
if (!searchPage.includes('@State private historyTerms: string[] = []')) {
  throw new Error('Search history must start empty instead of showing fabricated user history');
}

const profilePage = fs.readFileSync('entry/src/main/ets/pages/ProfilePage.ets', 'utf8');
const qa = fs.readFileSync(qaPath, 'utf8');
for (const needle of [
  '衣不缺',
  '穿搭 / 衣柜 / 相机 / 逛街 / 我的',
  '入口从上到下为 `穿搭`、`逛店`、`衣柜`',
  '拍照',
  '相册入口',
  '归类为 `衣橱`',
  '归类为 `美搭`',
  '归类为 `店铺`',
  '全宽搜索框',
  '双列原生瀑布流',
  '图片左上角显示分类图标',
  '长按衣物卡片',
  '长按穿搭卡片',
  '长按逛店卡片',
  '逛店',
  '我的',
  '身高',
  '体重',
  '腰围',
  '离线'
]) {
  if (!qa.includes(needle)) {
    throw new Error(`QA script missing ${needle}`);
  }
}

for (const removedHomeChrome of ['`我的衣柜` 标题', '黑色筛选按钮', '`一眼看衣服` 标题']) {
  if (qa.includes(removedHomeChrome)) {
    throw new Error(`QA script should not describe removed wardrobe chrome: ${removedHomeChrome}`);
  }
}

console.log('PASS');
