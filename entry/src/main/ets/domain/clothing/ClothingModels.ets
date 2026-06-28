import { ClothingCategory } from './ClothingCategory';

export interface PurchaseInfo {
  storeName?: string;
  price?: number;
  purchaseDate?: string;
  note?: string;
}

export interface ClothingItem {
  id: string;
  name: string;
  category: ClothingCategory;
  photoUris: string[];
  note?: string;
  purchaseInfo?: PurchaseInfo;
  createdAt: string;
  updatedAt: string;
}
