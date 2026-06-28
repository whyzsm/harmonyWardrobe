export interface WishlistItem {
  id: string;
  title: string;
  photoUris: string[];
  storeName?: string;
  price?: number;
  note?: string;
  createdAt: string;
  updatedAt: string;
}
