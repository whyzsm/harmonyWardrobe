export interface WearLog {
  id: string;
  outfitTemplateId: string;
  wornDate: string;
  photoUris: string[];
  placeText?: string;
  note?: string;
  createdAt: string;
  updatedAt: string;
}
