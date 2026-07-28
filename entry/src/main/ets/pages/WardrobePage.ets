import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { DeleteImageOverlay } from '../components/DeleteImageOverlay';
import { SavedFilterNotice } from '../components/SavedFilterNotice';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { SearchEntityType } from '../domain/search/SearchModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import {
  YibuqueColor,
  YibuqueMotion,
  YibuqueRadius,
  YibuqueShadow,
  YibuqueSpacing,
  YibuqueTransition
} from '../theme/Tokens';
import { ArrayDataSource } from '../utils/ArrayDataSource';
import { userFacingError } from '../utils/userFacingError';
import { ClothingDetailPage } from './ClothingDetailPage';
import { ClothingEditPage } from './ClothingEditPage';
import { SearchResultsPage } from './SearchResultsPage';

interface WardrobeCategoryFilter {
  label: string;
  category?: ClothingCategory;
  categories?: ClothingCategory[];
}

const WARDROBE_CATEGORY_FILTERS: WardrobeCategoryFilter[] = [
  { label: '全部' },
  { label: '上衣', category: ClothingCategory.Top },
  { label: '裤装', categories: [ClothingCategory.Pants, ClothingCategory.Shorts] },
  { label: '裙装', categories: [ClothingCategory.LongSkirt, ClothingCategory.HalfSkirt] }
];

@Component
export struct WardrobePage {
  clothingRepository?: ClothingRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onOpenCapture: () => void = () => {};
  onCreateClothing: () => void = () => {};
  onDetailModeChange: (showDetailTopBar: boolean) => void = () => {};
  onClothingEditorVisibilityChange: (visible: boolean) => void = () => {};
  onNestedPageVisibilityChange: (visible: boolean) => void = () => {};
  onOpenSearchTarget: (entityType: SearchEntityType, id: string, title: string) => void =
    (_entityType: SearchEntityType, _id: string, _title: string) => {};

  @State private searchQuery: string = '';
  @State private selectedCategoryLabel: string = '全部';
  @State private clothingItems: ClothingItem[] = [];
  @State private clothingDataSource: ArrayDataSource<ClothingItem> = new ArrayDataSource<ClothingItem>();
  @State private showEditor: boolean = false;
  @State private showClothingDetail: boolean = false;
  @State private editingClothingId: string = '';
  @State private detailClothingId: string = '';
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private pressedWardrobeItemId: string = '';
  @State private deletingClothingId: string = '';
  @State private deleteOverlayClothingId: string = '';
  @State private savedClothingOutsideCurrentFilterId: string = '';
  @StorageProp('windowBottomInsetVp') private windowBottomInsetVp: number = YibuqueSpacing.bottomSafe;
  private clothingCardClickBlockedUntil: number = 0;
  private nestedPageTransitionInProgress: boolean = false;

  aboutToAppear(): void {
    this.loadClothingItems();
  }

  aboutToDisappear(): void {
    this.onDetailModeChange(false);
    this.onClothingEditorVisibilityChange(false);
    this.onNestedPageVisibilityChange(false);
  }

  private async loadClothingItems(): Promise<void> {
    if (this.clothingRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.clothingItems = await this.clothingRepository.listClothing();
      this.refreshClothingDataSource();
    } catch (error) {
      this.errorMessage = userFacingError(error, '加载衣柜失败');
    } finally {
      this.loading = false;
    }
  }

  private selectedCategories(): ClothingCategory[] | undefined {
    for (const filter of WARDROBE_CATEGORY_FILTERS) {
      if (filter.label === this.selectedCategoryLabel) {
        if (filter.categories !== undefined) {
          return filter.categories;
        }

        if (filter.category !== undefined) {
          return [filter.category];
        }
      }
    }

    return undefined;
  }

