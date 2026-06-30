import common from '@ohos.app.ability.common';
import { WardrobeRuntime } from '../app/WardrobeRuntime';
import { TodayPage } from './TodayPage';
import { WardrobePage } from './WardrobePage';
import { CalendarPage } from './CalendarPage';
import { ShoppingPage } from './ShoppingPage';
import { AppTheme } from '../theme/Tokens';
import { ClothingEditPage } from './ClothingEditPage';
import { OutfitEditPage } from './OutfitEditPage';
import { WearLogEditPage } from './WearLogEditPage';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { WearLog } from '../domain/wearLog/WearLogModels';

@Entry
@Component
struct Index {
  @State private runtimeReady: boolean = false;
  @State private errorMessage: string = '';
  @State private selectedTabIndex: number = 0;
  @State private showQuickActions: boolean = false;
  @State private showClothingEditor: boolean = false;
  @State private showOutfitEditor: boolean = false;
  @State private showWearLogEditor: boolean = false;
  @State private quickActionErrorMessage: string = '';
  @State private quickActionClothingItems: ClothingItem[] = [];
  @State private quickActionOutfits: OutfitTemplate[] = [];
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

  private selectTab(index: number): void {
    this.selectedTabIndex = index;
    this.showQuickActions = false;
    this.quickActionErrorMessage = '';
  }

