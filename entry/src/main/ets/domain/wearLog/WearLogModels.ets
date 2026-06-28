export interface WearLog {
  id: string;
  outfitTemplateId: string;
  outfitTitleSnapshot: string;
  clothingItemIdsSnapshot: string[];
  wornDate: string;
  photoUris: string[];
  placeText?: string;
  note?: string;
  createdAt: string;
  updatedAt: string;
}
