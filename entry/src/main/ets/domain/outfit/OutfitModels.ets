export enum OutfitDisplaySource {
  Photo = 'photo',
  Wardrobe = 'wardrobe'
}

export interface OutfitTemplate {
  id: string;
  title: string;
  photoUris: string[];
  clothingItemIds: string[];
  displaySource: OutfitDisplaySource;
  note?: string;
  createdAt: string;
  updatedAt: string;
}
