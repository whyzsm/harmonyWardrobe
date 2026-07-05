import { ClothingPicker } from '../components/ClothingPicker';
import { PhotoGrid } from '../components/PhotoGrid';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem, PurchaseInfo } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { StoreVisit } from '../domain/store/StoreModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { toIsoDate } from '../utils/date';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

interface CaptureCategoryOption {
  label: string;
  value: ClothingCategory;
}

const CAPTURE_CATEGORY_OPTIONS: CaptureCategoryOption[] = [
  { label: '上衣', value: ClothingCategory.Top },
  { label: '裤子', value: ClothingCategory.Pants },
  { label: '短裤', value: ClothingCategory.Shorts },
  { label: '长裙', value: ClothingCategory.LongSkirt },
  { label: '半裙', value: ClothingCategory.HalfSkirt }
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
  if (Number.isNaN(parsed.getTime())) {
    return new Date();
  }

  return parsed;
}

function formatTimeLabel(value: string): string {
  const date = dateFromIsoDateTime(value);
  return `${padTwoDigits(date.getMonth() + 1)}-${padTwoDigits(date.getDate())} ${padTwoDigits(date.getHours())}:${padTwoDigits(date.getMinutes())}`;
}

function captureDate(value: string): string {
  return toIsoDate(dateFromIsoDateTime(value));
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
  wearLogRepository?: WearLogRepository = undefined;
  onSave: (target: string) => void = () => {};
  onCancel: () => void = () => {};

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
  @State private wearDate: string = '';
  @State private syncWearLog: boolean = false;
  @State private districtOrAddress: string = '';
  @State private visitDate: string = '';
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.photoUris.length === 0) {
      this.photoUris = [...this.initialPhotoUris];
    }

    if (this.wearDate.length === 0) {
      this.wearDate = this.captureDate();
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
    return optionalText(this.outfitTitle) ?? this.generatedOutfitTitle();
  }

  private normalizedStoreName(): string {
    return optionalText(this.storeName) ?? this.generatedStoreVisitName();
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

  private toggleClothingItem(id: string): void {
    if (this.selectedClothingItemIds.includes(id)) {
      this.selectedClothingItemIds = this.selectedClothingItemIds.filter((itemId: string) => itemId !== id);
      return;
    }

    this.selectedClothingItemIds = this.selectedClothingItemIds.concat([id]);
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

    const outfit: OutfitTemplate = await this.outfitRepository.createOutfit({
      title: this.normalizedOutfitTitle(),
      photoUris: this.photoUris,
      clothingItemIds: this.selectedClothingItemIds,
      note: optionalText(this.note)
    });

    if (this.syncWearLog && this.wearLogRepository !== undefined) {
      const _wearLog: WearLog = await this.wearLogRepository.createWearLog({
        outfitTemplateId: outfit.id,
        wornDate: optionalText(this.wearDate) ?? this.captureDate(),
        photoUris: this.photoUris,
        note: optionalText(this.note)
      });
    }

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

  build() {
    Scroll() {
      Column({ space: YibuqueSpacing.lg }) {
        Row() {
          Column({ space: YibuqueSpacing.xs }) {
            Text('补录照片')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textPrimary)

            Text(`拍照日期 ${this.captureDate()}`)
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

        PhotoGrid({ photoUris: this.photoUris })

        this.CaptureTypeTabs()
        this.NoteInput()
        this.OptionalFields()

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#EF4444')
        }

        Button(this.isSaving ? '保存中...' : `保存到${this.captureType}`)
          .width('100%')
          .height(56)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textInverse)
          .backgroundColor(this.canSave() ? YibuqueColor.actionBlack : YibuqueColor.textDisabled)
          .borderRadius(YibuqueRadius.full)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveCapture();
          })
      }
      .width('100%')
      .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.xxl, bottom: YibuqueSpacing.xxl })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 135,
      colors: [[YibuqueColor.bgDefault, 0], [YibuqueColor.bgHeaderBlue, 1]]
    })
  }

  @Builder
  CaptureTypeTabs() {
    Row({ space: YibuqueSpacing.sm }) {
      ForEach(['衣橱', '美搭', '店铺'], (type: string) => {
        Text(type)
          .height(42)
          .layoutWeight(1)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.captureType === type ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.captureType === type ? YibuqueColor.actionBlack : YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: this.captureType === type ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
          .onClick(() => {
            this.captureType = type;
          })
      }, (type: string) => type)
    }
    .width('100%')
  }

  @Builder
  NoteInput() {
    Column({ space: YibuqueSpacing.sm }) {
      Text('小记')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)

      TextArea({ text: this.note, placeholder: '写一点小记' })
        .height(108)
        .fontSize(16)
        .fontColor(YibuqueColor.textPrimary)
        .placeholderColor(YibuqueColor.textTertiary)
        .backgroundColor(YibuqueColor.cardWhite)
        .borderRadius(YibuqueRadius.xl)
        .border({ width: 1, color: YibuqueColor.borderLight })
        .onChange((value: string) => {
          this.note = value;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  OptionalFields() {
    Column({ space: YibuqueSpacing.md }) {
      Text('选填信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)

      if (this.captureType === '衣橱') {
        this.WardrobeFields()
      } else if (this.captureType === '美搭') {
        this.OutfitFields()
      } else {
        this.StoreFields()
      }
    }
    .width('100%')
    .padding(YibuqueSpacing.lg)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .shadow(YibuqueShadow.card)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WardrobeFields() {
    Column({ space: YibuqueSpacing.md }) {
      TextInput({ text: this.name, placeholder: this.generatedClothingName() })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.name = value;
        })

      this.CategoryTabs()

      TextInput({ text: this.storeName, placeholder: '购买店铺' })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.storeName = value;
        })

      TextInput({ text: this.price, placeholder: '价格' })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.price = value;
        })

      TextInput({ text: this.purchaseDate, placeholder: '购买日期 YYYY-MM-DD' })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.purchaseDate = value;
        })

      TextInput({ text: this.purchaseNote, placeholder: '购买备注' })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.purchaseNote = value;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  CategoryTabs() {
    Scroll() {
      Row({ space: YibuqueSpacing.sm }) {
        ForEach(CAPTURE_CATEGORY_OPTIONS, (option: CaptureCategoryOption) => {
          Text(option.label)
            .height(38)
            .padding({ left: 18, right: 18 })
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.category === option.value ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.category === option.value ? YibuqueColor.actionBlack : YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.full)
            .onClick(() => {
              this.category = option.value;
            })
        }, (option: CaptureCategoryOption) => option.label)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  OutfitFields() {
    Column({ space: YibuqueSpacing.md }) {
      TextInput({ text: this.outfitTitle, placeholder: this.generatedOutfitTitle() })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.outfitTitle = value;
        })

      ClothingPicker({
        items: this.clothingItems,
        selectedIds: this.selectedClothingItemIds,
        onToggle: (id: string) => {
          this.toggleClothingItem(id);
        }
      })

      TextInput({ text: this.wearDate, placeholder: '穿搭日期 YYYY-MM-DD' })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.wearDate = value;
          this.syncWearLog = value.trim().length > 0;
        })

      Row({ space: YibuqueSpacing.sm }) {
        Checkbox()
          .select(this.syncWearLog)
          .onChange((checked: boolean) => {
            this.syncWearLog = checked;
          })

        Text('同步到日历')
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StoreFields() {
    Column({ space: YibuqueSpacing.md }) {
      TextInput({ text: this.storeName, placeholder: this.generatedStoreVisitName() })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.storeName = value;
        })

      TextInput({ text: this.districtOrAddress, placeholder: '商圈或地址' })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.districtOrAddress = value;
        })

      TextInput({ text: this.visitDate, placeholder: '逛店日期 YYYY-MM-DD' })
        .height(52)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
        .onChange((value: string) => {
          this.visitDate = value;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
