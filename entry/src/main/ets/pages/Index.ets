import common from '@ohos.app.ability.common';
import { BottomNavigationBar } from '../components/BottomNavigationBar';
import { QuickCaptureSheet } from '../components/QuickCaptureSheet';
import {
  AppMainTab,
  AppRoute,
  AppRouteKind,
  AppRouteParams,
  createAppRoute,
  createDefaultAppRouteParams,
  createInitialAppRoute
} from '../app/AppRoute';
import { WardrobeRuntime } from '../app/WardrobeRuntime';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { SearchEntityType } from '../domain/search/SearchModels';
import { StoreVisit } from '../domain/store/StoreModels';
import { PhotoSource } from '../media/PhotoModels';
import {
  YibuqueColor,
  YibuqueMotion,
  YibuqueRadius,
  YibuqueSpacing,
  YibuqueTransition
} from '../theme/Tokens';
import { MAX_USER_PHOTOS } from '../utils/photoSelection';
import { userFacingError } from '../utils/userFacingError';
import { CaptureEditPage } from './CaptureEditPage';
import { ClothingEditPage } from './ClothingEditPage';
import { OutfitEditPage } from './OutfitEditPage';
import { OutfitsPage } from './OutfitsPage';
import { ProfilePage } from './ProfilePage';
import { StoreVisitEditPage } from './StoreVisitEditPage';
import { StoreVisitPage } from './StoreVisitPage';
import { WardrobePage } from './WardrobePage';
import { WishlistPage } from './WishlistPage';

@Entry
@Component
struct Index {
  @State private runtimeReady: boolean = false;
  @State private errorMessage: string = '';
  @State private activeRoute: AppRoute = createInitialAppRoute();
  @State private featureNestedContentVisible: boolean = false;
  @State private quickActionErrorMessage: string = '';
  @State private isCapturing: boolean = false;
  @StorageProp('windowTopInsetVp') private windowTopInsetVp: number = 0;
  @StorageProp('windowBottomInsetVp') private windowBottomInsetVp: number = 0;
  private routeTransitionInProgress: boolean = false;
  private runtime?: WardrobeRuntime = undefined;

  aboutToAppear(): void {
    this.initializeRuntime();
  }

  private async initializeRuntime(): Promise<void> {
    if (this.runtimeReady || this.runtime !== undefined) {
      return;
    }

    this.errorMessage = '';

    try {
      const hostContext = this.getUIContext().getHostContext();
      if (hostContext === undefined) {
        throw new Error('应用上下文不可用，请稍后重试');
      }

      const context = hostContext as common.Context;
      this.runtime = await WardrobeRuntime.create(context);
      this.runtimeReady = true;
    } catch (error) {
      this.errorMessage = userFacingError(error, '初始化应用失败');
    }
  }

  private copyCurrentRouteParams(): AppRouteParams {
    const params = this.activeRoute.params;
    return {
      outfitId: params.outfitId,
      storeVisitId: params.storeVisitId,
      storeQuery: params.storeQuery,
      wearLogId: params.wearLogId,
      wishlistItemId: params.wishlistItemId,
      quickCaptureSourceRouteKind: params.quickCaptureSourceRouteKind,
      capturePhotoUris: params.capturePhotoUris.slice(),
      captureCapturedAt: params.captureCapturedAt,
      captureClothingItems: params.captureClothingItems.slice(),
      outfitClothingItems: params.outfitClothingItems.slice()
    };
  }

  private setRouteWithoutTransition(route: AppRoute): void {
    this.activeRoute = route;
    this.featureNestedContentVisible = false;
  }

  private transitionToRoute(route: AppRoute): void {
    if (this.routeTransitionInProgress) {
      return;
    }

    this.routeTransitionInProgress = true;
    this.getUIContext().animateTo({
      duration: YibuqueMotion.fullScreenPageTransition,
      curve: Curve.EaseOut,
      onFinish: () => {
        this.routeTransitionInProgress = false;
      }
    }, () => {
      this.activeRoute = route;
      this.featureNestedContentVisible = false;
    });
  }

