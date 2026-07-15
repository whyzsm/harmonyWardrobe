import { EmptyState } from '../components/EmptyState';
import { SearchBar } from '../components/SearchBar';
import { WishlistCard } from '../components/WishlistCard';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { WishlistRepository } from '../data/repositories/WishlistRepository';
import { SearchEntityType } from '../domain/search/SearchModels';
import { WishlistItem } from '../domain/wishlist/WishlistModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { AppTheme } from '../theme/Tokens';
import { SearchResultsPage } from './SearchResultsPage';
import { WishlistEditPage } from './WishlistEditPage';

function firstPhotoUri(item: WishlistItem): string {
  return item.photoUris.length > 0 ? item.photoUris[0] : '';
}

function priceText(item: WishlistItem): string {
  return item.price === undefined ? '' : `¥${item.price.toFixed(2)}`;
}

@Component
export struct WishlistPage {
  wishlistRepository?: WishlistRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  @Prop initialWishlistItemId: string = '';
  onClose: () => void = () => {};
  onBack: () => void = () => {};
  onOpenCapture?: () => void = undefined;

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
      if (this.initialWishlistItemId.length > 0) {
        for (const item of this.wishlistItems) {
          if (item.id === this.initialWishlistItemId) {
            this.selectedWishlistItemId = item.id;
            this.showEditor = true;
            break;
          }
        }
      }
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

  private async deleteWishlistItem(item: WishlistItem): Promise<void> {
    if (this.wishlistRepository === undefined) {
      throw new Error('心愿仓库不可用，请稍后重试');
    }

    await this.wishlistRepository.deleteWishlistItem(item.id);
    this.wishlistItems = this.wishlistItems.filter((existingItem: WishlistItem) => existingItem.id !== item.id);
    this.closeEditor();
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
        onDelete: async (item: WishlistItem): Promise<void> => {
          await this.deleteWishlistItem(item);
        },
        onCancel: () => {
          this.closeEditor();
          if (this.initialWishlistItemId.length > 0) {
            this.onBack();
          }
        }
      })
    } else if (this.showUnifiedSearch) {
      SearchResultsPage({
        query: this.unifiedSearchQuery,
        searchRepository: this.searchRepository,
        initialScope: SearchEntityType.Wishlist,
        onOpenWishlistResult: (id: string) => {
          this.selectedWishlistItemId = id;
          this.showUnifiedSearch = false;
          this.showEditor = true;
        },
        onOpenCameraSearch: () => {
          this.showUnifiedSearch = false;
          if (this.onOpenCapture !== undefined) {
            this.onOpenCapture();
          }
        },
        onClose: () => {
          this.showUnifiedSearch = false;
        }
      })
    } else {
      Column({ space: 16 }) {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(22)
            .fontColor([AppTheme.color.text])
        }
        .width(44)
        .height(44)
        .accessibilityText('返回我的')
        .onClick(() => {
          this.onBack();
        })

        Column({ space: 4 }) {
          Text('心仪单品')
            .fontSize(30)
            .fontWeight(FontWeight.Regular)
            .fontColor(AppTheme.color.text)

          Text('记录想买的衣物、门店、价格和试穿照片。')
            .fontSize(15)
            .fontColor(AppTheme.color.textMuted)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('添加心愿')
          .height(40)
          .fontSize(14)
          .fontColor(AppTheme.color.surface)
          .backgroundColor(AppTheme.color.primary)
          .borderRadius(AppTheme.radius.md)
          .onClick(() => {
            this.onCreateWishlistItem();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
        Text('正在加载心愿...')
          .fontSize(14)
          .fontColor(AppTheme.color.textMuted)
      }

      if (this.errorMessage.length > 0) {
        Row({ space: 8 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(AppTheme.color.danger)
            .layoutWeight(1)

          Button('重试')
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
    .backgroundColor(AppTheme.color.surfaceMuted)
    }
  }
}
