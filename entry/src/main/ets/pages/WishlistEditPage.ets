import { PhotoGrid } from '../components/PhotoGrid';
import {
  CreateWishlistItemInput,
  UpdateWishlistItemInput,
  WishlistRepository
} from '../data/repositories/WishlistRepository';
import { WishlistItem } from '../domain/wishlist/WishlistModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';

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
  onCancel: () => void = () => {};

  @State private title: string = '';
  @State private photoUris: string[] = [];
  @State private storeName: string = '';
  @State private price: string = '';
  @State private note: string = '';
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialItem === undefined) {
      return;
    }

    this.title = this.initialItem.title;
    this.photoUris = this.initialItem.photoUris;
    this.storeName = this.initialItem.storeName ?? '';
    this.price = this.initialItem.price?.toString() ?? '';
    this.note = this.initialItem.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && this.title.trim().length > 0;
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

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 4 }) {
            Text(this.initialItem === undefined ? '添加心愿' : '编辑心愿')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')

            Text('记录照片、标题、门店、价格和备注。')
              .fontSize(14)
              .fontColor('#64748B')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('取消')
            .height(40)
            .fontSize(14)
            .fontColor('#334155')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#CBD5E1' })
            .onClick(() => {
              this.onCancel();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        PhotoGrid({ photoUris: this.photoUris })

        Row({ space: 10 }) {
          Button('从相册选择')
            .height(40)
            .fontSize(14)
            .backgroundColor('#0F172A')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .onClick(() => {
              this.pickGalleryPhotos();
            })

          Button('拍照')
            .height(40)
            .fontSize(14)
            .backgroundColor('#FFFFFF')
            .fontColor('#0F172A')
            .borderRadius(8)
            .border({ width: 1, color: '#CBD5E1' })
            .onClick(() => {
              this.capturePhoto();
            })
        }
        .width('100%')

        TextInput({ text: this.title, placeholder: 'title / 心仪单品' })
          .height(44)
          .fontSize(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .border({ width: 1, color: '#E2E8F0' })
          .onChange((value: string) => {
            this.title = value;
          })

        TextInput({ text: this.storeName, placeholder: 'storeName / 门店' })
          .height(44)
          .fontSize(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .border({ width: 1, color: '#E2E8F0' })
          .onChange((value: string) => {
            this.storeName = value;
          })

        TextInput({ text: this.price, placeholder: 'price / 价格' })
          .height(44)
          .fontSize(15)
          .type(InputType.Number)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .border({ width: 1, color: '#E2E8F0' })
          .onChange((value: string) => {
            this.price = value;
          })

        TextInput({ text: this.note, placeholder: 'note / 备注' })
          .height(44)
          .fontSize(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .border({ width: 1, color: '#E2E8F0' })
          .onChange((value: string) => {
            this.note = value;
          })

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#B91C1C')
        }

        Button(this.isSaving ? '保存中...' : '保存心愿')
          .height(44)
          .width('100%')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(this.canSave() ? '#0F172A' : '#94A3B8')
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
    .height('100%')
    .backgroundColor('#F8FAFC')
  }
}
