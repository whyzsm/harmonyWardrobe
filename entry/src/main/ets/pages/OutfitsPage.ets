import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { DeleteImageOverlay } from '../components/DeleteImageOverlay';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitCategory, OutfitDisplaySource, OutfitTemplate } from '../domain/outfit/OutfitModels';
import { SearchEntityType } from '../domain/search/SearchModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueMotion, YibuqueRadius } from '../theme/Tokens';
import { ArrayDataSource } from '../utils/ArrayDataSource';
import { userFacingError } from '../utils/userFacingError';
import { OutfitDetailPage } from './OutfitDetailPage';
import { OutfitEditPage } from './OutfitEditPage';
import { SearchResultsPage } from './SearchResultsPage';
import { WearLogEditPage } from './WearLogEditPage';

const ERROR = YibuqueColor.danger;
const ERROR_BG = YibuqueColor.cardSoftGray;
function emptyWearLog(): WearLog {
  return {
    id: '',
    outfitTemplateId: undefined,
    outfitTitleSnapshot: '',
    clothingItemIdsSnapshot: [],
    wornDate: '',
    photoUris: [],
    placeText: undefined,
    note: undefined,
    createdAt: '',
    updatedAt: ''
  };
}

@Component
export struct OutfitsPage {
  @Prop initialOutfitId: string = '';
  @Prop @Watch('onInitialWearLogIdChange') initialWearLogId: string = '';
  outfitRepository?: OutfitRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  wearLogRepository?: WearLogRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onOpenCapture: () => void = () => {};
  onCreateOutfit: () => void = () => {};
  onOpenSearchTarget: (entityType: SearchEntityType, id: string, title: string) => void =
    (_entityType: SearchEntityType, _id: string, _title: string) => {};
  onInitialOutfitConsumed: () => void = () => {};
  onInitialWearLogConsumed: () => void = () => {};
  onNestedPageVisibilityChange: (visible: boolean) => void = () => {};

  @State private searchQuery: string = '';
  @State private selectedCategoryId: string = '';
  @State private categories: OutfitCategory[] = [];
  @State private outfits: OutfitTemplate[] = [];
  @State private outfitDataSource: ArrayDataSource<OutfitTemplate> = new ArrayDataSource<OutfitTemplate>();
  @State private clothingItems: ClothingItem[] = [];
  @State private selectedOutfitId: string = '';
  @State private showOutfitDetail: boolean = false;
  @State private detailOutfitId: string = '';
  @State private selectedWearLogId: string = '';
  @State private selectedWearLog: WearLog = emptyWearLog();
  @State private showOutfitEditor: boolean = false;
  @State private showWearLogEditor: boolean = false;
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private pressedOutfitCardId: string = '';
  @State private deletingOutfitId: string = '';
  @State private deleteOverlayOutfitId: string = '';
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  private outfitCardClickBlockedUntil: number = 0;
  private nestedPageTransitionInProgress: boolean = false;

  aboutToAppear(): void {
    this.loadOutfits();
  }

  aboutToDisappear(): void {
    this.onNestedPageVisibilityChange(false);
  }

  private async loadOutfits(): Promise<void> {
    if (this.outfitRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.outfits = await this.outfitRepository.listOutfits();
      this.categories = await this.outfitRepository.listOutfitCategories();
      this.ensureSelectedCategoryExists();
      this.refreshOutfitDataSource();
      if (this.clothingRepository !== undefined) {
        this.clothingItems = await this.clothingRepository.listClothing();
      }
      if (this.initialOutfitId.length > 0) {
        for (const outfit of this.outfits) {
          if (outfit.id === this.initialOutfitId) {
            this.openOutfitDetail(outfit);
            break;
          }
        }
        this.onInitialOutfitConsumed();
      }
      if (this.initialWearLogId.length > 0) {
        await this.openWearLogById(this.initialWearLogId);
        this.onInitialWearLogConsumed();
      }
    } catch (error) {
      this.errorMessage = userFacingError(error, '加载穿搭失败');
    } finally {
      this.loading = false;
    }
  }

