import common from '@ohos.app.ability.common';
import { WardrobeRuntime } from '../app/WardrobeRuntime';
import { HomeRecommendation, TodayPage } from './TodayPage';
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
  @State private showRecommendationDetail: boolean = false;
  @State private activeRecommendation: HomeRecommendation = {
    id: '',
    title: '',
    subtitle: '',
    imageUri: '',
    imageUris: [],
    placeholder: '',
    authorName: '',
    authorAvatarText: '',
    body: '',
    likeText: '',
    collectText: '',
    commentText: ''
  };
  @State private recommendationImageIndex: number = 0;
  @State private quickActionErrorMessage: string = '';
  @State private quickActionClothingItems: ClothingItem[] = [];
  @State private quickActionOutfits: OutfitTemplate[] = [];
  private recommendationSwiperController: SwiperController = new SwiperController();
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

  private openRecommendationDetail(recommendation: HomeRecommendation): void {
    this.activeRecommendation = recommendation;
    this.recommendationImageIndex = 0;
    this.showRecommendationDetail = true;
    this.showQuickActions = false;
  }

  private closeRecommendationDetail(): void {
    this.showRecommendationDetail = false;
  }

  private activeRecommendationImages(): string[] {
    if (this.activeRecommendation.imageUris.length > 0) {
      return this.activeRecommendation.imageUris;
    }

    if (this.activeRecommendation.imageUri.length > 0) {
      return [this.activeRecommendation.imageUri];
    }

    return [];
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
            clothingRepository: this.runtime.clothingRepository,
            outfitRepository: this.runtime.outfitRepository,
            wearLogRepository: this.runtime.wearLogRepository,
            photoPickerAdapter: this.runtime.photoPickerAdapter,
            photoStorage: this.runtime.photoStorage,
            onOpenRecommendation: (recommendation: HomeRecommendation) => {
              this.openRecommendationDetail(recommendation);
            }
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

          this.BottomNavigationBar()
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

        if (this.showRecommendationDetail) {
          this.RecommendationDetailPage()
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  BottomNavigationBar() {
    Row() {
      this.BottomTabItem(0, '首页')
      this.BottomTabItem(1, '衣橱')
      this.RudderActionTab()
      this.BottomTabItem(2, '日历')
      this.BottomTabItem(3, '逛街')
    }
    .width('100%')
    .height(78)
    .padding({ left: 8, right: 8, top: 6, bottom: 12 })
    .backgroundColor(AppTheme.color.surface)
    .border({ width: { top: 1 }, color: AppTheme.color.border })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  BottomTabItem(index: number, title: string) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(this.selectedTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.selectedTabIndex === index ? AppTheme.color.primaryStrong : AppTheme.color.textMuted)
    }
    .layoutWeight(1)
    .height('100%')
    .backgroundColor('#00000000')
    .responseRegion({ x: 0, y: -6, width: '100%', height: 78 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.selectTab(index);
    })
  }

  @Builder
  RudderActionTab() {
    Column() {
      Image($r('app.media.activePlus'))
        .width(44)
        .height(40)
        .objectFit(ImageFit.Contain)
    }
    .layoutWeight(1)
    .height('100%')
    .backgroundColor('#00000000')
    .responseRegion({ x: 0, y: -6, width: '100%', height: 78 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.showQuickActions = true;
    })
  }

  @Builder
  RecommendationDetailPage() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Text('‹')
            .fontSize(38)
            .fontColor(AppTheme.color.text)
        }
        .width(44)
        .height(56)
        .onClick(() => {
          this.closeRecommendationDetail();
        })

        Row({ space: 10 }) {
          Text(this.activeRecommendation.authorAvatarText)
            .width(42)
            .height(42)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.primary)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppTheme.color.primarySoft)
            .borderRadius(21)

          Text(this.activeRecommendation.authorName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.text)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        Button('关注')
          .height(38)
          .width(78)
          .fontSize(16)
          .fontColor(AppTheme.color.accent)
          .backgroundColor(AppTheme.color.surface)
          .border({ width: 1, color: AppTheme.color.accent })
          .borderRadius(20)

        Text('↗')
          .width(44)
          .height(56)
          .fontSize(32)
          .fontColor(AppTheme.color.text)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(74)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(AppTheme.color.surface)

      Scroll() {
        Column() {
          if (this.activeRecommendationImages().length > 0) {
            Swiper(this.recommendationSwiperController) {
              ForEach(this.activeRecommendationImages(), (imageUri: string) => {
                Image(imageUri)
                  .width('100%')
                  .height('100%')
                  .objectFit(ImageFit.Cover)
                  .backgroundColor(AppTheme.color.surfaceMuted)
              }, (imageUri: string) => imageUri)
            }
              .width('100%')
              .aspectRatio(0.78)
              .backgroundColor(AppTheme.color.surfaceMuted)
              .indicator(false)
              .loop(this.activeRecommendationImages().length > 1)
              .autoPlay(this.activeRecommendationImages().length > 1)
              .interval(3000)
              .duration(400)
              .onChange((index: number) => {
                this.recommendationImageIndex = index;
              })
          } else {
            Column({ space: 12 }) {
              Text(this.activeRecommendation.placeholder)
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.color.primary)

              Text(this.activeRecommendation.subtitle)
                .fontSize(16)
                .fontColor(AppTheme.color.textMuted)
            }
            .width('100%')
            .aspectRatio(0.78)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
              .backgroundColor(AppTheme.color.primarySoft)
          }

          if (this.activeRecommendationImages().length > 1) {
            Row({ space: 6 }) {
              ForEach(this.activeRecommendationImages(), (_imageUri: string, index: number) => {
                Circle({ width: 8, height: 8 })
                  .fill(this.recommendationImageIndex === index ? AppTheme.color.accent : AppTheme.color.border)
              }, (_imageUri: string, index: number) => `${index}`)
            }
            .height(30)
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          } else {
            Blank()
              .height(18)
          }

          Column({ space: 12 }) {
            Text(this.activeRecommendation.title)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.color.text)
              .lineHeight(32)
              .width('100%')

            Text(this.activeRecommendation.body)
              .fontSize(19)
              .fontColor(AppTheme.color.text)
              .lineHeight(32)
              .width('100%')

            Text('#今日穿搭 #衣橱灵感 #推荐搭配')
              .fontSize(15)
              .fontColor(AppTheme.color.primary)
              .width('100%')
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 6, bottom: 24 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)

      Row({ space: 18 }) {
        Row({ space: 8 }) {
          Text('✎')
            .fontSize(22)
            .fontColor(AppTheme.color.textMuted)
          Text('说点什么...')
            .fontSize(18)
            .fontColor(AppTheme.color.textMuted)
        }
        .height(52)
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .backgroundColor(AppTheme.color.surfaceMuted)
        .borderRadius(26)

        Text(`♡ ${this.activeRecommendation.likeText}`)
          .fontSize(20)
          .fontColor(AppTheme.color.text)

        Text(`☆ ${this.activeRecommendation.collectText}`)
          .fontSize(20)
          .fontColor(AppTheme.color.text)

        Text(`☁ ${this.activeRecommendation.commentText}`)
          .fontSize(20)
          .fontColor(AppTheme.color.text)
      }
      .width('100%')
      .height(82)
      .padding({ left: 16, right: 16, top: 10, bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(AppTheme.color.surface)
      .border({ width: { top: 1 }, color: AppTheme.color.border })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.color.surface)
  }
}
