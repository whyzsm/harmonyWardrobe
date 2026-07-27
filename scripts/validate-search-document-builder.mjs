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
    .replace(/: StoreVisit/g, '')
    .replace(/: Store/g, '')
    .replace(/: WearLog/g, '')
    .replace(/: WishlistItem/g, '')
    .replace(/: SearchDocument/g, '');
}

assertIncludes("import { buildSearchNgrams } from '../../utils/ngram';", 'Builder must import buildSearchNgrams');
assertIncludes("import { normalizeSearchText } from '../../utils/text';", 'Builder must import normalizeSearchText');
assertIncludes("import { SearchEntityType } from './SearchModels';", 'Builder must import SearchEntityType');
assertMatches(
  /export\s+function\s+buildOutfitSearchDocument\s*\(\s*outfit:\s*OutfitTemplate,\s*clothingNames:\s*string\[\]\s*\):\s*SearchDocument/,
  'Outfit builder must require clothingNames'
);
assertMatches(
  /export\s+function\s+buildOutfitSearchDocument[\s\S]*\.\.\.clothingNames/,
  'Outfit builder must consume clothingNames'
);
if (source.includes('clothingNames ?? []')) {
  throw new Error('Outfit builder must not silently default missing clothingNames');
}
assertInterfaceFields('SearchDocument', ['entityType', 'entityId', 'title', 'body', 'category', 'storeName', 'ngrams']);

for (const builder of [
  'buildClothingSearchDocument',
  'buildOutfitSearchDocument',
  'buildWearLogSearchDocument',
  'buildWishlistSearchDocument',
  'buildStoreSearchDocument',
  'buildStoreVisitSearchDocument'
]) {
  assertMatches(new RegExp(`export\\s+function\\s+${builder}\\b`), `Missing exported ${builder}`);
}

for (const entityType of ['Clothing', 'Outfit', 'WearLog', 'Wishlist', 'Store', 'StoreVisit']) {
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
  const tokens = normalizeSearchText(input)
    .split(/\s+/)
    .map((token) => token.replace(/[^\p{Script=Han}\p{Letter}\p{Number}]+/gu, ''))
    .filter((token) => token.length > 0);

  const grams = [];
  const seen = new Set();
  for (const token of tokens) {
    for (let size = 1; size <= Math.min(3, Array.from(token).length); size += 1) {
      for (let start = 0; start <= Array.from(token).length - size; start += 1) {
        const gram = Array.from(token).slice(start, start + size).join('');
        if (!seen.has(gram)) {
          seen.add(gram);
          grams.push(gram);
        }
      }
    }
  }

  return grams;
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
this.buildStoreSearchDocument = buildStoreSearchDocument;
this.buildStoreVisitSearchDocument = buildStoreVisitSearchDocument;
`, context);

const clothingDocument = context.buildClothingSearchDocument({
  id: 'cloth-1',
  name: '  Wool Coat  ',
  category: 'LongSkirt',
  note: undefined,
  purchaseInfo: {
    storeName: 'Soho Store',
    note: '冬季 折扣'
  }
});
assert.equal(clothingDocument.entityType, SearchEntityType.Clothing);
assert.equal(clothingDocument.entityId, 'cloth-1');
assert.equal(clothingDocument.title, 'wool coat');
assert.equal(clothingDocument.category, 'longskirt');
assert.equal(clothingDocument.storeName, 'soho store');
assert.match(clothingDocument.body, /冬季 折扣/);
assert.doesNotMatch(`${clothingDocument.body} ${clothingDocument.ngrams}`, /undefined/);
assert.match(clothingDocument.ngrams, /\bwoo\b/);
assert.match(clothingDocument.ngrams, /\bsoh\b/);

const outfitDocument = context.buildOutfitSearchDocument({
  id: 'outfit-1',
  title: 'Work Look',
  categoryNames: ['通勤', '极简'],
  note: 'Client meeting'
}, ['Silk Shirt', '', 'Wide Pants']);
assert.equal(outfitDocument.entityType, SearchEntityType.Outfit);
assert.equal(outfitDocument.category, '通勤 极简');
assert.match(outfitDocument.body, /通勤/);
assert.match(outfitDocument.body, /极简/);
assert.match(outfitDocument.body, /client meeting/);
assert.match(outfitDocument.body, /silk shirt/);
assert.match(outfitDocument.body, /wide pants/);
assert.match(outfitDocument.ngrams, /\bsil\b/);

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
assert.match(wishlistDocument.ngrams, /\b299\b/);
assert.match(wishlistDocument.ngrams, /\b5\b/);
assert.doesNotMatch(`${wishlistDocument.body} ${wishlistDocument.ngrams}`, /undefined/);

const storeDocument = context.buildStoreSearchDocument({
  id: 'store-1',
  name: 'Vintage Shop',
  districtOrAddress: '南山',
  photoUris: [],
  note: '适合通勤',
  createdAt: '2026-07-04T00:00:00.000Z',
  updatedAt: '2026-07-04T00:00:00.000Z'
});
assert.equal(storeDocument.entityType, SearchEntityType.Store);
assert.match(storeDocument.body, /南山/);
assert.match(storeDocument.body, /适合通勤/);

const storeVisitDocument = context.buildStoreVisitSearchDocument({
  id: 'visit-1',
  storeNameSnapshot: 'Vintage Shop',
  districtOrAddress: '南山',
  visitDate: '2026-07-04',
  photoUris: [],
  note: '试了半裙',
  createdAt: '2026-07-04T00:00:00.000Z',
  updatedAt: '2026-07-04T00:00:00.000Z'
});
assert.equal(storeVisitDocument.entityType, SearchEntityType.StoreVisit);
assert.match(storeVisitDocument.body, /2026-07-04/);
assert.match(storeVisitDocument.body, /试了半裙/);

console.log('PASS');
