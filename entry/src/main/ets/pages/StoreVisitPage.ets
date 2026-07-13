import { StoreRepository } from '../data/repositories/StoreRepository';
import { StoreVisit, StoreVisitStatus } from '../domain/store/StoreModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor } from '../theme/Tokens';
import { StoreVisitEditPage } from './StoreVisitEditPage';

interface StoreVisitStatusFilter {
  label: string;
  value: string;
}

const STORE_VISIT_STATUS_FILTERS: StoreVisitStatusFilter[] = [
  { label: '全部', value: 'all' },
  { label: '去过', value: 'visited' },
  { label: '想去', value: 'wantToVisit' },
  { label: '刷新', value: 'refresh' }
];

const PAGE_BACKGROUND = YibuqueColor.bgDefault;
const TEXT_PRIMARY = YibuqueColor.textPrimary;
const TEXT_MUTED = YibuqueColor.textSecondary;
const TEXT_META = YibuqueColor.textTertiary;
const BORDER = YibuqueColor.borderMedium;
const BORDER_SOFT = YibuqueColor.borderLight;
const SURFACE_WARM = YibuqueColor.cardSoftGray;
const ACCENT = YibuqueColor.brandCyan;
const ACCENT_SOFT = YibuqueColor.cardBlue;

@Component
export struct StoreVisitPage {
  @Prop initialVisitId: string = '';
  @Prop initialSearchQuery: string = '';
  storeRepository?: StoreRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onEditorVisibilityChange: (visible: boolean) => void = () => {};

