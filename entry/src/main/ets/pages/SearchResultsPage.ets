import { EmptyState } from '../components/EmptyState';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { SearchEntityType, SearchResult } from '../domain/search/SearchModels';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

function entityTypeLabel(entityType: SearchEntityType): string {
  if (entityType === SearchEntityType.Clothing) {
    return '衣物';
  }

  if (entityType === SearchEntityType.Outfit) {
    return '美搭';
  }

  if (entityType === SearchEntityType.StoreVisit) {
    return '逛店记录';
  }

  if (entityType === SearchEntityType.Store) {
    return '店铺';
  }

  return '';
}

@Component
export struct SearchResultsPage {
  @Prop query: string = '';
  searchRepository?: SearchRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  onClose: () => void = () => {};

  @State private searchResults: SearchResult[] = [];
  @State private isSearching: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.performSearch();
  }

  private async performSearch(): Promise<void> {
    if (this.searchRepository === undefined || this.query.trim().length === 0) {
      this.searchResults = [];
      return;
    }

    this.isSearching = true;
    this.errorMessage = '';

    try {
      const results = await this.searchRepository.search(this.query, 30);
      this.searchResults = results.filter((result: SearchResult) => entityTypeLabel(result.entityType).length > 0);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '搜索失败';
    } finally {
      this.isSearching = false;
    }
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: '搜索',
        backAccessibilityText: '关闭搜索',
        onBack: () => {
          this.onClose();
        }
      })

      Column({ space: YibuqueSpacing.lg }) {
        Text(`正在找「${this.query}」`)
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)

        if (this.isSearching) {
          Text('搜索中...')
            .fontSize(14)
            .fontColor(YibuqueColor.textSecondary)
        } else if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#EF4444')
        } else if (this.searchResults.length === 0) {
          EmptyState({
            title: '没有搜索结果',
            description: '换个关键词试试衣物、美搭、逛店记录或店铺。'
          })
        } else {
          ForEach(this.searchResults, (result: SearchResult) => {
            Column({ space: 4 }) {
              Text(result.title)
                .fontSize(16)
                .fontWeight(FontWeight.Regular)
                .fontColor(YibuqueColor.textPrimary)

              Text(entityTypeLabel(result.entityType))
                .fontSize(12)
                .fontWeight(FontWeight.Regular)
                .fontColor(YibuqueColor.textSecondary)
            }
            .width('100%')
            .padding(YibuqueSpacing.md)
            .borderRadius(YibuqueRadius.xl)
            .backgroundColor(YibuqueColor.cardWhite)
            .border({ width: 1, color: YibuqueColor.borderLight })
            .alignItems(HorizontalAlign.Start)
          }, (result: SearchResult) => `${result.entityType}:${result.entityId}`)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding(YibuqueSpacing.pageX)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBlueGray)
  }
}
