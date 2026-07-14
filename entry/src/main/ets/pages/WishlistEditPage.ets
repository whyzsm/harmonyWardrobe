import { PhotoGrid } from '../components/PhotoGrid';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import {
  CreateWishlistItemInput,
  UpdateWishlistItemInput,
  WishlistRepository
} from '../data/repositories/WishlistRepository';
import { WishlistItem } from '../domain/wishlist/WishlistModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { AppTheme } from '../theme/Tokens';

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

@Component
export struct WishlistEditPage {
  @Prop initialItem?: WishlistItem = undefined;
  wishlistRepository?: WishlistRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onSave: (item: WishlistItem) => void = () => {};
  onDelete: (item: WishlistItem) => Promise<void> = async (_item: WishlistItem): Promise<void> => {};
  onCancel: () => void = () => {};

  @State private title: string = '';
  @State private photoUris: string[] = [];
  @State private storeName: string = '';
  @State private price: string = '';
  @State private note: string = '';
  @State private isSaving: boolean = false;
  @State private isDeleting: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialItem === undefined) {
      return;
    }

    this.title = this.initialItem.title;
    this.photoUris = [...this.initialItem.photoUris];
    this.storeName = this.initialItem.storeName ?? '';
    this.price = this.initialItem.price?.toString() ?? '';
    this.note = this.initialItem.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && !this.isDeleting && this.title.trim().length > 0;
  }

  private wishlistPrice(): number | undefined {
    const trimmedPrice = this.price.trim();
    if (trimmedPrice.length === 0) {
      return undefined;
    }

    const parsedPrice = Number(trimmedPrice);
    return Number.isFinite(parsedPrice) && parsedPrice >= 0 ? parsedPrice : undefined;
  }

  private async copySourcesToLocalUris(sources: PhotoSource[]): Promise<string[]> {
    if (this.photoStorage === undefined) {
      return [];
    }

    const localUris: string[] = [];
    for (const source of sources) {
      const storedPhoto = await this.photoStorage.copyToAppStorage(source);
      localUris.push(storedPhoto.localUri);
    }

    return localUris;
  }

  private async pickGalleryPhotos(): Promise<void> {
    if (this.photoPickerAdapter === undefined) {
      return;
    }

    const sources = await this.photoPickerAdapter.pickFromGallery({ maxSelectNumber: 6 });
    this.photoUris = this.photoUris.concat(await this.copySourcesToLocalUris(sources));
  }

  private async capturePhoto(): Promise<void> {
    if (this.photoPickerAdapter === undefined) {
      return;
    }

    const source = await this.photoPickerAdapter.captureFromCamera();
    this.photoUris = this.photoUris.concat(await this.copySourcesToLocalUris([source]));
  }

  private createInput(): CreateWishlistItemInput {
    return {
      title: this.title,
      photoUris: this.photoUris,
      storeName: optionalText(this.storeName),
      price: this.wishlistPrice(),
      note: optionalText(this.note)
    };
  }

  private updateInput(id: string): UpdateWishlistItemInput {
    return {
      id,
      title: this.title,
      photoUris: this.photoUris,
      storeName: optionalText(this.storeName),
      price: this.wishlistPrice(),
      note: optionalText(this.note)
    };
  }

  private async saveWishlistItem(): Promise<void> {
    if (this.wishlistRepository === undefined || !this.canSave()) {
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';

    try {
      const savedItem = this.initialItem === undefined
        ? await this.wishlistRepository.createWishlistItem(this.createInput())
        : await this.wishlistRepository.updateWishlistItem(this.updateInput(this.initialItem.id));
      this.onSave(savedItem);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存心愿失败';
    } finally {
      this.isSaving = false;
    }
  }

  private confirmDeleteWishlistItem(): void {
    const item = this.initialItem;
    if (item === undefined || this.isSaving || this.isDeleting) {
      return;
    }

    AlertDialog.show({
      title: '删除心愿',
      message: '确定要删除这条心愿吗？照片也会一并移除。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppTheme.color.danger,
        action: () => {
          this.deleteWishlistItem();
        }
      }
    });
  }

  private async deleteWishlistItem(): Promise<void> {
    const item = this.initialItem;
    if (item === undefined || this.isDeleting) {
      return;
    }

    this.isDeleting = true;
    this.errorMessage = '';
    try {
      await this.onDelete(item);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '删除心愿失败';
    } finally {
      this.isDeleting = false;
    }
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: this.initialItem === undefined ? '添加心愿' : '编辑心愿',
        backAccessibilityText: '返回心愿',
        onBack: () => {
          this.onCancel();
        }
      })

      Scroll() {
        Column({ space: 16 }) {
        PhotoGrid({ photoUris: this.photoUris })

        Row({ space: 10 }) {
          Button('从相册选择')
            .height(44)
            .fontSize(14)
            .backgroundColor(AppTheme.color.primary)
            .fontColor(AppTheme.color.surface)
            .borderRadius(8)
            .onClick(() => {
              this.pickGalleryPhotos();
            })

          Button('拍照')
            .height(44)
            .fontSize(14)
            .backgroundColor(AppTheme.color.surface)
            .fontColor(AppTheme.color.primary)
            .borderRadius(8)
            .border({ width: 1, color: AppTheme.color.border })
            .onClick(() => {
              this.capturePhoto();
            })
        }
        .width('100%')

        Text('商品名称')
          .fontSize(13)
          .fontColor(AppTheme.color.textMuted)

        TextInput({ text: this.title, placeholder: '输入心仪单品名称' })
          .height(44)
          .fontSize(15)
          .backgroundColor(AppTheme.color.surface)
          .borderRadius(8)
          .border({ width: 1, color: AppTheme.color.border })
          .onChange((value: string) => {
            this.title = value;
          })

        Text('门店')
          .fontSize(13)
          .fontColor(AppTheme.color.textMuted)

        TextInput({ text: this.storeName, placeholder: '输入门店或品牌' })
          .height(44)
          .fontSize(15)
          .backgroundColor(AppTheme.color.surface)
          .borderRadius(8)
          .border({ width: 1, color: AppTheme.color.border })
          .onChange((value: string) => {
            this.storeName = value;
          })

        Text('期望价格')
          .fontSize(13)
          .fontColor(AppTheme.color.textMuted)

        TextInput({ text: this.price, placeholder: '输入价格' })
          .height(44)
          .fontSize(15)
          .type(InputType.Number)
          .backgroundColor(AppTheme.color.surface)
          .borderRadius(8)
          .border({ width: 1, color: AppTheme.color.border })
          .onChange((value: string) => {
            this.price = value;
          })

        Text('备注')
          .fontSize(13)
          .fontColor(AppTheme.color.textMuted)

        TextInput({ text: this.note, placeholder: '记录尺码、试穿感受或购买理由' })
          .height(44)
          .fontSize(15)
          .backgroundColor(AppTheme.color.surface)
          .borderRadius(8)
          .border({ width: 1, color: AppTheme.color.border })
          .onChange((value: string) => {
            this.note = value;
          })

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor(AppTheme.color.danger)
        }

        if (this.initialItem !== undefined) {
          Button() {
            if (this.isDeleting) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(AppTheme.color.surface)
            } else {
              Text('删除心愿')
                .fontSize(15)
                .fontColor(AppTheme.color.surface)
            }
          }
            .height(44)
            .width('100%')
            .backgroundColor(AppTheme.color.danger)
            .borderRadius(8)
            .enabled(!this.isSaving && !this.isDeleting)
            .onClick(() => {
              this.confirmDeleteWishlistItem();
            })
        }

        Button() {
          if (this.isSaving) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(AppTheme.color.surface)
          } else {
            Text('保存心愿')
              .fontSize(15)
              .fontColor(AppTheme.color.surface)
          }
        }
          .height(44)
          .width('100%')
          .backgroundColor(this.canSave() ? AppTheme.color.primary : AppTheme.color.disabled)
          .borderRadius(8)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveWishlistItem();
          })
        }
        .width('100%')
        .padding(20)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.color.surfaceMuted)
  }
}
