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
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

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

function formatTimeForName(date: Date): string {
  return `${padTwoDigits(date.getMonth() + 1)}-${padTwoDigits(date.getDate())} ${padTwoDigits(date.getHours())}:${padTwoDigits(date.getMinutes())}`;
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
    this.photoUris = [...this.initialItem.photoUris];
    this.previewPhotoUri = this.initialItem.photoUris[0] ?? '';
    this.note = this.initialItem.note ?? '';
    this.storeName = this.initialItem.purchaseInfo?.storeName ?? '';
    this.price = this.initialItem.purchaseInfo?.price?.toString() ?? '';
    this.purchaseDate = this.initialItem.purchaseInfo?.purchaseDate ?? '';
    this.purchaseNote = this.initialItem.purchaseInfo?.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && this.hasSelectedPhoto();
  }

  private hasSelectedPhoto(): boolean {
    return this.previewPhotoUri.length > 0;
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

  private generatedName(): string {
    return `${labelForCategory(this.category)} ${formatTimeForName(new Date())}`;
  }

  private normalizedName(): string {
    const trimmedName = this.name.trim();
    return trimmedName.length > 0 ? trimmedName : this.generatedName();
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
      if (this.name.trim().length === 0) {
        this.name = this.generatedName();
      }

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
      name: this.normalizedName(),
      category: this.category,
      photoUris: this.photoUris,
      note: optionalText(this.note),
      purchaseInfo: this.purchaseInfo()
    };
  }

  private updateInput(id: string): UpdateClothingInput {
    return {
      id,
      name: this.normalizedName(),
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
    Stack({ alignContent: Alignment.Center }) {
      if (this.hasSelectedPhoto()) {
        Stack({ alignContent: Alignment.TopStart }) {
          Image(this.previewPhotoUri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .borderRadius(YibuqueRadius.xxl)

          Text('封面')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(YibuqueColor.cardWhite)
            .borderRadius(YibuqueRadius.full)
            .margin({ left: 14, top: 14 })

          Text('更换照片')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textInverse)
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .backgroundColor(YibuqueColor.overlayDark)
            .borderRadius(YibuqueRadius.full)
            .margin({ left: 14, top: 126 })
        }
        .width('100%')
        .height(176)
        .borderRadius(YibuqueRadius.xxl)
        .clip(true)
      } else {
        Column({ space: YibuqueSpacing.sm }) {
          Text('+')
            .fontSize(34)
            .fontWeight(FontWeight.Medium)
            .fontColor(YibuqueColor.textPrimary)

          Text('添加衣服照片')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)

          Text('从相册选择一张清晰单品照')
            .fontSize(13)
            .fontColor(YibuqueColor.textSecondary)
        }
        .width('100%')
        .height(176)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(YibuqueColor.cardWhite)
        .borderRadius(YibuqueRadius.xxl)
        .border({ width: 1, color: YibuqueColor.borderLight })
      }
    }
    .width('100%')
    .height(176)
    .borderRadius(YibuqueRadius.xxl)
    .shadow(YibuqueShadow.soft)
    .onClick(() => {
      this.pickGalleryPhotos();
    })
  }

  build() {
    Scroll() {
      Column({ space: YibuqueSpacing.lg }) {
        Row() {
          Column({ space: YibuqueSpacing.xs }) {
            Text(this.initialItem === undefined ? '添加衣服' : '编辑衣服')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textPrimary)

            Text('选图后会自动生成名称，其余信息都可选填。')
              .fontSize(14)
              .fontColor(YibuqueColor.textSecondary)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('取消')
            .height(44)
            .fontSize(15)
            .fontColor(YibuqueColor.textSecondary)
            .backgroundColor(YibuqueColor.cardWhite)
            .borderRadius(YibuqueRadius.full)
            .border({ width: 1, color: YibuqueColor.borderLight })
            .onClick(() => {
              this.onCancel();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        this.PhotoSelector()

        Column({ space: YibuqueSpacing.md }) {
          Text('基础信息（选填）')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)

          TextInput({ text: this.name, placeholder: '自动生成衣物名称，可修改' })
            .height(52)
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.name = value;
            })

          Row() {
            Text('分类')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textPrimary)
              .layoutWeight(1)

            Text(labelForCategory(this.category))
              .fontSize(13)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(CATEGORY_OPTIONS, (option: ClothingCategoryOption) => {
              Button(option.label)
                .height(40)
                .margin({ right: 8, bottom: 8 })
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(option.value === this.category ? YibuqueColor.textInverse : YibuqueColor.textSecondary)
                .backgroundColor(option.value === this.category ? YibuqueColor.actionBlack : YibuqueColor.cardWhite)
                .borderRadius(YibuqueRadius.full)
                .border({ width: 1, color: option.value === this.category ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
                .onClick(() => {
                  this.category = option.value;
                })
            }, (option: ClothingCategoryOption) => option.value)
          }

          TextInput({ text: this.note, placeholder: '备注' })
            .height(56)
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.note = value;
            })
        }
        .width('100%')
        .padding(YibuqueSpacing.lg)
        .borderRadius(YibuqueRadius.xxl)
        .backgroundColor(YibuqueColor.cardWhite)
        .shadow(YibuqueShadow.card)
        .alignItems(HorizontalAlign.Start)

        Column({ space: YibuqueSpacing.md }) {
          Column({ space: YibuqueSpacing.xs }) {
            Text('购买信息')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textPrimary)

            Text('可选，方便以后回想在哪里买。')
              .fontSize(13)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          TextInput({ text: this.storeName, placeholder: '购买门店' })
            .height(50)
            .fontSize(15)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.storeName = value;
            })

          TextInput({ text: this.price, placeholder: '价格' })
            .height(50)
            .fontSize(15)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .type(InputType.Number)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.price = value;
            })

          Row() {
            Column({ space: 2 }) {
              Text('购买日期')
                .fontSize(12)
                .fontColor(YibuqueColor.textSecondary)

              Text(this.purchaseDate.length > 0 ? this.purchaseDate : '选择购买日期')
                .fontSize(15)
                .fontColor(this.purchaseDate.length > 0 ? YibuqueColor.textPrimary : YibuqueColor.textTertiary)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            if (this.purchaseDate.length > 0) {
              Button('清除日期')
                .height(34)
                .fontSize(12)
                .fontColor(YibuqueColor.textSecondary)
                .backgroundColor(YibuqueColor.cardWhite)
                .borderRadius(YibuqueRadius.full)
                .border({ width: 1, color: YibuqueColor.borderLight })
                .onClick(() => {
                  this.purchaseDate = '';
                })
            }
          }
          .width('100%')
          .height(58)
          .padding({ left: 16, right: 12 })
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.lg)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openPurchaseDatePicker();
          })

          TextInput({ text: this.purchaseNote, placeholder: '购买备注' })
            .height(56)
            .fontSize(15)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.purchaseNote = value;
            })
        }
        .width('100%')
        .padding(YibuqueSpacing.lg)
        .borderRadius(YibuqueRadius.xxl)
        .backgroundColor(YibuqueColor.cardWhite)
        .shadow(YibuqueShadow.card)
        .alignItems(HorizontalAlign.Start)

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#EF4444')
        }

        Button(this.isSaving ? '保存中...' : (this.hasSelectedPhoto() ? '保存衣服' : '先添加照片'))
          .height(56)
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textInverse)
          .backgroundColor(this.canSave() ? YibuqueColor.actionBlack : YibuqueColor.textDisabled)
          .borderRadius(YibuqueRadius.full)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveClothing();
          })
      }
      .width('100%')
      .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.xxl, bottom: YibuqueSpacing.xxl })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBlueGray)
  }
}
