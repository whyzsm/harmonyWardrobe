export enum OutfitDisplaySource {
  Photo = 'photo',
  Wardrobe = 'wardrobe'
}

export const OUTFIT_CATEGORY_MAX_LENGTH: number = 12;

export interface OutfitCategory {
  id: string;
  name: string;
  usageCount: number;
}

export interface OutfitTemplate {
  id: string;
  title: string;
  photoUris: string[];
  clothingItemIds: string[];
  displaySource: OutfitDisplaySource;
  categoryId?: string;
  categoryName?: string;
  note?: string;
  createdAt: string;
  updatedAt: string;
}
