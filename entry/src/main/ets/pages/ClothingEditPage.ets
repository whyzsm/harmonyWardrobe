import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
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
import { PhotoCarousel } from '../components/PhotoCarousel';
import { appendPhotoUris, MAX_USER_PHOTOS, remainingPhotoSlots } from '../utils/photoSelection';
import { userFacingError } from '../utils/userFacingError';

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
const DISPLAY_CATEGORY_OPTIONS: ClothingCategoryOption[] = [
  { label: '上衣', value: ClothingCategory.Top },
  { label: '裤子', value: ClothingCategory.Pants },
  { label: '短裤', value: ClothingCategory.Shorts },
  { label: '长裙', value: ClothingCategory.LongSkirt }
];
const LEGACY_HALF_SKIRT_OPTION: ClothingCategoryOption = {
  label: '半裙',
  value: ClothingCategory.HalfSkirt
};
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
  @StorageProp('windowBottomInsetVp') private windowBottomInsetVp: number = YibuqueSpacing.bottomSafe;
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
  @State private isChoosingPhotos: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialItem === undefined) {
      return;
    }

    this.name = this.initialItem.name;
    this.category = this.initialItem.category;
    this.photoUris = [...this.initialItem.photoUris];
    this.note = this.initialItem.note ?? '';
    this.storeName = this.initialItem.purchaseInfo?.storeName ?? '';
    this.price = this.initialItem.purchaseInfo?.price?.toString() ?? '';
    this.purchaseDate = this.initialItem.purchaseInfo?.purchaseDate ?? '';
    this.purchaseNote = this.initialItem.purchaseInfo?.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && !this.isChoosingPhotos && this.hasSelectedPhoto();
  }

  private hasSelectedPhoto(): boolean {
    return this.photoUris.length > 0;
  }

  private visibleCategoryOptions(): ClothingCategoryOption[] {
    if (this.category === ClothingCategory.HalfSkirt) {
      return [
        DISPLAY_CATEGORY_OPTIONS[0],
        DISPLAY_CATEGORY_OPTIONS[1],
        DISPLAY_CATEGORY_OPTIONS[2],
        LEGACY_HALF_SKIRT_OPTION
      ];
    }

    return DISPLAY_CATEGORY_OPTIONS;
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
    this.getUIContext().showDatePickerDialog({
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
    if (this.photoPickerAdapter === undefined || this.isSaving || this.isChoosingPhotos) {
      if (this.photoPickerAdapter === undefined) {
        this.errorMessage = '照片选择能力不可用';
      }
      return;
    }

    this.isChoosingPhotos = true;
    this.errorMessage = '';
    try {
      const availableSlots = remainingPhotoSlots(this.photoUris);
      if (availableSlots === 0) {
        this.errorMessage = `最多添加 ${MAX_USER_PHOTOS} 张照片。`;
        return;
      }
      const sources = await this.photoPickerAdapter.pickFromGallery({ maxSelectNumber: availableSlots });
      if (sources.length === 0) {
        return;
      }

      try {
        const localUris = await this.copySourcesToLocalUris(sources);
        if (localUris.length > 0) {
          this.photoUris = appendPhotoUris(this.photoUris, localUris);
          if (this.name.trim().length === 0) {
            this.name = this.generatedName();
          }
        } else {
          this.errorMessage = '照片复制失败，请重试';
        }
      } catch (copyError) {
        const detail = copyError instanceof Error ? copyError.message : '未知错误';
        this.errorMessage = `照片保存失败：${detail}`;
      }
    } catch (error) {
      this.errorMessage = userFacingError(error, '选择照片失败');
    } finally {
      this.isChoosingPhotos = false;
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
      this.showSaveToast('衣物已保存');
      this.onSave(savedItem);
    } catch (error) {
      this.errorMessage = userFacingError(error, '保存衣物失败');
    } finally {
      this.isSaving = false;
    }
  }

  private showSaveToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message });
  }

  @Builder
  PhotoHero() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.hasSelectedPhoto()) {
        PhotoCarousel({ photoUris: this.photoUris })
          .width('100%')
          .height('100%')
      } else {
        Image($r('app.media.default_fashion_cover'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      Row({ space: 10 }) {
        SymbolGlyph($r('sys.symbol.picture'))
          .fontSize(18)
          .fontColor([YibuqueColor.textPrimary])

        Text(this.isChoosingPhotos ? '选择中...' : '选择照片')
          .fontSize(15)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
      }
      .height(44)
      .padding({ left: 18, right: 18 })
      .margin({ left: 24, bottom: 24 })
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius(YibuqueRadius.full)
      .shadow(YibuqueShadow.soft)
    }
    .width('100%')
    .aspectRatio(1)
    .borderRadius(YibuqueRadius.xxxl)
    .clip(true)
    .enabled(!this.isSaving && !this.isChoosingPhotos)
    .accessibilityText('选择衣物照片')
    .onClick(() => {
      this.pickGalleryPhotos();
    })
  }

  @Builder
  ItemDetailCard() {
    Column({ space: 2 }) {
      Text('项目详情')
        .fontSize(13)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textSecondary)

      TextInput({ text: this.name, placeholder: '衣物名称' })
        .width('100%')
        .height(42)
        .padding(0)
        .fontSize(20)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .placeholderColor(YibuqueColor.textTertiary)
        .backgroundColor(YibuqueColor.transparent)
        .onChange((value: string) => {
          this.name = value;
        })
    }
    .width('100%')
    .height(98)
    .padding({ left: 24, right: 24, top: 18, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxxl)
    .border({ width: 1, color: YibuqueColor.borderLight })
  }

  @Builder
  CategorySection() {
    Column({ space: 14 }) {
      Row() {
        Text('分类')
          .fontSize(16)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .layoutWeight(1)

        Text(`已选：${labelForCategory(this.category)}`)
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 12 }) {
        ForEach(this.visibleCategoryOptions(), (option: ClothingCategoryOption) => {
          Button(option.label)
            .height(42)
            .layoutWeight(1)
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor(option.value === this.category ? YibuqueColor.textInverse : YibuqueColor.textSecondary)
            .backgroundColor(option.value === this.category ? YibuqueColor.actionBlack : YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.md)
            .border({ width: 1, color: option.value === this.category ? YibuqueColor.actionBlack : YibuqueColor.borderMedium })
            .onClick(() => {
              this.category = option.value;
            })
        }, (option: ClothingCategoryOption) => option.value)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  NoteSection() {
    Column({ space: 14 }) {
      Text('备注')
        .fontSize(16)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)

      TextArea({ text: this.note, placeholder: '输入关于这件衣服的描述...' })
        .width('100%')
        .height(120)
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .fontSize(15)
        .fontColor(YibuqueColor.textPrimary)
        .placeholderColor(YibuqueColor.textTertiary)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.note = value;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PurchaseSection() {
    Column({ space: 16 }) {
      Column({ space: 4 }) {
        Text('购买信息')
          .fontSize(16)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)

        Text('可选，方便以后回想在哪里买。')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row({ space: 14 }) {
        SymbolGlyph($r('sys.symbol.store_fill'))
          .fontSize(20)
          .fontColor([YibuqueColor.textSecondary])

        TextInput({ text: this.storeName, placeholder: '购买门店' })
          .layoutWeight(1)
          .height('100%')
          .padding(0)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .backgroundColor(YibuqueColor.transparent)
          .onChange((value: string) => {
            this.storeName = value;
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 18, right: 18 })
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.lg)
      .alignItems(VerticalAlign.Center)

      Row({ space: 14 }) {
        SymbolGlyph($r('sys.symbol.creditcard'))
          .fontSize(20)
          .fontColor([YibuqueColor.textSecondary])

        TextInput({ text: this.price, placeholder: '价格' })
          .layoutWeight(1)
          .height('100%')
          .padding(0)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .type(InputType.Number)
          .backgroundColor(YibuqueColor.transparent)
          .onChange((value: string) => {
            this.price = value;
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 18, right: 18 })
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.lg)
      .alignItems(VerticalAlign.Center)

      Row({ space: 14 }) {
        SymbolGlyph($r('sys.symbol.calendar'))
          .fontSize(20)
          .fontColor([YibuqueColor.textSecondary])
          .onClick(() => {
            this.openPurchaseDatePicker();
          })

        Column({ space: 2 }) {
          Text('购买日期')
            .fontSize(12)
            .fontColor(YibuqueColor.textSecondary)

          Text(this.purchaseDate.length > 0 ? this.purchaseDate : '选择购买日期')
            .fontSize(15)
            .fontColor(this.purchaseDate.length > 0 ? YibuqueColor.textPrimary : YibuqueColor.textPrimary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .onClick(() => {
          this.openPurchaseDatePicker();
        })

        if (this.purchaseDate.length > 0) {
          Stack({ alignContent: Alignment.Center }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(16)
              .fontColor([YibuqueColor.textSecondary])
          }
          .width(44)
          .height(44)
          .accessibilityText('清除日期')
          .onClick(() => {
            this.purchaseDate = '';
          })
        } else {
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(17)
            .fontColor([YibuqueColor.textSecondary])
            .onClick(() => {
              this.openPurchaseDatePicker();
            })
        }
      }
      .width('100%')
      .height(66)
      .padding({ left: 18, right: 18 })
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.lg)
      .alignItems(VerticalAlign.Center)

      Row({ space: 14 }) {
        SymbolGlyph($r('sys.symbol.list_bullet'))
          .fontSize(20)
          .fontColor([YibuqueColor.textSecondary])

        TextInput({ text: this.purchaseNote, placeholder: '购买备注' })
          .layoutWeight(1)
          .height('100%')
          .padding(0)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .backgroundColor(YibuqueColor.transparent)
          .onChange((value: string) => {
            this.purchaseNote = value;
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 18, right: 18 })
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.lg)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SaveAction() {
    Column() {
      if (this.isSaving) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(YibuqueColor.textInverse)
        }
        .width('100%')
        .height(52)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.full)
        .shadow(YibuqueShadow.soft)
      } else if (this.canSave()) {
        Button() {
          Text('保存衣物')
            .fontSize(17)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)
        }
        .width('100%')
        .height(52)
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.full)
        .shadow(YibuqueShadow.soft)
        .onClick(() => {
          this.saveClothing();
        })
      } else {
        Row() {
          Text(this.hasSelectedPhoto() ? '保存衣物' : '先选择照片')
            .fontSize(17)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
        }
        .width('100%')
        .height(52)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(YibuqueColor.textDisabled)
        .borderRadius(YibuqueRadius.full)
        .shadow(YibuqueShadow.soft)
      }
    }
    .width('100%')
    .padding({
      left: YibuqueSpacing.pageX,
      right: YibuqueSpacing.pageX,
      top: 16,
      bottom: 32 + this.windowBottomInsetVp
    })
    .backgroundColor(YibuqueColor.cardWhite)
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: this.initialItem === undefined ? '添加衣物' : '编辑衣物',
        backAccessibilityText: '返回衣柜',
        onBack: () => {
          this.onCancel();
        }
      })

      Scroll() {
        Column({ space: 28 }) {
          this.PhotoHero()
          this.ItemDetailCard()
          this.CategorySection()
          this.NoteSection()
          this.PurchaseSection()

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(13)
              .fontColor(YibuqueColor.danger)
          }
        }
        .width('100%')
        .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: 20, bottom: 32 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })

      this.SaveAction()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBase)
  }
}
