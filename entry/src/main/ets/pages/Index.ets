import common from '@ohos.app.ability.common';
import { BottomNavigationBar } from '../components/BottomNavigationBar';
import { QuickCaptureSheet } from '../components/QuickCaptureSheet';
import { WardrobeRuntime } from '../app/WardrobeRuntime';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { SearchEntityType } from '../domain/search/SearchModels';
import { StoreVisit } from '../domain/store/StoreModels';
import { PhotoSource } from '../media/PhotoModels';
import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';
import { CaptureEditPage } from './CaptureEditPage';
import { OutfitsPage } from './OutfitsPage';
import { ProfilePage } from './ProfilePage';
import { StoreVisitEditPage } from './StoreVisitEditPage';
import { StoreVisitPage } from './StoreVisitPage';
import { WardrobePage } from './WardrobePage';
import { ShoppingPage } from './ShoppingPage';

@Entry
@Component
struct Index {
  @State private runtimeReady: boolean = false;
  @State private errorMessage: string = '';
  @State private selectedMainTab: string = 'wardrobe';
  @State private showQuickActions: boolean = false;
  @State private showCaptureEditor: boolean = false;
  @State private showStoreEditor: boolean = false;
  @State private showQuickStoreEditor: boolean = false;
  @State private showClothingEditor: boolean = false;
  @State private showNestedPage: boolean = false;
  @State private showWishlistPage: boolean = false;
  @State private quickActionErrorMessage: string = '';
  @State private capturePhotoUris: string[] = [];
  @State private captureCapturedAt: string = '';
  @State private captureClothingItems: ClothingItem[] = [];
  @State private initialWardrobeTab: string = '衣裤';
  @State private initialOutfitId: string = '';
  @State private initialStoreVisitId: string = '';
  @State private initialStoreQuery: string = '';
  @State private isCapturing: boolean = false;
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
      this.errorMessage = error instanceof Error ? error.message : '初始化应用失败';
    }
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

    this.captureClothingItems = await this.runtime.clothingRepository.listClothing();
    this.capturePhotoUris = photoUris;
    this.captureCapturedAt = new Date().toISOString();
    this.showCaptureEditor = true;
  }

  private closeCaptureEditor(): void {
    this.showCaptureEditor = false;
    this.capturePhotoUris = [];
    this.captureCapturedAt = '';
    this.captureClothingItems = [];
  }

  private openQuickStoreEditor(): void {
    this.closeCaptureEditor();
    this.selectedMainTab = 'store';
    this.showQuickActions = false;
    this.quickActionErrorMessage = '';
    this.showQuickStoreEditor = true;
  }

  private closeQuickStoreEditor(): void {
    this.showQuickStoreEditor = false;
  }

  private openStoreVisitList(): void {
    this.closeCaptureEditor();
    this.closeQuickStoreEditor();
    this.selectedMainTab = 'store';
    this.showQuickActions = false;
    this.quickActionErrorMessage = '';
  }

  private async startCameraCapture(): Promise<void> {
    if (this.runtime === undefined || this.isCapturing) {
      return;
    }

    this.isCapturing = true;
    this.showQuickActions = false;
    this.quickActionErrorMessage = '';

    try {
      const source = await this.runtime.photoPickerAdapter.captureFromCamera();
      const photoUris = await this.copySourcesToLocalUris([source]);
      await this.openCaptureEditor(photoUris);
    } catch (error) {
      this.quickActionErrorMessage = error instanceof Error ? error.message : '拍照失败，请重试';
    } finally {
      this.isCapturing = false;
    }
  }

  private async startGalleryCapture(): Promise<void> {
    if (this.runtime === undefined || this.isCapturing) {
      return;
    }

    this.isCapturing = true;
    this.showQuickActions = false;
    this.quickActionErrorMessage = '';

    try {
      const sources = await this.runtime.photoPickerAdapter.pickFromGallery({ maxSelectNumber: 6 });
      const photoUris = await this.copySourcesToLocalUris(sources);
      await this.openCaptureEditor(photoUris);
    } catch (error) {
      this.quickActionErrorMessage = error instanceof Error ? error.message : '选择照片失败，请重试';
    } finally {
      this.isCapturing = false;
    }
  }

  private async pickCapturePhotos(): Promise<string[]> {
    if (this.runtime === undefined || this.isCapturing) {
      return [];
    }

    this.isCapturing = true;
    try {
      const sources = await this.runtime.photoPickerAdapter.pickFromGallery({ maxSelectNumber: 6 });
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
          Text('正在初始化本地衣橱...')
            .fontSize(14)
            .fontColor(YibuqueColor.textSecondary)
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(YibuqueColor.bgDefault)
    } else {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.showQuickStoreEditor) {
            StoreVisitEditPage({
              storeRepository: this.runtime.storeRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onSave: (_visit: StoreVisit) => {
                this.closeQuickStoreEditor();
                this.selectedMainTab = 'store';
              },
              onCancel: () => {
                this.closeQuickStoreEditor();
              }
            })
              .layoutWeight(1)
          } else if (this.showWishlistPage) {
            ShoppingPage({
              wishlistRepository: this.runtime.wishlistRepository,
              searchRepository: this.runtime.searchRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage
            })
              .layoutWeight(1)
          } else if (this.showCaptureEditor) {
            CaptureEditPage({
              initialPhotoUris: this.capturePhotoUris,
              capturedAt: this.captureCapturedAt,
              clothingItems: this.captureClothingItems,
              clothingRepository: this.runtime.clothingRepository,
              outfitRepository: this.runtime.outfitRepository,
              storeRepository: this.runtime.storeRepository,
              onChoosePhotos: async (): Promise<string[]> => {
                return await this.pickCapturePhotos();
              },
              onCancel: () => {
                this.closeCaptureEditor();
              },
              onSave: (target: string) => {
                this.closeCaptureEditor();
                if (target === '店铺') {
                  this.selectedMainTab = 'store';
                } else if (target === '美搭') {
                  this.selectedMainTab = 'outfit';
                } else {
                  this.initialWardrobeTab = '衣裤';
                  this.selectedMainTab = 'wardrobe';
                }
              }
            })
              .layoutWeight(1)
          } else if (this.selectedMainTab === 'wardrobe') {
            WardrobePage({
              clothingRepository: this.runtime.clothingRepository,
              outfitRepository: this.runtime.outfitRepository,
              wearLogRepository: this.runtime.wearLogRepository,
              searchRepository: this.runtime.searchRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              initialWardrobeTab: this.initialWardrobeTab,
              onOpenCapture: () => {
                this.startCameraCapture();
              },
              onClothingEditorVisibilityChange: (visible: boolean) => {
                this.showClothingEditor = visible;
              },
              onNestedPageVisibilityChange: (visible: boolean) => {
                this.showNestedPage = visible;
              },
              onOpenSearchTarget: (entityType: SearchEntityType, id: string, title: string) => {
                this.showNestedPage = false;
                if (entityType === SearchEntityType.Outfit) {
                  this.initialOutfitId = id;
                  this.initialStoreVisitId = '';
                  this.initialStoreQuery = '';
                  this.selectedMainTab = 'outfit';
                } else if (entityType === SearchEntityType.Store || entityType === SearchEntityType.StoreVisit) {
                  this.initialOutfitId = '';
                  this.initialStoreVisitId = entityType === SearchEntityType.StoreVisit ? id : '';
                  this.initialStoreQuery = entityType === SearchEntityType.Store ? title : '';
                  this.selectedMainTab = 'store';
                } else if (entityType === SearchEntityType.Wishlist) {
                  this.initialOutfitId = '';
                  this.initialStoreVisitId = '';
                  this.initialStoreQuery = '';
                  this.selectedMainTab = 'profile';
                  this.showWishlistPage = true;
                } else if (entityType === SearchEntityType.WearLog) {
                  this.initialOutfitId = '';
                  this.initialStoreVisitId = '';
                  this.initialStoreQuery = '';
                  this.showWishlistPage = false;
                  this.initialWardrobeTab = '日历';
                  this.selectedMainTab = 'wardrobe';
                } else {
                  this.initialOutfitId = '';
                  this.initialStoreVisitId = '';
                  this.initialStoreQuery = '';
                  this.selectedMainTab = 'profile';
                }
              }
            })
              .layoutWeight(1)
          } else if (this.selectedMainTab === 'store') {
            StoreVisitPage({
              initialVisitId: this.initialStoreVisitId,
              initialSearchQuery: this.initialStoreQuery,
              storeRepository: this.runtime.storeRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onEditorVisibilityChange: (visible: boolean) => {
                this.showStoreEditor = visible;
              }
            })
              .layoutWeight(1)
          } else if (this.selectedMainTab === 'outfit') {
            OutfitsPage({
              initialOutfitId: this.initialOutfitId,
              outfitRepository: this.runtime.outfitRepository,
              clothingRepository: this.runtime.clothingRepository,
              wearLogRepository: this.runtime.wearLogRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              onNestedPageVisibilityChange: (visible: boolean) => {
                this.showNestedPage = visible;
              }
            })
              .layoutWeight(1)
          } else {
            ProfilePage({
              profileRepository: this.runtime.profileRepository,
              clothingRepository: this.runtime.clothingRepository,
              storeRepository: this.runtime.storeRepository,
              outfitRepository: this.runtime.outfitRepository,
              onOpenStoreEditor: () => {
                this.openQuickStoreEditor();
              },
              onOpenCapture: () => {
                this.showQuickActions = true;
                this.quickActionErrorMessage = '';
              },
              onOpenOutfits: () => {
                this.selectedMainTab = 'outfit';
                this.showQuickActions = false;
                this.quickActionErrorMessage = '';
              },
              onOpenWishlist: () => {
                this.showWishlistPage = true;
                this.showQuickActions = false;
                this.quickActionErrorMessage = '';
              },
              onNestedPageVisibilityChange: (visible: boolean) => {
                this.showNestedPage = visible;
              }
            })
              .layoutWeight(1)
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
        .backgroundColor('#FFFFFF')

        if (!this.showCaptureEditor && !this.showStoreEditor && !this.showQuickStoreEditor && !this.showClothingEditor && !this.showNestedPage && !this.showQuickActions && !this.showWishlistPage) {
          BottomNavigationBar({
            selected: this.showCaptureEditor ? 'capture' : this.selectedMainTab,
            onSelectWardrobe: () => {
              this.closeCaptureEditor();
              this.showWishlistPage = false;
              this.initialOutfitId = '';
              this.initialStoreVisitId = '';
              this.initialStoreQuery = '';
              this.selectedMainTab = 'wardrobe';
              this.initialWardrobeTab = '衣裤';
              this.showQuickActions = false;
              this.quickActionErrorMessage = '';
            },
            onOpenCapture: () => {
              this.showQuickActions = true;
              this.quickActionErrorMessage = '';
            },
            onSelectStore: () => {
              this.showWishlistPage = false;
              this.initialStoreVisitId = '';
              this.initialStoreQuery = '';
              this.openStoreVisitList();
            },
            onSelectOutfit: () => {
              this.closeCaptureEditor();
              this.showWishlistPage = false;
              this.initialOutfitId = '';
              this.selectedMainTab = 'outfit';
              this.showQuickActions = false;
              this.quickActionErrorMessage = '';
            },
            onOpenProfile: () => {
              this.closeCaptureEditor();
              this.showWishlistPage = false;
              this.selectedMainTab = 'profile';
              this.showQuickActions = false;
              this.quickActionErrorMessage = '';
            }
          })
        }

        if (this.showQuickActions) {
          QuickCaptureSheet({
            onTakePhoto: () => {
              this.startCameraCapture();
            },
            onPickGallery: () => {
              this.startGalleryCapture();
            },
            onCancel: () => {
              this.showQuickActions = false;
            }
          })
        }
      }
      .width('100%')
      .height('100%')
    }
  }

}
