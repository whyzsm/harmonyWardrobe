export interface Store {
  id: string;
  name: string;
  districtOrAddress?: string;
  photoUris: string[];
  note?: string;
  createdAt: string;
  updatedAt: string;
}

export interface StoreVisit {
  id: string;
  storeId?: string;
  storeNameSnapshot: string;
  districtOrAddress?: string;
  visitDate: string;
  photoUris: string[];
  note?: string;
  createdAt: string;
  updatedAt: string;
}
