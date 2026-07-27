import common from '@ohos.app.ability.common';
import { window } from '@kit.ArkUI';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { SearchEntityType, SearchResult } from '../domain/search/SearchModels';
import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';
import { ArrayDataSource } from '../utils/ArrayDataSource';
import { userFacingError } from '../utils/userFacingError';

interface SearchVisualResult {
  entityType: SearchEntityType;
  entityId: string;
  title: string;
  subtitle: string;
  photoUri: string;
}

interface SearchScopeOption {
  key: string;
  label: string;
}

const SEARCH_SCOPES: SearchScopeOption[] = [
  { key: 'all', label: '全部' },
  { key: 'clothes', label: '衣柜' },
  { key: 'shops', label: '逛店' },
  { key: 'outfits', label: '穿搭' }
];

const DEFAULT_SEARCH_TERM = '上衣';

function entityTypeLabel(entityType: SearchEntityType): string {
  if (entityType === SearchEntityType.Clothing) {
    return '衣柜';
  }
  if (entityType === SearchEntityType.Outfit) {
    return '穿搭';
  }
  if (entityType === SearchEntityType.StoreVisit) {
    return '逛店记录';
  }
  if (entityType === SearchEntityType.Store) {
    return '店铺';
  }
  if (entityType === SearchEntityType.WearLog) {
    return '穿着';
  }
  if (entityType === SearchEntityType.Wishlist) {
    return '心愿';
  }
  return '';
}

function firstUsablePhoto(photoUris: string[]): string {
  for (const photoUri of photoUris) {
    if (photoUri.length > 0) {
      return photoUri;
    }
  }
  return '';
}

