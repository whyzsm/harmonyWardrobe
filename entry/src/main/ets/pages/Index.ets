import common from '@ohos.app.ability.common';
import { WardrobeRuntime } from '../app/WardrobeRuntime';
import { TodayPage } from './TodayPage';
import { WardrobePage } from './WardrobePage';
import { OutfitsPage } from './OutfitsPage';
import { CalendarPage } from './CalendarPage';
import { ShoppingPage } from './ShoppingPage';
import { AppTheme } from '../theme/Tokens';

@Entry
@Component
struct Index {
  @State private runtimeReady: boolean = false;
  @State private errorMessage: string = '';
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
    } else {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          TodayPage({
            outfitRepository: this.runtime.outfitRepository,
            wearLogRepository: this.runtime.wearLogRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
        }
        .tabBar('今日')

        TabContent() {
          WardrobePage({
            clothingRepository: this.runtime.clothingRepository,
            searchRepository: this.runtime.searchRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
        }
        .tabBar('衣橱')

        TabContent() {
          OutfitsPage({
            outfitRepository: this.runtime.outfitRepository,
            clothingRepository: this.runtime.clothingRepository,
            wearLogRepository: this.runtime.wearLogRepository,
            searchRepository: this.runtime.searchRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
        }
        .tabBar('套装')

        TabContent() {
          CalendarPage({
            outfitRepository: this.runtime.outfitRepository,
            wearLogRepository: this.runtime.wearLogRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
        }
        .tabBar('日历')

        TabContent() {
          ShoppingPage({
            wishlistRepository: this.runtime.wishlistRepository,
            searchRepository: this.runtime.searchRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage
          })
        }
        .tabBar('逛街')
      }
      .width('100%')
      .height('100%')
      .barMode(BarMode.Fixed)
      .backgroundColor(AppTheme.color.surfaceMuted)
    }
  }
}