  private ensureSelectedCategoryExists(): void {
    if (this.selectedCategoryId.length === 0) {
      return;
    }

    for (const category of this.categories) {
      if (category.id === this.selectedCategoryId) {
        return;
      }
    }

    this.selectedCategoryId = '';
  }

  private filterOutfits(): OutfitTemplate[] {
    const normalizedQuery = this.searchQuery.trim().toLowerCase();

    return this.outfits.filter((outfit: OutfitTemplate) => {
      const searchableText = `${outfit.title} ${outfit.categoryNames.join(' ')} ${outfit.note ?? ''}`.toLowerCase();
      const matchesQuery = normalizedQuery.length === 0 || searchableText.includes(normalizedQuery);
      if (!matchesQuery) {
        return false;
      }

      if (this.selectedCategoryId.length === 0) {
        return true;
      }

      return outfit.categoryIds.includes(this.selectedCategoryId);
    });
  }

  private refreshOutfitDataSource(): void {
    this.outfitDataSource.setData(this.filterOutfits());
  }

  private selectedClothingPhotoUris(outfit: OutfitTemplate): string[] {
    const photoUris: string[] = [];
    for (const clothingItemId of outfit.clothingItemIds) {
      for (const item of this.clothingItems) {
        if (item.id !== clothingItemId || item.photoUris.length === 0) {
          continue;
        }

        const photoUri = item.photoUris[0].trim();
        if (photoUri.length > 0) {
          photoUris.push(photoUri);
        }
        break;
      }
    }

    return photoUris;
  }

  private displayPhotoUris(outfit: OutfitTemplate): string[] {
    const clothingPhotoUris = this.selectedClothingPhotoUris(outfit);
    if (outfit.displaySource === OutfitDisplaySource.Wardrobe) {
      return clothingPhotoUris.length > 0 ? clothingPhotoUris : outfit.photoUris;
    }

    return outfit.photoUris.length > 0 ? outfit.photoUris : clothingPhotoUris;
  }

  private displayPhotoUriAt(outfit: OutfitTemplate, slot: number): string {
    const photoUris = this.displayPhotoUris(outfit);
    return photoUris.length > slot ? photoUris[slot] : '';
  }

  private displayPhotoCount(outfit: OutfitTemplate): number {
    return this.displayPhotoUris(outfit).length;
  }

  private outfitStackAspectRatio(index: number): number {
    return index % 4 === 2 ? 1 / 1.18 : 1 / 1.48;
  }

  private outfitCategoryLabel(outfit: OutfitTemplate): string {
    return outfit.categoryNames.length > 0 ? outfit.categoryNames.join('、') : '未分类';
  }

  private outfitDetailMeta(outfit: OutfitTemplate): string {
    const note = outfit.note?.trim() ?? '';
    return note.length > 0 ? note : `${outfit.clothingItemIds.length} 件单品`;
  }

  private displayOutfitTitle(outfit: OutfitTemplate): string {
    const autoTitlePattern = /^(穿搭|美搭) \d{2}-\d{2} \d{2}:\d{2}$/;
    const match = autoTitlePattern.exec(outfit.title.trim());
    return match === null ? outfit.title : match[1];
  }

  private selectedOutfit(): OutfitTemplate | undefined {
    if (this.selectedOutfitId.length === 0) {
      return undefined;
    }

    for (const outfit of this.outfits) {
      if (outfit.id === this.selectedOutfitId) {
        return outfit;
      }
    }

    return undefined;
  }

  private detailOutfit(): OutfitTemplate | undefined {
    for (const outfit of this.outfits) {
      if (outfit.id === this.detailOutfitId) {
        return outfit;
      }
    }
    return undefined;
  }