  private showMainRoute(mainTab: AppMainTab, params: AppRouteParams): void {
    this.transitionToRoute(createAppRoute(AppRouteKind.Main, mainTab, params));
  }

  private replaceCurrentRouteParams(params: AppRouteParams): void {
    this.activeRoute = createAppRoute(this.activeRoute.kind, this.activeRoute.mainTab, params);
  }

  private consumeOutfitRoute(): void {
    if (this.activeRoute.mainTab !== AppMainTab.Outfit || this.activeRoute.params.outfitId.length === 0) {
      return;
    }

    const params = this.copyCurrentRouteParams();
    params.outfitId = '';
    this.replaceCurrentRouteParams(params);
  }

  private consumeWearLogRoute(): void {
    if (this.activeRoute.mainTab !== AppMainTab.Outfit || this.activeRoute.params.wearLogId.length === 0) {
      return;
    }

    const params = this.copyCurrentRouteParams();
    params.wearLogId = '';
    this.replaceCurrentRouteParams(params);
  }

  private consumeStoreVisitRoute(): void {
    if (this.activeRoute.mainTab !== AppMainTab.Store || this.activeRoute.params.storeVisitId.length === 0) {
      return;
    }

    const params = this.copyCurrentRouteParams();
    params.storeVisitId = '';
    this.replaceCurrentRouteParams(params);
  }

  private consumeWishlistRoute(): void {
    if (this.activeRoute.kind !== AppRouteKind.Wishlist || this.activeRoute.params.wishlistItemId.length === 0) {
      return;
    }

    const params = this.copyCurrentRouteParams();
    params.wishlistItemId = '';
    this.replaceCurrentRouteParams(params);
  }

  private resetMainRoute(mainTab: AppMainTab): void {
    this.showMainRoute(mainTab, createDefaultAppRouteParams());
  }

  private shouldShowBottomNavigation(): boolean {
    return this.activeRoute.kind === AppRouteKind.Main && !this.featureNestedContentVisible;
  }

  private returnToCaptureSource(): void {
    const params = this.copyCurrentRouteParams();
    params.capturePhotoUris = [];
    params.captureCapturedAt = '';
    params.captureClothingItems = [];
    const route = params.quickCaptureSourceRouteKind === AppRouteKind.Wishlist ?
      createAppRoute(AppRouteKind.Wishlist, AppMainTab.Profile, params) :
      createAppRoute(AppRouteKind.Main, this.activeRoute.mainTab, params);

    if (this.activeRoute.kind === AppRouteKind.CaptureEditor) {
      this.transitionToRoute(route);
    } else {
      this.setRouteWithoutTransition(route);
    }
  }

  private openQuickActions(): void {
    const params = this.copyCurrentRouteParams();
    params.quickCaptureSourceRouteKind = this.activeRoute.kind;
    this.setRouteWithoutTransition(createAppRoute(
      AppRouteKind.QuickCapture,
      this.activeRoute.mainTab,
      params
    ));
    this.quickActionErrorMessage = '';
  }

  private openWishlistPage(itemId: string): void {
    const params = createDefaultAppRouteParams();
    params.wishlistItemId = itemId;
    this.transitionToRoute(createAppRoute(AppRouteKind.Wishlist, AppMainTab.Profile, params));
    this.quickActionErrorMessage = '';
  }

  private async copySourcesToLocalUris(sources: PhotoSource[]): Promise<string[]> {
    if (this.runtime === undefined) {
      return [];
    }

    const localUris: string[] = [];
    for (const source of sources) {
      const storedPhoto = await this.runtime.photoStorage.copyToAppStorage(source);
      localUris.push(storedPhoto.localUri);
    }

    return localUris;
  }

