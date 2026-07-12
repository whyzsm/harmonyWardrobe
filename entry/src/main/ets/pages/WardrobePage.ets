import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { MonthCalendar } from '../components/MonthCalendar';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { SearchEntityType } from '../domain/search/SearchModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';
import { monthKey, toIsoDate } from '../utils/date';
import { ClothingDetailPage } from './ClothingDetailPage';
import { ClothingEditPage } from './ClothingEditPage';
import { OutfitEditPage } from './OutfitEditPage';
import { SearchResultsPage } from './SearchResultsPage';
import { WearLogEditPage } from './WearLogEditPage';

interface WardrobeCategoryFilter {
  label: string;
  category?: ClothingCategory;
  categories?: ClothingCategory[];
}

const WARDROBE_CATEGORY_FILTERS: WardrobeCategoryFilter[] = [
  { label: '全部' },
  { label: '上衣', category: ClothingCategory.Top },
  { label: '裤装', categories: [ClothingCategory.Pants, ClothingCategory.Shorts] },
  { label: '裙装', categories: [ClothingCategory.LongSkirt, ClothingCategory.HalfSkirt] },
  { label: '包袋', categories: [] },
  { label: '待同步', categories: [] }
];

const OPEN_DESIGN_BLACK = '#242021';
const OPEN_DESIGN_SURFACE = '#FFFFFF';
const OPEN_DESIGN_MUTED = '#717177';
const OPEN_DESIGN_BORDER = '#D9D9DE';
const SCREENSHOT_BLUE = '#3174D3';
const SCREENSHOT_BLUE_BG = '#EDF4FF';
const SCREENSHOT_NAV_GRAY = '#74747A';

const DEMO_TITLES: string[] = ['牛仔短外套', '白毛衣牛仔裤', '衣架上的上衣', '极简灯下裙'];
const DEMO_META: string[] = ['亮色外套', '周末轻搭', '待回看', '极简陈列'];

@Component
export struct WardrobePage {
  clothingRepository?: ClothingRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  wearLogRepository?: WearLogRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onOpenCapture: () => void = () => {};
  onDetailModeChange: (showDetailTopBar: boolean) => void = () => {};
  onClothingEditorVisibilityChange: (visible: boolean) => void = () => {};
  onNestedPageVisibilityChange: (visible: boolean) => void = () => {};
  onOpenSearchTarget: (entityType: SearchEntityType, id: string, title: string) => void =
    (_entityType: SearchEntityType, _id: string, _title: string) => {};
  @Prop initialWardrobeTab: string = '衣裤';

