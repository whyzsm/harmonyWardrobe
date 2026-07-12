export interface Store {
  id: string;
  name: string;
  districtOrAddress?: string;
  photoUris: string[];
  note?: string;
  createdAt: string;
  updatedAt: string;
}

export enum StoreVisitStatus {
  Visited = 'visited',
  WantToVisit = 'wantToVisit',
  Repurchase = 'repurchase'
}

export interface StoreVisit {
  id: string;
  storeId?: string;
  storeNameSnapshot: string;
  districtOrAddress?: string;
  visitDate: string;
  photoUris: string[];
  status?: StoreVisitStatus;
  focusTags?: string[];
  note?: string;
  createdAt: string;
  updatedAt: string;
}