function clothingCategoryLabel(category: ClothingCategory): string {
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

@Component
export struct SearchResultsPage {
  @Prop query: string = '';
  @Prop initialScope?: SearchEntityType = undefined;
  searchRepository?: SearchRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  onClose: () => void = () => {};
  onOpenClothingResult: (id: string) => void = (_id: string) => {};
  onOpenOutfitResult: (id: string) => void = (_id: string) => {};
  onOpenStoreResult: (entityType: SearchEntityType, id: string, title: string) => void =
    (_entityType: SearchEntityType, _id: string, _title: string) => {};
  onOpenWishlistResult: (id: string) => void = (_id: string) => {};
  onOpenWearLogResult: (id: string) => void = (_id: string) => {};
  onOpenProfileResult: (entityType: SearchEntityType, id: string) => void =
    (_entityType: SearchEntityType, _id: string) => {};

  @State private searchText: string = '';
  @State private activeQuery: string = '';
  @State private selectedScope: string = 'all';
  @State private historyTerms: string[] = [];
  @State private searchResults: SearchResult[] = [];
  @State private visualResults: SearchVisualResult[] = [];
  @State private visualResultDataSource: ArrayDataSource<SearchVisualResult> = new ArrayDataSource<SearchVisualResult>();
  @State private isSearching: boolean = false;
  @State private errorMessage: string = '';
  @State private inputErrorMessage: string = '';
  private searchRequestVersion: number = 0;
  private searchWindow?: window.Window = undefined;
  private previousStatusBarColor: string = YibuqueColor.bgDefault;
  private previousStatusBarLightIcon: boolean = true;
  private searchStatusBarColorApplied: boolean = false;

  aboutToAppear(): void {
    this.applySearchStatusBarColor();
    const initialQuery = this.query.trim();
    this.searchText = initialQuery.length > 0 ? this.query : '';
    this.activeQuery = initialQuery;
    this.selectedScope = this.initialScope ?? 'all';
    if (this.activeQuery.length > 0) {
      this.performSearch(this.activeQuery);
    }
  }

  aboutToDisappear(): void {
    this.restoreSearchStatusBarColor();
  }

  private async applySearchStatusBarColor(): Promise<void> {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      return;
    }

    try {
      const searchWindow = await window.getLastWindow(hostContext as common.Context);
      const previousProperties = searchWindow.getWindowSystemBarProperties();
      this.searchWindow = searchWindow;
      this.previousStatusBarColor = previousProperties.statusBarColor ?? YibuqueColor.bgDefault;
      this.previousStatusBarLightIcon = previousProperties.isStatusBarLightIcon ?? true;
      await searchWindow.setWindowSystemBarProperties({
        statusBarColor: YibuqueColor.searchHeaderSurface,
        isStatusBarLightIcon: true
      });
      this.searchStatusBarColorApplied = true;
    } catch (_error) {
      this.searchWindow = undefined;
    }
  }

  private async restoreSearchStatusBarColor(): Promise<void> {
    if (!this.searchStatusBarColorApplied || this.searchWindow === undefined) {
      return;
    }

    const searchWindow = this.searchWindow;
    this.searchStatusBarColorApplied = false;
    try {
      await searchWindow.setWindowSystemBarProperties({
        statusBarColor: this.previousStatusBarColor,
        isStatusBarLightIcon: this.previousStatusBarLightIcon
      });
    } catch (_error) {
      // The window may already be closing; there is nothing to restore in that case.
    } finally {
      this.searchWindow = undefined;
    }
  }

  private async performSearch(searchQuery: string): Promise<void> {
    if (this.searchRepository === undefined || searchQuery.trim().length === 0) {
      this.searchResults = [];
      this.visualResults = [];
      this.refreshVisualResultDataSource();
      return;
    }

    const requestVersion = ++this.searchRequestVersion;
    this.isSearching = true;
    this.errorMessage = '';

    try {
      const results = await this.searchRepository.search(searchQuery, 100);
      const supportedResults = results.filter((result: SearchResult) => {
        return entityTypeLabel(result.entityType).length > 0 && this.matchesInitialScope(result.entityType);
      });
      const clothingItems = await this.loadClothingItems();
      const outfits = await this.loadOutfits();
      if (requestVersion !== this.searchRequestVersion) {
        return;
      }
      this.searchResults = supportedResults;
      this.visualResults = this.buildVisualResults(supportedResults, clothingItems, outfits);
      this.refreshVisualResultDataSource();
    } catch (error) {
      if (requestVersion !== this.searchRequestVersion) {
        return;
      }
      this.errorMessage = userFacingError(error, '搜索失败');
      this.visualResults = [];
      this.refreshVisualResultDataSource();
    } finally {
      if (requestVersion === this.searchRequestVersion) {
        this.isSearching = false;
      }
    }
  }

  private async loadClothingItems(): Promise<ClothingItem[]> {
    if (this.clothingRepository === undefined) {
      return [];
    }

    try {
      return await this.clothingRepository.listClothing();
    } catch (_error) {
      return [];
    }
  }

  private async loadOutfits(): Promise<OutfitTemplate[]> {
    if (this.outfitRepository === undefined) {
      return [];
    }

    try {
      return await this.outfitRepository.listOutfits();
    } catch (_error) {
      return [];
    }
  }

  private buildVisualResults(
    results: SearchResult[],
    clothingItems: ClothingItem[],
    outfits: OutfitTemplate[]
  ): SearchVisualResult[] {
    const nextResults: SearchVisualResult[] = [];

    for (const result of results) {
      let title = result.title;
      let subtitle = entityTypeLabel(result.entityType);
      let photoUri = '';

      if (result.entityType === SearchEntityType.Clothing) {
        for (const item of clothingItems) {
          if (item.id === result.entityId) {
            const category = clothingCategoryLabel(item.category);
            const autoNamePattern = new RegExp(`^${category} \\d{2}-\\d{2} \\d{2}:\\d{2}$`);
            const note = item.note?.trim() ?? '';
            title = autoNamePattern.test(item.name) ? category : item.name;
            subtitle = note.length > 0 ? `${category} · ${note}` : category;
            photoUri = firstUsablePhoto(item.photoUris);
            break;
          }
        }
      } else if (result.entityType === SearchEntityType.Outfit) {
        for (const outfit of outfits) {
          if (outfit.id === result.entityId) {
            const note = outfit.note?.trim() ?? '';
            subtitle = note.length > 0
              ? `${outfit.clothingItemIds.length} 件单品 · ${note}`
              : `${outfit.clothingItemIds.length} 件单品`;
            photoUri = firstUsablePhoto(outfit.photoUris);
            break;
          }
        }
      }

      nextResults.push({
        entityType: result.entityType,
        entityId: result.entityId,
        title,
        subtitle,
        photoUri
      });
    }

    return nextResults;
  }

  private submitSearch(term: string = ''): void {
    if (term.length > 0) {
      this.searchText = term;
    }

    const trimmedQuery = this.searchText.trim();
    const nextQuery = trimmedQuery.length > 0 ? trimmedQuery : DEFAULT_SEARCH_TERM;
    this.searchText = nextQuery;

    this.activeQuery = nextQuery;
    this.errorMessage = '';
    this.inputErrorMessage = '';
    const nextHistory: string[] = [nextQuery];
    for (const historyTerm of this.historyTerms) {
      if (historyTerm !== nextQuery) {
        nextHistory.push(historyTerm);
      }
    }
    this.historyTerms = nextHistory.slice(0, 8);
    this.performSearch(nextQuery);
  }

  private clearSearch(): void {
    this.searchRequestVersion += 1;
    this.searchText = '';
    this.activeQuery = '';
    this.searchResults = [];
    this.visualResults = [];
    this.refreshVisualResultDataSource();
    this.errorMessage = '';
    this.inputErrorMessage = '';
  }

  private clearHistory(): void {
    this.historyTerms = [];
  }

  private matchesInitialScope(entityType: SearchEntityType): boolean {
    return this.initialScope === undefined || entityType === this.initialScope;
  }

  private availableScopes(): SearchScopeOption[] {
    if (this.initialScope !== undefined) {
      return [{ key: this.initialScope, label: entityTypeLabel(this.initialScope) }];
    }
    return SEARCH_SCOPES;
  }

  private resultMatchesScope(result: SearchVisualResult): boolean {
    if (this.initialScope !== undefined) {
      return result.entityType === this.initialScope;
    }
    if (this.selectedScope === 'all') {
      return true;
    }
    if (this.selectedScope === 'clothes') {
      return result.entityType === SearchEntityType.Clothing;
    }
    if (this.selectedScope === 'shops') {
      return result.entityType === SearchEntityType.Store || result.entityType === SearchEntityType.StoreVisit;
    }
    if (this.selectedScope === 'outfits') {
      return result.entityType === SearchEntityType.Outfit;
    }
    return false;
  }

  private filteredVisualResults(): SearchVisualResult[] {
    return this.visualResults.filter((result: SearchVisualResult) => this.resultMatchesScope(result));
  }

  private emptyResultTitle(): string {
    if (this.initialScope !== undefined) {
      return `没有找到「${this.activeQuery}」`;
    }

    if (this.selectedScope === 'clothes') {
      return '没有找到相关衣柜';
    }
    if (this.selectedScope === 'shops') {
      return '没有找到相关逛店记录';
    }
    if (this.selectedScope === 'outfits') {
      return '没有找到相关穿搭';
    }
    return `没有找到「${this.activeQuery}」`;
  }

  private emptyResultDescription(): string {
    if (this.initialScope !== undefined) {
      return '换个名称、门店、分类或备注关键词。';
    }

    if (this.selectedScope === 'clothes') {
      return '换个衣柜名称、分类或备注。';
    }
    if (this.selectedScope === 'shops') {
      return '换个商场、品牌或试穿关键词。';
    }
    if (this.selectedScope === 'outfits') {
      return '换个场景、穿搭名称或备注。';
    }
    return '换个名称、商场、分类或备注关键词。';
  }

  private refreshVisualResultDataSource(): void {
    this.visualResultDataSource.setData(this.filteredVisualResults());
  }

  private openResult(result: SearchVisualResult): void {
    if (result.entityType === SearchEntityType.Clothing) {
      this.onOpenClothingResult(result.entityId);
    } else if (result.entityType === SearchEntityType.Outfit) {
      this.onOpenOutfitResult(result.entityId);
    } else if (result.entityType === SearchEntityType.Store || result.entityType === SearchEntityType.StoreVisit) {
      this.onOpenStoreResult(result.entityType, result.entityId, result.title);
    } else if (result.entityType === SearchEntityType.Wishlist) {
      this.onOpenWishlistResult(result.entityId);
    } else if (result.entityType === SearchEntityType.WearLog) {
      this.onOpenWearLogResult(result.entityId);
    } else {
      this.onOpenProfileResult(result.entityType, result.entityId);
    }
  }

  build() {
    Column() {
      this.SearchHeader()

      if (this.activeQuery.length === 0) {
        this.IdlePanel()
      } else if (this.isSearching) {
        this.LoadingList()
      } else if (this.errorMessage.length > 0) {
        this.ErrorPanel()
      } else {
        this.ResultsPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgDefault)
  }

  @Builder
  SearchHeader() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(22)
            .fontColor([YibuqueColor.textPrimary])
        }
        .width(34)
        .height(48)
        .accessibilityText('返回上一页')
        .onClick(() => {
          this.onClose();
        })

        Row({ space: 4 }) {
          TextInput({ text: this.searchText, placeholder: '搜索衣服、商场、穿搭' })
            .layoutWeight(1)
            .height(46)
            .padding({ left: 14, right: 4 })
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.transparent)
            .enterKeyType(EnterKeyType.Search)
            .onChange((value: string) => {
              this.searchText = value;
              if (value.trim().length === 0) {
                this.clearSearch();
              }
            })
            .onSubmit(() => {
              this.submitSearch();
            })

          if (this.searchText.length > 0) {
            Stack({ alignContent: Alignment.Center }) {
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(15)
                .fontColor([YibuqueColor.textSecondary])
            }
            .width(44)
            .height(44)
            .accessibilityText('清空搜索')
            .onClick(() => {
              this.clearSearch();
            })
          }

        }
        .layoutWeight(1)
        .height(48)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.md)
        .border({ width: 1, color: YibuqueColor.borderLight })

        Text('搜索')
          .width(36)
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.submitSearch();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      this.SearchTabs()

      if (this.inputErrorMessage.length > 0) {
        Text(this.inputErrorMessage)
          .width('100%')
          .fontSize(12)
          .fontColor(YibuqueColor.danger)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 4, bottom: 12 })
    .backgroundColor(YibuqueColor.searchHeaderSurface)
  }

  @Builder
  SearchTabs() {
    Scroll() {
      Row({ space: 22 }) {
        ForEach(this.availableScopes(), (scope: SearchScopeOption) => {
          Column({ space: 5 }) {
            Text(scope.label)
              .fontSize(16)
              .fontWeight(FontWeight.Regular)
              .fontColor(this.selectedScope === scope.key ? YibuqueColor.selectionAccent : YibuqueColor.textSecondary)

            Row()
              .width('100%')
              .height(3)
              .backgroundColor(this.selectedScope === scope.key ? YibuqueColor.selectionAccent : YibuqueColor.transparent)
              .borderRadius(YibuqueRadius.full)
          }
          .width(48)
          .constraintSize({ minHeight: 44 })
          .justifyContent(FlexAlign.End)
          .accessibilityText(`${scope.label}${this.selectedScope === scope.key ? '，已选中' : ''}`)
          .onClick(() => {
            this.selectedScope = scope.key;
            this.refreshVisualResultDataSource();
          })
        }, (scope: SearchScopeOption) => scope.key)
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 44 })
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  IdlePanel() {
    Column({ space: 28 }) {
      Column({ space: 12 }) {
        Row() {
          Text('历史记录')
            .layoutWeight(1)
            .fontSize(20)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)

          Stack({ alignContent: Alignment.Center }) {
            SymbolGlyph($r('sys.symbol.trash'))
              .fontSize(20)
              .fontColor([YibuqueColor.textSecondary])
        }
          .width(34)
          .height(34)
          .accessibilityText('清空历史记录')
          .onClick(() => {
            this.clearHistory();
          })
        }
        .width('100%')

        if (this.historyTerms.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.historyTerms, (term: string) => {
              this.SearchChip(term)
            }, (term: string) => term)
          }
          .width('100%')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 20, right: 20, top: 14, bottom: 36 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SearchChip(term: string) {
    Text(term)
      .constraintSize({ minHeight: 44 })
      .padding({ left: 15, right: 15 })
      .margin({ right: 10, bottom: 10 })
      .fontSize(14)
      .fontColor(YibuqueColor.textPrimary)
      .textAlign(TextAlign.Center)
      .backgroundColor(YibuqueColor.bgDefault)
      .borderRadius(YibuqueRadius.full)
      .border({ width: 1, color: YibuqueColor.borderLight })
      .onClick(() => {
        this.submitSearch(term);
      })
  }

  @Builder
  ResultsPanel() {
    if (this.filteredVisualResults().length === 0) {
      Column({ space: 10 }) {
        Text(this.emptyResultTitle())
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)

        Text(this.emptyResultDescription())
          .width('100%')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20, top: 28 })
      .alignItems(HorizontalAlign.Start)
    } else {
      List() {
        LazyForEach(this.visualResultDataSource, (result: SearchVisualResult, index: number) => {
          ListItem() {
            this.ResultCard(result, index)
          }
          .margin({ bottom: 10 })
        }, (result: SearchVisualResult) => `${result.entityType}:${result.entityId}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20, top: 14, bottom: 24 })
      .scrollBar(BarState.Off)
    }
  }

  @Builder
  ResultCard(result: SearchVisualResult, _index: number) {
    Row({ space: 12 }) {
      this.ResultThumbnail(result)

      Column({ space: 4 }) {
        Text(result.title)
          .width('100%')
          .fontSize(15)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(result.subtitle)
          .width('100%')
          .fontSize(12)
          .fontColor(YibuqueColor.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(entityTypeLabel(result.entityType))
        .height(44)
        .padding({ left: 10, right: 10 })
        .fontSize(12)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.actionBlack)
        .textAlign(TextAlign.Center)
        .backgroundColor(YibuqueColor.cardSurface)
        .borderRadius(YibuqueRadius.full)
    }
    .width('100%')
    .height(76)
    .padding(10)
    .backgroundColor(YibuqueColor.cardSoftGray)
    .borderRadius(YibuqueRadius.md)
    .border({ width: 1, color: YibuqueColor.borderLight })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openResult(result);
    })
  }

  @Builder
  ResultThumbnail(result: SearchVisualResult) {
    Stack({ alignContent: Alignment.Center }) {
      if (result.photoUri.length > 0) {
        Image(result.photoUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else if (result.entityType === SearchEntityType.Clothing) {
        SymbolGlyph($r('sys.symbol.shirt'))
          .fontSize(24)
          .fontColor([YibuqueColor.actionBlack])
      } else if (result.entityType === SearchEntityType.Outfit) {
        SymbolGlyph($r('sys.symbol.hanger_and_towels'))
          .fontSize(24)
          .fontColor([YibuqueColor.actionBlack])
      } else if (result.entityType === SearchEntityType.WearLog || result.entityType === SearchEntityType.Wishlist) {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize(24)
          .fontColor([YibuqueColor.actionBlack])
      } else {
        SymbolGlyph($r('sys.symbol.store_fill'))
          .fontSize(24)
          .fontColor([YibuqueColor.actionBlack])
      }
    }
    .width(54)
    .height(54)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xs)
    .border({ width: 1, color: YibuqueColor.borderLight })
    .clip(true)
  }

  @Builder
  LoadingList() {
    List() {
      ForEach([0, 1, 2, 3], (skeletonIndex: number) => {
        ListItem() {
          Row({ space: 12 }) {
            Row()
              .width(54)
              .height(54)
              .backgroundColor(YibuqueColor.borderLight)
              .borderRadius(YibuqueRadius.xs)

            Column({ space: 8 }) {
              Row()
                .width('72%')
                .height(14)
                .backgroundColor(YibuqueColor.borderLight)
                .borderRadius(YibuqueRadius.micro)
              Row()
                .width('46%')
                .height(11)
                .backgroundColor(YibuqueColor.borderLight)
                .borderRadius(YibuqueRadius.micro)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .height(76)
          .padding(10)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.md)
          .accessibilityText(`搜索结果加载占位 ${skeletonIndex + 1}`)
        }
        .margin({ bottom: 10 })
      }, (skeletonIndex: number) => `${skeletonIndex}`)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 20, right: 20, top: 14, bottom: 24 })
    .scrollBar(BarState.Off)
  }

  @Builder
  ErrorPanel() {
    Column({ space: 12 }) {
      Text(this.errorMessage)
        .width('100%')
        .fontSize(14)
        .fontColor(YibuqueColor.danger)

      Button('重试')
        .height(44)
        .fontSize(13)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textInverse)
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.full)
        .onClick(() => {
          this.performSearch(this.activeQuery);
        })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 20, right: 20, top: 28 })
    .alignItems(HorizontalAlign.Start)
  }
}
