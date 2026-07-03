import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { AppTheme, YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';
import { ClothingEditPage } from './ClothingEditPage';
import { OutfitEditPage } from './OutfitEditPage';
import { SearchResultsPage } from './SearchResultsPage';

interface WardrobeCategoryFilter {
  label: string;
  category?: ClothingCategory;
}

const WARDROBE_CATEGORY_FILTERS: WardrobeCategoryFilter[] = [
  { label: '上衣', category: ClothingCategory.Top },
  { label: '裤子', category: ClothingCategory.Pants },
  { label: '短裤', category: ClothingCategory.Shorts },
  { label: '长裙', category: ClothingCategory.LongSkirt },
  { label: '半裙', category: ClothingCategory.HalfSkirt }
];

const WARDROBE_TOP_RESULT_COUNT = 3;
const WARDROBE_HERO_PREVIEW_COUNT = 3;

function categoryLabel(category: ClothingCategory): string {
  for (const filter of WARDROBE_CATEGORY_FILTERS) {
    if (filter.category === category) {
      return filter.label;
    }
  }

  return '上衣';
}

@Component
export struct WardrobePage {
  clothingRepository?: ClothingRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;

  @State private selectedWardrobeTab: string = '衣裤';
  @State private searchQuery: string = '';
  @State private selectedCategoryLabel: string = '上衣';
  @State private clothingItems: ClothingItem[] = [];
  @State private outfits: OutfitTemplate[] = [];
  @State private showEditor: boolean = false;
  @State private showOutfitEditor: boolean = false;
  @State private editingClothingId: string = '';
  @State private editingOutfitId: string = '';
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private homeHeroOpacity: number = 0.0;
  @State private homeHeroTranslateY: number = 12;
  @State private homeHeroPressed: boolean = false;

  aboutToAppear(): void {
    this.loadClothingItems();
    this.loadOutfits();
    setTimeout(() => {
      this.homeHeroOpacity = 1.0;
      this.homeHeroTranslateY = 0;
    }, 80);
  }

  private async loadClothingItems(): Promise<void> {
    if (this.clothingRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.clothingItems = await this.clothingRepository.listClothing();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载衣橱失败';
    } finally {
      this.loading = false;
    }
  }

  private async loadOutfits(): Promise<void> {
    if (this.outfitRepository === undefined) {
      return;
    }

    this.errorMessage = '';

    try {
      this.outfits = await this.outfitRepository.listOutfits();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载美搭失败';
    }
  }

  private selectedCategory(): ClothingCategory | undefined {
    for (const filter of WARDROBE_CATEGORY_FILTERS) {
      if (filter.label === this.selectedCategoryLabel) {
        return filter.category;
      }
    }

    return undefined;
  }

  private filterClothingItems(): ClothingItem[] {
    const selectedCategory = this.selectedCategory();
    const normalizedQuery = this.searchQuery.trim().toLowerCase();

    return this.clothingItems.filter((item: ClothingItem) => {
      const matchesCategory = selectedCategory === undefined || item.category === selectedCategory;
      const matchesQuery = normalizedQuery.length === 0 ||
        item.name.toLowerCase().includes(normalizedQuery) ||
        (item.note !== undefined && item.note.toLowerCase().includes(normalizedQuery));

      return matchesCategory && matchesQuery;
    });
  }

  private categoryLabels(): string[] {
    return WARDROBE_CATEGORY_FILTERS.map((filter: WardrobeCategoryFilter) => filter.label);
  }

  private visibleClothingItems(): ClothingItem[] {
    return this.filterClothingItems();
  }

  private visibleOutfits(): OutfitTemplate[] {
    const normalizedQuery = this.searchQuery.trim().toLowerCase();
    if (normalizedQuery.length === 0) {
      return this.outfits;
    }

    return this.outfits.filter((outfit: OutfitTemplate) => {
      return outfit.title.toLowerCase().includes(normalizedQuery) ||
        (outfit.note !== undefined && outfit.note.toLowerCase().includes(normalizedQuery));
    });
  }

  private firstPhotoUri(item: ClothingItem): string {
    return item.photoUris.length > 0 ? item.photoUris[0] : '';
  }

  private firstOutfitPhotoUri(outfit: OutfitTemplate): string {
    return outfit.photoUris.length > 0 ? outfit.photoUris[0] : '';
  }

  private wardrobeCardAspectRatio(index: number): number {
    return index < 3 ? 2.18 : 1.38;
  }

  private editingItem(): ClothingItem | undefined {
    if (this.editingClothingId.length === 0) {
      return undefined;
    }

    for (const item of this.clothingItems) {
      if (item.id === this.editingClothingId) {
        return item;
      }
    }

    return undefined;
  }

  private editingOutfit(): OutfitTemplate | undefined {
    if (this.editingOutfitId.length === 0) {
      return undefined;
    }

    for (const outfit of this.outfits) {
      if (outfit.id === this.editingOutfitId) {
        return outfit;
      }
    }

    return undefined;
  }

  private openCreateEditor(): void {
    this.editingClothingId = '';
    this.showEditor = true;
  }

  private openEditEditor(item: ClothingItem): void {
    this.editingClothingId = item.id;
    this.showEditor = true;
  }

  private closeEditor(): void {
    this.showEditor = false;
    this.editingClothingId = '';
  }

  private openOutfitEditor(outfit?: OutfitTemplate): void {
    this.editingOutfitId = outfit?.id ?? '';
    this.showOutfitEditor = true;
  }

  private closeOutfitEditor(): void {
    this.showOutfitEditor = false;
    this.editingOutfitId = '';
  }

  private onEdit(item: ClothingItem): void {
    this.openEditEditor(item);
  }

  private upsertClothingItem(savedItem: ClothingItem): void {
    const nextItems: ClothingItem[] = [];
    let replaced = false;

    for (const item of this.clothingItems) {
      if (item.id === savedItem.id) {
        nextItems.push(savedItem);
        replaced = true;
      } else {
        nextItems.push(item);
      }
    }

    if (!replaced) {
      nextItems.unshift(savedItem);
    }

    this.clothingItems = nextItems;
  }

  private upsertOutfit(savedOutfit: OutfitTemplate): void {
    const nextOutfits: OutfitTemplate[] = [];
    let replaced = false;

    for (const outfit of this.outfits) {
      if (outfit.id === savedOutfit.id) {
        nextOutfits.push(savedOutfit);
        replaced = true;
      } else {
        nextOutfits.push(outfit);
      }
    }

    if (!replaced) {
      nextOutfits.unshift(savedOutfit);
    }

    this.outfits = nextOutfits;
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.showUnifiedSearch = query.trim().length > 0;
  }

  private retry(): void {
    this.loadClothingItems();
  }

  private openSearch(): void {
    this.openUnifiedSearch(this.searchQuery);
  }

  private wardrobeSummaryText(): string {
    if (this.selectedWardrobeTab === '美搭') {
      return this.searchQuery.trim().length > 0
        ? `找到 ${this.visibleOutfits().length} 套美搭`
        : `${this.outfits.length} 套美搭`;
    }

    return this.searchQuery.trim().length > 0
      ? `找到 ${this.visibleClothingItems().length} 件衣物`
      : `${this.clothingItems.length} 件衣物`;
  }

  private wardrobeHeroText(): string {
    if (this.clothingItems.length === 0 && this.outfits.length === 0) {
      return '从第一张衣服照片开始，慢慢整理自己的风格。';
    }

    if (this.outfits.length > 0) {
      return '翻一翻最近保存的美搭，今天也能轻松出门。';
    }

    return '衣物已经开始成形，可以继续补几张常穿单品。';
  }

  private heroPreviewPhotoUris(): string[] {
    const photoUris: string[] = [];

    for (const item of this.clothingItems) {
      if (photoUris.length >= WARDROBE_HERO_PREVIEW_COUNT) {
        return photoUris;
      }
      const photoUri = this.firstPhotoUri(item);
      if (photoUri.length > 0) {
        photoUris.push(photoUri);
      }
    }

    for (const outfit of this.outfits) {
      if (photoUris.length >= WARDROBE_HERO_PREVIEW_COUNT) {
        return photoUris;
      }
      const photoUri = this.firstOutfitPhotoUri(outfit);
      if (photoUri.length > 0) {
        photoUris.push(photoUri);
      }
    }

    return photoUris;
  }

  build() {
    if (this.showEditor) {
      ClothingEditPage({
        initialItem: this.editingItem(),
        clothingRepository: this.clothingRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (item: ClothingItem) => {
          this.upsertClothingItem(item);
          this.closeEditor();
        },
        onCancel: () => {
          this.closeEditor();
        }
      })
    } else if (this.showOutfitEditor) {
      OutfitEditPage({
        initialOutfit: this.editingOutfit(),
        clothingItems: this.clothingItems,
        outfitRepository: this.outfitRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (outfit: OutfitTemplate) => {
          this.upsertOutfit(outfit);
          this.closeOutfitEditor();
          this.selectedWardrobeTab = '美搭';
        },
        onCancel: () => {
          this.closeOutfitEditor();
        }
      })
    } else if (this.showUnifiedSearch) {
      SearchResultsPage({
        query: this.unifiedSearchQuery,
        searchRepository: this.searchRepository,
        clothingRepository: this.clothingRepository,
        onClose: () => {
          this.showUnifiedSearch = false;
        }
      })
    } else {
      Column({ space: 14 }) {
      this.WardrobeHomeHero()
      this.WardrobeSearchHeader()
      this.WardrobePrimaryTabs()

      Text(this.wardrobeSummaryText())
        .fontSize(14)
        .fontColor(YibuqueColor.textSecondary)
        .width('100%')

      if (this.loading) {
        Text('正在加载衣橱...')
          .fontSize(14)
          .fontColor(AppTheme.color.textMuted)
      }

      if (this.errorMessage.length > 0) {
        Row({ space: 8 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(AppTheme.color.danger)
            .layoutWeight(1)

          Button('重试')
            .height(34)
            .fontSize(13)
            .onClick(() => {
              this.retry();
            })
        }
        .width('100%')
      }

      if (this.selectedWardrobeTab === '衣裤') {
        this.WardrobeSearchTabs()
      }

      if (this.selectedWardrobeTab === '衣裤' && this.visibleClothingItems().length === 0) {
        Column({ space: 10 }) {
          Column({ space: 8 }) {
            Text('衣')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.color.primary)

            Text('先放入第一件衣服')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppTheme.color.text)

            Text('拍照或从相册选图后，按分类收进衣橱。')
              .fontSize(13)
              .fontColor(AppTheme.color.textMuted)
          }
          .width('100%')
          .height(190)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(AppTheme.color.primarySoft)
          .borderRadius(8)

          Text('点击底部 + 的拍衣服添加第一件衣服')
            .fontSize(15)
            .fontColor(AppTheme.color.text)

          Text('衣服会按图片检索流排在这里。')
            .fontSize(12)
            .fontColor(AppTheme.color.textMuted)
        }
        .width('100%')
        .padding(8)
        .borderRadius(AppTheme.radius.lg)
        .backgroundColor(AppTheme.color.surfaceRaised)
      } else if (this.selectedWardrobeTab === '美搭' && this.visibleOutfits().length === 0) {
        Column({ space: 10 }) {
          Text('搭')
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)

          Text('点击底部 + 的拍搭配添加第一套美搭')
            .fontSize(16)
            .fontColor(YibuqueColor.textSecondary)
        }
        .width('100%')
        .height(220)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(YibuqueColor.cardBlue)
        .borderRadius(YibuqueRadius.xxl)
      } else if (this.selectedWardrobeTab === '衣裤') {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.visibleClothingItems().slice(0, WARDROBE_TOP_RESULT_COUNT), (item: ClothingItem, index: number) => {
              this.WardrobeSearchResultCard(item, index)
            }, (item: ClothingItem) => item.id)

            if (this.visibleClothingItems().length > WARDROBE_TOP_RESULT_COUNT) {
              WaterFlow() {
                ForEach(this.visibleClothingItems().slice(WARDROBE_TOP_RESULT_COUNT), (item: ClothingItem, index: number) => {
                  FlowItem() {
                    this.WardrobeSearchResultCard(item, index + WARDROBE_TOP_RESULT_COUNT)
                  }
                  .width('100%')
                }, (item: ClothingItem) => item.id)
              }
              .cachedCount(8)
              .columnsTemplate('1fr 1fr')
              .columnsGap(8)
              .rowsGap(8)
              .width('100%')
              .height(360)
              .scrollBar(BarState.Off)
            }
          }
          .width('100%')
          .padding({ bottom: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        Scroll() {
          Grid() {
            ForEach(this.visibleOutfits(), (outfit: OutfitTemplate) => {
              GridItem() {
                this.OutfitResultCard(outfit)
              }
            }, (outfit: OutfitTemplate) => outfit.id)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(YibuqueSpacing.md)
          .rowsGap(YibuqueSpacing.md)
          .width('100%')
          .padding({ bottom: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12, top: 28, bottom: 14 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(AppTheme.color.surface)
    }
  }

  @Builder
  WardrobeHomeHero() {
    Column({ space: YibuqueSpacing.lg }) {
      Row() {
        Column({ space: YibuqueSpacing.xs }) {
          Text('今日衣橱')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)

          Text(this.wardrobeHeroText())
            .fontSize(14)
            .fontColor(YibuqueColor.textSecondary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('轻整理')
          .height(34)
          .padding({ left: 14, right: 14 })
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardMint)
          .borderRadius(YibuqueRadius.full)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: YibuqueSpacing.md }) {
        this.HeroMetric('衣物', `${this.clothingItems.length}`, '件')
        this.HeroMetric('美搭', `${this.outfits.length}`, '套')

        Stack({ alignContent: Alignment.Center }) {
          if (this.heroPreviewPhotoUris().length > 0) {
            Row({ space: -8 }) {
              ForEach(this.heroPreviewPhotoUris(), (photoUri: string) => {
                Image(photoUri)
                  .width(46)
                  .height(54)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(YibuqueRadius.lg)
                  .border({ width: 2, color: YibuqueColor.cardWhite })
              }, (photoUri: string) => photoUri)
            }
          } else {
            Text('衣')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textPrimary)
          }
        }
        .layoutWeight(1)
        .height(64)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.xl)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('点击底部 + 快速拍衣服或拍搭配')
        .fontSize(13)
        .fontColor(YibuqueColor.textTertiary)
        .width('100%')
    }
    .width('100%')
    .padding(YibuqueSpacing.xl)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxxl)
    .shadow(YibuqueShadow.soft)
    .opacity(this.homeHeroOpacity)
    .translate({ y: this.homeHeroTranslateY })
    .scale({ x: this.homeHeroPressed ? 0.98 : 1.0, y: this.homeHeroPressed ? 0.98 : 1.0 })
    .animation({
      duration: 320,
      curve: Curve.FastOutSlowIn,
      playMode: PlayMode.Normal
    })
    .onTouch((event: TouchEvent) => {
      this.homeHeroPressed = event.type === TouchType.Down;
    })
    .onClick(() => {
      this.homeHeroPressed = false;
    })
  }

  @Builder
  HeroMetric(label: string, value: string, unit: string) {
    Column({ space: YibuqueSpacing.xxs }) {
      Row({ space: 2 }) {
        Text(value)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)

        Text(unit)
          .fontSize(12)
          .fontColor(YibuqueColor.textSecondary)
          .margin({ top: 8 })
      }
      .alignItems(VerticalAlign.Top)

      Text(label)
        .fontSize(12)
        .fontColor(YibuqueColor.textSecondary)
    }
    .width(74)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(YibuqueColor.cardBlue)
    .borderRadius(YibuqueRadius.xl)
  }

  @Builder
  WardrobeSearchHeader() {
    Row({ space: 0 }) {
      Row({ space: 10 }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 17, height: 17 })
            .fill('#00000000')
            .stroke(AppTheme.color.textMuted)
            .strokeWidth(2)
          Line()
            .startPoint([1, 1])
            .endPoint([9, 9])
            .stroke(AppTheme.color.textMuted)
            .strokeWidth(2)
            .margin({ left: 8, top: 8 })
        }
        .width(26)
        .height(42)

        TextInput({ text: this.searchQuery, placeholder: '搜索衣服、美搭、备注' })
          .height(42)
          .layoutWeight(1)
          .fontSize(16)
          .fontColor(AppTheme.color.text)
          .placeholderColor(AppTheme.color.textMuted)
          .backgroundColor('#00000000')
          .onChange((value: string) => {
            this.searchQuery = value;
          })

        Divider()
          .vertical(true)
          .height(22)
          .color(AppTheme.color.border)
          .strokeWidth(1)

        Text('搜索')
          .width(76)
          .height(42)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.color.primary)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.openSearch();
          })
      }
      .layoutWeight(1)
      .height(52)
      .padding({ left: 16, right: 6 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(AppTheme.color.surfaceMuted)
      .borderRadius(26)
    }
    .width('100%')
    .height(54)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  WardrobePrimaryTabs() {
    Row({ space: YibuqueSpacing.sm }) {
      ForEach(['衣裤', '美搭'], (tab: string) => {
        Text(tab)
          .height(42)
          .padding({ left: 22, right: 22 })
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedWardrobeTab === tab ? YibuqueColor.textPrimary : YibuqueColor.textTertiary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.full)
          .border({ width: this.selectedWardrobeTab === tab ? 2 : 1, color: this.selectedWardrobeTab === tab ? YibuqueColor.borderStrong : YibuqueColor.borderLight })
          .onClick(() => {
            this.selectedWardrobeTab = tab;
          })
      }, (tab: string) => tab)
    }
    .width('100%')
    .height(46)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  WardrobeSearchTabs() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(this.categoryLabels(), (category: string) => {
          Text(category)
            .height(42)
            .padding({ left: 22, right: 22 })
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.selectedCategoryLabel === category ? YibuqueColor.textPrimary : YibuqueColor.textTertiary)
            .textAlign(TextAlign.Center)
            .backgroundColor(YibuqueColor.cardWhite)
            .borderRadius(YibuqueRadius.full)
            .border({ width: this.selectedCategoryLabel === category ? 2 : 1, color: this.selectedCategoryLabel === category ? YibuqueColor.borderStrong : YibuqueColor.borderLight })
            .onClick(() => {
              this.selectedCategoryLabel = category;
            })
        }, (category: string) => category)
      }
      .padding({ right: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(46)
  }

  @Builder
  WardrobeSearchResultCard(item: ClothingItem, index: number) {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.firstPhotoUri(item).length > 0) {
        Image(this.firstPhotoUri(item))
          .width('100%')
          .aspectRatio(this.wardrobeCardAspectRatio(index))
          .objectFit(ImageFit.Cover)
          .borderRadius(24)
      } else {
        Column() {
          Text(categoryLabel(item.category))
            .fontSize(index < 3 ? 34 : 20)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)
        }
        .width('100%')
        .aspectRatio(this.wardrobeCardAspectRatio(index))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(index % 2 === 0 ? YibuqueColor.cardBlue : YibuqueColor.cardMint)
        .borderRadius(24)
      }

      Column()
        .width('100%')
        .height(index < 3 ? 52 : 42)
        .linearGradient({
          angle: 180,
          colors: [['#00000000', 0], ['#66000000', 1]]
        })
        .borderRadius({ bottomLeft: 8, bottomRight: 8 })

      Column({ space: 2 }) {
        Text(item.name)
          .fontSize(index < 3 ? 16 : 13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.color.surface)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(categoryLabel(item.category))
          .fontSize(11)
          .fontColor(AppTheme.color.surface)
          .opacity(0.86)
      }
      .width('80%')
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12, bottom: 10 })
    }
    .width('100%')
    .borderRadius(24)
    .clip(true)
    .shadow(YibuqueShadow.card)
    .onClick(() => {
      this.onEdit(item);
    })
  }

  @Builder
  OutfitResultCard(outfit: OutfitTemplate) {
    Column({ space: 10 }) {
      if (this.firstOutfitPhotoUri(outfit).length > 0) {
        Image(this.firstOutfitPhotoUri(outfit))
          .width('100%')
          .height(150)
          .objectFit(ImageFit.Cover)
          .borderRadius(24)
      } else {
        Column() {
          Text('搭')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)
        }
        .width('100%')
        .height(150)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(YibuqueColor.cardMint)
        .borderRadius(24)
      }

      Text(outfit.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(`${outfit.clothingItemIds.length} 件衣物`)
        .fontSize(13)
        .fontColor(YibuqueColor.textSecondary)
        .width('100%')
    }
    .width('100%')
    .padding(10)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .shadow(YibuqueShadow.card)
    .onClick(() => {
      this.openOutfitEditor(outfit);
    })
  }
}
