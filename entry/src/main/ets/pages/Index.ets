import common from '@ohos.app.ability.common';
import { AppTopBar } from '../components/AppTopBar';
import { BottomNavigationBar } from '../components/BottomNavigationBar';
import { QuickCaptureSheet } from '../components/QuickCaptureSheet';
import { WardrobeRuntime } from '../app/WardrobeRuntime';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { StoreVisit } from '../domain/store/StoreModels';
import { PhotoSource } from '../media/PhotoModels';
import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';
import { CaptureEditPage } from './CaptureEditPage';
import { ClothingEditPage } from './ClothingEditPage';
import { OutfitEditPage } from './OutfitEditPage';
import { ProfilePage } from './ProfilePage';
import { StoreVisitEditPage } from './StoreVisitEditPage';
import { StoreVisitPage } from './StoreVisitPage';
import { WardrobePage } from './WardrobePage';

@Entry
@Component
struct Index {
  @State private runtimeReady: boolean = false;
  @State private errorMessage: string = '';
  @State private selectedMainTab: string = 'wardrobe';
  @State private showQuickActions: boolean = false;
  @State private showClothingEditor: boolean = false;
  @State private showOutfitEditor: boolean = false;
  @State private showStoreVisitEditor: boolean = false;
  @State private showProfilePage: boolean = false;
  @State private showCaptureEditor: boolean = false;
  @State private quickActionErrorMessage: string = '';
  @State private quickActionClothingItems: ClothingItem[] = [];
  @State private capturePhotoUris: string[] = [];
  @State private captureCapturedAt: string = '';
  @State private captureClothingItems: ClothingItem[] = [];
  @State private initialWardrobeTab: string = '衣裤';
  @State private isCapturing: boolean = false;
  @State private showWardrobeDetailTopBar: boolean = false;
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

  private closeQuickEditors(): void {
    this.showClothingEditor = false;
    this.showOutfitEditor = false;
    this.showStoreVisitEditor = false;
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

  build() {
    if (!this.runtimeReady || this.runtime === undefined) {
      Column({ space: 12 }) {
        Text('衣不缺')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#EF4444')

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
      .linearGradient({
        angle: 135,
        colors: [[YibuqueColor.bgDefault, 0], [YibuqueColor.bgHeaderBlue, 1]]
      })
    } else if (this.showClothingEditor) {
      ClothingEditPage({
        clothingRepository: this.runtime.clothingRepository,
        photoPickerAdapter: this.runtime.photoPickerAdapter,
        photoStorage: this.runtime.photoStorage,
        onSave: (_item: ClothingItem) => {
          this.closeQuickEditors();
          this.selectedMainTab = 'wardrobe';
        },
        onCancel: () => {
          this.closeQuickEditors();
        }
      })
    } else if (this.showOutfitEditor) {
      OutfitEditPage({
        clothingItems: this.quickActionClothingItems,
        outfitRepository: this.runtime.outfitRepository,
        photoPickerAdapter: this.runtime.photoPickerAdapter,
        photoStorage: this.runtime.photoStorage,
        onSave: (_outfit: OutfitTemplate) => {
          this.closeQuickEditors();
          this.selectedMainTab = 'wardrobe';
        },
        onCancel: () => {
          this.closeQuickEditors();
        }
      })
    } else if (this.showStoreVisitEditor) {
      StoreVisitEditPage({
        storeRepository: this.runtime.storeRepository,
        photoPickerAdapter: this.runtime.photoPickerAdapter,
        photoStorage: this.runtime.photoStorage,
        onSave: (_visit: StoreVisit) => {
          this.closeQuickEditors();
          this.selectedMainTab = 'store';
        },
        onCancel: () => {
          this.closeQuickEditors();
        }
      })
    } else if (this.showCaptureEditor) {
      CaptureEditPage({
        initialPhotoUris: this.capturePhotoUris,
        capturedAt: this.captureCapturedAt,
        clothingItems: this.captureClothingItems,
        clothingRepository: this.runtime.clothingRepository,
        outfitRepository: this.runtime.outfitRepository,
        storeRepository: this.runtime.storeRepository,
        wearLogRepository: this.runtime.wearLogRepository,
        onSave: (target: string) => {
          this.closeCaptureEditor();
          if (target === '店铺') {
            this.selectedMainTab = 'store';
          } else if (target === '美搭') {
            this.initialWardrobeTab = '美搭';
            this.selectedMainTab = 'wardrobe';
          } else {
            this.initialWardrobeTab = '衣裤';
            this.selectedMainTab = 'wardrobe';
          }
        },
        onCancel: () => {
          this.closeCaptureEditor();
        }
      })
    } else if (this.showProfilePage) {
      ProfilePage({
        profileRepository: this.runtime.profileRepository,
        onClose: () => {
          this.showProfilePage = false;
        }
      })
    } else {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (!(this.selectedMainTab === 'wardrobe' && this.showWardrobeDetailTopBar)) {
            AppTopBar({
              onOpenProfile: () => {
                this.showProfilePage = true;
                this.showQuickActions = false;
              }
            })
          }

          if (this.selectedMainTab === 'wardrobe') {
            WardrobePage({
              clothingRepository: this.runtime.clothingRepository,
              outfitRepository: this.runtime.outfitRepository,
              wearLogRepository: this.runtime.wearLogRepository,
              searchRepository: this.runtime.searchRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage,
              initialWardrobeTab: this.initialWardrobeTab,
              onDetailModeChange: (showDetailTopBar: boolean) => {
                this.showWardrobeDetailTopBar = showDetailTopBar;
              }
            })
              .layoutWeight(1)
          } else {
            StoreVisitPage({
              storeRepository: this.runtime.storeRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage
            })
              .layoutWeight(1)
          }

          if (this.quickActionErrorMessage.length > 0) {
            Text(this.quickActionErrorMessage)
              .width('100%')
              .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: 8, bottom: 8 })
              .fontSize(13)
              .fontColor('#EF4444')
              .backgroundColor(YibuqueColor.cardWhite)
          }

          BottomNavigationBar({
            selected: this.selectedMainTab,
            onSelectWardrobe: () => {
              this.selectedMainTab = 'wardrobe';
              this.showQuickActions = false;
              this.quickActionErrorMessage = '';
            },
            onOpenCapture: () => {
              this.showQuickActions = true;
            },
            onSelectStore: () => {
              this.selectedMainTab = 'store';
              this.showWardrobeDetailTopBar = false;
              this.showQuickActions = false;
              this.quickActionErrorMessage = '';
            }
          })
        }
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [[YibuqueColor.bgDefault, 0], [YibuqueColor.bgHeaderBlue, 1]]
        })

        if (this.showQuickActions) {
          QuickCaptureSheet({
            onCapturePhoto: () => {
              this.startCameraCapture();
            },
            onPickPhoto: () => {
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
