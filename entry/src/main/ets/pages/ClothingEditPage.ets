import { PhotoGrid } from '../components/PhotoGrid';
import {
  ClothingRepository,
  CreateClothingInput,
  UpdateClothingInput
} from '../data/repositories/ClothingRepository';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem, PurchaseInfo } from '../domain/clothing/ClothingModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { AppTheme } from '../theme/Tokens';

interface ClothingCategoryOption {
  label: string;
  value: ClothingCategory;
}

const CATEGORY_OPTIONS: ClothingCategoryOption[] = [
  { label: '上衣', value: ClothingCategory.Top },
  { label: '裤装', value: ClothingCategory.Pants },
  { label: '裙装', value: ClothingCategory.Skirt },
  { label: '外套', value: ClothingCategory.Outerwear },
  { label: '鞋', value: ClothingCategory.Shoes },
  { label: '包', value: ClothingCategory.Bag },
  { label: '配饰', value: ClothingCategory.Accessory },
  { label: '其他', value: ClothingCategory.Other }
];

function labelForCategory(category: ClothingCategory): string {
  for (const option of CATEGORY_OPTIONS) {
    if (option.value === category) {
      return option.label;
    }
  }

  return '其他';
}

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

@Component
export struct ClothingEditPage {
  @Prop initialItem?: ClothingItem = undefined;
  clothingRepository?: ClothingRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onSave: (item: ClothingItem) => void = () => {};
  onCancel: () => void = () => {};

