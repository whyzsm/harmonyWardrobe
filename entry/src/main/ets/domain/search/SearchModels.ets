export enum SearchEntityType {
  Clothing = 'clothing',
  Outfit = 'outfit',
  WearLog = 'wearLog',
  Wishlist = 'wishlist'
}

export interface SearchResult {
  entityType: SearchEntityType;
  entityId: string;
  title: string;
}