  private filterClothingItems(): ClothingItem[] {
    const selectedCategories = this.selectedCategories();
    const normalizedQuery = this.searchQuery.trim().toLowerCase();

    return this.clothingItems.filter((item: ClothingItem) => {
      const matchesCategory = selectedCategories === undefined || selectedCategories.includes(item.category);
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

  private refreshClothingDataSource(): void {
    this.clothingDataSource.setData(this.filterClothingItems());
  }

  private firstPhotoUri(item: ClothingItem): string {
    return item.photoUris.length > 0 ? item.photoUris[0] : '';
  }

  private wardrobeCardAspectRatio(index: number): number {
    if (index % 4 === 0) {
      return 0.73;
    }

    if (index % 4 === 1) {
      return 0.83;
    }

    return 0.82;
  }

  private categoryLabel(category: ClothingCategory): string {
    if (category === ClothingCategory.Pants) {
      return '裤子';
    }
    if (category === ClothingCategory.Shorts) {
      return '短裤';
    }
    if (category === ClothingCategory.LongSkirt) {
      return '长裙';
    }
    if (category === ClothingCategory.HalfSkirt) {
      return '半裙';
    }

    return '上衣';
  }

  private displayItemTitle(item: ClothingItem): string {
    const categoryLabel = this.categoryLabel(item.category);
    const autoNamePattern = new RegExp(`^${categoryLabel} \\d{2}-\\d{2} \\d{2}:\\d{2}$`);
    return autoNamePattern.test(item.name) ? categoryLabel : item.name;
  }

  private displayItemMeta(item: ClothingItem): string {
    const note = item.note?.trim() ?? '';
    if (note.length > 0) {
      return note;
    }

    const categoryLabel = this.categoryLabel(item.category);
    return this.displayItemTitle(item) === categoryLabel ? '' : categoryLabel;
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

  private detailItem(): ClothingItem | undefined {
    if (this.detailClothingId.length === 0) {
      return undefined;
    }

    for (const item of this.clothingItems) {
      if (item.id === this.detailClothingId) {
        return item;
      }
    }

    return undefined;
  }

  private animateNestedPageChange(change: () => void): void {
    if (this.nestedPageTransitionInProgress) {
      return;
    }

    this.nestedPageTransitionInProgress = true;
    this.getUIContext().animateTo({
      duration: YibuqueMotion.fullScreenPageTransition,
      curve: Curve.EaseOut,
      onFinish: () => {
        this.nestedPageTransitionInProgress = false;
      }
    }, () => {
      change();
    });
  }

  private openCreateEditor(): void {
    this.editingClothingId = '';
    this.animateNestedPageChange(() => {
      this.showEditor = true;
      this.onClothingEditorVisibilityChange(true);
      this.onNestedPageVisibilityChange(true);
    });
  }

  private openEditEditor(item: ClothingItem): void {
    this.editingClothingId = item.id;
    this.animateNestedPageChange(() => {
      this.showEditor = true;
      this.onClothingEditorVisibilityChange(true);
      this.onNestedPageVisibilityChange(true);
    });
  }

  private closeEditor(returnToList: boolean = false): void {
    this.animateNestedPageChange(() => {
      this.showEditor = false;
      this.editingClothingId = '';
      if (returnToList) {
        this.showClothingDetail = false;
        this.detailClothingId = '';
        this.onDetailModeChange(false);
      }
      this.onClothingEditorVisibilityChange(false);
      this.onNestedPageVisibilityChange(this.showClothingDetail);
    });
  }

  private openClothingDetail(item: ClothingItem): void {
    this.detailClothingId = item.id;
    this.animateNestedPageChange(() => {
      this.showClothingDetail = true;
      this.onDetailModeChange(true);
      this.onNestedPageVisibilityChange(true);
    });
  }

  private closeClothingDetail(): void {
    this.animateNestedPageChange(() => {
      this.showClothingDetail = false;
      this.detailClothingId = '';
      this.showUnifiedSearch = false;
      this.onDetailModeChange(false);
      this.onNestedPageVisibilityChange(false);
    });
  }

  private editFromDetail(item: ClothingItem): void {
    this.editingClothingId = item.id;
    this.animateNestedPageChange(() => {
      this.showEditor = true;
      this.onClothingEditorVisibilityChange(true);
      this.onNestedPageVisibilityChange(true);
    });
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
    this.refreshClothingDataSource();
    this.savedClothingOutsideCurrentFilterId = this.filterClothingItems().some((item: ClothingItem) => item.id === savedItem.id)
      ? ''
      : savedItem.id;
  }

  private savedClothingIsOutsideCurrentFilter(): boolean {
    if (this.savedClothingOutsideCurrentFilterId.length === 0) {
      return false;
    }

    return !this.filterClothingItems().some((item: ClothingItem) => item.id === this.savedClothingOutsideCurrentFilterId);
  }

  private showAllClothingFromSaveNotice(): void {
    this.searchQuery = '';
    this.selectedCategoryLabel = '全部';
    this.savedClothingOutsideCurrentFilterId = '';
    this.refreshClothingDataSource();
  }

  private async deleteClothingItem(item: ClothingItem): Promise<void> {
    if (this.clothingRepository === undefined) {
      throw new Error('衣物仓库不可用，请稍后重试');
    }

    await this.clothingRepository.deleteClothing(item.id);
    this.clothingItems = this.clothingItems.filter((existingItem: ClothingItem) => existingItem.id !== item.id);
    this.refreshClothingDataSource();
  }

  private confirmDeleteClothingFromList(item: ClothingItem): void {
    if (this.deletingClothingId.length > 0) {
      return;
    }

    this.pressedWardrobeItemId = '';
    AlertDialog.show({
      title: '删除衣物',
      message: `确定删除“${this.displayItemTitle(item)}”吗？本地照片会一并移除，关联穿搭将解除该单品。`,
      primaryButton: {
        value: '取消',
        action: () => {
          this.deleteOverlayClothingId = '';
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: YibuqueColor.danger,
        action: () => {
          this.deleteClothingFromList(item);
        }
      }
    });
  }

  private async deleteClothingFromList(item: ClothingItem): Promise<void> {
    if (this.deletingClothingId.length > 0) {
      return;
    }

    this.deletingClothingId = item.id;
    try {
      await this.deleteClothingItem(item);
      this.getUIContext().getPromptAction().showToast({ message: '衣物已删除' });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({
        message: userFacingError(error, '删除衣物失败')
      });
    } finally {
      this.deletingClothingId = '';
      this.deleteOverlayClothingId = '';
    }
  }

  private showClothingDeleteOverlay(item: ClothingItem): void {
    if (this.deletingClothingId.length > 0) {
      return;
    }

    this.pressedWardrobeItemId = '';
    this.deleteOverlayClothingId = item.id;
    this.clothingCardClickBlockedUntil = Date.now() + 60000;
  }

  private handleClothingCardClick(item: ClothingItem): void {
    if (Date.now() <= this.clothingCardClickBlockedUntil) {
      return;
    }

    if (this.deleteOverlayClothingId.length > 0) {
      this.deleteOverlayClothingId = '';
      return;
    }

    this.openClothingDetail(item);
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.animateNestedPageChange(() => {
      this.showUnifiedSearch = true;
      this.onNestedPageVisibilityChange(true);
    });
  }

  private closeUnifiedSearch(): void {
    this.animateNestedPageChange(() => {
      this.showUnifiedSearch = false;
      this.onNestedPageVisibilityChange(false);
    });
  }

  private retry(): void {
    this.loadClothingItems();
  }

  private openSearch(): void {
    this.openUnifiedSearch(this.searchQuery);
  }

  private async openClothingSearchResult(id: string): Promise<void> {
    let targetItem: ClothingItem | undefined = undefined;
    for (const item of this.clothingItems) {
      if (item.id === id) {
        targetItem = item;
        break;
      }
    }

    if (targetItem === undefined && this.clothingRepository !== undefined) {
      targetItem = await this.clothingRepository.getClothingById(id);
    }

    if (targetItem !== undefined) {
      this.detailClothingId = targetItem.id;
      this.animateNestedPageChange(() => {
        this.showUnifiedSearch = false;
        this.showClothingDetail = true;
        this.onDetailModeChange(true);
        this.onNestedPageVisibilityChange(true);
      });
    }
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
          this.closeEditor(true);
        },
        onCancel: () => {
          this.closeEditor();
        }
      })
        .transition(YibuqueTransition.fullScreenOpacity)
    } else if (this.showClothingDetail) {
      ClothingDetailPage({
        item: this.detailItem(),
        onBack: () => {
          this.closeClothingDetail();
        },
        onEdit: (item: ClothingItem) => {
          this.editFromDetail(item);
        },
        onDelete: async (item: ClothingItem): Promise<void> => {
          await this.deleteClothingItem(item);
          this.closeClothingDetail();
        }
      })
        .transition(YibuqueTransition.fullScreenOpacity)
    } else if (this.showUnifiedSearch) {
      SearchResultsPage({
        query: this.unifiedSearchQuery,
        searchRepository: this.searchRepository,
        clothingRepository: this.clothingRepository,
        outfitRepository: this.outfitRepository,
        onOpenClothingResult: (id: string) => {
          this.openClothingSearchResult(id);
        },
        onOpenOutfitResult: (_id: string) => {
          this.onOpenSearchTarget(SearchEntityType.Outfit, _id, '');
        },
        onOpenStoreResult: (entityType: SearchEntityType, id: string, title: string) => {
          this.onOpenSearchTarget(entityType, id, title);
        },
        onOpenWishlistResult: (id: string) => {
          this.onOpenSearchTarget(SearchEntityType.Wishlist, id, '');
        },
        onOpenWearLogResult: (id: string) => {
          this.onOpenSearchTarget(SearchEntityType.WearLog, id, '');
        },
        onOpenProfileResult: (entityType: SearchEntityType, id: string) => {
          this.onOpenSearchTarget(entityType, id, '');
        },
        onClose: () => {
          this.closeUnifiedSearch();
        }
      })
        .transition(YibuqueTransition.fullScreenOpacity)
    } else {
      Column({ space: 14 }) {
      this.WardrobeSearchHeader()

      if (this.loading) {
        Text('正在加载衣柜...')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
      }

      if (this.errorMessage.length > 0) {
        Row({ space: 8 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(YibuqueColor.danger)
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

      this.WardrobeSearchTabs()

      SavedFilterNotice({
        visible: this.savedClothingIsOutsideCurrentFilter(),
        onViewAll: () => {
          this.showAllClothingFromSaveNotice();
        }
      })

      if (this.visibleClothingItems().length === 0) {
        Column({ space: 10 }) {
          Column({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.shirt'))
              .fontSize(36)
              .fontColor([YibuqueColor.textPrimary])

            Text('先放入第一件衣服')
              .fontSize(16)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textPrimary)

            Text('拍照或从相册选图后，按分类收进衣柜。')
              .fontSize(13)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .height(190)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.xxl)
          .border({ width: 1, color: YibuqueColor.borderMedium })
            .accessibilityText('新增衣物')
            .onClick(() => {
              this.onCreateClothing();
            })

          Text('点底部相机，选择照片后归类为衣柜')
            .fontSize(15)
            .fontColor(YibuqueColor.textPrimary)

          Text('衣服会按图片检索流排在这里。')
            .fontSize(12)
            .fontColor(YibuqueColor.textSecondary)
        }
        .width('100%')
        .padding(8)
        .borderRadius(YibuqueRadius.xxl)
        .backgroundColor(YibuqueColor.cardWhite)
      } else {
        this.WardrobeWaterFlow()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 0 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(YibuqueColor.cardWhite)
    .transition(YibuqueTransition.fullScreenOpacity)
    }
  }

  @Builder
  WardrobeSearchHeader() {
    Row({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(18)
          .fontColor([YibuqueColor.textSecondary])
      }
      .width(44)
      .height(46)
      .accessibilityText('执行搜索')
      .onClick(() => {
        this.openSearch();
      })

      TextInput({ text: this.searchQuery, placeholder: '搜索衣服、裤子、裙子' })
        .height(46)
        .layoutWeight(1)
        .fontSize(14)
        .fontColor(YibuqueColor.textPrimary)
        .placeholderColor(YibuqueColor.textTertiary)
        .backgroundColor(Color.Transparent)
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string) => {
          this.searchQuery = value;
          this.refreshClothingDataSource();
        })
        .onClick(() => {
          this.openSearch();
        })
        .onSubmit(() => {
          this.openSearch();
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 14 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.md)
    .border({ width: 1, color: YibuqueColor.borderMedium })
  }

  @Builder
  WardrobeSearchTabs() {
    Row({ space: 6 }) {
      ForEach(this.categoryLabels(), (category: string) => {
        Row({ space: 6 }) {
          this.CategoryFilterIcon(category)

          Text(category)
            .fontSize(13)
            .fontWeight(this.selectedCategoryLabel === category ? FontWeight.Regular : FontWeight.Regular)
            .fontColor(this.selectedCategoryLabel === category ? YibuqueColor.textInverse : YibuqueColor.textQuaternary)
        }
        .constraintSize({ minWidth: 0, minHeight: 44 })
        .padding({ left: 8, right: 8 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(this.selectedCategoryLabel === category ? YibuqueColor.actionBlack : YibuqueColor.cardWhite)
        .borderRadius(YibuqueRadius.full)
        .border({ width: 1, color: this.selectedCategoryLabel === category ? YibuqueColor.actionBlack : YibuqueColor.borderMedium })
        .accessibilityText(`${category}${this.selectedCategoryLabel === category ? '，已选中' : ''}`)
        .onClick(() => {
          this.selectedCategoryLabel = category;
          this.refreshClothingDataSource();
        })
      }, (category: string) => category)
    }
    .width('100%')
    .height(44)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CategoryFilterIcon(category: string) {
    if (category === '全部') {
      SymbolGlyph($r('sys.symbol.square_grid_2x2'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    } else if (category === '上衣') {
      SymbolGlyph($r('sys.symbol.shirt'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    } else if (category === '裤装') {
      SymbolGlyph($r('sys.symbol.clothing'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    } else if (category === '裙装') {
      SymbolGlyph($r('sys.symbol.hanger_and_towels'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    } else {
      SymbolGlyph($r('sys.symbol.arrow_left_arrow_right'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    }
  }

  @Builder
  WardrobeWaterFlow() {
    WaterFlow() {
      LazyForEach(this.clothingDataSource, (item: ClothingItem, index: number) => {
        FlowItem() {
          this.WardrobeSearchResultCard(item, index)
        }
        .width('100%')
      }, (item: ClothingItem) => item.id)
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(16)
    .rowsGap(8)
    .padding({
      top: 4,
      bottom: YibuqueSpacing.mainNavigationClearance + this.windowBottomInsetVp
    })
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
  }

  @Builder
  WardrobeSearchResultCard(item: ClothingItem, index: number) {
    Column({ space: 2 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.firstPhotoUri(item).length === 0) {
          Column({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.picture'))
              .fontSize(34)
              .fontColor([YibuqueColor.textSecondary])

            Text('暂无照片')
              .fontSize(12)
              .fontColor(YibuqueColor.textSecondary)
          }
            .width('100%')
            .aspectRatio(this.wardrobeCardAspectRatio(index))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.xxl)
        } else {
          Image(this.firstPhotoUri(item))
            .width('100%')
            .aspectRatio(this.wardrobeCardAspectRatio(index))
            .objectFit(ImageFit.Cover)
            .borderRadius(YibuqueRadius.xxl)
        }

        Row() {
          this.CardCategoryIcon(item.category)

          Blank()
            .layoutWeight(1)

        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8 })
        .alignItems(VerticalAlign.Top)

        if (this.deleteOverlayClothingId === item.id) {
          DeleteImageOverlay({
            label: '删除衣物',
            deleting: this.deletingClothingId === item.id,
            cornerRadius: YibuqueRadius.xxl,
            onDelete: () => {
              this.clothingCardClickBlockedUntil = Date.now() + 300;
              this.confirmDeleteClothingFromList(item);
            },
            onDismiss: () => {
              this.clothingCardClickBlockedUntil = Date.now() + 300;
              this.deleteOverlayClothingId = '';
            }
          })
        }
      }
      .width('100%')
      .aspectRatio(this.wardrobeCardAspectRatio(index))
      .priorityGesture(
        LongPressGesture({ repeat: false, duration: 500 })
          .onAction(() => {
            this.showClothingDeleteOverlay(item);
          })
          .onActionEnd(() => {
            this.clothingCardClickBlockedUntil = Date.now() + 300;
          })
      )

      Row({ space: 8 }) {
        Text(this.displayItemTitle(item))
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .lineHeight(20)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.displayItemMeta(item))
          .fontSize(12)
          .fontColor(YibuqueColor.textSecondary)
          .lineHeight(20)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
        .width('100%')
        .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .scale({ x: this.pressedWardrobeItemId === item.id ? 0.98 : 1.0, y: this.pressedWardrobeItemId === item.id ? 0.98 : 1.0 })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedWardrobeItemId = item.id;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedWardrobeItemId = '';
      }
    })
    .onClick(() => {
      this.handleClothingCardClick(item);
    })
    .accessibilityTextHint('长按图片可显示删除操作')
  }

  @Builder
  CardCategoryIcon(category: ClothingCategory) {
    Stack({ alignContent: Alignment.Center }) {
      if (category === ClothingCategory.Top) {
        SymbolGlyph($r('sys.symbol.shirt'))
          .fontSize(14)
          .fontColor([YibuqueColor.textPrimary])
      } else if (category === ClothingCategory.Pants || category === ClothingCategory.Shorts) {
        SymbolGlyph($r('sys.symbol.clothing'))
          .fontSize(14)
          .fontColor([YibuqueColor.textPrimary])
      } else {
        SymbolGlyph($r('sys.symbol.hanger_and_towels'))
          .fontSize(14)
          .fontColor([YibuqueColor.textPrimary])
      }
    }
    .width(28)
    .height(28)
    .backgroundColor(YibuqueColor.glassBadge)
    .borderRadius(YibuqueRadius.lg)
    .shadow(YibuqueShadow.badge)
  }

}
