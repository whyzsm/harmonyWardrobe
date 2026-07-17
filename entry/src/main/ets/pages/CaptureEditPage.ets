import { ClothingPicker } from '../components/ClothingPicker';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import { ClothingItem, PurchaseInfo } from '../domain/clothing/ClothingModels';
import { StoreVisit } from '../domain/store/StoreModels';
import { toIsoDate } from '../utils/date';
import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';

interface CaptureCategoryOption {
  label: string;
  value: ClothingCategory;
}

const CAPTURE_CATEGORY_OPTIONS: CaptureCategoryOption[] = [
  { label: '上衣', value: ClothingCategory.Top },
  { label: '裤装', value: ClothingCategory.Pants },
  { label: '裙装', value: ClothingCategory.LongSkirt }
];

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function padTwoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function dateFromIsoDateTime(value: string): Date {
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? new Date() : parsed;
}

function formatTimeLabel(value: string): string {
  const date = dateFromIsoDateTime(value);
  return `${padTwoDigits(date.getMonth() + 1)}-${padTwoDigits(date.getDate())} ${padTwoDigits(date.getHours())}:${padTwoDigits(date.getMinutes())}`;
}

function captureDate(value: string): string {
  return toIsoDate(dateFromIsoDateTime(value));
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

function categoryLabel(category: ClothingCategory): string {
  for (const option of CAPTURE_CATEGORY_OPTIONS) {
    if (option.value === category) {
      return option.label;
    }
  }
  return '上衣';
}

@Component
export struct CaptureEditPage {
  @Prop initialPhotoUris: string[] = [];
  @Prop capturedAt: string = '';
  @Prop clothingItems: ClothingItem[] = [];
  clothingRepository?: ClothingRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  storeRepository?: StoreRepository = undefined;
  onChoosePhotos: () => Promise<string[]> = async () => [];
  onSave: (target: string) => void = () => {};
  onCancel: () => void = () => {};

  @State private captureMode: string = '单品';
  @State private captureType: string = '衣橱';
  @State private note: string = '';
  @State private name: string = '';
  @State private category: ClothingCategory = ClothingCategory.Top;
  @State private photoUris: string[] = [];
  @State private storeName: string = '';
  @State private price: string = '';
  @State private purchaseDate: string = '';
  @State private purchaseNote: string = '';
  @State private outfitTitle: string = '';
  @State private selectedClothingItemIds: string[] = [];
  @State private districtOrAddress: string = '';
  @State private visitDate: string = '';
  @State private isSaving: boolean = false;
  @State private isChoosingPhotos: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.photoUris.length === 0) {
      this.photoUris = [...this.initialPhotoUris];
    }
    if (this.visitDate.length === 0) {
      this.visitDate = this.captureDate();
    }
  }

  private captureTimestamp(): string {
    return this.capturedAt.length > 0 ? this.capturedAt : new Date().toISOString();
  }

  private captureDate(): string {
    return captureDate(this.captureTimestamp());
  }

  private generatedClothingName(): string {
    return `${categoryLabel(this.category)} ${formatTimeLabel(this.captureTimestamp())}`;
  }

  private generatedOutfitTitle(): string {
    return `美搭 ${formatTimeLabel(this.captureTimestamp())}`;
  }

  private generatedStoreVisitName(): string {
    return `逛店 ${formatTimeLabel(this.captureTimestamp())}`;
  }

  private normalizedClothingName(): string {
    return optionalText(this.name) ?? this.generatedClothingName();
  }

  private normalizedOutfitTitle(): string {
    return optionalText(this.outfitTitle) ?? optionalText(this.name) ?? this.generatedOutfitTitle();
  }

  private normalizedStoreName(): string {
    return optionalText(this.storeName) ?? optionalText(this.name) ?? this.generatedStoreVisitName();
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

  private openVisitDatePicker(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(),
      selected: dateFromStorage(this.visitDate.length > 0 ? this.visitDate : this.captureDate()),
      onDateAccept: (date: Date) => {
        this.visitDate = formatDateForStorage(date);
      }
    });
  }

  private canSave(): boolean {
    return !this.isSaving && this.photoUris.length > 0;
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
    if (info.storeName === undefined && info.price === undefined && info.purchaseDate === undefined && info.note === undefined) {
      return undefined;
    }
    return info;
  }

  private selectMode(mode: string): void {
    this.captureMode = mode;
    if (mode === '单品') {
      this.captureType = '衣橱';
    } else if (mode === '试穿') {
      this.captureType = '美搭';
    } else {
      this.captureType = '店铺';
    }
  }

  private toggleClothingItem(id: string): void {
    if (this.selectedClothingItemIds.includes(id)) {
      this.selectedClothingItemIds = this.selectedClothingItemIds.filter((itemId: string) => itemId !== id);
      return;
    }
    this.selectedClothingItemIds = this.selectedClothingItemIds.concat([id]);
  }

  private async choosePhotos(): Promise<void> {
    if (this.isSaving || this.isChoosingPhotos) {
      return;
    }
    this.isChoosingPhotos = true;
    this.errorMessage = '';
    try {
      const selectedPhotoUris = await this.onChoosePhotos();
      if (selectedPhotoUris.length > 0) {
        this.photoUris = selectedPhotoUris;
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '选择照片失败，请重试';
    } finally {
      this.isChoosingPhotos = false;
    }
  }

  private async saveWardrobe(): Promise<void> {
    if (this.clothingRepository === undefined) {
      return;
    }
    await this.clothingRepository.createClothing({
      name: this.normalizedClothingName(),
      category: this.category,
      photoUris: this.photoUris,
      note: optionalText(this.note),
      purchaseInfo: this.purchaseInfo()
    });
    this.onSave('衣橱');
  }

  private async saveOutfit(): Promise<void> {
    if (this.outfitRepository === undefined) {
      return;
    }
    await this.outfitRepository.createOutfit({
      title: this.normalizedOutfitTitle(),
      photoUris: this.photoUris,
      clothingItemIds: this.selectedClothingItemIds,
      note: optionalText(this.note)
    });
    this.onSave('美搭');
  }

  private async saveStore(): Promise<void> {
    if (this.storeRepository === undefined) {
      return;
    }
    const _visit: StoreVisit = await this.storeRepository.createStoreVisitWithOptionalStore({
      storeName: optionalText(this.storeName),
      storeNameSnapshot: this.normalizedStoreName(),
      districtOrAddress: optionalText(this.districtOrAddress),
      visitDate: optionalText(this.visitDate) ?? this.captureDate(),
      photoUris: this.photoUris,
      note: optionalText(this.note)
    });
    this.onSave('店铺');
  }

  private async saveCapture(): Promise<void> {
    if (!this.canSave()) {
      return;
    }
    this.isSaving = true;
    this.errorMessage = '';
    try {
      if (this.captureType === '衣橱') {
        await this.saveWardrobe();
      } else if (this.captureType === '美搭') {
        await this.saveOutfit();
      } else {
        await this.saveStore();
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存失败';
    } finally {
      this.isSaving = false;
    }
  }

  private saveButtonLabel(): string {
    if (this.isSaving) {
      return '保存中...';
    }
    if (this.captureType === '美搭') {
      return '保存试穿';
    }
    if (this.captureType === '店铺') {
      return '保存吊牌';
    }
    return this.photoUris.length > 0 ? '保存衣服' : '先添加照片';
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: '拍照录入',
        backAccessibilityText: '返回',
        onBack: () => {
          this.onCancel();
        }
      })

      Scroll() {
        Column({ space: 14 }) {
        this.ModeTabs()
        this.CapturePreview()

        Row({ space: 10 }) {
          Button(this.isChoosingPhotos ? '选择中...' : '选择照片')
            .layoutWeight(1)
            .height(44)
            .fontSize(13)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.xxxl)
            .border({ width: 1, color: YibuqueColor.borderMedium })
            .enabled(!this.isSaving && !this.isChoosingPhotos)
            .onClick(() => {
              this.choosePhotos();
            })

          Button() {
            if (this.isSaving) {
              LoadingProgress()
                .width(18)
                .height(18)
                .color(YibuqueColor.textInverse)
            } else {
              Text(this.saveButtonLabel())
                .fontSize(13)
                .fontWeight(FontWeight.Regular)
                .fontColor(YibuqueColor.textInverse)
            }
          }
            .layoutWeight(1)
            .height(44)
            .backgroundColor(this.canSave() ? YibuqueColor.actionBlack : YibuqueColor.textTertiary)
            .borderRadius(YibuqueRadius.xxxl)
            .enabled(this.canSave())
            .onClick(() => {
              this.saveCapture();
            })
        }
        .width('100%')

        if (this.captureType === '衣橱') {
          this.CategoryTabs()
        }

        this.NameField()
        this.NoteInput()

        if (this.captureType === '美搭') {
          this.OutfitFields()
        } else if (this.captureType === '店铺') {
          this.StoreFields()
        } else {
          this.PurchaseFields()
        }

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .width('100%')
            .fontSize(12)
            .fontColor(YibuqueColor.danger)
        }

        this.RecentCaptures()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 116 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgDefault)
  }

  @Builder
  ModeTabs() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(['单品', '试穿', '吊牌'], (mode: string) => {
          Row({ space: 7 }) {
            if (mode === '单品') {
              SymbolGlyph($r('sys.symbol.shirt'))
                .fontSize(17)
                .fontColor([this.captureMode === mode ? YibuqueColor.selectionAccent : YibuqueColor.textSecondary])
            } else if (mode === '试穿') {
              SymbolGlyph($r('sys.symbol.hanger_and_towels'))
                .fontSize(17)
                .fontColor([this.captureMode === mode ? YibuqueColor.selectionAccent : YibuqueColor.textSecondary])
            } else {
              SymbolGlyph($r('sys.symbol.bag'))
                .fontSize(17)
                .fontColor([this.captureMode === mode ? YibuqueColor.selectionAccent : YibuqueColor.textSecondary])
            }

            Text(mode)
              .fontSize(12)
              .fontWeight(this.captureMode === mode ? FontWeight.Regular : FontWeight.Regular)
              .fontColor(this.captureMode === mode ? YibuqueColor.selectionAccent : YibuqueColor.textSecondary)
          }
          .height(44)
          .padding({ left: 13, right: 15 })
          .backgroundColor(this.captureMode === mode ? YibuqueColor.selectionAccentSurface : YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.xxxl)
          .border({ width: 1, color: this.captureMode === mode ? YibuqueColor.selectionAccent : YibuqueColor.borderMedium })
          .onClick(() => {
            this.selectMode(mode);
          })
        }, (mode: string) => mode)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  CapturePreview() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.photoUris.length > 0) {
        Image(this.photoUris[0])
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else {
        Image($r('app.media.default_fashion_cover'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .border({ width: 1, color: YibuqueColor.glassMedium })
          .borderRadius(YibuqueRadius.xs)
      }
      .width('91%')
      .height(336)
      .margin({ left: 15, bottom: 18 })

      Text(`自动识别：${categoryLabel(this.category)}`)
        .height(32)
        .padding({ left: 12, right: 12 })
        .fontSize(12)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textInverse)
        .textAlign(TextAlign.Center)
        .backgroundColor(YibuqueColor.overlayDark)
        .borderRadius(YibuqueRadius.xl)
        .margin({ left: 12, bottom: 12 })
    }
    .width('100%')
    .height(372)
    .borderRadius(YibuqueRadius.xs)
    .clip(true)
    .border({ width: 1, color: YibuqueColor.borderLight })
    .backgroundColor(YibuqueColor.bgGray)
  }

  @Builder
  CategoryTabs() {
    Grid() {
      ForEach(CAPTURE_CATEGORY_OPTIONS, (option: CaptureCategoryOption) => {
        GridItem() {
          Text(option.label)
            .width('100%')
            .height(46)
            .fontSize(13)
            .fontWeight(this.category === option.value ? FontWeight.Regular : FontWeight.Regular)
            .fontColor(this.category === option.value ? YibuqueColor.selectionAccent : YibuqueColor.textSecondary)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.category === option.value ? YibuqueColor.selectionAccentSurface : YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.md)
            .border({ width: 1, color: this.category === option.value ? YibuqueColor.selectionAccent : YibuqueColor.borderMedium })
            .onClick(() => {
              this.category = option.value;
            })
        }
      }, (option: CaptureCategoryOption) => option.label)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(10)
    .width('100%')
    .height(46)
  }

  @Builder
  NameField() {
    Column({ space: 6 }) {
      Text('单品名称')
        .fontSize(13)
        .fontColor(YibuqueColor.textSecondary)

      Row({ space: 9 }) {
        SymbolGlyph($r('sys.symbol.shirt'))
          .fontSize(18)
          .fontColor([YibuqueColor.textSecondary])

        TextInput({ text: this.name, placeholder: this.generatedClothingName() })
          .layoutWeight(1)
          .height(46)
          .fontSize(14)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.name = value;
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 14, right: 10 })
      .border({ width: 1, color: YibuqueColor.borderMedium })
      .borderRadius(YibuqueRadius.md)
      .backgroundColor(YibuqueColor.bgDefault)
    }
    .width('100%')
  }

  @Builder
  NoteInput() {
    Column({ space: 6 }) {
      Text('备注')
        .fontSize(13)
        .fontColor(YibuqueColor.textSecondary)

      TextArea({ text: this.note, placeholder: '颜色、尺码、在哪里买的…' })
        .width('100%')
        .height(82)
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .fontSize(14)
        .fontColor(YibuqueColor.textPrimary)
        .placeholderColor(YibuqueColor.textTertiary)
        .backgroundColor(YibuqueColor.bgDefault)
        .borderRadius(YibuqueRadius.md)
        .border({ width: 1, color: YibuqueColor.borderMedium })
        .onChange((value: string) => {
          this.note = value;
        })
    }
    .width('100%')
  }

  @Builder
  PurchaseFields() {
    Column({ space: 10 }) {
      Column({ space: 6 }) {
        Text('购买店铺')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

        TextInput({ text: this.storeName, placeholder: '购买店铺（选填）' })
          .height(48)
          .fontSize(14)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.md)
          .onChange((value: string) => {
            this.storeName = value;
          })
      }
      .width('100%')

      Row({ space: 10 }) {
        Column({ space: 6 }) {
          Text('价格')
            .fontSize(13)
            .fontColor(YibuqueColor.textSecondary)

          TextInput({ text: this.price, placeholder: '价格' })
            .height(48)
            .fontSize(14)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.md)
            .onChange((value: string) => {
              this.price = value;
            })
        }
        .layoutWeight(1)

        Column({ space: 6 }) {
          Text('购买日期')
            .fontSize(13)
            .fontColor(YibuqueColor.textSecondary)

          Row() {
            Text(this.purchaseDate.length > 0 ? this.purchaseDate : '购买日期')
              .fontSize(14)
              .fontColor(this.purchaseDate.length > 0 ? YibuqueColor.textPrimary : YibuqueColor.textTertiary)
          }
            .width('100%')
            .height(48)
            .padding({ left: 12, right: 12 })
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.md)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.openPurchaseDatePicker();
            })
        }
        .layoutWeight(1)
      }
      .width('100%')

      Column({ space: 6 }) {
        Text('购买备注')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

        TextInput({ text: this.purchaseNote, placeholder: '购买备注' })
          .height(48)
          .fontSize(14)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.md)
          .onChange((value: string) => {
            this.purchaseNote = value;
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  OutfitFields() {
    Column({ space: 10 }) {
      Column({ space: 6 }) {
        Text('美搭名称')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

        TextInput({ text: this.outfitTitle, placeholder: this.generatedOutfitTitle() })
          .height(48)
          .fontSize(14)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.md)
          .onChange((value: string) => {
            this.outfitTitle = value;
          })
      }
      .width('100%')

      ClothingPicker({
        items: this.clothingItems,
        selectedIds: this.selectedClothingItemIds,
        onToggle: (id: string) => {
          this.toggleClothingItem(id);
        }
      })
    }
    .width('100%')
  }

  @Builder
  StoreFields() {
    Column({ space: 10 }) {
      Column({ space: 6 }) {
        Text('店铺名')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

        TextInput({ text: this.storeName, placeholder: this.generatedStoreVisitName() })
          .height(48)
          .fontSize(14)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.md)
          .onChange((value: string) => {
            this.storeName = value;
          })
      }
      .width('100%')

      Column({ space: 6 }) {
        Text('地点')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

        TextInput({ text: this.districtOrAddress, placeholder: '商场、商圈或地址' })
          .height(48)
          .fontSize(14)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.md)
          .onChange((value: string) => {
            this.districtOrAddress = value;
          })
      }
      .width('100%')

      Column({ space: 6 }) {
        Text('逛店日期')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

        Row() {
          Text(this.visitDate.length > 0 ? this.visitDate : '逛店日期 YYYY-MM-DD')
            .fontSize(14)
            .fontColor(this.visitDate.length > 0 ? YibuqueColor.textPrimary : YibuqueColor.textTertiary)
        }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.md)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openVisitDatePicker();
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  RecentCaptures() {
    Column({ space: 10 }) {
      Text('刚录入')
        .fontSize(19)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)

      Grid() {
        ForEach(this.photoUris.slice(0, 3), (photoUri: string) => {
          GridItem() {
            Image(photoUri)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(YibuqueRadius.xs)
          }
        }, (photoUri: string) => photoUri)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(10)
      .width('100%')
      .height(112)
    }
    .width('100%')
    .margin({ top: 4 })
    .alignItems(HorizontalAlign.Start)
  }
}