  @State private name: string = '';
  @State private category: ClothingCategory = ClothingCategory.Top;
  @State private photoUris: string[] = [];
  @State private note: string = '';
  @State private storeName: string = '';
  @State private price: string = '';
  @State private purchaseDate: string = '';
  @State private purchaseNote: string = '';
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialItem === undefined) {
      return;
    }

    this.name = this.initialItem.name;
    this.category = this.initialItem.category;
    this.photoUris = this.initialItem.photoUris;
    this.note = this.initialItem.note ?? '';
    this.storeName = this.initialItem.purchaseInfo?.storeName ?? '';
    this.price = this.initialItem.purchaseInfo?.price?.toString() ?? '';
    this.purchaseDate = this.initialItem.purchaseInfo?.purchaseDate ?? '';
    this.purchaseNote = this.initialItem.purchaseInfo?.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && this.name.trim().length > 0;
  }

  private purchasePrice(): number | undefined {
    const trimmedPrice = this.price.trim();
    if (trimmedPrice.length === 0) {
      return undefined;
    }

    const parsedPrice = Number(trimmedPrice);
    return Number.isFinite(parsedPrice) && parsedPrice >= 0 ? parsedPrice : undefined;
  }

  private purchaseInfo(): PurchaseInfo | undefined {
    const info: PurchaseInfo = {
      storeName: optionalText(this.storeName),
      price: this.purchasePrice(),
      purchaseDate: optionalText(this.purchaseDate),
      note: optionalText(this.purchaseNote)
    };

    if (
      info.storeName === undefined &&
      info.price === undefined &&
      info.purchaseDate === undefined &&
      info.note === undefined
    ) {
      return undefined;
    }

    return info;
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

  private createInput(): CreateClothingInput {
    return {
      name: this.name,
      category: this.category,
      photoUris: this.photoUris,
      note: optionalText(this.note),
      purchaseInfo: this.purchaseInfo()
    };
  }

  private updateInput(id: string): UpdateClothingInput {
    return {
      id,
      name: this.name,
      category: this.category,
      photoUris: this.photoUris,
      note: optionalText(this.note),
      purchaseInfo: this.purchaseInfo()
    };
  }

  private async saveClothing(): Promise<void> {
    if (this.clothingRepository === undefined || !this.canSave()) {
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';

    try {
      const savedItem = this.initialItem === undefined
        ? await this.clothingRepository.createClothing(this.createInput())
        : await this.clothingRepository.updateClothing(this.updateInput(this.initialItem.id));
      this.onSave(savedItem);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存衣物失败';
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 4 }) {
            Text(this.initialItem === undefined ? '添加衣服' : '编辑衣服')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.color.text)

            Text('补全照片、分类、备注和购买信息。')
              .fontSize(14)
              .fontColor(AppTheme.color.textMuted)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('取消')
            .height(40)
            .fontSize(14)
            .fontColor(AppTheme.color.textMuted)
            .backgroundColor(AppTheme.color.surface)
            .borderRadius(8)
            .border({ width: 1, color: AppTheme.color.border })
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
            .backgroundColor(AppTheme.color.primary)
            .fontColor(AppTheme.color.surface)
            .borderRadius(8)
            .onClick(() => {
              this.pickGalleryPhotos();
            })

          Button('拍照')
            .height(40)
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

        TextInput({ text: this.name, placeholder: 'name / 衣物名称' })
          .height(44)
          .fontSize(15)
          .backgroundColor(AppTheme.color.surface)
          .borderRadius(8)
          .border({ width: 1, color: AppTheme.color.border })
          .onChange((value: string) => {
            this.name = value;
          })

        Column({ space: 8 }) {
          Text(`category / 分类：${labelForCategory(this.category)}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.color.textMuted)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(CATEGORY_OPTIONS, (option: ClothingCategoryOption) => {
              Button(option.label)
                .height(36)
                .margin({ right: 8, bottom: 8 })
                .fontSize(13)
                .fontColor(option.value === this.category ? AppTheme.color.surface : AppTheme.color.textMuted)
                .backgroundColor(option.value === this.category ? AppTheme.color.primary : AppTheme.color.surface)
                .borderRadius(8)
                .border({ width: 1, color: option.value === this.category ? AppTheme.color.primary : AppTheme.color.border })
                .onClick(() => {
                  this.category = option.value;
                })
            }, (option: ClothingCategoryOption) => option.value)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        TextInput({ text: this.note, placeholder: 'note / 备注' })
          .height(44)
          .fontSize(15)
          .backgroundColor(AppTheme.color.surface)
          .borderRadius(8)
          .border({ width: 1, color: AppTheme.color.border })
          .onChange((value: string) => {
            this.note = value;
          })

        Column({ space: 10 }) {
          Text('purchase / 购买信息')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.color.text)

          TextInput({ text: this.storeName, placeholder: 'storeName / 门店' })
            .height(42)
            .fontSize(14)
            .backgroundColor(AppTheme.color.surface)
            .borderRadius(8)
            .border({ width: 1, color: AppTheme.color.border })
            .onChange((value: string) => {
              this.storeName = value;
            })

          TextInput({ text: this.price, placeholder: 'price / 价格' })
            .height(42)
            .fontSize(14)
            .type(InputType.Number)
            .backgroundColor(AppTheme.color.surface)
            .borderRadius(8)
            .border({ width: 1, color: AppTheme.color.border })
            .onChange((value: string) => {
              this.price = value;
            })

          TextInput({ text: this.purchaseDate, placeholder: 'purchaseDate / 购买日期 YYYY-MM-DD' })
            .height(42)
            .fontSize(14)
            .backgroundColor(AppTheme.color.surface)
            .borderRadius(8)
            .border({ width: 1, color: AppTheme.color.border })
            .onChange((value: string) => {
              this.purchaseDate = value;
            })

          TextInput({ text: this.purchaseNote, placeholder: 'purchase note / 购买备注' })
            .height(42)
            .fontSize(14)
            .backgroundColor(AppTheme.color.surface)
            .borderRadius(8)
            .border({ width: 1, color: AppTheme.color.border })
            .onChange((value: string) => {
              this.purchaseNote = value;
            })
        }
        .width('100%')
        .padding(12)
        .borderRadius(8)
        .backgroundColor(AppTheme.color.surface)
        .border({ width: 1, color: AppTheme.color.border })
        .alignItems(HorizontalAlign.Start)

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor(AppTheme.color.danger)
        }

        Button(this.isSaving ? '保存中...' : '保存')
          .height(44)
          .width('100%')
          .fontSize(15)
          .fontColor(AppTheme.color.surface)
          .backgroundColor(this.canSave() ? AppTheme.color.primary : AppTheme.color.disabled)
          .borderRadius(8)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveClothing();
          })
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.color.surfaceMuted)
  }
}
