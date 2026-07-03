export enum SearchEntityType {
  Clothing = 'clothing',
  Outfit = 'outfit',
  WearLog = 'wearLog',
  Wishlist = 'wishlist',
  Store = 'store',
  StoreVisit = 'storeVisit'
}

export interface SearchResult {
  entityType: SearchEntityType;
  entityId: string;
  title: string;
}
