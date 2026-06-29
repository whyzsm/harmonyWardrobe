import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const sourcePath = 'entry/src/main/ets/domain/search/SearchDocumentBuilder.ets';

if (!fs.existsSync(sourcePath)) {
  console.error(`${sourcePath} does not exist`);
  process.exit(1);
}

const source = fs.readFileSync(sourcePath, 'utf8');

function assertIncludes(needle, message = `Missing ${needle}`) {
  if (!source.includes(needle)) {
    throw new Error(message);
  }
}

function assertMatches(pattern, message) {
  if (!pattern.test(source)) {
    throw new Error(message);
  }
}

function assertInterfaceFields(interfaceName, fields) {
  const match = source.match(new RegExp(`export\\s+interface\\s+${interfaceName}\\s*{([\\s\\S]*?)\\n}`));
  if (!match) {
    throw new Error(`Missing exported interface ${interfaceName}`);
  }

  for (const field of fields) {
    if (!new RegExp(`\\b${field}\\??\\s*:`).test(match[1])) {
      throw new Error(`${interfaceName} missing field ${field}`);
    }
  }
}

function createRunnableBuilderSource() {
  return source
    .replace(/^import .*;\n/gm, '')
    .replace(/\bexport\s+/g, '')
    .replace(/interface\s+\w+\s*{[\s\S]*?\n}\n/g, '')
    .replace(/new Set<string>\(/g, 'new Set(')
    .replace(/([A-Za-z_$][\w$]*)\?\s*:/g, '$1:')
    .replace(/\)\s*:\s*[A-Za-z_$][\w$]*\s+is\s+[A-Za-z_$][\w$]*\s*=>/g, ') =>')
    .replace(/:\s*Array<[^>]+>/g, '')
    .replace(/: string\[\]/g, '')
    .replace(/: string\s*\|\s*undefined/g, '')
    .replace(/: number\s*\|\s*undefined/g, '')
    .replace(/: string/g, '')
    .replace(/: number/g, '')
    .replace(/: ClothingItem/g, '')
    .replace(/: OutfitTemplate/g, '')
    .replace(/: WearLog/g, '')
    .replace(/: WishlistItem/g, '')
    .replace(/: SearchDocument/g, '');
}

assertIncludes("import { buildSearchNgrams } from '../../utils/ngram';", 'Builder must import buildSearchNgrams');
assertIncludes("import { normalizeSearchText } from '../../utils/text';", 'Builder must import normalizeSearchText');
assertIncludes("import { SearchEntityType } from './SearchModels';", 'Builder must import SearchEntityType');
assertIncludes('clothingNames?: string[]', 'Outfit builder must accept optional clothingNames');
assertInterfaceFields('SearchDocument', ['entityType', 'entityId', 'title', 'body', 'category', 'storeName', 'ngrams']);

for (const builder of [
  'buildClothingSearchDocument',
  'buildOutfitSearchDocument',
  'buildWearLogSearchDocument',
  'buildWishlistSearchDocument'
]) {
  assertMatches(new RegExp(`export\\s+function\\s+${builder}\\b`), `Missing exported ${builder}`);
}

for (const entityType of ['Clothing', 'Outfit', 'WearLog', 'Wishlist']) {
  assertIncludes(`SearchEntityType.${entityType}`, `Missing SearchEntityType.${entityType}`);
}

assertMatches(/!==\s*undefined[\s\S]*\.push\s*\(/, 'Builder must compact optional fields instead of indexing undefined');
assertIncludes('item.price', 'Wishlist price must be converted into searchable text');
assertMatches(/buildSearchNgrams[\s\S]*\.join\(' '\)/, 'Builder must store ngrams as space-joined text');

const SearchEntityType = {
  Clothing: 'clothing',
  Outfit: 'outfit',
  WearLog: 'wearLog',
  Wishlist: 'wishlist'
};

function normalizeSearchText(input) {
  return input.normalize('NFKC').trim().toLowerCase().replace(/\s+/g, ' ');
}

function buildSearchNgrams(input) {
  return normalizeSearchText(input)
    .split(/\s+/)
    .filter((token) => token.length > 0);
}

const context = {
  SearchEntityType,
  normalizeSearchText,
  buildSearchNgrams
};

vm.createContext(context);
vm.runInContext(`
${createRunnableBuilderSource()}
this.buildClothingSearchDocument = buildClothingSearchDocument;
this.buildOutfitSearchDocument = buildOutfitSearchDocument;
this.buildWearLogSearchDocument = buildWearLogSearchDocument;
this.buildWishlistSearchDocument = buildWishlistSearchDocument;
`, context);

const clothingDocument = context.buildClothingSearchDocument({
  id: 'cloth-1',
  name: '  Wool Coat  ',
  category: 'Outerwear',
  note: undefined,
  purchaseInfo: {
    storeName: 'Soho Store',
    note: '冬季 折扣'
  }
});
assert.equal(clothingDocument.entityType, SearchEntityType.Clothing);
assert.equal(clothingDocument.entityId, 'cloth-1');
assert.equal(clothingDocument.title, 'wool coat');
assert.equal(clothingDocument.category, 'outerwear');
assert.equal(clothingDocument.storeName, 'soho store');
assert.match(clothingDocument.body, /冬季 折扣/);
assert.doesNotMatch(`${clothingDocument.body} ${clothingDocument.ngrams}`, /undefined/);
assert.match(clothingDocument.ngrams, /wool/);
assert.match(clothingDocument.ngrams, /soho/);

const outfitDocument = context.buildOutfitSearchDocument({
  id: 'outfit-1',
  title: 'Work Look',
  note: 'Client meeting'
}, ['Silk Shirt', '', 'Wide Pants']);
assert.equal(outfitDocument.entityType, SearchEntityType.Outfit);
assert.match(outfitDocument.body, /client meeting/);
assert.match(outfitDocument.body, /silk shirt/);
assert.match(outfitDocument.body, /wide pants/);
assert.match(outfitDocument.ngrams, /silk/);

const wearLogDocument = context.buildWearLogSearchDocument({
  id: 'wear-1',
  wornDate: '2026-06-29',
  placeText: 'Office',
  note: undefined,
  outfitTitleSnapshot: 'Work Look'
});
assert.equal(wearLogDocument.entityType, SearchEntityType.WearLog);
assert.equal(wearLogDocument.title, '2026-06-29');
assert.match(wearLogDocument.body, /office/);
assert.match(wearLogDocument.body, /work look/);
assert.doesNotMatch(`${wearLogDocument.body} ${wearLogDocument.ngrams}`, /undefined/);

const wishlistDocument = context.buildWishlistSearchDocument({
  id: 'wish-1',
  title: 'Linen Dress',
  storeName: undefined,
  price: 299.5,
  note: '夏季'
});
assert.equal(wishlistDocument.entityType, SearchEntityType.Wishlist);
assert.equal(wishlistDocument.storeName, undefined);
assert.match(wishlistDocument.body, /299\.5/);
assert.match(wishlistDocument.ngrams, /299\.5/);
assert.doesNotMatch(`${wishlistDocument.body} ${wishlistDocument.ngrams}`, /undefined/);

console.log('PASS');
