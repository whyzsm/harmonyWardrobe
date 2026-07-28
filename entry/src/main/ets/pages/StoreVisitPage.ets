import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { DeleteImageOverlay } from '../components/DeleteImageOverlay';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { SearchEntityType } from '../domain/search/SearchModels';
import { StoreVisit, StoreVisitStatus } from '../domain/store/StoreModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { SavedFilterNotice } from '../components/SavedFilterNotice';
import {
  YibuqueColor,
  YibuqueMotion,
  YibuqueRadius,
  YibuqueShadow,
  YibuqueSpacing,
  YibuqueTransition
} from '../theme/Tokens';
import { ArrayDataSource } from '../utils/ArrayDataSource';
import { toIsoDate } from '../utils/date';
import { userFacingError } from '../utils/userFacingError';
import { SearchResultsPage } from './SearchResultsPage';
import { StoreVisitDetailPage } from './StoreVisitDetailPage';
import { StoreVisitEditPage } from './StoreVisitEditPage';

interface StoreVisitStatusFilter {
  label: string;
  value: string;
}

const STORE_VISIT_STATUS_FILTERS: StoreVisitStatusFilter[] = [
  { label: '全部', value: 'all' },
  { label: '去过', value: 'visited' },
  { label: '想去', value: 'wantToVisit' }
];

const PAGE_BACKGROUND = YibuqueColor.bgDefault;
const TEXT_PRIMARY = YibuqueColor.textPrimary;
const TEXT_MUTED = YibuqueColor.textSecondary;
const TEXT_META = YibuqueColor.textTertiary;
const BORDER = YibuqueColor.borderMedium;
const BORDER_SOFT = YibuqueColor.borderLight;
const SURFACE_WARM = YibuqueColor.cardSoftGray;
const PRIMARY_ACTION = YibuqueColor.actionBlack;
const ACCENT = YibuqueColor.selectionAccent;
const ACCENT_SOFT = YibuqueColor.selectionAccentSurface;

@Component
export struct StoreVisitPage {
  @Prop initialVisitId: string = '';
  @Prop initialSearchQuery: string = '';
  storeRepository?: StoreRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onEditorVisibilityChange: (visible: boolean) => void = () => {};
  onCreateStoreVisit: () => void = () => {};
  onInitialVisitConsumed: () => void = () => {};
  onOpenSearchTarget: (entityType: SearchEntityType, id: string, title: string) => void =
    (_entityType: SearchEntityType, _id: string, _title: string) => {};

  @State private visits: StoreVisit[] = [];
  @State private storeVisitDataSource: ArrayDataSource<StoreVisit> = new ArrayDataSource<StoreVisit>();
  @State private searchQuery: string = '';
  @State private selectedStatus: string = 'all';
  @State private showEditor: boolean = false;
  @State private editingVisitId: string = '';
  @State private showDetail: boolean = false;
  @State private detailVisitId: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private pressedVisitCardId: string = '';
  @State private deletingVisitId: string = '';
  @State private deleteOverlayVisitId: string = '';
  @State private savedVisitOutsideCurrentFilterId: string = '';
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @StorageProp('windowBottomInsetVp') private windowBottomInsetVp: number = YibuqueSpacing.bottomSafe;
  private visitCardClickBlockedUntil: number = 0;
  private nestedPageTransitionInProgress: boolean = false;

  aboutToAppear(): void {
    this.loadStoreVisits();
  }

  aboutToDisappear(): void {
    this.onEditorVisibilityChange(false);
  }

