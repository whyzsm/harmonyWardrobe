import { ClothingItem } from '../domain/clothing/ClothingModels';

export enum AppMainTab {
  Wardrobe = 'wardrobe',
  Store = 'store',
  Outfit = 'outfit',
  Profile = 'profile'
}

export enum AppRouteKind {
  Main = 'main',
  QuickCapture = 'quickCapture',
  CaptureEditor = 'captureEditor',
  ClothingEditor = 'clothingEditor',
  OutfitEditor = 'outfitEditor',
  StoreEditor = 'storeEditor',
  Wishlist = 'wishlist'
}

export interface AppRouteParams {
  wardrobeTab: string;
  outfitId: string;
  storeVisitId: string;
  storeQuery: string;
  wearLogId: string;
  wishlistItemId: string;
  quickCaptureSourceRouteKind: AppRouteKind;
  capturePhotoUris: string[];
  captureCapturedAt: string;
  captureClothingItems: ClothingItem[];
  outfitClothingItems: ClothingItem[];
}

export interface AppRoute {
  kind: AppRouteKind;
  mainTab: AppMainTab;
  params: AppRouteParams;
}

export function createDefaultAppRouteParams(): AppRouteParams {
  return {
    wardrobeTab: '衣裤',
    outfitId: '',
    storeVisitId: '',
    storeQuery: '',
    wearLogId: '',
    wishlistItemId: '',
    quickCaptureSourceRouteKind: AppRouteKind.Main,
    capturePhotoUris: [],
    captureCapturedAt: '',
    captureClothingItems: [],
    outfitClothingItems: []
  };
}

export function createAppRoute(kind: AppRouteKind, mainTab: AppMainTab, params: AppRouteParams): AppRoute {
  return { kind, mainTab, params };
}

export function createInitialAppRoute(): AppRoute {
  return createAppRoute(AppRouteKind.Main, AppMainTab.Wardrobe, createDefaultAppRouteParams());
}