  private async openCaptureEditor(photoUris: string[]): Promise<void> {
    if (this.runtime === undefined || photoUris.length === 0) {
      return;
    }

    const params = this.copyCurrentRouteParams();
    params.captureClothingItems = await this.runtime.clothingRepository.listClothing();
    params.capturePhotoUris = photoUris;
    params.captureCapturedAt = new Date().toISOString();
    this.transitionToRoute(createAppRoute(AppRouteKind.CaptureEditor, this.activeRoute.mainTab, params));
  }

  private closeCaptureEditor(): void {
    if (this.activeRoute.kind === AppRouteKind.CaptureEditor) {
      this.returnToCaptureSource();
    }
  }

  private openQuickStoreEditor(): void {
    this.transitionToRoute(createAppRoute(
      AppRouteKind.StoreEditor,
      AppMainTab.Store,
      createDefaultAppRouteParams()
    ));
    this.quickActionErrorMessage = '';
  }

  private closeQuickStoreEditor(): void {
    this.resetMainRoute(AppMainTab.Store);
  }

  private openQuickClothingEditor(): void {
    this.transitionToRoute(createAppRoute(
      AppRouteKind.ClothingEditor,
      AppMainTab.Wardrobe,
      createDefaultAppRouteParams()
    ));
    this.quickActionErrorMessage = '';
  }

  private closeQuickClothingEditor(): void {
    this.resetMainRoute(AppMainTab.Wardrobe);
    this.quickActionErrorMessage = '';
  }

  private async openQuickOutfitEditor(): Promise<void> {
    if (this.runtime === undefined) {
      return;
    }

    const params = createDefaultAppRouteParams();
    this.quickActionErrorMessage = '';
    try {
      params.outfitClothingItems = await this.runtime.clothingRepository.listClothing();
    } catch (error) {
      this.quickActionErrorMessage = userFacingError(error, '加载衣物失败');
    }

    this.transitionToRoute(createAppRoute(AppRouteKind.OutfitEditor, AppMainTab.Outfit, params));
  }

  private closeQuickOutfitEditor(): void {
    this.resetMainRoute(AppMainTab.Outfit);
    this.quickActionErrorMessage = '';
  }

  private openStoreVisitList(): void {
    this.resetMainRoute(AppMainTab.Store);
    this.quickActionErrorMessage = '';
  }

  private async startCameraCapture(): Promise<void> {
    if (this.runtime === undefined || this.isCapturing) {
      return;
    }

    this.isCapturing = true;
    this.returnToCaptureSource();
    this.quickActionErrorMessage = '';

    try {
      const source = await this.runtime.photoPickerAdapter.captureFromCamera();
      const photoUris = await this.copySourcesToLocalUris([source]);
      await this.openCaptureEditor(photoUris);
    } catch (error) {
      this.quickActionErrorMessage = userFacingError(error, '拍照失败，请重试');
    } finally {
      this.isCapturing = false;
    }
  }

  private async startGalleryCapture(): Promise<void> {
    if (this.runtime === undefined || this.isCapturing) {
      return;
    }

    this.isCapturing = true;
    this.returnToCaptureSource();
    this.quickActionErrorMessage = '';

    try {
      const sources = await this.runtime.photoPickerAdapter.pickFromGallery({ maxSelectNumber: MAX_USER_PHOTOS });
      const photoUris = await this.copySourcesToLocalUris(sources);
      await this.openCaptureEditor(photoUris);
    } catch (error) {
      this.quickActionErrorMessage = userFacingError(error, '选择照片失败，请重试');
    } finally {
      this.isCapturing = false;
    }
  }

  private async pickCapturePhotos(maxSelectNumber: number): Promise<string[]> {
    if (this.runtime === undefined || this.isCapturing) {
      return [];
    }

    this.isCapturing = true;
    try {
      const sources = await this.runtime.photoPickerAdapter.pickFromGallery({ maxSelectNumber });
      return await this.copySourcesToLocalUris(sources);
    } finally {
      this.isCapturing = false;
    }
  }