  private selectedWearLogForEditor(): WearLog | undefined {
    return this.selectedWearLogId.length > 0 ? this.selectedWearLog : undefined;
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

  private onInitialWearLogIdChange(): void {
    if (this.initialWearLogId.length > 0) {
      this.openInitialWearLog(this.initialWearLogId);
    }
  }

  private async openInitialWearLog(wearLogId: string): Promise<void> {
    await this.openWearLogById(wearLogId);
    this.onInitialWearLogConsumed();
  }

  private async openWearLogById(wearLogId: string): Promise<void> {
    if (this.wearLogRepository === undefined) {
      return;
    }

    const wearLog = await this.wearLogRepository.getWearLogById(wearLogId);
    if (wearLog === undefined) {
      return;
    }

    this.selectedWearLog = wearLog;
    this.selectedWearLogId = wearLog.id;
    this.selectedOutfitId = wearLog.outfitTemplateId ?? '';
    this.animateNestedPageChange(() => {
      this.showWearLogEditor = true;
      this.onNestedPageVisibilityChange(true);
    });
  }

  private onEditOutfit(outfit: OutfitTemplate): void {
    this.selectedOutfitId = outfit.id;
    this.animateNestedPageChange(() => {
      this.showOutfitEditor = true;
      this.onNestedPageVisibilityChange(true);
    });
  }

  private openOutfitDetail(outfit: OutfitTemplate): void {
    this.detailOutfitId = outfit.id;
    this.animateNestedPageChange(() => {
      this.showOutfitDetail = true;
      this.onNestedPageVisibilityChange(true);
    });
  }

  private closeOutfitDetail(): void {
    this.animateNestedPageChange(() => {
      this.showOutfitDetail = false;
      this.detailOutfitId = '';
      this.showUnifiedSearch = false;
      this.onNestedPageVisibilityChange(false);
    });
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
    this.refreshOutfitDataSource();
    this.refreshOutfitCategories();
  }

  private async refreshOutfitCategories(): Promise<void> {
    if (this.outfitRepository === undefined) {
      return;
    }

    try {
      this.categories = await this.outfitRepository.listOutfitCategories();
      this.ensureSelectedCategoryExists();
      this.refreshOutfitDataSource();
    } catch (error) {
      this.errorMessage = userFacingError(error, '加载分类失败');
    }
  }

  private async refreshOutfitsAfterCategoryChange(): Promise<void> {
    if (this.outfitRepository === undefined) {
      return;
    }

    this.outfits = await this.outfitRepository.listOutfits();
    this.categories = await this.outfitRepository.listOutfitCategories();
    this.ensureSelectedCategoryExists();
    this.refreshOutfitDataSource();
  }

  private async deleteOutfit(outfit: OutfitTemplate): Promise<void> {
    if (this.outfitRepository === undefined) {
      throw new Error('穿搭数据不可用，请稍后重试');
    }

    await this.outfitRepository.deleteOutfit(outfit.id);
    this.outfits = this.outfits.filter((existingOutfit: OutfitTemplate) => existingOutfit.id !== outfit.id);
    this.refreshOutfitDataSource();
    this.refreshOutfitCategories();
  }

  private confirmDeleteOutfitFromList(outfit: OutfitTemplate): void {
    if (this.deletingOutfitId.length > 0) {
      return;
    }

    this.pressedOutfitCardId = '';
    AlertDialog.show({
      title: '删除穿搭',
      message: `确定删除“${this.displayOutfitTitle(outfit)}”吗？穿搭照片会一并移除，已有穿着记录将保留但不再关联这套穿搭。`,
      primaryButton: {
        value: '取消',
        action: () => {
          this.deleteOverlayOutfitId = '';
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: YibuqueColor.danger,
        action: () => {
          this.deleteOutfitFromList(outfit);
        }
      }
    });
  }

  private async deleteOutfitFromList(outfit: OutfitTemplate): Promise<void> {
    if (this.deletingOutfitId.length > 0) {
      return;
    }

    this.deletingOutfitId = outfit.id;
    try {
      await this.deleteOutfit(outfit);
      this.getUIContext().getPromptAction().showToast({ message: '穿搭已删除' });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({
        message: userFacingError(error, '删除穿搭失败')
      });
    } finally {
      this.deletingOutfitId = '';
      this.deleteOverlayOutfitId = '';
    }
  }

  private showOutfitDeleteOverlay(outfit: OutfitTemplate): void {
    if (this.deletingOutfitId.length > 0) {
      return;
    }

    this.pressedOutfitCardId = '';
    this.deleteOverlayOutfitId = outfit.id;
    this.outfitCardClickBlockedUntil = Date.now() + 60000;
  }

  private handleOutfitCardClick(outfit: OutfitTemplate): void {
    if (Date.now() <= this.outfitCardClickBlockedUntil) {
      return;
    }

    if (this.deleteOverlayOutfitId.length > 0) {
      this.deleteOverlayOutfitId = '';
      return;
    }

    this.openOutfitDetail(outfit);
  }

  private async deleteWearLog(wearLog: WearLog): Promise<void> {
    if (this.wearLogRepository === undefined) {
      throw new Error('穿着记录仓库不可用，请稍后重试');
    }

    await this.wearLogRepository.deleteWearLog(wearLog.id);
    this.closeWearLogEditor();
  }

  private closeOutfitEditor(): void {
    this.animateNestedPageChange(() => {
      this.showOutfitEditor = false;
      this.selectedOutfitId = '';
      this.onNestedPageVisibilityChange(this.showOutfitDetail);
    });
  }

  private closeWearLogEditor(): void {
    this.animateNestedPageChange(() => {
      this.showWearLogEditor = false;
      this.selectedWearLog = emptyWearLog();
      this.selectedWearLogId = '';
      this.selectedOutfitId = '';
      this.onNestedPageVisibilityChange(this.showOutfitDetail);
    });
  }

  private retry(): void {
    this.loadOutfits();
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.animateNestedPageChange(() => {
      this.showUnifiedSearch = true;
      this.onNestedPageVisibilityChange(true);
    });
  }

  private openSearch(): void {
    this.openUnifiedSearch(this.searchQuery);
  }

  private closeUnifiedSearch(): void {
    this.animateNestedPageChange(() => {
      this.showUnifiedSearch = false;
      this.onNestedPageVisibilityChange(false);
    });
  }

  private async openOutfitSearchResult(id: string): Promise<void> {
    let targetOutfit: OutfitTemplate | undefined = undefined;
    for (const outfit of this.outfits) {
      if (outfit.id === id) {
        targetOutfit = outfit;
        break;
      }
    }

    if (targetOutfit === undefined && this.outfitRepository !== undefined) {
      targetOutfit = await this.outfitRepository.getOutfitById(id);
    }

    if (targetOutfit !== undefined) {
      this.detailOutfitId = targetOutfit.id;
      this.animateNestedPageChange(() => {
        this.showUnifiedSearch = false;
        this.showOutfitDetail = true;
        this.onNestedPageVisibilityChange(true);
      });
    }
  }

  build() {
    if (this.showOutfitEditor) {
      OutfitEditPage({
        initialOutfit: this.selectedOutfit(),
        clothingItems: this.clothingItems,
        outfitRepository: this.outfitRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (outfit: OutfitTemplate) => {
          this.upsertOutfit(outfit);
          this.closeOutfitEditor();
        },
        onCancel: () => {
          this.closeOutfitEditor();
        },
        onCategoriesChange: async (): Promise<void> => {
          await this.refreshOutfitsAfterCategoryChange();
        }
      })
        .transition(TransitionEffect.OPACITY)
    } else if (this.showWearLogEditor) {
      WearLogEditPage({
        initialWearLog: this.selectedWearLogForEditor(),
        initialOutfitTemplateId: this.selectedOutfitId,
        outfits: this.outfits,
        wearLogRepository: this.wearLogRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (_wearLog: WearLog) => {
          this.closeWearLogEditor();
        },
        onDelete: async (wearLog: WearLog): Promise<void> => {
          await this.deleteWearLog(wearLog);
        },
        onCancel: () => {
          this.closeWearLogEditor();
        }
      })
        .transition(TransitionEffect.OPACITY)
    } else if (this.showOutfitDetail) {
      OutfitDetailPage({
        outfit: this.detailOutfit(),
        clothingItems: this.clothingItems,
        onBack: () => {
          this.closeOutfitDetail();
        },
        onEdit: (outfit: OutfitTemplate) => {
          this.onEditOutfit(outfit);
        },
        onDelete: async (outfit: OutfitTemplate): Promise<void> => {
          await this.deleteOutfit(outfit);
          this.closeOutfitDetail();
        }
      })
        .transition(TransitionEffect.OPACITY)
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
          this.openOutfitSearchResult(id);
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
        .transition(TransitionEffect.OPACITY)
    } else {
      Stack() {
        Column({ space: 14 }) {
          this.OutfitSearchHeader()
          this.FilterStrip()
          this.OutfitGuideCard()

          if (this.loading) {
          Column({ space: 10 }) {
            LoadingProgress()
              .width(22)
              .height(22)
              .color(YibuqueColor.textPrimary)

            Text('正在加载穿搭...')
              .fontSize(14)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          } else if (this.errorMessage.length > 0) {
          Column({ space: 12 }) {
            Row({ space: 10 }) {
              Text(this.errorMessage)
                .fontSize(14)
                .fontColor(ERROR)
                .layoutWeight(1)
                .maxLines(3)

              Button('重试')
                .height(44)
                .fontSize(13)
                .fontColor(YibuqueColor.textInverse)
                .backgroundColor(ERROR)
                .borderRadius(YibuqueRadius.xxl)
                .onClick(() => {
                  this.retry();
                })
            }
            .width('100%')
            .padding(14)
            .backgroundColor(ERROR_BG)
            .borderRadius(YibuqueRadius.md)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20 })
          .justifyContent(FlexAlign.Center)
          } else if (this.outfits.length === 0) {
          Column({ space: 14 }) {
            this.OutfitEmptyState('还没有穿搭',
              '拍照或从相册选图后，按分类收进穿搭。',
              '点底部相机，选择照片后归类为穿搭',
              '穿搭会按图片组合流排在这里。')

          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20 })
          .justifyContent(FlexAlign.Start)
          } else if (this.filterOutfits().length === 0) {
          Column({ space: 14 }) {
            this.OutfitEmptyState('暂时没有这类穿搭',
              '当前分类下还没有匹配的穿搭。',
              '换一个分类看看，或查看全部穿搭',
              '已有穿搭会继续按图片组合流排在这里。')

            Button('查看全部')
              .height(44)
              .fontSize(14)
              .fontColor(YibuqueColor.textPrimary)
              .backgroundColor(YibuqueColor.cardSurface)
              .borderRadius(YibuqueRadius.xxxl)
              .onClick(() => {
                this.selectedCategoryId = '';
                this.refreshOutfitDataSource();
              })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20 })
          .justifyContent(FlexAlign.Center)
          } else {
          WaterFlow() {
            LazyForEach(this.outfitDataSource, (outfit: OutfitTemplate, index: number) => {
              FlowItem() {
                this.OutfitWallCard(outfit, index)
              }
              .width('100%')
            }, (outfit: OutfitTemplate) => outfit.id)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(16)
          .rowsGap(8)
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20, bottom: 96 })
          .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(YibuqueColor.bgDefault)
        .transition(TransitionEffect.OPACITY)

      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  OutfitSearchHeader() {
    Column() {
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

      TextInput({ text: this.searchQuery, placeholder: '搜索穿搭、分类、备注' })
        .height(46)
        .layoutWeight(1)
        .fontSize(14)
        .fontColor(YibuqueColor.textPrimary)
        .placeholderColor(YibuqueColor.textTertiary)
        .backgroundColor(YibuqueColor.transparent)
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string) => {
          this.searchQuery = value;
          this.refreshOutfitDataSource();
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
    .width('100%')
    .padding({ left: 20, right: 20, top: 14 })
  }

  @Builder
  OutfitEmptyState(title: string, description: string, guideTitle: string, guideDescription: string) {
    Column({ space: 10 }) {
      Column({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.hanger_and_towels'))
          .fontSize(36)
          .fontColor([YibuqueColor.textPrimary])

        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)

        Text(description)
          .fontSize(13)
          .lineHeight(19)
          .fontColor(YibuqueColor.textSecondary)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(190)
      .padding({ left: 18, right: 18 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: YibuqueColor.borderMedium })
      .accessibilityText('新增穿搭')
      .onClick(() => {
        this.onCreateOutfit();
      })

      Text(guideTitle)
        .fontSize(15)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .textAlign(TextAlign.Center)

      Text(guideDescription)
        .fontSize(12)
        .lineHeight(18)
        .fontColor(YibuqueColor.textSecondary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(8)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(YibuqueColor.bgDefault)
    .borderRadius(YibuqueRadius.xxl)
  }

  @Builder
  FilterStrip() {
    Row() {
      Scroll() {
        Row({ space: 8 }) {
          this.CategoryFilterChip('', '全部', true)

          ForEach(this.categories, (category: OutfitCategory) => {
            this.CategoryFilterChip(category.id, category.name, false)
          }, (category: OutfitCategory) => category.id)
        }
        .height(44)
      }
      .width('100%')
      .height(44)
      .align(Alignment.Start)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height(44)
    .padding({ left: 20, right: 20 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CategoryFilterChip(categoryId: string, label: string, system: boolean) {
    Button() {
      Row({ space: 6 }) {
        if (system) {
          SymbolGlyph($r('sys.symbol.hanger_and_towels'))
            .fontSize(17)
            .fontColor([this.selectedCategoryId === categoryId ? YibuqueColor.textInverse : YibuqueColor.textSecondary])
        } else {
          SymbolGlyph($r('sys.symbol.clothing'))
            .fontSize(17)
            .fontColor([this.selectedCategoryId === categoryId ? YibuqueColor.textInverse : YibuqueColor.textSecondary])
        }

        Text(label)
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(this.selectedCategoryId === categoryId ? YibuqueColor.textInverse : YibuqueColor.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .height(44)
    .constraintSize({ minWidth: 76, maxWidth: 168 })
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.selectedCategoryId === categoryId ? YibuqueColor.actionBlack : YibuqueColor.cardSoftGray)
    .borderRadius(YibuqueRadius.full)
    .border({
      width: 1,
      color: this.selectedCategoryId === categoryId ? YibuqueColor.borderStrong : YibuqueColor.borderMedium
    })
    .accessibilityText(`${label}${this.selectedCategoryId === categoryId ? '，已选中' : ''}`)
    .onClick(() => {
      this.selectedCategoryId = categoryId;
      this.refreshOutfitDataSource();
    })
  }

  @Builder
  OutfitGuideCard() {
    Row() {
      Row({ space: 12 }) {
        Column({ space: 2 }) {
          Text(this.clothingItems.length > 0 ? '从已有单品开始搭配' : '先添加衣物再创建穿搭')
            .fontSize(15)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .lineHeight(18)

          Text(this.clothingItems.length > 0 ?
            '选择衣柜里的真实单品，组合适合自己的穿搭。' :
            '衣柜中有单品后，就可以在这里创建搭配。')
            .fontSize(12)
            .fontColor(YibuqueColor.textSecondary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(`${this.clothingItems.length} 件`)
          .height(36)
          .padding({ left: 12, right: 12 })
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.iconAccentSurface)
          .borderRadius(YibuqueRadius.xxl)
      }
      .width('100%')
      .padding(14)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: YibuqueColor.borderLight })
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  @Builder
  OutfitWallCard(outfit: OutfitTemplate, index: number) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.displayPhotoCount(outfit) > 1) {
          Column({ space: 6 }) {
            this.OutfitPhoto(outfit, 0, 1.18)
            this.OutfitPhoto(outfit, 1, 0.92)
          }
          .width('100%')
          .height('100%')
        } else {
          this.SingleOutfitPhoto(outfit)
        }

        if (this.displayPhotoCount(outfit) > 2) {
          Text(`+${this.displayPhotoCount(outfit) - 2}`)
            .height(26)
            .padding({ left: 9, right: 9 })
            .margin({ right: 8, bottom: 8 })
            .fontSize(12)
            .fontColor(YibuqueColor.textInverse)
            .textAlign(TextAlign.Center)
            .backgroundColor(YibuqueColor.overlayDark)
            .borderRadius(YibuqueRadius.full)
        }

        if (this.deleteOverlayOutfitId === outfit.id) {
          DeleteImageOverlay({
            label: '删除穿搭',
            deleting: this.deletingOutfitId === outfit.id,
            cornerRadius: YibuqueRadius.xxl,
            onDelete: () => {
              this.outfitCardClickBlockedUntil = Date.now() + 300;
              this.confirmDeleteOutfitFromList(outfit);
            },
            onDismiss: () => {
              this.outfitCardClickBlockedUntil = Date.now() + 300;
              this.deleteOverlayOutfitId = '';
            }
          })
        }
      }
      .width('100%')
      .aspectRatio(this.outfitStackAspectRatio(index))
      .onClick(() => {
        this.handleOutfitCardClick(outfit);
      })
      .gesture(
        LongPressGesture({ repeat: false, duration: 500 })
          .onAction(() => {
            this.showOutfitDeleteOverlay(outfit);
          })
          .onActionEnd(() => {
            this.outfitCardClickBlockedUntil = Date.now() + 300;
          })
      )

      Row({ space: 8 }) {
        Column({ space: 2 }) {
          Row({ space: 6 }) {
            Text(this.displayOutfitTitle(outfit))
              .layoutWeight(1)
              .fontSize(14)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textPrimary)
              .lineHeight(17)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                this.handleOutfitCardClick(outfit);
              })

            Text(this.outfitCategoryLabel(outfit))
              .constraintSize({ maxWidth: 72 })
              .fontSize(11)
              .fontColor(YibuqueColor.textTertiary)
              .lineHeight(17)
              .maxLines(1)
              .textAlign(TextAlign.End)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.outfitDetailMeta(outfit))
            .fontSize(11)
            .fontColor(YibuqueColor.textTertiary)
            .lineHeight(15)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      }
      .width('100%')
      .constraintSize({ minHeight: 44 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .scale({ x: this.pressedOutfitCardId === outfit.id ? 0.98 : 1.0, y: this.pressedOutfitCardId === outfit.id ? 0.98 : 1.0 })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedOutfitCardId = outfit.id;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedOutfitCardId = '';
      }
    })
    .accessibilityTextHint('长按图片可显示删除操作')
  }

  @Builder
  SingleOutfitPhoto(outfit: OutfitTemplate) {
    if (this.displayPhotoUriAt(outfit, 0).length === 0) {
      Column({ space: 5 }) {
        SymbolGlyph($r('sys.symbol.picture'))
          .fontSize(24)
          .fontColor([YibuqueColor.textSecondary])

        Text('暂无照片')
          .fontSize(10)
          .fontColor(YibuqueColor.textTertiary)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
    } else {
      Image(this.displayPhotoUriAt(outfit, 0))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .borderRadius(YibuqueRadius.xxl)
    }
  }

  @Builder
  OutfitPhoto(outfit: OutfitTemplate, slot: number, weight: number) {
    if (this.displayPhotoUriAt(outfit, slot).length === 0) {
      Column({ space: 5 }) {
        SymbolGlyph($r('sys.symbol.picture'))
          .fontSize(24)
          .fontColor([YibuqueColor.textSecondary])

        Text('暂无照片')
          .fontSize(10)
          .fontColor(YibuqueColor.textTertiary)
      }
        .width('100%')
        .layoutWeight(weight)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.xxl)
    } else {
      Image(this.displayPhotoUriAt(outfit, slot))
        .width('100%')
        .layoutWeight(weight)
        .objectFit(ImageFit.Cover)
        .borderRadius(YibuqueRadius.xxl)
    }
  }
}
