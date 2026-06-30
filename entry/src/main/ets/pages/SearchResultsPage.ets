import { EmptyState } from '../components/EmptyState';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { WishlistRepository } from '../data/repositories/WishlistRepository';
import { SearchEntityType, SearchResult } from '../domain/search/SearchModels';
import { AppTheme } from '../theme/Tokens';

function entityTypeLabel(entityType: SearchEntityType): string {
  if (entityType === SearchEntityType.Clothing) {
    return '衣物';
  }

  if (entityType === SearchEntityType.Outfit) {
    return '套装';
  }

  if (entityType === SearchEntityType.WearLog) {
    return '穿着记录';
  }

  return '心愿';
}

@Component
export struct SearchResultsPage {
  @Prop query: string = '';
  searchRepository?: SearchRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  wishlistRepository?: WishlistRepository = undefined;
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
      this.searchResults = await this.searchRepository.search(this.query, 30);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '搜索失败';
    } finally {
      this.isSearching = false;
    }
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Column({ space: 4 }) {
          Text('统一搜索')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.text)

          Text(`query: ${this.query}`)
            .fontSize(14)
            .fontColor(AppTheme.color.textMuted)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('关闭')
          .height(40)
          .fontSize(14)
          .fontColor(AppTheme.color.textMuted)
          .backgroundColor(AppTheme.color.surface)
          .borderRadius(8)
          .border({ width: 1, color: AppTheme.color.border })
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('entity_type / entity_id')
        .fontSize(12)
        .fontColor(AppTheme.color.disabled)

      if (this.isSearching) {
        Text('搜索中...')
          .fontSize(14)
          .fontColor(AppTheme.color.textMuted)
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(AppTheme.color.danger)
      } else if (this.searchResults.length === 0) {
        EmptyState({
          title: '没有搜索结果',
          description: '换个关键词试试衣物、套装、穿着记录或心愿。'
        })
      } else {
        ForEach(this.searchResults, (result: SearchResult) => {
          Column({ space: 4 }) {
            Text(result.title)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppTheme.color.text)

            Text(`${entityTypeLabel(result.entityType)} · entity_type=${result.entityType} · entity_id=${result.entityId}`)
              .fontSize(12)
              .fontColor(AppTheme.color.textMuted)
          }
          .width('100%')
          .padding(12)
          .borderRadius(8)
          .backgroundColor(AppTheme.color.surface)
          .border({ width: 1, color: AppTheme.color.border })
          .alignItems(HorizontalAlign.Start)
        }, (result: SearchResult) => `${result.entityType}:${result.entityId}`)
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(AppTheme.color.surfaceMuted)
  }
}
