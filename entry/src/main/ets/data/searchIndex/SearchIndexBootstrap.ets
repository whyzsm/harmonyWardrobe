import { ClothingRepository } from '../repositories/ClothingRepository';
import { OutfitRepository } from '../repositories/OutfitRepository';
import { SearchRepository } from '../repositories/SearchRepository';
import { StoreRepository } from '../repositories/StoreRepository';
import { WearLogRepository } from '../repositories/WearLogRepository';
import { WishlistRepository } from '../repositories/WishlistRepository';
import {
  buildClothingSearchDocument,
  buildOutfitSearchDocument,
  buildStoreSearchDocument,
  buildStoreVisitSearchDocument,
  buildWearLogSearchDocument,
  buildWishlistSearchDocument,
  SearchDocument
} from '../../domain/search/SearchDocumentBuilder';
import { ClothingItem } from '../../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../../domain/outfit/OutfitModels';

export interface SearchIndexBootstrapDependencies {
  searchRepository: SearchRepository;
  clothingRepository: ClothingRepository;
  outfitRepository: OutfitRepository;
  wearLogRepository: WearLogRepository;
  wishlistRepository: WishlistRepository;
  storeRepository: StoreRepository;
}

export class SearchIndexBootstrap {
  static async rebuild(dependencies: SearchIndexBootstrapDependencies): Promise<void> {
    const clothingItems = await dependencies.clothingRepository.listClothing();
    const outfits = await dependencies.outfitRepository.listOutfits();
    const wearLogs = await dependencies.wearLogRepository.listWearLogs();
    const wishlistItems = await dependencies.wishlistRepository.listWishlistItems();
    const stores = await dependencies.storeRepository.listStores();
    const storeVisits = await dependencies.storeRepository.listStoreVisits();
    const clothingNameById = buildClothingNameById(clothingItems);
    const documents: SearchDocument[] = [];

    for (const item of clothingItems) {
      documents.push(buildClothingSearchDocument(item));
    }

    for (const outfit of outfits) {
      documents.push(buildOutfitSearchDocument(outfit, clothingNamesForOutfit(outfit, clothingNameById)));
    }

    for (const wearLog of wearLogs) {
      documents.push(buildWearLogSearchDocument(wearLog));
    }

    for (const item of wishlistItems) {
      documents.push(buildWishlistSearchDocument(item));
    }

    for (const store of stores) {
      documents.push(buildStoreSearchDocument(store));
    }

    for (const visit of storeVisits) {
      documents.push(buildStoreVisitSearchDocument(visit));
    }

    await dependencies.searchRepository.rebuildSearchIndex(documents);
  }
}

function buildClothingNameById(clothingItems: ClothingItem[]): Map<string, string> {
  const clothingNameById = new Map<string, string>();
  for (const item of clothingItems) {
    clothingNameById.set(item.id, item.name);
  }
  return clothingNameById;
}

function clothingNamesForOutfit(outfit: OutfitTemplate, clothingNameById: Map<string, string>): string[] {
  const names: string[] = [];
  for (const itemId of outfit.clothingItemIds) {
    const name = clothingNameById.get(itemId);
    if (name !== undefined) {
      names.push(name);
    }
  }
  return names;
}