  private closeQuickEditors(): void {
    this.showClothingEditor = false;
    this.showOutfitEditor = false;
    this.showWearLogEditor = false;
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
      this.quickActionErrorMessage = error instanceof Error ? error.message : '打开创建套装失败';
    }
  }

  private async openRecordToday(): Promise<void> {
    if (this.runtime === undefined) {
      return;
    }

    this.showQuickActions = false;
    this.quickActionErrorMessage = '';

    try {
      this.quickActionOutfits = await this.runtime.outfitRepository.listOutfits();
      this.showWearLogEditor = true;
    } catch (error) {
      this.quickActionErrorMessage = error instanceof Error ? error.message : '打开记录今日失败';
    }
  }

  build() {
    if (!this.runtimeReady || this.runtime === undefined) {
      Column({ space: 12 }) {
        Text('Harmony Wardrobe')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.color.text)

        if (this.errorMessage.length > 0) {
          Text(`runtime / ${this.errorMessage}`)
            .fontSize(14)
            .fontColor(AppTheme.color.danger)

          Button('重试')
            .height(40)
            .fontSize(14)
            .fontColor(AppTheme.color.surface)
            .backgroundColor(AppTheme.color.primary)
            .borderRadius(AppTheme.radius.md)
            .onClick(() => {
              this.initializeRuntime();
            })
        } else {
          Text('runtime / 正在初始化本地衣橱...')
            .fontSize(14)
            .fontColor(AppTheme.color.textMuted)
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(AppTheme.color.surfaceMuted)
    } else if (this.showClothingEditor) {
      ClothingEditPage({
        clothingRepository: this.runtime.clothingRepository,
        photoPickerAdapter: this.runtime.photoPickerAdapter,
        photoStorage: this.runtime.photoStorage,
        onSave: (_item: ClothingItem) => {
          this.closeQuickEditors();
          this.selectedTabIndex = 1;
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
          this.selectedTabIndex = 0;
        },
        onCancel: () => {
          this.closeQuickEditors();
        }
      })
    } else if (this.showWearLogEditor) {
      WearLogEditPage({
        outfits: this.quickActionOutfits,
        wearLogRepository: this.runtime.wearLogRepository,
        photoPickerAdapter: this.runtime.photoPickerAdapter,
        photoStorage: this.runtime.photoStorage,
        onSave: (_wearLog: WearLog) => {
          this.closeQuickEditors();
          this.selectedTabIndex = 0;
        },
        onCancel: () => {
          this.closeQuickEditors();
        }
      })
    } else {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.selectedTabIndex === 0) {
          TodayPage({
            outfitRepository: this.runtime.outfitRepository,
            wearLogRepository: this.runtime.wearLogRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
            .layoutWeight(1)
          } else if (this.selectedTabIndex === 1) {
          WardrobePage({
            clothingRepository: this.runtime.clothingRepository,
            searchRepository: this.runtime.searchRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
            .layoutWeight(1)
          } else if (this.selectedTabIndex === 2) {
          CalendarPage({
            outfitRepository: this.runtime.outfitRepository,
            wearLogRepository: this.runtime.wearLogRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
            .layoutWeight(1)
          } else {
          ShoppingPage({
            wishlistRepository: this.runtime.wishlistRepository,
            searchRepository: this.runtime.searchRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
            .layoutWeight(1)
          }

          if (this.quickActionErrorMessage.length > 0) {
            Text(this.quickActionErrorMessage)
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .fontSize(13)
              .fontColor(AppTheme.color.danger)
              .backgroundColor(AppTheme.color.surface)
          }

          Row() {
            Text('首页')
              .fontSize(16)
              .fontWeight(this.selectedTabIndex === 0 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.selectedTabIndex === 0 ? AppTheme.color.primary : AppTheme.color.textMuted)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.selectTab(0);
              })

            Text('衣橱')
              .fontSize(16)
              .fontWeight(this.selectedTabIndex === 1 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.selectedTabIndex === 1 ? AppTheme.color.primary : AppTheme.color.textMuted)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.selectTab(1);
              })

            Button('+')
              .width(56)
              .height(48)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.color.surface)
              .backgroundColor(AppTheme.color.primary)
              .borderRadius(16)
              .onClick(() => {
                this.showQuickActions = true;
              })

            Text('日历')
              .fontSize(16)
              .fontWeight(this.selectedTabIndex === 2 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.selectedTabIndex === 2 ? AppTheme.color.primary : AppTheme.color.textMuted)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.selectTab(2);
              })

            Text('逛街')
              .fontSize(16)
              .fontWeight(this.selectedTabIndex === 3 ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.selectedTabIndex === 3 ? AppTheme.color.primary : AppTheme.color.textMuted)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.selectTab(3);
              })
          }
          .width('100%')
          .height(74)
          .padding({ left: 18, right: 18, bottom: 6 })
          .backgroundColor(AppTheme.color.surface)
          .border({ width: 1, color: AppTheme.color.border })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(AppTheme.color.surfaceMuted)

        if (this.showQuickActions) {
          Column() {
            Column()
              .width('100%')
              .layoutWeight(1)
              .onClick(() => {
                this.showQuickActions = false;
              })

            Column({ space: 10 }) {
              Text('快捷添加')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.color.text)

              Button('添加衣服')
                .width('100%')
                .height(46)
                .fontSize(15)
                .fontColor(AppTheme.color.surface)
                .backgroundColor(AppTheme.color.primary)
                .borderRadius(AppTheme.radius.md)
                .onClick(() => {
                  this.openAddClothing();
                })

              Button('创建套装')
                .width('100%')
                .height(46)
                .fontSize(15)
                .fontColor(AppTheme.color.text)
                .backgroundColor(AppTheme.color.primarySoft)
                .borderRadius(AppTheme.radius.md)
                .onClick(() => {
                  this.openCreateOutfit();
                })

              Button('记录今日')
                .width('100%')
                .height(46)
                .fontSize(15)
                .fontColor(AppTheme.color.text)
                .backgroundColor(AppTheme.color.primarySoft)
                .borderRadius(AppTheme.radius.md)
                .onClick(() => {
                  this.openRecordToday();
                })

              Button('取消')
                .width('100%')
                .height(44)
                .fontSize(14)
                .fontColor(AppTheme.color.textMuted)
                .backgroundColor(AppTheme.color.surface)
                .borderRadius(AppTheme.radius.md)
                .border({ width: 1, color: AppTheme.color.border })
                .onClick(() => {
                  this.showQuickActions = false;
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 18, bottom: 28 })
            .backgroundColor(AppTheme.color.surface)
            .borderRadius(AppTheme.radius.lg)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
        }
      }
      .width('100%')
      .height('100%')
    }
  }
}
