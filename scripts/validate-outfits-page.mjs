import fs from 'node:fs';

const outfitsPath = 'entry/src/main/ets/pages/OutfitsPage.ets';
const detailPath = 'entry/src/main/ets/pages/OutfitDetailPage.ets';
const text = fs.readFileSync(outfitsPath, 'utf8');
const detail = fs.readFileSync(detailPath, 'utf8');

for (const needle of [
  'OutfitEmptyState',
  'OutfitRepository',
  'OutfitTemplate',
  "{ label: '全部' }",
  "{ label: '逛店'",
  "{ label: '周末'",
  "{ label: '通勤'",
  '从已有单品开始搭配',
  '先添加衣物再创建穿搭',
  'OutfitGuideCard',
  'Column({ space: 14 })',
  'Row({ space: 6 })',
  '.constraintSize({ minWidth: 0, minHeight: 44 })',
  '.padding({ left: 8, right: 8 })',
  '.layoutWeight(1)',
  'OutfitDetailPage',
  'OutfitSearchHeader',
  'SearchRepository',
  'SearchResultsPage',
  'searchQuery',
  'openUnifiedSearch',
  'onOpenSearchTarget',
  'onOpenCapture',
  'openOutfitDetail',
  'showOutfitDetail',
  'displayOutfitTitle',
  'this.clothingItems.length',
  '.padding({ left: 20, right: 20 })',
  'filterOutfits',
  'onNestedPageVisibilityChange',
  'onInitialOutfitConsumed',
  'onInitialWearLogConsumed',
  "columnsTemplate('1fr 1fr')",
  'OutfitWallCard',
  'selectedClothingPhotoUris',
  'OutfitDisplaySource',
  'displayPhotoUris',
  'displayPhotoUriAt',
  'displayPhotoCount',
  'SingleOutfitPhoto',
  'YibuqueColor.overlayDark',
  '暂无照片',
  'borderRadius(YibuqueRadius.xs)',
  '正在加载穿搭',
  '重试',
  '拍照或从相册选图后，按分类收进穿搭。',
  '点底部相机，选择照片后归类为穿搭',
  '穿搭会按图片组合流排在这里。'
]) {
  if (!text.includes(needle)) {
    throw new Error(`OutfitsPage missing ${needle}`);
  }
}

if (!/private filterOutfits\(\): OutfitTemplate\[\][\s\S]*?normalizedQuery\s*=\s*this\.searchQuery\.trim\(\)\.toLowerCase\(\)[\s\S]*?matchesQuery/.test(text)) {
  throw new Error('OutfitsPage search must filter outfits by the entered query');
}

if (!/OutfitSearchHeader\(\)[\s\S]*?TextInput\(\{ text: this\.searchQuery, placeholder: '搜索穿搭、场景、备注' \}\)[\s\S]*?this\.refreshOutfitDataSource\(\)[\s\S]*?this\.openSearch\(\)/.test(text)) {
  throw new Error('OutfitsPage search header must match the wardrobe search interaction');
}

if (!/FilterStrip\(\)[\s\S]*?Row\(\{ space: 6 \}\)[\s\S]*?\.layoutWeight\(1\)[\s\S]*?\.height\(44\)[\s\S]*?\.padding\(\{ left: 20, right: 20 \}\)/.test(text)) {
  throw new Error('OutfitsPage filter strip must keep the same vertical spacing as the wardrobe tabs');
}

