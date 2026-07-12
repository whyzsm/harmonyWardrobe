import fs from 'node:fs';

const pageFiles = [
  'entry/src/main/ets/pages/CaptureEditPage.ets',
  'entry/src/main/ets/pages/ClothingDetailPage.ets',
  'entry/src/main/ets/pages/ClothingEditPage.ets',
  'entry/src/main/ets/pages/OutfitEditPage.ets',
  'entry/src/main/ets/pages/SearchResultsPage.ets',
  'entry/src/main/ets/pages/StoreVisitEditPage.ets',
  'entry/src/main/ets/pages/WearLogEditPage.ets',
  'entry/src/main/ets/pages/WishlistEditPage.ets'
];

const headerFile = 'entry/src/main/ets/components/SecondaryPageHeader.ets';
const header = fs.readFileSync(headerFile, 'utf8');

function blockAfter(source, marker, fromIndex = 0) {
  const markerIndex = source.indexOf(marker, fromIndex);
  if (markerIndex < 0) {
    throw new Error(`Missing block marker ${marker}`);
  }
  const openIndex = source.indexOf('{', markerIndex + marker.length);
  if (openIndex < 0) {
    throw new Error(`Missing opening brace after ${marker}`);
  }

  let depth = 0;
  for (let index = openIndex; index < source.length; index += 1) {
    if (source[index] === '{') {
      depth += 1;
    } else if (source[index] === '}') {
      depth -= 1;
      if (depth === 0) {
        return {
          body: source.slice(openIndex + 1, index),
          endIndex: index
        };
      }
    }
  }
  throw new Error(`Missing closing brace after ${marker}`);
}

function modifierChainAfter(source, endIndex) {
  let cursor = endIndex + 1;
  let chain = '';
  while (cursor < source.length) {
    while (/\s/.test(source[cursor] ?? '')) {
      cursor += 1;
    }
    if (source[cursor] !== '.') {
      break;
    }
    const modifierStart = cursor;
    const openIndex = source.indexOf('(', cursor);
    if (openIndex < 0) {
      break;
    }
    let depth = 0;
    cursor = openIndex;
    for (; cursor < source.length; cursor += 1) {
      if (source[cursor] === '(') {
        depth += 1;
      } else if (source[cursor] === ')') {
        depth -= 1;
        if (depth === 0) {
          cursor += 1;
          chain += source.slice(modifierStart, cursor);
          break;
        }
      }
    }
  }
  return chain;
}

function assertPinnedRoot(source, label, headerCall) {
  let current = source.trimStart();
  for (let depth = 0; depth < 4; depth += 1) {
    if (current.startsWith(headerCall)) {
      let callEndIndex = headerCall.length - 1;
      if (headerCall.endsWith('({')) {
        const props = blockAfter(current, headerCall.slice(0, -1));
        callEndIndex = current.indexOf(')', props.endIndex + 1);
      }
      const headerModifiers = modifierChainAfter(current, callEndIndex);
      if (/\.(?:padding|margin|position|offset|translate)\(/.test(headerModifiers)) {
        throw new Error(`${label} must not displace the header instance`);
      }
      return;
    }
    const rootMatch = /^(?:Column|Stack)\s*\([^)]*\)\s*\{/.exec(current);
    if (rootMatch === null) {
      throw new Error(`${label} must render ${headerCall} as its first visible content`);
    }
    const root = blockAfter(current, rootMatch[0].slice(0, -1));
    const modifiers = modifierChainAfter(current, root.endIndex);
    if (/\.(?:padding|margin|position|offset|translate)\(/.test(modifiers)) {
      throw new Error(`${label} header ancestors must not add spacing or displacement`);
    }
    current = root.body.trimStart();
  }
  throw new Error(`${label} nests ${headerCall} too deeply`);
}

for (const needle of [
  ".height(60)",
  ".padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX })"
]) {
  if (!header.includes(needle)) {
    throw new Error(`${headerFile} must pin the navigation content to the top: missing ${needle}`);
  }
}

if (/\.padding\(\{[^}]*top\s*:/.test(header) || header.includes('.height(96)')) {
  throw new Error(`${headerFile} must not add extra top spacing`);
}

const balancedActionAreas = header.match(/\.width\(48\)\s*\.height\(48\)/g) ?? [];
if (balancedActionAreas.length !== 3) {
  throw new Error(`${headerFile} must keep three paired 48x48 action or balance areas`);
}

if (/\.margin\(\{[^}]*\btop\s*:|\.position\(|\.offset\(/.test(header)) {
  throw new Error(`${headerFile} must remain pinned without margin, position, or offset displacement`);
}

for (const file of pageFiles) {
  const source = fs.readFileSync(file, 'utf8');
  if (!source.includes("import { SecondaryPageHeader } from '../components/SecondaryPageHeader';") ||
    !source.includes('SecondaryPageHeader({')) {
    throw new Error(`${file} must use the shared secondary page header`);
  }
  if (!file.endsWith('/ClothingDetailPage.ets')) {
    assertPinnedRoot(blockAfter(source, 'build()').body, file, 'SecondaryPageHeader({');
  }
}

const detailPage = fs.readFileSync('entry/src/main/ets/pages/ClothingDetailPage.ets', 'utf8');
const detailBuild = blockAfter(detailPage, 'build()').body;
const missingItemBranch = blockAfter(detailBuild, 'if (this.item === undefined)');
const contentBranch = blockAfter(detailBuild, 'else', missingItemBranch.endIndex + 1);
assertPinnedRoot(missingItemBranch.body, 'ClothingDetailPage missing-item state', 'SecondaryPageHeader({');
assertPinnedRoot(contentBranch.body, 'ClothingDetailPage content state', 'this.DetailTopBar()');
const detailTopBarBody = blockAfter(detailPage, 'DetailTopBar()').body.trimStart();
if (!detailTopBarBody.startsWith('SecondaryPageHeader({')) {
  throw new Error('ClothingDetailPage DetailTopBar must render SecondaryPageHeader first');
}

console.log('PASS');
