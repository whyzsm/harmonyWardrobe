import common from '@ohos.app.ability.common';
import { AppTopBar } from '../components/AppTopBar';
import { BottomNavigationBar } from '../components/BottomNavigationBar';
import { QuickCaptureSheet } from '../components/QuickCaptureSheet';
import { WardrobeRuntime } from '../app/WardrobeRuntime';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { StoreVisit } from '../domain/store/StoreModels';
import { AppTheme, YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';
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
  @State private quickActionErrorMessage: string = '';
  @State private quickActionClothingItems: ClothingItem[] = [];
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
      const context = getContext(this) as common.Context;
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

  private openAddClothing(): void {
    this.showQuickActions = false;
    this.quickActionErrorMessage = '';
    this.showClothingEditor = true;
  }

  private async openCreateOutfit(): Promise<void> {
    if (this.runtime === undefined) {
      return;
    }

    this.showQuickActions = false;
    this.quickActionErrorMessage = '';

    try {
      this.quickActionClothingItems = await this.runtime.clothingRepository.listClothing();
      this.showOutfitEditor = true;
    } catch (error) {
      this.quickActionErrorMessage = error instanceof Error ? error.message : '打开拍搭配失败';
    }
  }

  private openCreateStoreVisit(): void {
    this.showQuickActions = false;
    this.quickActionErrorMessage = '';
    this.selectedMainTab = 'store';
    this.showStoreVisitEditor = true;
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
            .fontColor(AppTheme.color.danger)

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
      .backgroundColor(YibuqueColor.bgBlueGray)
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
          AppTopBar({
            onOpenProfile: () => {
              this.showProfilePage = true;
              this.showQuickActions = false;
            }
          })

          if (this.selectedMainTab === 'wardrobe') {
            WardrobePage({
              clothingRepository: this.runtime.clothingRepository,
              outfitRepository: this.runtime.outfitRepository,
              searchRepository: this.runtime.searchRepository,
              photoPickerAdapter: this.runtime.photoPickerAdapter,
              photoStorage: this.runtime.photoStorage
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
              .fontColor(AppTheme.color.danger)
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
              this.showQuickActions = false;
              this.quickActionErrorMessage = '';
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(YibuqueColor.bgDefault)

        if (this.showQuickActions) {
          QuickCaptureSheet({
            onCapturePhoto: () => {
              this.openAddClothing();
            },
            onPickPhoto: () => {
              this.openCreateOutfit();
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