  @State private selectedWardrobeTab: string = '衣裤';
  @State private searchQuery: string = '';
  @State private selectedCategoryLabel: string = '全部';
  @State private clothingItems: ClothingItem[] = [];
  @State private outfits: OutfitTemplate[] = [];
  @State private showEditor: boolean = false;
  @State private showClothingDetail: boolean = false;
  @State private showOutfitEditor: boolean = false;
  @State private editingClothingId: string = '';
  @State private detailClothingId: string = '';
  @State private editingOutfitId: string = '';
  @State private currentMonth: string = monthKey(new Date());
  @State private selectedDate: string = toIsoDate(new Date());
  @State private markedDates: string[] = [];
  @State private selectedDateLogs: WearLog[] = [];
  @State private editingWearLogId: string = '';
  @State private showWearLogEditor: boolean = false;
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialWardrobeTab === '美搭' || this.initialWardrobeTab === '日历' || this.initialWardrobeTab === '衣裤') {
      this.selectedWardrobeTab = this.initialWardrobeTab;
    }
    this.loadClothingItems();
    this.loadOutfits();
    this.loadCalendar();
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

  private async loadCalendar(): Promise<void> {
    await this.loadMonthMarkers();
    await this.loadSelectedDateLogs();
  }

  private async loadMonthMarkers(): Promise<void> {
    if (this.wearLogRepository === undefined) {
      return;
    }

    this.markedDates = await this.wearLogRepository.listWearLogDatesForMonth(this.currentMonth);
  }

  private async loadSelectedDateLogs(): Promise<void> {
    if (this.wearLogRepository === undefined) {
      return;
    }

    this.selectedDateLogs = await this.wearLogRepository.listWearLogsByDate(this.selectedDate);
  }

  private selectCalendarDate(date: string): void {
    this.selectedDate = date;
    this.loadSelectedDateLogs();
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

  private isWardrobePrimaryTabSelected(tab: string): boolean {
    return (tab === '衣橱' && this.selectedWardrobeTab === '衣裤') || this.selectedWardrobeTab === tab;
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
    if (index % 4 === 0) {
      return 0.73;
    }

    if (index % 4 === 1) {
      return 0.83;
    }

    return 0.82;
  }

  private isDesignFallbackPhoto(photoUri: string): boolean {
    return photoUri.length === 0 || photoUri.startsWith('debug://');
  }

  private designDemoResource(index: number): Resource {
    if (index % 4 === 0) {
      return $r('app.media.wardrobe_demo_1');
    }

    if (index % 4 === 1) {
      return $r('app.media.wardrobe_demo_2');
    }

    if (index % 4 === 2) {
      return $r('app.media.wardrobe_demo_3');
    }

    return $r('app.media.wardrobe_demo_4');
  }

  private designDemoTitle(index: number): string {
    return DEMO_TITLES[index % DEMO_TITLES.length];
  }

  private designDemoMeta(index: number): string {
    return DEMO_META[index % DEMO_META.length];
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

  private displayItemTitle(item: ClothingItem, index: number): string {
    if (this.isDesignFallbackPhoto(this.firstPhotoUri(item))) {
      return this.designDemoTitle(index);
    }

    const categoryLabel = this.categoryLabel(item.category);
    const autoNamePattern = new RegExp(`^${categoryLabel} \\d{2}-\\d{2} \\d{2}:\\d{2}$`);
    return autoNamePattern.test(item.name) ? categoryLabel : item.name;
  }

  private displayItemMeta(item: ClothingItem, index: number): string {
    if (this.isDesignFallbackPhoto(this.firstPhotoUri(item))) {
      return this.designDemoMeta(index);
    }

    const note = item.note?.trim() ?? '';
    if (note.length > 0) {
      return note;
    }

    const categoryLabel = this.categoryLabel(item.category);
    return this.displayItemTitle(item, index) === categoryLabel ? '' : categoryLabel;
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
    this.onClothingEditorVisibilityChange(true);
    this.onNestedPageVisibilityChange(true);
  }

  private openEditEditor(item: ClothingItem): void {
    this.editingClothingId = item.id;
    this.showEditor = true;
    this.onClothingEditorVisibilityChange(true);
    this.onNestedPageVisibilityChange(true);
  }

  private closeEditor(): void {
    this.showEditor = false;
    this.editingClothingId = '';
    this.onClothingEditorVisibilityChange(false);
    this.onNestedPageVisibilityChange(this.showClothingDetail);
  }

  private openClothingDetail(item: ClothingItem): void {
    this.detailClothingId = item.id;
    this.showClothingDetail = true;
    this.onDetailModeChange(true);
    this.onNestedPageVisibilityChange(true);
  }

  private closeClothingDetail(): void {
    this.showClothingDetail = false;
    this.detailClothingId = '';
    this.onDetailModeChange(false);
    this.onNestedPageVisibilityChange(false);
  }

  private editFromDetail(item: ClothingItem): void {
    this.editingClothingId = item.id;
    this.showEditor = true;
    this.onClothingEditorVisibilityChange(true);
    this.onNestedPageVisibilityChange(true);
  }

  private openOutfitEditor(outfit?: OutfitTemplate): void {
    this.editingOutfitId = outfit?.id ?? '';
    this.showOutfitEditor = true;
    this.onNestedPageVisibilityChange(true);
  }

  private closeOutfitEditor(): void {
    this.showOutfitEditor = false;
    this.editingOutfitId = '';
    this.onNestedPageVisibilityChange(false);
  }

  private openWearLogEditor(wearLog?: WearLog): void {
    this.editingWearLogId = wearLog?.id ?? '';
    this.showWearLogEditor = true;
    this.onNestedPageVisibilityChange(true);
  }

  private closeWearLogEditor(): void {
    this.showWearLogEditor = false;
    this.editingWearLogId = '';
    this.onNestedPageVisibilityChange(false);
  }

  private editingWearLog(): WearLog | undefined {
    if (this.editingWearLogId.length === 0) {
      return undefined;
    }

    for (const wearLog of this.selectedDateLogs) {
      if (wearLog.id === this.editingWearLogId) {
        return wearLog;
      }
    }

    return undefined;
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
    this.showUnifiedSearch = true;
    this.onNestedPageVisibilityChange(true);
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
      this.showUnifiedSearch = false;
      this.openClothingDetail(targetItem);
    }
  }

  private wardrobeSummaryText(): string {
    if (this.selectedWardrobeTab === '美搭') {
      return this.searchQuery.trim().length > 0
        ? `找到 ${this.visibleOutfits().length} 套美搭`
        : `${this.outfits.length} 套美搭`;
    }

    if (this.selectedWardrobeTab === '日历') {
      return `${this.selectedDate} ${this.selectedDateLogs.length} 条穿搭`;
    }

    return this.searchQuery.trim().length > 0
      ? `找到 ${this.visibleClothingItems().length} 件衣物`
      : `${this.clothingItems.length} 件衣物`;
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
          if (this.showClothingDetail) {
            this.detailClothingId = item.id;
          }
        },
        onCancel: () => {
          this.closeEditor();
        }
      })
    } else if (this.showClothingDetail) {
      ClothingDetailPage({
        item: this.detailItem(),
        onBack: () => {
          this.closeClothingDetail();
        },
        onEdit: (item: ClothingItem) => {
          this.editFromDetail(item);
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
    } else if (this.showWearLogEditor) {
      WearLogEditPage({
        initialWearLog: this.editingWearLog(),
        outfits: this.outfits,
        wearLogRepository: this.wearLogRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (_wearLog: WearLog) => {
          this.closeWearLogEditor();
          this.loadCalendar();
        },
        onCancel: () => {
          this.closeWearLogEditor();
        }
      })
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
        onOpenProfileResult: (entityType: SearchEntityType, id: string) => {
          this.onOpenSearchTarget(entityType, id, '');
        },
        onOpenCameraSearch: () => {
          this.showUnifiedSearch = false;
          this.onNestedPageVisibilityChange(false);
          this.onOpenCapture();
        },
        onClose: () => {
          this.showUnifiedSearch = false;
          this.onNestedPageVisibilityChange(false);
        }
      })
    } else {
      Column({ space: 14 }) {
      this.WardrobeSearchHeader()

      if (this.loading) {
        Text('正在加载衣橱...')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
      }

      if (this.errorMessage.length > 0) {
        Row({ space: 8 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#EF4444')
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

      if (this.selectedWardrobeTab === '日历') {
        this.CalendarTab()
      } else if (this.selectedWardrobeTab === '衣裤' && this.visibleClothingItems().length === 0) {
        Column({ space: 10 }) {
          Column({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.shirt'))
              .fontSize(36)
              .fontColor([YibuqueColor.textPrimary])

            Text('先放入第一件衣服')
              .fontSize(16)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textPrimary)

            Text('拍照或从相册选图后，按分类收进衣橱。')
              .fontSize(13)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .height(190)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(YibuqueColor.cardMint)
          .borderRadius(8)

          Text('点底部相机，选择照片后归类为衣橱')
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
      } else if (this.selectedWardrobeTab === '美搭' && this.visibleOutfits().length === 0) {
        Column({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.hanger_and_towels'))
            .fontSize(42)
            .fontColor([YibuqueColor.textPrimary])

          Text('点底部相机，选择照片后归类为美搭')
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
        this.WardrobeWaterFlow()
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
    .padding({ left: 20, right: 20, top: 14, bottom: 0 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(OPEN_DESIGN_SURFACE)
    }
  }

  @Builder
  WardrobeSearchHeader() {
    Row({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(18)
          .fontColor([OPEN_DESIGN_MUTED])
      }
      .width(22)
      .height(46)
      .accessibilityText('执行搜索')
      .onClick(() => {
        this.openSearch();
      })

      TextInput({ text: this.searchQuery, placeholder: '搜索衣服、裤子、裙子' })
        .height(46)
        .layoutWeight(1)
        .fontSize(14)
        .fontColor(OPEN_DESIGN_BLACK)
        .placeholderColor('#96969C')
        .backgroundColor(Color.Transparent)
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string) => {
          this.searchQuery = value;
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
    .backgroundColor(OPEN_DESIGN_SURFACE)
    .borderRadius(12)
    .border({ width: 1, color: OPEN_DESIGN_BORDER })
  }

  @Builder
  WardrobePrimaryTabs() {
    Row({ space: YibuqueSpacing.sm }) {
      ForEach(['衣橱', '美搭', '日历'], (tab: string) => {
        Text(tab)
          .height(42)
          .padding({ left: 22, right: 22 })
          .fontSize(15)
          .fontWeight(this.isWardrobePrimaryTabSelected(tab) ? FontWeight.Regular : FontWeight.Regular)
          .fontColor(this.isWardrobePrimaryTabSelected(tab) ? YibuqueColor.textInverse : OPEN_DESIGN_BLACK)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.isWardrobePrimaryTabSelected(tab) ? OPEN_DESIGN_BLACK : OPEN_DESIGN_SURFACE)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: this.isWardrobePrimaryTabSelected(tab) ? OPEN_DESIGN_BLACK : OPEN_DESIGN_BORDER })
          .onClick(() => {
            this.selectedWardrobeTab = tab === '衣橱' ? '衣裤' : tab;
            if (tab === '日历') {
              this.loadCalendar();
            }
          })
      }, (tab: string) => tab)
    }
    .width('100%')
    .height(46)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CalendarTab() {
    Scroll() {
      Column({ space: YibuqueSpacing.lg }) {
        Column({ space: YibuqueSpacing.md }) {
          Row() {
            Text(this.currentMonth)
              .fontSize(20)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textPrimary)
              .layoutWeight(1)

            Button('补记')
              .height(38)
              .fontSize(14)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textInverse)
              .backgroundColor(YibuqueColor.actionBlack)
              .borderRadius(YibuqueRadius.full)
              .onClick(() => {
                this.openWearLogEditor();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          MonthCalendar({
            month: this.currentMonth,
            markedDates: this.markedDates,
            selectedDate: this.selectedDate,
            onSelectDate: (date: string) => {
              this.selectCalendarDate(date);
            }
          })
        }
        .width('100%')
        .padding(YibuqueSpacing.lg)
        .backgroundColor(YibuqueColor.cardWhite)
        .borderRadius(YibuqueRadius.xxl)
        .shadow(YibuqueShadow.card)
        .alignItems(HorizontalAlign.Start)

        Text(`${this.selectedDate} 的穿搭`)
          .fontSize(18)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .width('100%')

        if (this.selectedDateLogs.length === 0) {
          Column({ space: YibuqueSpacing.sm }) {
            Text('今天穿了什么？')
              .fontSize(20)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textPrimary)

            Text('从相机记录一套，也可以在这里补记。')
              .fontSize(14)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .height(180)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(YibuqueColor.cardMint)
          .borderRadius(YibuqueRadius.xxl)
        } else {
          ForEach(this.selectedDateLogs, (wearLog: WearLog) => {
            this.WearLogCard(wearLog)
          }, (wearLog: WearLog) => wearLog.id)
        }
      }
      .width('100%')
      .padding({ bottom: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  WearLogCard(wearLog: WearLog) {
    Row({ space: YibuqueSpacing.md }) {
      if (wearLog.photoUris.length > 0) {
        Image(wearLog.photoUris[0])
          .width(78)
          .height(92)
          .objectFit(ImageFit.Cover)
          .borderRadius(YibuqueRadius.xl)
      } else {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.hanger_and_towels'))
            .fontSize(32)
            .fontColor([YibuqueColor.textPrimary])
        }
        .width(78)
        .height(92)
        .backgroundColor(YibuqueColor.cardBlue)
        .borderRadius(YibuqueRadius.xl)
      }

      Column({ space: YibuqueSpacing.xs }) {
        Text(wearLog.outfitTitleSnapshot)
          .fontSize(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(wearLog.note ?? wearLog.placeText ?? '每日穿搭')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('编辑')
          .fontSize(13)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .onClick(() => {
            this.openWearLogEditor(wearLog);
          })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(YibuqueSpacing.md)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .shadow(YibuqueShadow.card)
  }

  @Builder
  WardrobeSearchTabs() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(this.categoryLabels(), (category: string) => {
          Row({ space: 6 }) {
            this.CategoryFilterIcon(category)

            Text(category)
              .fontSize(13)
              .fontWeight(this.selectedCategoryLabel === category ? FontWeight.Regular : FontWeight.Regular)
              .fontColor(this.selectedCategoryLabel === category ? SCREENSHOT_BLUE : '#626267')
          }
          .width(76)
          .height(42)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .backgroundColor(this.selectedCategoryLabel === category ? SCREENSHOT_BLUE_BG : OPEN_DESIGN_SURFACE)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: this.selectedCategoryLabel === category ? '#8CB4EC' : OPEN_DESIGN_BORDER })
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
    .height(44)
  }

  @Builder
  CategoryFilterIcon(category: string) {
    if (category === '全部') {
      SymbolGlyph($r('sys.symbol.square_grid_2x2'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? SCREENSHOT_BLUE : SCREENSHOT_NAV_GRAY])
    } else if (category === '上衣') {
      SymbolGlyph($r('sys.symbol.shirt'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? SCREENSHOT_BLUE : SCREENSHOT_NAV_GRAY])
    } else if (category === '裤装') {
      SymbolGlyph($r('sys.symbol.clothing'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? SCREENSHOT_BLUE : SCREENSHOT_NAV_GRAY])
    } else if (category === '裙装') {
      SymbolGlyph($r('sys.symbol.hanger_and_towels'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? SCREENSHOT_BLUE : SCREENSHOT_NAV_GRAY])
    } else if (category === '包袋') {
      SymbolGlyph($r('sys.symbol.bag'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? SCREENSHOT_BLUE : SCREENSHOT_NAV_GRAY])
    } else {
      SymbolGlyph($r('sys.symbol.arrow_left_arrow_right'))
        .fontSize(14)
        .fontColor([this.selectedCategoryLabel === category ? SCREENSHOT_BLUE : SCREENSHOT_NAV_GRAY])
    }
  }

  @Builder
  WardrobeWaterFlow() {
    WaterFlow() {
      ForEach(this.visibleClothingItems(), (item: ClothingItem, index: number) => {
        FlowItem() {
          this.WardrobeSearchResultCard(item, index)
        }
        .width('100%')
      }, (item: ClothingItem) => item.id)
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(16)
    .rowsGap(20)
    .padding({ top: 4, bottom: 92 })
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  WardrobeSearchResultCard(item: ClothingItem, index: number) {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.isDesignFallbackPhoto(this.firstPhotoUri(item))) {
          Image(this.designDemoResource(index))
            .width('100%')
            .aspectRatio(this.wardrobeCardAspectRatio(index))
            .objectFit(ImageFit.Cover)
            .borderRadius(5)
        } else {
          Image(this.firstPhotoUri(item))
            .width('100%')
            .aspectRatio(this.wardrobeCardAspectRatio(index))
            .objectFit(ImageFit.Cover)
            .borderRadius(5)
        }

        Row() {
          this.CardCategoryIcon(item.category)

          Blank()
            .layoutWeight(1)

          if (!this.isDesignFallbackPhoto(this.firstPhotoUri(item))) {
            this.CardHeart()
          }
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8 })
        .alignItems(VerticalAlign.Top)
      }
      .width('100%')

      Row({ space: 8 }) {
        Text(this.displayItemTitle(item, index))
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .fontColor(OPEN_DESIGN_BLACK)
          .lineHeight(20)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.displayItemMeta(item, index))
          .fontSize(12)
          .fontColor(OPEN_DESIGN_MUTED)
          .lineHeight(20)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
        .width('100%')
        .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .onClick(() => {
      this.openClothingDetail(item);
    })
  }

  @Builder
  CardCategoryIcon(category: ClothingCategory) {
    Stack({ alignContent: Alignment.Center }) {
      if (category === ClothingCategory.Top) {
        SymbolGlyph($r('sys.symbol.shirt'))
          .fontSize(14)
          .fontColor([OPEN_DESIGN_BLACK])
      } else if (category === ClothingCategory.Pants || category === ClothingCategory.Shorts) {
        SymbolGlyph($r('sys.symbol.clothing'))
          .fontSize(14)
          .fontColor([OPEN_DESIGN_BLACK])
      } else {
        SymbolGlyph($r('sys.symbol.hanger_and_towels'))
          .fontSize(14)
          .fontColor([OPEN_DESIGN_BLACK])
      }
    }
    .width(28)
    .height(28)
    .backgroundColor('#E6FFFFFF')
    .borderRadius(14)
    .shadow({ radius: 8, color: '#16000000', offsetX: 0, offsetY: 3 })
  }

  @Builder
  CardHeart() {
    Stack({ alignContent: Alignment.Center }) {
      SymbolGlyph($r('sys.symbol.heart'))
        .fontSize(14)
        .fontColor([OPEN_DESIGN_BLACK])
    }
    .width(30)
    .height(30)
    .backgroundColor('#F5FFFFFF')
    .borderRadius(15)
    .shadow({ radius: 10, color: '#1A000000', offsetX: 0, offsetY: 4 })
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
          SymbolGlyph($r('sys.symbol.hanger_and_towels'))
            .fontSize(36)
            .fontColor([YibuqueColor.textPrimary])
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
        .fontWeight(FontWeight.Regular)
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