  private async loadStoreVisits(): Promise<void> {
    if (this.storeRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';
    try {
      this.visits = await this.storeRepository.listStoreVisits();
      this.refreshStoreVisitDataSource();
      if (this.initialSearchQuery.length > 0) {
        this.searchQuery = this.initialSearchQuery;
        this.refreshStoreVisitDataSource();
      }
      if (this.initialVisitId.length > 0) {
        for (const visit of this.visits) {
          if (visit.id === this.initialVisitId) {
            this.openVisitDetail(visit);
            break;
          }
        }
        this.onInitialVisitConsumed();
      }
    } catch (error) {
      this.errorMessage = userFacingError(error, '加载逛店失败');
    } finally {
      this.loading = false;
    }
  }

  private legacyWantToVisitRecord(visit: StoreVisit): boolean {
    const note = visit.note?.toLowerCase() ?? '';
    const intentWords: string[] = ['想去', '回看', '回头', '再去'];
    for (const word of intentWords) {
      if (note.includes(word)) {
        return true;
      }
    }
    return false;
  }

  private visitStatus(visit: StoreVisit): StoreVisitStatus {
    if (visit.status !== undefined) {
      return visit.status;
    }
    if (this.legacyWantToVisitRecord(visit)) {
      return StoreVisitStatus.WantToVisit;
    }
    if (visit.note?.includes('回购')) {
      return StoreVisitStatus.Repurchase;
    }
    return StoreVisitStatus.Visited;
  }

  private filterStoreVisits(): StoreVisit[] {
    const query = this.searchQuery.trim().toLowerCase();
    return this.visits.filter((visit: StoreVisit) => {
      const matchesQuery = query.length === 0 ||
        visit.storeNameSnapshot.toLowerCase().includes(query) ||
        visit.visitDate.toLowerCase().includes(query) ||
        (visit.districtOrAddress !== undefined && visit.districtOrAddress.toLowerCase().includes(query)) ||
        (visit.note !== undefined && visit.note.toLowerCase().includes(query)) ||
        (visit.focusTags !== undefined && visit.focusTags.join(' ').toLowerCase().includes(query));

      if (!matchesQuery) {
        return false;
      }
      if (this.selectedStatus === 'visited') {
        return this.visitStatus(visit) !== StoreVisitStatus.WantToVisit;
      }
      if (this.selectedStatus === 'wantToVisit') {
        return this.visitStatus(visit) === StoreVisitStatus.WantToVisit;
      }
      return true;
    });
  }

  private refreshStoreVisitDataSource(): void {
    this.storeVisitDataSource.setData(this.filterStoreVisits());
  }

  private editingVisit(): StoreVisit | undefined {
    for (const visit of this.visits) {
      if (visit.id === this.editingVisitId) {
        return visit;
      }
    }
    return undefined;
  }

  private detailVisit(): StoreVisit | undefined {
    for (const visit of this.visits) {
      if (visit.id === this.detailVisitId) {
        return visit;
      }
    }
    return undefined;
  }

  private detailStatusLabel(): string {
    const visit = this.detailVisit();
    return visit === undefined ? '已去' : this.visitBadge(visit);
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

  private openVisitDetail(visit: StoreVisit): void {
    this.detailVisitId = visit.id;
    this.animateNestedPageChange(() => {
      this.showDetail = true;
      this.onEditorVisibilityChange(true);
    });
  }

  private closeDetail(): void {
    this.animateNestedPageChange(() => {
      this.showDetail = false;
      this.detailVisitId = '';
      this.onEditorVisibilityChange(false);
    });
  }

  private openVisitEditor(visit: StoreVisit): void {
    this.editingVisitId = visit.id;
    this.animateNestedPageChange(() => {
      this.showEditor = true;
      this.onEditorVisibilityChange(true);
    });
  }

  private closeEditor(returnToList: boolean = false): void {
    this.animateNestedPageChange(() => {
      this.showEditor = false;
      this.editingVisitId = '';
      if (returnToList) {
        this.showDetail = false;
        this.detailVisitId = '';
      }
      this.onEditorVisibilityChange(this.showDetail);
    });
  }

  private selectStatus(filter: StoreVisitStatusFilter): void {
    this.selectedStatus = filter.value;
    this.refreshStoreVisitDataSource();
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.animateNestedPageChange(() => {
      this.showUnifiedSearch = true;
      this.onEditorVisibilityChange(true);
    });
  }

  private closeUnifiedSearch(): void {
    this.animateNestedPageChange(() => {
      this.showUnifiedSearch = false;
      this.onEditorVisibilityChange(false);
    });
  }

  private openSearch(): void {
    this.openUnifiedSearch(this.searchQuery);
  }

  private async openStoreVisitSearchResult(entityType: SearchEntityType, id: string, title: string): Promise<void> {
    if (entityType === SearchEntityType.Store) {
      this.searchQuery = title;
      this.refreshStoreVisitDataSource();
      this.closeUnifiedSearch();
      return;
    }
    if (entityType !== SearchEntityType.StoreVisit) {
      return;
    }

    let targetVisit: StoreVisit | undefined = undefined;
    for (const visit of this.visits) {
      if (visit.id === id) {
        targetVisit = visit;
        break;
      }
    }

    if (targetVisit === undefined && this.storeRepository !== undefined) {
      targetVisit = await this.storeRepository.getStoreVisitById(id);
    }

    if (targetVisit !== undefined) {
      this.detailVisitId = targetVisit.id;
      this.animateNestedPageChange(() => {
        this.showUnifiedSearch = false;
        this.showDetail = true;
        this.onEditorVisibilityChange(true);
      });
    }
  }

  private isSearching(): boolean {
    return this.searchQuery.trim().length > 0;
  }

  private routeSummaryText(): string {
    if (this.isSearching()) {
      return `找到 ${this.filterStoreVisits().length} 条逛店记录`;
    }

    return `${this.routeVisitedCount()} 家去过，${this.routeWantToVisitCount()} 家想去。`;
  }

  private upsertVisit(savedVisit: StoreVisit): void {
    const nextVisits: StoreVisit[] = [];
    let replaced = false;
    for (const visit of this.visits) {
      if (visit.id === savedVisit.id) {
        nextVisits.push(savedVisit);
        replaced = true;
      } else {
        nextVisits.push(visit);
      }
    }
    if (!replaced) {
      nextVisits.unshift(savedVisit);
    }
    this.visits = nextVisits;
    this.refreshStoreVisitDataSource();
    this.savedVisitOutsideCurrentFilterId = this.filterStoreVisits().some((visit: StoreVisit) => visit.id === savedVisit.id)
      ? ''
      : savedVisit.id;
  }

  private savedVisitIsOutsideCurrentFilter(): boolean {
    if (this.savedVisitOutsideCurrentFilterId.length === 0) {
      return false;
    }

    return !this.filterStoreVisits().some((visit: StoreVisit) => visit.id === this.savedVisitOutsideCurrentFilterId);
  }

  private showAllVisitsFromSaveNotice(): void {
    this.searchQuery = '';
    this.selectedStatus = 'all';
    this.savedVisitOutsideCurrentFilterId = '';
    this.refreshStoreVisitDataSource();
  }

  private async deleteStoreVisit(visit: StoreVisit): Promise<void> {
    if (this.storeRepository === undefined) {
      throw new Error('逛店仓库不可用，请稍后重试');
    }

    await this.storeRepository.deleteStoreVisit(visit.id);
    this.visits = this.visits.filter((existingVisit: StoreVisit) => existingVisit.id !== visit.id);
    this.refreshStoreVisitDataSource();
  }

  private confirmDeleteVisitFromList(visit: StoreVisit): void {
    if (this.deletingVisitId.length > 0) {
      return;
    }

    this.pressedVisitCardId = '';
    AlertDialog.show({
      title: '删除逛店记录',
      message: `确定删除“${visit.storeNameSnapshot}”的这条逛店记录吗？本地照片会一并移除，门店资料仍会保留。`,
      primaryButton: {
        value: '取消',
        action: () => {
          this.deleteOverlayVisitId = '';
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: YibuqueColor.danger,
        action: () => {
          this.deleteVisitFromList(visit);
        }
      }
    });
  }

  private async deleteVisitFromList(visit: StoreVisit): Promise<void> {
    if (this.deletingVisitId.length > 0) {
      return;
    }

    this.deletingVisitId = visit.id;
    try {
      await this.deleteStoreVisit(visit);
      this.getUIContext().getPromptAction().showToast({ message: '逛店记录已删除' });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({
        message: userFacingError(error, '删除逛店记录失败')
      });
    } finally {
      this.deletingVisitId = '';
      this.deleteOverlayVisitId = '';
    }
  }

  private showVisitDeleteOverlay(visit: StoreVisit): void {
    if (this.deletingVisitId.length > 0) {
      return;
    }

    this.pressedVisitCardId = '';
    this.deleteOverlayVisitId = visit.id;
    this.visitCardClickBlockedUntil = Date.now() + 60000;
  }

  private handleVisitCardClick(visit: StoreVisit): void {
    if (Date.now() <= this.visitCardClickBlockedUntil) {
      return;
    }

    if (this.deleteOverlayVisitId.length > 0) {
      this.deleteOverlayVisitId = '';
      return;
    }

    this.openVisitDetail(visit);
  }

  private coverPhotoUri(visit: StoreVisit): string {
    return visit.photoUris.length > 0 ? visit.photoUris[0] : '';
  }

  private cardAspectRatio(index: number): number {
    if (index % 4 === 0) {
      return 0.704;
    }
    if (index % 4 === 2) {
      return 0.98;
    }
    return 0.833;
  }

  private visitBadge(visit: StoreVisit): string {
    const status = this.visitStatus(visit);
    if (status === StoreVisitStatus.WantToVisit) {
      return '想去';
    }
    if (status === StoreVisitStatus.Repurchase) {
      return '回购';
    }
    return '已去';
  }

  private visitMeta(visit: StoreVisit): string {
    if (visit.focusTags !== undefined && visit.focusTags.length > 0) {
      return visit.focusTags.join(' · ');
    }
    const detail = visit.note?.trim() ?? visit.districtOrAddress?.trim() ?? '';
    return detail.length > 0 ? detail : visit.visitDate;
  }

  private routeVisits(): StoreVisit[] {
    const today = toIsoDate(new Date());
    const todayVisits = this.visits.filter((visit: StoreVisit) => visit.visitDate === today);
    return todayVisits.length > 0 ? todayVisits : this.visits;
  }

  private hasTodayRoute(): boolean {
    const today = toIsoDate(new Date());
    return this.visits.some((visit: StoreVisit) => visit.visitDate === today);
  }

  private routeLocation(): string {
    for (const visit of this.routeVisits()) {
      if (visit.districtOrAddress !== undefined && visit.districtOrAddress.trim().length > 0) {
        return visit.districtOrAddress.trim();
      }
    }
    return '逛店随手记';
  }

  private routeVisitedCount(): number {
    let count = 0;
    for (const visit of this.routeVisits()) {
      if (this.visitStatus(visit) !== StoreVisitStatus.WantToVisit) {
        count += 1;
      }
    }
    return count;
  }

  private routeWantToVisitCount(): number {
    let count = 0;
    for (const visit of this.routeVisits()) {
      if (this.visitStatus(visit) === StoreVisitStatus.WantToVisit) {
        count += 1;
      }
    }
    return count;
  }

  build() {
    if (this.showEditor) {
      StoreVisitEditPage({
        initialVisit: this.editingVisit(),
        storeRepository: this.storeRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (visit: StoreVisit) => {
          this.upsertVisit(visit);
          this.closeEditor(true);
        },
        onCancel: () => {
          this.closeEditor();
        }
      })
        .transition(YibuqueTransition.fullScreenOpacity)
    } else if (this.showDetail) {
      StoreVisitDetailPage({
        visit: this.detailVisit(),
        statusLabel: this.detailStatusLabel(),
        onBack: () => {
          this.closeDetail();
        },
        onEdit: (visit: StoreVisit) => {
          this.openVisitEditor(visit);
        },
        onDelete: async (visit: StoreVisit): Promise<void> => {
          await this.deleteStoreVisit(visit);
          this.closeDetail();
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
          this.onOpenSearchTarget(SearchEntityType.Clothing, id, '');
        },
        onOpenOutfitResult: (id: string) => {
          this.onOpenSearchTarget(SearchEntityType.Outfit, id, '');
        },
        onOpenStoreResult: (entityType: SearchEntityType, id: string, title: string) => {
          this.openStoreVisitSearchResult(entityType, id, title);
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
      Column() {
        this.StoreVisitControls()

        SavedFilterNotice({
          visible: this.savedVisitIsOutsideCurrentFilter(),
          onViewAll: () => {
            this.showAllVisitsFromSaveNotice();
          }
        })

        if (this.loading) {
          this.LoadingState()
        } else if (this.errorMessage.length > 0) {
          this.ErrorState()
        } else {
          if (this.visits.length > 0) {
            this.RouteCard()
          }
          if (this.filterStoreVisits().length === 0) {
            this.EmptyState()
          } else {
            this.StoreVisitWaterFlow()
          }
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 0 })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(PAGE_BACKGROUND)
      .transition(YibuqueTransition.fullScreenOpacity)
    }
  }

  @Builder
  StoreVisitControls() {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Row({ space: 9 }) {
          Stack({ alignContent: Alignment.Center }) {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontSize(18)
              .fontColor([TEXT_MUTED])
          }
          .width(44)
          .height(46)
          .accessibilityText('执行搜索')
          .onClick(() => {
            this.openSearch();
          })

          TextInput({ text: this.searchQuery, placeholder: '搜索商场、品牌、试穿记录' })
            .height(46)
            .layoutWeight(1)
            .fontSize(14)
            .fontColor(TEXT_PRIMARY)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.transparent)
            .accessibilityText('搜索逛店记录')
            .enterKeyType(EnterKeyType.Search)
            .onChange((value: string) => {
              this.searchQuery = value;
              this.refreshStoreVisitDataSource();
            })
            .onClick(() => {
              this.openSearch();
            })
            .onSubmit(() => {
              this.openSearch();
            })
        }
        .height(48)
        .layoutWeight(1)
        .padding({ left: 14, right: 14 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(PAGE_BACKGROUND)
        .borderRadius(YibuqueRadius.md)
        .border({ width: 1, color: BORDER })

      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 6 }) {
        ForEach(STORE_VISIT_STATUS_FILTERS, (filter: StoreVisitStatusFilter) => {
          Row({ space: 6 }) {
            this.StatusFilterIcon(filter.value)
            Text(filter.label)
              .fontSize(12)
              .fontWeight(this.selectedStatus === filter.value ? FontWeight.Regular : FontWeight.Regular)
              .fontColor(this.selectedStatus === filter.value ? YibuqueColor.textInverse : TEXT_MUTED)
          }
          .constraintSize({ minWidth: 0, minHeight: 44 })
          .padding({ left: 8, right: 8 })
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .backgroundColor(this.selectedStatus === filter.value ? YibuqueColor.actionBlack : SURFACE_WARM)
          .borderRadius(YibuqueRadius.xxxl)
          .border({ width: 1, color: this.selectedStatus === filter.value ? YibuqueColor.actionBlack : BORDER })
          .accessibilityText(`${filter.label}${this.selectedStatus === filter.value ? '，已选中' : ''}`)
          .onClick(() => {
            this.selectStatus(filter);
          })
        }, (filter: StoreVisitStatusFilter) => filter.value)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StatusFilterIcon(status: string) {
    if (status === 'all') {
      SymbolGlyph($r('sys.symbol.square_grid_2x2'))
        .fontSize(17)
        .fontColor([this.selectedStatus === status ? YibuqueColor.textInverse : TEXT_MUTED])
    } else if (status === 'visited') {
      SymbolGlyph($r('sys.symbol.store_fill'))
        .fontSize(17)
        .fontColor([this.selectedStatus === status ? YibuqueColor.textInverse : TEXT_MUTED])
    } else if (status === 'wantToVisit') {
      SymbolGlyph($r('sys.symbol.heart'))
        .fontSize(17)
        .fontColor([this.selectedStatus === status ? YibuqueColor.textInverse : TEXT_MUTED])
    } else {
      SymbolGlyph($r('sys.symbol.arrow_clockwise'))
        .fontSize(17)
        .fontColor([TEXT_MUTED])
    }
  }

  @Builder
  RouteCard() {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(`${this.hasTodayRoute() ? '今天路线' : '最近路线'}：${this.routeLocation()}`)
          .width('100%')
          .fontSize(14)
          .lineHeight(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.routeSummaryText())
          .width('100%')
          .fontSize(12)
          .fontColor(TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Stack({ alignContent: Alignment.Center }) {
        Text(`${this.isSearching() ? this.filterStoreVisits().length : this.visits.length}`)
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(ACCENT)
      }
      .width(44)
      .height(44)
      .backgroundColor(ACCENT_SOFT)
      .borderRadius(YibuqueRadius.xxl)
    }
    .width('100%')
    .padding(12)
    .margin({ bottom: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(SURFACE_WARM)
    .borderRadius(YibuqueRadius.xxl)
    .border({ width: 1, color: BORDER_SOFT })
  }

  @Builder
  StoreVisitWaterFlow() {
    WaterFlow() {
      LazyForEach(this.storeVisitDataSource, (visit: StoreVisit, index: number) => {
        FlowItem() {
          this.StoreVisitResultCard(visit, index)
        }
        .width('100%')
      }, (visit: StoreVisit) => visit.id)
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
  StoreVisitResultCard(visit: StoreVisit, index: number) {
    Column({ space: 2 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.coverPhotoUri(visit).length > 0) {
          Image(this.coverPhotoUri(visit))
            .width('100%')
            .aspectRatio(this.cardAspectRatio(index))
            .objectFit(ImageFit.Cover)
            .borderRadius(YibuqueRadius.xxl)
        } else {
          Column({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.store_fill'))
              .fontSize(34)
              .fontColor([TEXT_MUTED])
            Text('暂无照片')
              .fontSize(12)
              .fontColor(TEXT_META)
          }
          .width('100%')
          .aspectRatio(this.cardAspectRatio(index))
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(SURFACE_WARM)
          .borderRadius(YibuqueRadius.xxl)
        }

        Row() {
          Blank().layoutWeight(1)
          Text(this.visitBadge(visit))
            .height(28)
            .padding({ left: 9, right: 9 })
            .fontSize(11)
            .fontWeight(FontWeight.Regular)
            .fontColor(TEXT_PRIMARY)
            .textAlign(TextAlign.Center)
            .backgroundColor(YibuqueColor.glassStrong)
            .borderRadius(YibuqueRadius.lg)
            .shadow(YibuqueShadow.soft)
        }
        .width('100%')
        .padding({ top: 8, right: 8 })

        if (this.deleteOverlayVisitId === visit.id) {
          DeleteImageOverlay({
            label: '删除逛店记录',
            deleting: this.deletingVisitId === visit.id,
            cornerRadius: YibuqueRadius.xxl,
            onDelete: () => {
              this.visitCardClickBlockedUntil = Date.now() + 300;
              this.confirmDeleteVisitFromList(visit);
            },
            onDismiss: () => {
              this.visitCardClickBlockedUntil = Date.now() + 300;
              this.deleteOverlayVisitId = '';
            }
          })
        }
      }
      .width('100%')
      .aspectRatio(this.cardAspectRatio(index))
      .priorityGesture(
        LongPressGesture({ repeat: false, duration: 500 })
          .onAction(() => {
            this.showVisitDeleteOverlay(visit);
          })
          .onActionEnd(() => {
            this.visitCardClickBlockedUntil = Date.now() + 300;
          })
      )

      Row({ space: 8 }) {
        Text(visit.storeNameSnapshot)
          .layoutWeight(1)
          .fontSize(14)
          .lineHeight(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(TEXT_PRIMARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.visitMeta(visit))
          .width(78)
          .fontSize(11)
          .fontColor(TEXT_META)
          .textAlign(TextAlign.End)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .margin({ top: index % 4 === 3 ? 6 : 0 })
    .scale({ x: this.pressedVisitCardId === visit.id ? 0.98 : 1.0, y: this.pressedVisitCardId === visit.id ? 0.98 : 1.0 })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedVisitCardId = visit.id;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedVisitCardId = '';
      }
    })
    .accessibilityText(`${visit.storeNameSnapshot}，${this.visitBadge(visit)}，${this.visitMeta(visit)}`)
    .onClick(() => {
      this.handleVisitCardClick(visit);
    })
    .accessibilityTextHint('长按图片可显示删除操作')
  }

  @Builder
  LoadingState() {
    Column({ space: 8 }) {
      LoadingProgress()
        .width(22)
        .height(22)
        .color(TEXT_PRIMARY)

      Text('正在加载逛店记录...')
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(TEXT_PRIMARY)
      Text('逛店记录正在从本地衣柜读取。')
        .fontSize(12)
        .fontColor(TEXT_MUTED)
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(SURFACE_WARM)
    .borderRadius(YibuqueRadius.xxl)
    .border({ width: 1, color: BORDER })
  }

  @Builder
  ErrorState() {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text('逛店记录暂时没有加载成功')
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .fontColor(TEXT_PRIMARY)
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor(YibuqueColor.danger)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Button('重试')
        .height(44)
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textInverse)
            .backgroundColor(PRIMARY_ACTION)
        .borderRadius(YibuqueRadius.xxl)
        .onClick(() => {
          this.loadStoreVisits();
        })
    }
    .width('100%')
    .padding(18)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(SURFACE_WARM)
    .borderRadius(YibuqueRadius.xxl)
    .border({ width: 1, color: BORDER })
  }

  @Builder
  EmptyState() {
    Column({ space: 10 }) {
      Column({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.store_fill'))
          .fontSize(36)
          .fontColor([TEXT_PRIMARY])
        Text(this.isSearching() ? '没有找到相关逛店记录' : this.visits.length === 0 ? '还没有逛店记录' : '这个状态下还没有逛店记录')
          .fontSize(16)
          .fontWeight(FontWeight.Regular)
          .fontColor(TEXT_PRIMARY)
          .textAlign(TextAlign.Center)
        Text(this.isSearching() ? '可以换个商场、品牌或试穿关键词。' : this.visits.length === 0 ? '拍照或从相册选图后，按状态收进逛店。' : '当前状态下没有匹配记录。')
          .fontSize(13)
          .lineHeight(19)
          .fontColor(TEXT_MUTED)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(190)
      .padding({ left: 18, right: 18 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(SURFACE_WARM)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: BORDER })
      .accessibilityText(this.isSearching() ? '没有找到相关逛店记录' : '新增逛店记录')
      .onClick(() => {
        if (!this.isSearching() && this.visits.length === 0) {
          this.onCreateStoreVisit();
        }
      })

      Text(this.isSearching() ? '换个关键词，看看其它逛店记录' : this.visits.length === 0 ? '点底部相机，打开快捷录入里的新增逛店。' : '切换状态，看看其他逛店记录。')
        .fontSize(15)
        .fontWeight(FontWeight.Regular)
        .fontColor(TEXT_PRIMARY)
        .textAlign(TextAlign.Center)

      Text(this.isSearching() ? '也可以清空搜索回到全部逛店。' : this.visits.length === 0 ? '逛店会按图片记录流排在这里。' : '已有逛店记录会按图片墙排在这里。')
        .fontSize(12)
        .lineHeight(18)
        .fontColor(TEXT_MUTED)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(8)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(PAGE_BACKGROUND)
    .borderRadius(YibuqueRadius.xxl)
  }
}
