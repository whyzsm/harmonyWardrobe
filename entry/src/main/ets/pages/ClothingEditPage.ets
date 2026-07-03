import type { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
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
  { label: '裤子', value: ClothingCategory.Pants },
  { label: '短裤', value: ClothingCategory.Shorts },
  { label: '长裙', value: ClothingCategory.LongSkirt },
  { label: '半裙', value: ClothingCategory.HalfSkirt }
];

function labelForCategory(category: ClothingCategory): string {
  for (const option of CATEGORY_OPTIONS) {
    if (option.value === category) {
      return option.label;
    }
  }

  return '上衣';
}

function padTwoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function formatDateForStorage(date: Date): string {
  return `${date.getFullYear()}-${padTwoDigits(date.getMonth() + 1)}-${padTwoDigits(date.getDate())}`;
}

function dateFromStorage(value: string): Date {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value.trim());
  if (match === null) {
    return new Date();
  }

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) {
    return new Date();
  }

  return new Date(year, month - 1, day);
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
  @State private previewPhotoUri: string = '';
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
    this.previewPhotoUri = this.initialItem.photoUris[0] ?? '';
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

  private openPurchaseDatePicker(): void {
    DatePickerDialog.show({
      start: new Date(2000, 0, 1),
      end: new Date(),
      selected: dateFromStorage(this.purchaseDate),
      onDateAccept: (date: Date) => {
        this.purchaseDate = formatDateForStorage(date);
      }
    });
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
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);
      const selectedUri = photoSelectResult.photoUris?.[0] ?? '';

      if (selectedUri.length === 0) {
        return;
      }

      this.previewPhotoUri = selectedUri;
      this.photoUris = [selectedUri];

      try {
        const localUris = await this.copySourcesToLocalUris([{
          uri: selectedUri,
          mimeType: 'image/*'
        }]);
        if (localUris.length > 0) {
          this.photoUris = localUris;
          this.previewPhotoUri = localUris[0];
        }
      } catch (copyError) {
        const err: BusinessError = copyError as BusinessError;
        console.info(`PhotoViewPicker.copy failed with err: ${err.code}, ${err.message}`);
      }

      console.info(`PhotoViewPicker.select succeed, PhotoSelectResult uri: ${selectedUri}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.info(`PhotoViewPicker.select failed with err: ${err.code}, ${err.message}`);
    }
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

  @Builder
  PhotoSelector() {
    Row({ space: 10 }) {
      Column() {
        Text('+')
          .fontSize(32)
          .fontWeight(FontWeight.Regular)
          .fontColor(AppTheme.color.textDisabled)
      }
      .width(84)
      .height(84)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(AppTheme.color.surface)
      .borderRadius(12)
      .border({ width: 1, color: AppTheme.color.border })
      .onClick(() => {
        this.pickGalleryPhotos();
      })

      if (this.previewPhotoUri.length > 0) {
        Stack({ alignContent: Alignment.TopStart }) {
          Image(this.previewPhotoUri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .borderRadius(12)

          Text('封面')
            .fontSize(12)
            .fontColor(AppTheme.color.text)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(AppTheme.color.surface)
            .borderRadius(10)
            .margin({ left: 8, top: 8 })
        }
        .width(84)
        .height(84)
        .borderRadius(12)
        .clip(true)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
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

        this.PhotoSelector()

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

          Row() {
            Column({ space: 2 }) {
              Text('购买日期')
                .fontSize(12)
                .fontColor(AppTheme.color.textMuted)

              Text(this.purchaseDate.length > 0 ? this.purchaseDate : '选择购买日期')
                .fontSize(14)
                .fontColor(this.purchaseDate.length > 0 ? AppTheme.color.text : AppTheme.color.textDisabled)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            if (this.purchaseDate.length > 0) {
              Button('清除日期')
                .height(32)
                .fontSize(12)
                .fontColor(AppTheme.color.textMuted)
                .backgroundColor(AppTheme.color.surface)
                .borderRadius(8)
                .border({ width: 1, color: AppTheme.color.border })
                .onClick(() => {
                  this.purchaseDate = '';
                })
            }
          }
          .width('100%')
          .height(52)
          .padding({ left: 12, right: 12 })
          .backgroundColor(AppTheme.color.surface)
          .borderRadius(8)
          .border({ width: 1, color: AppTheme.color.border })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openPurchaseDatePicker();
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
