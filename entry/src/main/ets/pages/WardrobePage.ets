import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { AppTheme } from '../theme/Tokens';
import { ClothingEditPage } from './ClothingEditPage';
import { SearchResultsPage } from './SearchResultsPage';

interface WardrobeCategoryFilter {
  label: string;
  category?: ClothingCategory;
}

const WARDROBE_CATEGORY_FILTERS: WardrobeCategoryFilter[] = [
  { label: '综合' },
  { label: '商户', category: ClothingCategory.Top },
  { label: '笔记', category: ClothingCategory.Pants },
  { label: '团购', category: ClothingCategory.Skirt },
  { label: '用户' }
];

const WARDROBE_TOP_RESULT_COUNT = 3;

function categoryLabel(category: ClothingCategory): string {
  if (category === ClothingCategory.Shoes || category === ClothingCategory.Bag) {
    return '鞋包';
  }

  for (const filter of WARDROBE_CATEGORY_FILTERS) {
    if (filter.category === category) {
      return filter.label;
    }
  }

  return '其他';
}

@Component
export struct WardrobePage {
  clothingRepository?: ClothingRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;

  @State private searchQuery: string = '';
  @State private selectedCategoryLabel: string = '综合';
  @State private clothingItems: ClothingItem[] = [];
  @State private showEditor: boolean = false;
  @State private editingClothingId: string = '';
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadClothingItems();
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
      const matchesCategory = this.selectedCategoryLabel === '鞋包'
        ? item.category === ClothingCategory.Shoes || item.category === ClothingCategory.Bag
        : selectedCategory === undefined || item.category === selectedCategory;
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

  private firstPhotoUri(item: ClothingItem): string {
    return item.photoUris.length > 0 ? item.photoUris[0] : '';
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
      this.WardrobeSearchHeader()

      if (this.loading) {
        Text('loading / 正在加载衣橱...')
          .fontSize(14)
          .fontColor(AppTheme.color.textMuted)
      }

      if (this.errorMessage.length > 0) {
        Row({ space: 8 }) {
          Text(`error / ${this.errorMessage}`)
            .fontSize(14)
            .fontColor(AppTheme.color.danger)
            .layoutWeight(1)

          Button('retry')
            .height(34)
            .fontSize(13)
            .onClick(() => {
              this.retry();
            })
        }
        .width('100%')
      }

      this.WardrobeSearchTabs()

      if (this.visibleClothingItems().length === 0) {
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
          }
          .width('100%')
          .height(190)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(AppTheme.color.primarySoft)
          .borderRadius(8)

          Text('点击 search 旁的加号逻辑添加第一件衣服')
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
      } else {
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

        TextInput({ text: this.searchQuery, placeholder: '搜索衣服、套装、备注' })
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

        Text('search')
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
  WardrobeSearchTabs() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(this.categoryLabels(), (category: string) => {
          Text(category)
            .height(42)
            .padding({ left: 22, right: 22 })
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.selectedCategoryLabel === category ? AppTheme.color.surface : AppTheme.color.text)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.selectedCategoryLabel === category ? AppTheme.color.primary : AppTheme.color.surfaceMuted)
            .borderRadius(21)
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
          .borderRadius(8)
      } else {
        Column() {
          Text(categoryLabel(item.category))
            .fontSize(index < 3 ? 34 : 20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.primary)
        }
        .width('100%')
        .aspectRatio(this.wardrobeCardAspectRatio(index))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(AppTheme.color.primarySoft)
        .borderRadius(8)
      }

      Column()
        .width('100%')
        .height(index < 3 ? 52 : 42)
        .linearGradient({
          angle: 180,
          colors: [['#00000000', 0], ['#66000000', 1]]
        })
        .borderRadius({ bottomLeft: 8, bottomRight: 8 })

      Text(`NO. ${index + 1}`)
        .fontSize(index < 3 ? 16 : 13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.color.surface)
        .margin({ left: 12, bottom: 10 })
    }
    .width('100%')
    .onClick(() => {
      this.onEdit(item);
    })
  }
}
