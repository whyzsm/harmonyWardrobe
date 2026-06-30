import { EmptyState } from '../components/EmptyState';
import { OutfitCard } from '../components/OutfitCard';
import { SearchBar } from '../components/SearchBar';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { AppTheme } from '../theme/Tokens';
import { OutfitEditPage } from './OutfitEditPage';
import { SearchResultsPage } from './SearchResultsPage';
import { WearLogEditPage } from './WearLogEditPage';

@Component
export struct OutfitsPage {
  outfitRepository?: OutfitRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  wearLogRepository?: WearLogRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;

  @State private searchQuery: string = '';
  @State private outfits: OutfitTemplate[] = [];
  @State private clothingItems: ClothingItem[] = [];
  @State private selectedOutfitId: string = '';
  @State private showOutfitEditor: boolean = false;
  @State private showWearLogEditor: boolean = false;
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadOutfits();
  }

  private async loadOutfits(): Promise<void> {
    if (this.outfitRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.outfits = await this.outfitRepository.listOutfits();
      if (this.clothingRepository !== undefined) {
        this.clothingItems = await this.clothingRepository.listClothing();
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载套装失败';
    } finally {
      this.loading = false;
    }
  }

  private filterOutfits(): OutfitTemplate[] {
    const normalizedQuery = this.searchQuery.trim().toLowerCase();
    if (normalizedQuery.length === 0) {
      return this.outfits;
    }

    return this.outfits.filter((outfit: OutfitTemplate) => {
      return outfit.title.toLowerCase().includes(normalizedQuery) ||
        (outfit.note !== undefined && outfit.note.toLowerCase().includes(normalizedQuery));
    });
  }

  private firstPhotoUri(outfit: OutfitTemplate): string {
    return outfit.photoUris.length > 0 ? outfit.photoUris[0] : '';
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

  private onCreateOutfit(): void {
    this.selectedOutfitId = '';
    this.showOutfitEditor = true;
  }

  private onRecordWear(outfit?: OutfitTemplate): void {
    this.selectedOutfitId = outfit?.id ?? '';
    this.showWearLogEditor = true;
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

  private closeOutfitEditor(): void {
    this.showOutfitEditor = false;
    this.selectedOutfitId = '';
  }

  private closeWearLogEditor(): void {
    this.showWearLogEditor = false;
    this.selectedOutfitId = '';
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.showUnifiedSearch = query.trim().length > 0;
  }

  private retry(): void {
    this.loadOutfits();
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
        }
      })
    } else if (this.showWearLogEditor) {
      WearLogEditPage({
        initialOutfitTemplateId: this.selectedOutfitId,
        outfits: this.outfits,
        wearLogRepository: this.wearLogRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (_wearLog: WearLog) => {
          this.closeWearLogEditor();
        },
        onCancel: () => {
          this.closeWearLogEditor();
        }
      })
    } else if (this.showUnifiedSearch) {
      SearchResultsPage({
        query: this.unifiedSearchQuery,
        searchRepository: this.searchRepository,
        outfitRepository: this.outfitRepository,
        onClose: () => {
          this.showUnifiedSearch = false;
        }
      })
    } else {
      Column({ space: 16 }) {
      Row() {
        Column({ space: 4 }) {
          Text('套装')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.text)

          Text('组合常穿搭配，方便每天快速记录。')
            .fontSize(15)
            .fontColor(AppTheme.color.textMuted)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('创建套装')
          .height(40)
          .fontSize(14)
          .fontColor(AppTheme.color.surface)
          .backgroundColor(AppTheme.color.primary)
          .borderRadius(AppTheme.radius.md)
          .onClick(() => {
            this.onCreateOutfit();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
        Text('loading / 正在加载套装...')
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

      SearchBar({
        value: this.searchQuery,
        placeholder: '搜索套装、备注',
        onChange: (value: string) => {
          this.searchQuery = value;
          this.openUnifiedSearch(value);
        }
      })

      Button('记录一次穿着')
        .height(40)
        .fontSize(14)
        .fontColor(AppTheme.color.primary)
        .backgroundColor(AppTheme.color.surface)
        .borderRadius(AppTheme.radius.md)
        .border({ width: 1, color: AppTheme.color.primary })
        .onClick(() => {
          this.onRecordWear();
        })

      if (this.filterOutfits().length === 0) {
        EmptyState({
          title: '还没有套装',
          description: '创建套装后会在这里显示，也可以从套装快速记录一次穿着。'
        })
      } else {
        Grid() {
          ForEach(this.filterOutfits(), (outfit: OutfitTemplate) => {
            GridItem() {
              Column({ space: 8 }) {
                OutfitCard({
                  title: outfit.title,
                  itemCount: outfit.clothingItemIds.length,
                  photoUri: this.firstPhotoUri(outfit)
                })
                  .onClick(() => {
                    this.selectedOutfitId = outfit.id;
                    this.showOutfitEditor = true;
                  })

                Button('记录一次穿着')
                  .height(36)
                  .width('100%')
                  .fontSize(13)
                  .fontColor(AppTheme.color.primary)
                  .backgroundColor(AppTheme.color.surface)
                  .borderRadius(AppTheme.radius.md)
                  .border({ width: 1, color: AppTheme.color.primary })
                  .onClick(() => {
                    this.onRecordWear(outfit);
                  })
              }
            }
          }, (outfit: OutfitTemplate) => outfit.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(AppTheme.color.surfaceMuted)
    }
  }
}
