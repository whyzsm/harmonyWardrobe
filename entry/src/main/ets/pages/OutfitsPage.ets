import { EmptyState } from '../components/EmptyState';
import { OutfitCard } from '../components/OutfitCard';
import { SearchBar } from '../components/SearchBar';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { SearchResultsPage } from './SearchResultsPage';

@Component
export struct OutfitsPage {
  @State private searchQuery: string = '';
  @State private outfits: OutfitTemplate[] = [];
  @State private selectedOutfitId: string = '';
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  private outfitRepository?: OutfitRepository = undefined;

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

  private onCreateOutfit(): void {
    this.selectedOutfitId = '';
  }

  private onRecordWear(outfit?: OutfitTemplate): void {
    this.selectedOutfitId = outfit?.id ?? '';
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.showUnifiedSearch = query.trim().length > 0;
  }

  private retry(): void {
    this.loading = false;
    this.errorMessage = '';
  }

  build() {
    if (this.showUnifiedSearch) {
      SearchResultsPage({
        query: this.unifiedSearchQuery,
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
            .fontColor('#111827')

          Text('组合常穿搭配，方便每天快速记录。')
            .fontSize(15)
            .fontColor('#475569')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('创建套装')
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#0F172A')
          .borderRadius(8)
          .onClick(() => {
            this.onCreateOutfit();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
        Text('loading / 正在加载套装...')
          .fontSize(14)
          .fontColor('#64748B')
      }

      if (this.errorMessage.length > 0) {
        Row({ space: 8 }) {
          Text(`error / ${this.errorMessage}`)
            .fontSize(14)
            .fontColor('#B91C1C')
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
        .fontColor('#0F172A')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ width: 1, color: '#CBD5E1' })
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

                Button('记录一次穿着')
                  .height(36)
                  .width('100%')
                  .fontSize(13)
                  .fontColor('#0F172A')
                  .backgroundColor('#FFFFFF')
                  .borderRadius(8)
                  .border({ width: 1, color: '#CBD5E1' })
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
    .backgroundColor('#F8FAFC')
    }
  }
}