if (!/else if \(this\.showUnifiedSearch\)[\s\S]*?SearchResultsPage\(\{[\s\S]*?searchRepository: this\.searchRepository[\s\S]*?onOpenOutfitResult/.test(text)) {
  throw new Error('OutfitsPage search must open the unified search results page');
}

for (const forbidden of [
  "Button('记录穿着')",
  'RECORD_WEAR_ACCESSIBILITY_TEXT',
  'onRecordWear'
]) {
  if (text.includes(forbidden)) {
    throw new Error(`OutfitsPage must hide the card wear action: ${forbidden}`);
  }
}

if (/OutfitGuideCard\(\)[\s\S]*?\.margin\(\{ left: 20, right: 20, bottom: 16 \}\)/.test(text)) {
  throw new Error('OutfitsPage guide card must use container padding instead of overflowing full-width margins');
}

const outfitGuideCardBuilder = text.match(/@Builder\n  OutfitGuideCard\(\) \{([\s\S]*?)\n  \}\n\n  @Builder\n  OutfitWallCard/)?.[1] ?? '';

if (!/Row\(\)\s*\{[\s\S]*?Row\(\{ space: 12 \}\)[\s\S]*?\.padding\(\{ left: 20, right: 20 \}\)/.test(outfitGuideCardBuilder)) {
  throw new Error('OutfitsPage guide card must align to the waterfall grid horizontal padding without extra bottom spacing');
}

if (/\.padding\(\{ left: 20, right: 20, bottom:/.test(outfitGuideCardBuilder)) {
  throw new Error('OutfitsPage guide card must not add extra bottom spacing before the empty state');
}

if (/wardrobe_look_|debug:\/\/|Text\('22°'\)/.test(text)) {
  throw new Error('OutfitsPage must not render sample outfits or hard-coded weather data');
}

if (/Button\('创建穿搭'\)/.test(text)) {
  throw new Error('OutfitsPage empty state must not render a create-outfit button');
}

if (!/OutfitWallCard\([\s\S]*?\.onClick\(\(\) => \{[\s\S]*?openOutfitDetail\(outfit\)/.test(text)) {
  throw new Error('OutfitsPage list cards must open the read-only detail page');
}

if (!/private displayPhotoUris\(outfit: OutfitTemplate\): string\[\] \{[\s\S]*?outfit\.displaySource === OutfitDisplaySource\.Wardrobe[\s\S]*?return clothingPhotoUris\.length > 0 \? clothingPhotoUris : outfit\.photoUris;[\s\S]*?return outfit\.photoUris\.length > 0 \? outfit\.photoUris : clothingPhotoUris;/.test(text)) {
  throw new Error('OutfitsPage display photos must follow the saved display source with fallback');
}

if (!/OutfitWallCard\(outfit: OutfitTemplate, index: number\)[\s\S]*?if \(this\.displayPhotoCount\(outfit\) > 1\)[\s\S]*?this\.OutfitPhoto\(outfit, 0, 1\.18\)[\s\S]*?this\.OutfitPhoto\(outfit, 1, 0\.92\)[\s\S]*?else \{[\s\S]*?this\.SingleOutfitPhoto\(outfit\)/.test(text)) {
  throw new Error('OutfitsPage cards must render a single full image for one photo and stacked images only for two or more photos');
}

if (!/if \(this\.displayPhotoCount\(outfit\) > 2\)[\s\S]*?Text\(`\+\$\{this\.displayPhotoCount\(outfit\) - 2\}`\)[\s\S]*?YibuqueColor\.overlayDark/.test(text)) {
  throw new Error('OutfitsPage cards must show a compact +N badge for extra display photos');
}

if (/private photoUriAt\(outfit: OutfitTemplate/.test(text) || /this\.photoUriAt\(outfit/.test(text)) {
  throw new Error('OutfitsPage must use displayPhotoUriAt instead of the old raw outfit photo accessor');
}

if (!/private displayOutfitTitle\(outfit: OutfitTemplate\)[\s\S]*?穿搭\|美搭[\s\S]*?return match === null \? outfit\.title : match\[1\]/.test(text) ||
  !text.includes('Text(this.displayOutfitTitle(outfit))')) {
  throw new Error('OutfitsPage waterfall titles must hide generated dates without changing custom titles');
}

if (!/else if \(this\.outfits\.length === 0\) \{[\s\S]*?\.justifyContent\(FlexAlign\.Start\)/.test(text)) {
  throw new Error('OutfitsPage empty state must align below the weather card instead of centering vertically');
}

const emptyStateBuilder = text.match(/OutfitEmptyState\(title: string, description: string, guideTitle: string, guideDescription: string\) \{([\s\S]*?)\n  \}\n\n  @Builder\n  FilterStrip/)?.[1] ?? '';

if (!/Column\(\{ space: 10 \}\)[\s\S]*?Column\(\{ space: 8 \}\)[\s\S]*?\.fontSize\(36\)[\s\S]*?\.height\(190\)[\s\S]*?\.backgroundColor\(YibuqueColor\.cardSoftGray\)[\s\S]*?\.borderRadius\(YibuqueRadius\.xxl\)[\s\S]*?\.border\(\{ width: 1, color: YibuqueColor\.borderMedium \}\)[\s\S]*?Text\(guideTitle\)[\s\S]*?\.fontSize\(15\)[\s\S]*?Text\(guideDescription\)[\s\S]*?\.fontSize\(12\)[\s\S]*?\.backgroundColor\(YibuqueColor\.bgDefault\)/.test(emptyStateBuilder)) {
  throw new Error('OutfitsPage empty state must match the wardrobe empty layout');
}

if (!/private detailPhotoUris\(\): string\[\] \{[\s\S]*?const uploadedPhotoUris = this\.photoUris\(\);[\s\S]*?const clothingPhotoUris = this\.selectedClothingPhotoUris\(\);[\s\S]*?this\.outfit\?\.displaySource === OutfitDisplaySource\.Wardrobe[\s\S]*?return clothingPhotoUris\.length > 0 \? clothingPhotoUris : uploadedPhotoUris;[\s\S]*?return uploadedPhotoUris\.length > 0 \? uploadedPhotoUris : clothingPhotoUris;/.test(detail)) {
  throw new Error('OutfitDetailPage must follow the saved display source with fallback');
}

if (!/private displayOutfitTitle\(\): string[\s\S]*?穿搭\|美搭[\s\S]*?Text\(this\.displayOutfitTitle\(\)\)/.test(detail)) {
  throw new Error('OutfitDetailPage must hide generated date titles');
}

if (detail.includes('暂未填写备注') || !/private hasNoteText\(\): boolean[\s\S]*?if \(this\.hasNoteText\(\)\)[\s\S]*?Text\(this\.noteText\(\)\)/.test(detail)) {
  throw new Error('OutfitDetailPage must hide the note block when no note exists');
}

if (!/onDelete:\s*\(outfit: OutfitTemplate\)[\s\S]*?DeleteAction\(\)[\s\S]*?删除穿搭/.test(detail)) {
  throw new Error('OutfitDetailPage must own the outfit delete action');
}

if (!/Text\(`\$\{this\.outfit\?\.clothingItemIds\.length \?\? 0\} 件单品`\)[\s\S]*?fontColor\(YibuqueColor\.iconAccent\)[\s\S]*?backgroundColor\(YibuqueColor\.iconAccentSurface\)[\s\S]*?border\(\{ width: 1, color: YibuqueColor\.iconAccentSurface \}\)/.test(detail)) {
  throw new Error('OutfitDetailPage item count badge must use the blue accent treatment');
}

console.log('PASS');
