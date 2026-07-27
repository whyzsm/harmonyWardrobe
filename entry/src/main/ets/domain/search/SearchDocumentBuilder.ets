import { ClothingItem } from '../clothing/ClothingModels';
import { OutfitTemplate } from '../outfit/OutfitModels';
import { Store, StoreVisit } from '../store/StoreModels';
import { WearLog } from '../wearLog/WearLogModels';
import { WishlistItem } from '../wishlist/WishlistModels';
import { buildSearchNgrams } from '../../utils/ngram';
import { normalizeSearchText } from '../../utils/text';
import { SearchEntityType } from './SearchModels';

export interface SearchDocument {
  entityType: SearchEntityType;
  entityId: string;
  title: string;
  body: string;
  category?: string;
  storeName?: string;
  ngrams: string;
}

function normalizeOptionalText(value?: string): string | undefined {
  if (value === undefined) {
    return undefined;
  }

  const normalized = normalizeSearchText(value);
  return normalized.length > 0 ? normalized : undefined;
}

function compactSearchTexts(values: Array<string | undefined>): string[] {
  const texts: string[] = [];

  for (const value of values) {
    const normalized = normalizeOptionalText(value);
    if (normalized !== undefined) {
      texts.push(normalized);
    }
  }

  return texts;
}

function joinSearchText(values: Array<string | undefined>): string {
  return compactSearchTexts(values).join(' ');
}

function buildSearchNgramText(values: Array<string | undefined>): string {
  return buildSearchNgrams(joinSearchText(values)).join(' ');
}

function priceToSearchText(price?: number): string | undefined {
  if (price === undefined || !Number.isFinite(price)) {
    return undefined;
  }

  return `${price}`;
}

export function buildClothingSearchDocument(item: ClothingItem): SearchDocument {
  const title = normalizeSearchText(item.name);
  const category = normalizeOptionalText(item.category);
  const storeName = normalizeOptionalText(item.purchaseInfo?.storeName);
  const body = joinSearchText([
    item.category,
    item.note,
    item.purchaseInfo?.storeName,
    item.purchaseInfo?.note
  ]);

  return {
    entityType: SearchEntityType.Clothing,
    entityId: item.id,
    title,
    body,
    category,
    storeName,
    ngrams: buildSearchNgramText([title, body, category, storeName])
  };
}

export function buildOutfitSearchDocument(outfit: OutfitTemplate, clothingNames: string[]): SearchDocument {
  const title = normalizeSearchText(outfit.title);
  const category = normalizeOptionalText(outfit.categoryNames.join(' '));
  const body = joinSearchText([
    ...outfit.categoryNames,
    outfit.note,
    ...clothingNames
  ]);

  return {
    entityType: SearchEntityType.Outfit,
    entityId: outfit.id,
    title,
    body,
    category,
    ngrams: buildSearchNgramText([title, body, category])
  };
}

export function buildWearLogSearchDocument(wearLog: WearLog): SearchDocument {
  const title = normalizeSearchText(wearLog.wornDate);
  const body = joinSearchText([
    wearLog.wornDate,
    wearLog.placeText,
    wearLog.note,
    wearLog.outfitTitleSnapshot
  ]);

  return {
    entityType: SearchEntityType.WearLog,
    entityId: wearLog.id,
    title,
    body,
    ngrams: buildSearchNgramText([title, body])
  };
}

export function buildWishlistSearchDocument(item: WishlistItem): SearchDocument {
  const title = normalizeSearchText(item.title);
  const storeName = normalizeOptionalText(item.storeName);
  const priceText = priceToSearchText(item.price);
  const body = joinSearchText([
    item.storeName,
    priceText,
    item.note
  ]);

  return {
    entityType: SearchEntityType.Wishlist,
    entityId: item.id,
    title,
    body,
    storeName,
    ngrams: buildSearchNgramText([title, body, storeName])
  };
}

export function buildStoreSearchDocument(store: Store): SearchDocument {
  const title = normalizeSearchText(store.name);
  const storeName = normalizeOptionalText(store.name);
  const body = joinSearchText([
    store.districtOrAddress,
    store.note
  ]);

  return {
    entityType: SearchEntityType.Store,
    entityId: store.id,
    title,
    body,
    storeName,
    ngrams: buildSearchNgramText([title, body, storeName])
  };
}

export function buildStoreVisitSearchDocument(visit: StoreVisit): SearchDocument {
  const title = normalizeSearchText(visit.storeNameSnapshot);
  const storeName = normalizeOptionalText(visit.storeNameSnapshot);
  const body = joinSearchText([
    visit.visitDate,
    visit.districtOrAddress,
    visit.status,
    visit.focusTags?.join(' '),
    visit.note
  ]);

  return {
    entityType: SearchEntityType.StoreVisit,
    entityId: visit.id,
    title,
    body,
    storeName,
    ngrams: buildSearchNgramText([title, body, storeName])
  };
}