  @State private visits: StoreVisit[] = [];
  @State private searchQuery: string = '';
  @State private selectedStatus: string = 'all';
  @State private showEditor: boolean = false;
  @State private editingVisitId: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadStoreVisits();
  }

  private async loadStoreVisits(): Promise<void> {
    if (this.storeRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';
    try {
      this.visits = await this.storeRepository.listStoreVisits();
      if (this.initialSearchQuery.length > 0) {
        this.searchQuery = this.initialSearchQuery;
      }
      if (this.initialVisitId.length > 0) {
        for (const visit of this.visits) {
          if (visit.id === this.initialVisitId) {
            this.openVisitEditor(visit);
            break;
          }
        }
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载逛店失败';
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

  private editingVisit(): StoreVisit | undefined {
    for (const visit of this.visits) {
      if (visit.id === this.editingVisitId) {
        return visit;
      }
    }
    return undefined;
  }

  private openVisitEditor(visit: StoreVisit): void {
    this.editingVisitId = visit.id;
    this.showEditor = true;
    this.onEditorVisibilityChange(true);
  }

  private closeEditor(): void {
    this.showEditor = false;
    this.editingVisitId = '';
    this.onEditorVisibilityChange(false);
  }

  private selectStatus(filter: StoreVisitStatusFilter): void {
    if (filter.value === 'refresh') {
      this.loadStoreVisits();
      return;
    }
    this.selectedStatus = filter.value;
  }

  private isSearching(): boolean {
    return this.searchQuery.trim().length > 0;
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

  private routeLocation(): string {
    for (const visit of this.visits) {
      if (visit.districtOrAddress !== undefined && visit.districtOrAddress.trim().length > 0) {
        return visit.districtOrAddress.trim();
      }
    }
    return '逛店随手记';
  }

  private routeVisitedCount(): number {
    let count = 0;
    for (const visit of this.visits) {
      if (this.visitStatus(visit) !== StoreVisitStatus.WantToVisit) {
        count += 1;
      }
    }
    return count;
  }

  private routeWantToVisitCount(): number {
    let count = 0;
    for (const visit of this.visits) {
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
          this.closeEditor();
        },
        onCancel: () => {
          this.closeEditor();
        }
      })
    } else {
      Column() {
        this.StoreVisitControls()

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
    }
  }

  @Builder
  StoreVisitControls() {
    Column({ space: 14 }) {
      Row({ space: 10 }) {
        Row({ space: 9 }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(18)
            .fontColor([TEXT_MUTED])

          TextInput({ text: this.searchQuery, placeholder: '搜索商场、品牌、试穿记录' })
            .height(46)
            .layoutWeight(1)
            .fontSize(14)
            .fontColor(TEXT_PRIMARY)
            .placeholderColor('#96969C')
            .backgroundColor(Color.Transparent)
            .enterKeyType(EnterKeyType.Search)
            .onChange((value: string) => {
              this.searchQuery = value;
            })
        }
        .height(48)
        .layoutWeight(1)
        .padding({ left: 14, right: 14 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(PAGE_BACKGROUND)
        .borderRadius(12)
        .border({ width: 1, color: BORDER })

      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Row({ space: 10 }) {
          ForEach(STORE_VISIT_STATUS_FILTERS, (filter: StoreVisitStatusFilter) => {
            Row({ space: 7 }) {
              this.StatusFilterIcon(filter.value)
              Text(filter.label)
                .fontSize(12)
                .fontWeight(this.selectedStatus === filter.value ? FontWeight.Regular : FontWeight.Regular)
                .fontColor(this.selectedStatus === filter.value ? YibuqueColor.textInverse : TEXT_MUTED)
            }
            .height(44)
            .padding({ left: 12, right: 15 })
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .backgroundColor(this.selectedStatus === filter.value ? TEXT_PRIMARY : SURFACE_WARM)
            .borderRadius(22)
            .border({ width: 1, color: this.selectedStatus === filter.value ? TEXT_PRIMARY : BORDER })
            .onClick(() => {
              this.selectStatus(filter);
            })
          }, (filter: StoreVisitStatusFilter) => filter.value)
        }
        .padding({ right: 10 })
        .alignItems(VerticalAlign.Center)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(48)
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
        Text(`今天路线：${this.routeLocation()}`)
          .width('100%')
          .fontSize(14)
          .lineHeight(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.routeVisitedCount()} 家去过，${this.routeWantToVisitCount()} 家想去。`)
          .width('100%')
          .fontSize(12)
          .fontColor(TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Stack({ alignContent: Alignment.Center }) {
        Text(`${this.visits.length}`)
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(ACCENT)
      }
      .width(38)
      .height(38)
      .backgroundColor(ACCENT_SOFT)
      .borderRadius(19)
    }
    .width('100%')
    .padding(12)
    .margin({ bottom: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(SURFACE_WARM)
    .borderRadius(18)
    .border({ width: 1, color: BORDER_SOFT })
  }

  @Builder
  StoreVisitWaterFlow() {
    WaterFlow() {
      ForEach(this.filterStoreVisits(), (visit: StoreVisit, index: number) => {
        FlowItem() {
          this.StoreVisitResultCard(visit, index)
        }
        .width('100%')
      }, (visit: StoreVisit) => visit.id)
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(13)
    .rowsGap(18)
    .padding({ bottom: 96 })
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  StoreVisitResultCard(visit: StoreVisit, index: number) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.coverPhotoUri(visit).length > 0) {
          Image(this.coverPhotoUri(visit))
            .width('100%')
            .aspectRatio(this.cardAspectRatio(index))
            .objectFit(ImageFit.Cover)
            .borderRadius(18)
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
          .borderRadius(18)
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
            .backgroundColor('#EFFFFFFF')
            .borderRadius(14)
            .shadow({ radius: 9, color: '#24000000', offsetX: 0, offsetY: 4 })
        }
        .width('100%')
        .padding({ top: 8, right: 8 })
      }
      .width('100%')

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
    .accessibilityText(`${visit.storeNameSnapshot}，${this.visitBadge(visit)}，${this.visitMeta(visit)}`)
    .onClick(() => {
      this.openVisitEditor(visit);
    })
  }

  @Builder
  LoadingState() {
    Column({ space: 8 }) {
      Text('正在加载逛店记录...')
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(TEXT_PRIMARY)
      Text('相机记录正在从本地衣橱读取。')
        .fontSize(12)
        .fontColor(TEXT_MUTED)
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(SURFACE_WARM)
    .borderRadius(18)
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
          .fontColor('#DC2626')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Button('重试')
        .height(36)
        .padding({ left: 14, right: 14 })
        .fontSize(13)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textInverse)
        .backgroundColor(TEXT_PRIMARY)
        .borderRadius(18)
        .onClick(() => {
          this.loadStoreVisits();
        })
    }
    .width('100%')
    .padding(18)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(SURFACE_WARM)
    .borderRadius(18)
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
      .borderRadius(18)
      .border({ width: 1, color: BORDER })

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
    .borderRadius(18)
  }
}
