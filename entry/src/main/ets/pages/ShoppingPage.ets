import { EmptyState } from '../components/EmptyState';
import { SearchBar } from '../components/SearchBar';
import { WishlistCard } from '../components/WishlistCard';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { WishlistRepository } from '../data/repositories/WishlistRepository';
import { WishlistItem } from '../domain/wishlist/WishlistModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { SearchResultsPage } from './SearchResultsPage';
import { WishlistEditPage } from './WishlistEditPage';

function firstPhotoUri(item: WishlistItem): string {
  return item.photoUris.length > 0 ? item.photoUris[0] : '';
}

function priceText(item: WishlistItem): string {
  return item.price === undefined ? '' : `¥${item.price.toFixed(2)}`;
}

@Component
export struct ShoppingPage {
  wishlistRepository?: WishlistRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;

  @State private searchQuery: string = '';
  @State private wishlistItems: WishlistItem[] = [];
  @State private selectedWishlistItemId: string = '';
  @State private showEditor: boolean = false;
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadWishlistItems();
  }

  private async loadWishlistItems(): Promise<void> {
    if (this.wishlistRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.wishlistItems = await this.wishlistRepository.listWishlistItems();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载心愿失败';
    } finally {
      this.loading = false;
    }
  }

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
    this.showEditor = true;
  }

  private onOpenWishlistItem(item: WishlistItem): void {
    this.selectedWishlistItemId = item.id;
    this.showEditor = true;
  }

  private selectedWishlistItem(): WishlistItem | undefined {
    if (this.selectedWishlistItemId.length === 0) {
      return undefined;
    }

    for (const item of this.wishlistItems) {
      if (item.id === this.selectedWishlistItemId) {
        return item;
      }
    }

    return undefined;
  }

  private upsertWishlistItem(savedItem: WishlistItem): void {
    const nextItems: WishlistItem[] = [];
    let replaced = false;

    for (const item of this.wishlistItems) {
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

    this.wishlistItems = nextItems;
  }

  private closeEditor(): void {
    this.showEditor = false;
    this.selectedWishlistItemId = '';
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.showUnifiedSearch = query.trim().length > 0;
  }

  private retry(): void {
    this.loadWishlistItems();
  }

  build() {
    if (this.showEditor) {
      WishlistEditPage({
        initialItem: this.selectedWishlistItem(),
        wishlistRepository: this.wishlistRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (item: WishlistItem) => {
          this.upsertWishlistItem(item);
          this.closeEditor();
        },
        onCancel: () => {
          this.closeEditor();
        }
      })
    } else if (this.showUnifiedSearch) {
      SearchResultsPage({
        query: this.unifiedSearchQuery,
        searchRepository: this.searchRepository,
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

      if (this.loading) {
        Text('loading / 正在加载心愿...')
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
