import { EmptyState } from '../components/EmptyState';
import { SearchBar } from '../components/SearchBar';
import { WishlistCard } from '../components/WishlistCard';
import { WishlistRepository } from '../data/repositories/WishlistRepository';
import { WishlistItem } from '../domain/wishlist/WishlistModels';
import { SearchResultsPage } from './SearchResultsPage';

function firstPhotoUri(item: WishlistItem): string {
  return item.photoUris.length > 0 ? item.photoUris[0] : '';
}

function priceText(item: WishlistItem): string {
  return item.price === undefined ? '' : `¥${item.price.toFixed(2)}`;
}

@Component
export struct ShoppingPage {
  @State private searchQuery: string = '';
  @State private wishlistItems: WishlistItem[] = [];
  @State private selectedWishlistItemId: string = '';
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  private wishlistRepository?: WishlistRepository = undefined;

  private filterWishlistItems(): WishlistItem[] {
    const normalizedQuery = this.searchQuery.trim().toLowerCase();
    if (normalizedQuery.length === 0) {
      return this.wishlistItems;
    }

    return this.wishlistItems.filter((item: WishlistItem) => {
      return item.title.toLowerCase().includes(normalizedQuery) ||
        (item.storeName !== undefined && item.storeName.toLowerCase().includes(normalizedQuery)) ||
        (item.note !== undefined && item.note.toLowerCase().includes(normalizedQuery));
    });
  }

  private onCreateWishlistItem(): void {
    this.selectedWishlistItemId = '';
  }

  private onOpenWishlistItem(item: WishlistItem): void {
    this.selectedWishlistItemId = item.id;
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.showUnifiedSearch = query.trim().length > 0;
  }

  build() {
    if (this.showUnifiedSearch) {
      SearchResultsPage({
        query: this.unifiedSearchQuery,
        wishlistRepository: this.wishlistRepository,
        onClose: () => {
          this.showUnifiedSearch = false;
        }
      })
    } else {
      Column({ space: 16 }) {
      Row() {
        Column({ space: 4 }) {
          Text('心仪单品')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')

          Text('记录想买的衣物、门店、价格和试穿照片。')
            .fontSize(15)
            .fontColor('#475569')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('添加心愿')
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#0F172A')
          .borderRadius(8)
          .onClick(() => {
            this.onCreateWishlistItem();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      SearchBar({
        value: this.searchQuery,
        placeholder: '搜索心仪单品、门店、备注',
        onChange: (value: string) => {
          this.searchQuery = value;
          this.openUnifiedSearch(value);
        }
      })

      if (this.filterWishlistItems().length === 0) {
        EmptyState({
          title: '还没有心仪单品',
          description: '添加心愿后会在这里显示，也可以按门店和关键词搜索。'
        })
      } else {
        ForEach(this.filterWishlistItems(), (item: WishlistItem) => {
          WishlistCard({
            title: item.title,
            storeName: item.storeName ?? '',
            priceText: priceText(item),
            photoUri: firstPhotoUri(item)
          })
            .onClick(() => {
              this.onOpenWishlistItem(item);
            })
        }, (item: WishlistItem) => item.id)
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