  build() {
    if (!this.runtimeReady || this.runtime === undefined) {
      Column({ space: 12 }) {
        Text('衣不缺')
          .fontSize(28)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(YibuqueColor.danger)

          Button('重试')
            .height(44)
            .fontSize(15)
            .fontColor(YibuqueColor.textInverse)
            .backgroundColor(YibuqueColor.actionBlack)
            .borderRadius(YibuqueRadius.full)
            .onClick(() => {
              this.initializeRuntime();
            })
        } else {
          Text('正在初始化本地衣柜...')
            .fontSize(14)
            .fontColor(YibuqueColor.textSecondary)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.windowTopInsetVp, bottom: this.windowBottomInsetVp })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(YibuqueColor.bgDefault)
    } else {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.activeRoute.kind === AppRouteKind.ClothingEditor) {
            ClothingEditPage({
              clothingRepository: this.runtime.clothingRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onSave: (_item: ClothingItem) => {
                this.closeQuickClothingEditor();
              },
              onCancel: () => {
                this.closeQuickClothingEditor();
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          } else if (this.activeRoute.kind === AppRouteKind.OutfitEditor) {
            OutfitEditPage({
              clothingItems: this.activeRoute.params.outfitClothingItems,
              outfitRepository: this.runtime.outfitRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onSave: (_outfit: OutfitTemplate) => {
                this.closeQuickOutfitEditor();
              },
              onCancel: () => {
                this.closeQuickOutfitEditor();
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          } else if (this.activeRoute.kind === AppRouteKind.StoreEditor) {
            StoreVisitEditPage({
              storeRepository: this.runtime.storeRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onSave: (_visit: StoreVisit) => {
                this.closeQuickStoreEditor();
              },
              onCancel: () => {
                this.closeQuickStoreEditor();
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          } else if (this.activeRoute.kind === AppRouteKind.Wishlist) {
            WishlistPage({
              wishlistRepository: this.runtime.wishlistRepository,
              searchRepository: this.runtime.searchRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              initialWishlistItemId: this.activeRoute.params.wishlistItemId,
              onInitialWishlistItemConsumed: () => {
                this.consumeWishlistRoute();
              },
              onClose: () => {
                this.resetMainRoute(AppMainTab.Profile);
              },
              onBack: () => {
                this.resetMainRoute(AppMainTab.Profile);
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          } else if (this.activeRoute.kind === AppRouteKind.CaptureEditor) {
            CaptureEditPage({
              initialPhotoUris: this.activeRoute.params.capturePhotoUris,
              capturedAt: this.activeRoute.params.captureCapturedAt,
              clothingItems: this.activeRoute.params.captureClothingItems,
              clothingRepository: this.runtime.clothingRepository,
              outfitRepository: this.runtime.outfitRepository,
              storeRepository: this.runtime.storeRepository,
              onChoosePhotos: async (maxSelectNumber: number): Promise<string[]> => {
                return await this.pickCapturePhotos(maxSelectNumber);
              },
              onCancel: () => {
                this.closeCaptureEditor();
              },
              onSave: (target: string) => {
                if (target === '店铺') {
                  this.resetMainRoute(AppMainTab.Store);
                } else if (target === '美搭') {
                  this.resetMainRoute(AppMainTab.Outfit);
                } else {
                  this.resetMainRoute(AppMainTab.Wardrobe);
                }
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          } else if (this.activeRoute.mainTab === AppMainTab.Wardrobe) {
            WardrobePage({
              clothingRepository: this.runtime.clothingRepository,
              outfitRepository: this.runtime.outfitRepository,
              searchRepository: this.runtime.searchRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onOpenCapture: () => {
                this.startCameraCapture();
              },
              onCreateClothing: () => {
                this.openQuickClothingEditor();
              },
              onClothingEditorVisibilityChange: (visible: boolean) => {
                this.featureNestedContentVisible = visible;
              },
              onNestedPageVisibilityChange: (visible: boolean) => {
                this.featureNestedContentVisible = visible;
              },
              onOpenSearchTarget: (entityType: SearchEntityType, id: string, title: string) => {
                if (entityType === SearchEntityType.Outfit) {
                  const params = createDefaultAppRouteParams();
                  params.outfitId = id;
                  this.showMainRoute(AppMainTab.Outfit, params);
                } else if (entityType === SearchEntityType.Store || entityType === SearchEntityType.StoreVisit) {
                  const params = createDefaultAppRouteParams();
                  params.storeVisitId = entityType === SearchEntityType.StoreVisit ? id : '';
                  params.storeQuery = entityType === SearchEntityType.Store ? title : '';
                  this.showMainRoute(AppMainTab.Store, params);
                } else if (entityType === SearchEntityType.Wishlist) {
                  this.openWishlistPage(id);
                } else if (entityType === SearchEntityType.WearLog) {
                  const params = createDefaultAppRouteParams();
                  params.wearLogId = id;
                  this.showMainRoute(AppMainTab.Outfit, params);
                } else {
                  this.resetMainRoute(AppMainTab.Profile);
                }
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          } else if (this.activeRoute.mainTab === AppMainTab.Store) {
            StoreVisitPage({
              initialVisitId: this.activeRoute.params.storeVisitId,
              initialSearchQuery: this.activeRoute.params.storeQuery,
              storeRepository: this.runtime.storeRepository,
              searchRepository: this.runtime.searchRepository,
              clothingRepository: this.runtime.clothingRepository,
              outfitRepository: this.runtime.outfitRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onEditorVisibilityChange: (visible: boolean) => {
                this.featureNestedContentVisible = visible;
              },
              onInitialVisitConsumed: () => {
                this.consumeStoreVisitRoute();
              },
              onCreateStoreVisit: () => {
                this.openQuickStoreEditor();
              },
              onOpenSearchTarget: (entityType: SearchEntityType, id: string, title: string) => {
                if (entityType === SearchEntityType.Clothing) {
                  this.resetMainRoute(AppMainTab.Wardrobe);
                } else if (entityType === SearchEntityType.Outfit) {
                  const params = createDefaultAppRouteParams();
                  params.outfitId = id;
                  this.showMainRoute(AppMainTab.Outfit, params);
                } else if (entityType === SearchEntityType.Store || entityType === SearchEntityType.StoreVisit) {
                  const params = createDefaultAppRouteParams();
                  params.storeVisitId = entityType === SearchEntityType.StoreVisit ? id : '';
                  params.storeQuery = entityType === SearchEntityType.Store ? title : '';
                  this.showMainRoute(AppMainTab.Store, params);
                } else if (entityType === SearchEntityType.Wishlist) {
                  this.openWishlistPage(id);
                } else if (entityType === SearchEntityType.WearLog) {
                  const params = createDefaultAppRouteParams();
                  params.wearLogId = id;
                  this.showMainRoute(AppMainTab.Outfit, params);
                } else {
                  this.resetMainRoute(AppMainTab.Profile);
                }
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          } else if (this.activeRoute.mainTab === AppMainTab.Outfit) {
            OutfitsPage({
              initialOutfitId: this.activeRoute.params.outfitId,
              initialWearLogId: this.activeRoute.params.wearLogId,
              onInitialOutfitConsumed: () => {
                this.consumeOutfitRoute();
              },
              onInitialWearLogConsumed: () => {
                this.consumeWearLogRoute();
              },
              outfitRepository: this.runtime.outfitRepository,
              searchRepository: this.runtime.searchRepository,
              clothingRepository: this.runtime.clothingRepository,
              wearLogRepository: this.runtime.wearLogRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onOpenCapture: () => {
                this.startCameraCapture();
              },
              onCreateOutfit: () => {
                this.openQuickOutfitEditor();
              },
              onOpenSearchTarget: (entityType: SearchEntityType, id: string, title: string) => {
                if (entityType === SearchEntityType.Clothing) {
                  this.resetMainRoute(AppMainTab.Wardrobe);
                } else if (entityType === SearchEntityType.Outfit) {
                  const params = createDefaultAppRouteParams();
                  params.outfitId = id;
                  this.showMainRoute(AppMainTab.Outfit, params);
                } else if (entityType === SearchEntityType.Store || entityType === SearchEntityType.StoreVisit) {
                  const params = createDefaultAppRouteParams();
                  params.storeVisitId = entityType === SearchEntityType.StoreVisit ? id : '';
                  params.storeQuery = entityType === SearchEntityType.Store ? title : '';
                  this.showMainRoute(AppMainTab.Store, params);
                } else if (entityType === SearchEntityType.Wishlist) {
                  this.openWishlistPage(id);
                } else if (entityType === SearchEntityType.WearLog) {
                  const params = createDefaultAppRouteParams();
                  params.wearLogId = id;
                  this.showMainRoute(AppMainTab.Outfit, params);
                } else {
                  this.resetMainRoute(AppMainTab.Profile);
                }
              },
              onNestedPageVisibilityChange: (visible: boolean) => {
                this.featureNestedContentVisible = visible;
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          } else {
            ProfilePage({
              profileRepository: this.runtime.profileRepository,
              clothingRepository: this.runtime.clothingRepository,
              storeRepository: this.runtime.storeRepository,
              outfitRepository: this.runtime.outfitRepository,
              backupService: this.runtime.backupService,
              onOpenWishlist: () => {
                this.openWishlistPage('');
              },
              onNestedPageVisibilityChange: (visible: boolean) => {
                this.featureNestedContentVisible = visible;
              }
            })
              .layoutWeight(1)
              .transition(YibuqueTransition.fullScreenOpacity)
          }

          if (this.quickActionErrorMessage.length > 0) {
            Text(this.quickActionErrorMessage)
              .width('100%')
              .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: 8, bottom: 8 })
              .fontSize(13)
              .fontColor(YibuqueColor.danger)
              .backgroundColor(YibuqueColor.cardWhite)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(YibuqueColor.bgDefault)

        if (this.shouldShowBottomNavigation()) {
          Column() {
            BottomNavigationBar({
              selected: this.activeRoute.mainTab,
              bottomInsetVp: this.windowBottomInsetVp,
              onSelectWardrobe: () => {
                this.resetMainRoute(AppMainTab.Wardrobe);
                this.quickActionErrorMessage = '';
              },
              onOpenCapture: () => {
                this.openQuickActions();
              },
              onSelectStore: () => {
                this.openStoreVisitList();
              },
              onSelectOutfit: () => {
                this.resetMainRoute(AppMainTab.Outfit);
                this.quickActionErrorMessage = '';
              },
              onOpenProfile: () => {
                this.resetMainRoute(AppMainTab.Profile);
                this.quickActionErrorMessage = '';
              }
            })
          }
          .width('100%')
          .padding({ top: 10, bottom: 0 })
          .alignItems(HorizontalAlign.Center)
        }

        if (this.activeRoute.kind === AppRouteKind.QuickCapture) {
          QuickCaptureSheet({
            selectedCategory: this.activeRoute.mainTab,
            bottomInsetVp: this.windowBottomInsetVp,
            onOpenWardrobe: () => {
              this.openQuickClothingEditor();
            },
            onOpenStoreVisit: () => {
              this.openQuickStoreEditor();
            },
            onOpenOutfit: () => {
              this.openQuickOutfitEditor();
            },
            onCancel: () => {
              this.returnToCaptureSource();
            }
          })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.windowTopInsetVp })
      .backgroundColor(YibuqueColor.bgDefault)
    }
  }

}
