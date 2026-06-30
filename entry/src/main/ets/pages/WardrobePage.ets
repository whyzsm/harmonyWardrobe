import { SearchBar } from '../components/SearchBar';
import { CategoryTabs } from '../components/CategoryTabs';
import { ClothingCard } from '../components/ClothingCard';
import { EmptyState } from '../components/EmptyState';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { ClothingEditPage } from './ClothingEditPage';
import { SearchResultsPage } from './SearchResultsPage';

interface WardrobeCategoryFilter {
  label: string;
  category?: ClothingCategory;
}

const WARDROBE_CATEGORY_FILTERS: WardrobeCategoryFilter[] = [
  { label: '全部' },
  { label: '上衣', category: ClothingCategory.Top },
  { label: '裤装', category: ClothingCategory.Pants },
  { label: '裙装', category: ClothingCategory.Skirt },
  { label: '外套', category: ClothingCategory.Outerwear },
  { label: '鞋', category: ClothingCategory.Shoes },
  { label: '包', category: ClothingCategory.Bag },
  { label: '配饰', category: ClothingCategory.Accessory },
  { label: '其他', category: ClothingCategory.Other }
];

function categoryLabel(category: ClothingCategory): string {
  for (const filter of WARDROBE_CATEGORY_FILTERS) {
    if (filter.category === category) {
      return filter.label;
    }
  }

  return '其他';
}

@Component
export struct WardrobePage {
  clothingRepository?: ClothingRepository = undefined;
  searchRepository?: SearchRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;

  @State private searchQuery: string = '';
  @State private selectedCategoryLabel: string = '全部';
  @State private clothingItems: ClothingItem[] = [];
  @State private showEditor: boolean = false;
  @State private editingClothingId: string = '';
  @State private showUnifiedSearch: boolean = false;
  @State private unifiedSearchQuery: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadClothingItems();
  }

  private async loadClothingItems(): Promise<void> {
    if (this.clothingRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.clothingItems = await this.clothingRepository.listClothing();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载衣橱失败';
    } finally {
      this.loading = false;
    }
  }

  private selectedCategory(): ClothingCategory | undefined {
    for (const filter of WARDROBE_CATEGORY_FILTERS) {
      if (filter.label === this.selectedCategoryLabel) {
        return filter.category;
      }
    }

    return undefined;
  }

  private filterClothingItems(): ClothingItem[] {
    const selectedCategory = this.selectedCategory();
    const normalizedQuery = this.searchQuery.trim().toLowerCase();

    return this.clothingItems.filter((item: ClothingItem) => {
      const matchesCategory = selectedCategory === undefined || item.category === selectedCategory;
      const matchesQuery = normalizedQuery.length === 0 ||
        item.name.toLowerCase().includes(normalizedQuery) ||
        (item.note !== undefined && item.note.toLowerCase().includes(normalizedQuery));

      return matchesCategory && matchesQuery;
    });
  }

  private categoryLabels(): string[] {
    return WARDROBE_CATEGORY_FILTERS.map((filter: WardrobeCategoryFilter) => filter.label);
  }

  private firstPhotoUri(item: ClothingItem): string {
    return item.photoUris.length > 0 ? item.photoUris[0] : '';
  }

  private editingItem(): ClothingItem | undefined {
    if (this.editingClothingId.length === 0) {
      return undefined;
    }

    for (const item of this.clothingItems) {
      if (item.id === this.editingClothingId) {
        return item;
      }
    }

    return undefined;
  }

  private openCreateEditor(): void {
    this.editingClothingId = '';
    this.showEditor = true;
  }

  private openEditEditor(item: ClothingItem): void {
    this.editingClothingId = item.id;
    this.showEditor = true;
  }

  private closeEditor(): void {
    this.showEditor = false;
    this.editingClothingId = '';
  }

  private onEdit(item: ClothingItem): void {
    this.openEditEditor(item);
  }

  private upsertClothingItem(savedItem: ClothingItem): void {
    const nextItems: ClothingItem[] = [];
    let replaced = false;

    for (const item of this.clothingItems) {
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

    this.clothingItems = nextItems;
  }

  private openUnifiedSearch(query: string): void {
    this.unifiedSearchQuery = query;
    this.showUnifiedSearch = query.trim().length > 0;
  }

  private retry(): void {
    this.loadClothingItems();
  }

  build() {
    if (this.showEditor) {
      ClothingEditPage({
        initialItem: this.editingItem(),
        clothingRepository: this.clothingRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (item: ClothingItem) => {
          this.upsertClothingItem(item);
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
        clothingRepository: this.clothingRepository,
        onClose: () => {
          this.showUnifiedSearch = false;
        }
      })
    } else {
      Column({ space: 16 }) {
      Row() {
        Column({ space: 4 }) {
          Text('衣橱')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')

          Text('管理上衣、裤装、裙装、外套、鞋包和配饰。')
            .fontSize(15)
            .fontColor('#475569')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('添加衣服')
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#0F172A')
          .borderRadius(8)
          .onClick(() => {
            this.openCreateEditor();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
        Text('loading / 正在加载衣橱...')
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
        placeholder: '搜索衣服、备注',
        onChange: (value: string) => {
          this.searchQuery = value;
          this.openUnifiedSearch(value);
        }
      })

      CategoryTabs({
        categories: this.categoryLabels(),
        selected: this.selectedCategoryLabel,
        onSelect: (category: string) => {
          this.selectedCategoryLabel = category;
        }
      })

      if (this.filterClothingItems().length === 0) {
        EmptyState({
          title: '还没有衣物',
          description: '添加衣服后会在这里显示，也可以按分类和关键词筛选。'
        })
      } else {
        Grid() {
          ForEach(this.filterClothingItems(), (item: ClothingItem) => {
            GridItem() {
              ClothingCard({
                name: item.name,
                category: categoryLabel(item.category),
                photoUri: this.firstPhotoUri(item)
              })
                .onClick(() => {
                  this.onEdit(item);
                })
            }
          }, (item: ClothingItem) => item.id)
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
