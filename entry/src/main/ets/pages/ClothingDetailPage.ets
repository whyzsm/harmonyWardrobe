import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem, PurchaseInfo } from '../domain/clothing/ClothingModels';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

function labelForCategory(category: ClothingCategory): string {
  if (category === ClothingCategory.Pants) {
    return '裤子';
  }
  if (category === ClothingCategory.Shorts) {
    return '短裤';
  }
  if (category === ClothingCategory.LongSkirt) {
    return '长裙';
  }
  if (category === ClothingCategory.HalfSkirt) {
    return '半裙';
  }

  return '上衣';
}

function padTwoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function formatDateTime(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return `${date.getFullYear()}-${padTwoDigits(date.getMonth() + 1)}-${padTwoDigits(date.getDate())} ${padTwoDigits(date.getHours())}:${padTwoDigits(date.getMinutes())}`;
}

function priceText(price?: number): string {
  if (price === undefined || !Number.isFinite(price)) {
    return '';
  }

  return `¥${price.toFixed(2)}`;
}

function visibleItemName(item?: ClothingItem): string {
  if (item === undefined) {
    return '衣物详情';
  }

  const categoryLabel = labelForCategory(item.category);
  const autoNamePattern = new RegExp(`^${categoryLabel} \\d{2}-\\d{2} \\d{2}:\\d{2}$`);
  return autoNamePattern.test(item.name) ? categoryLabel : item.name;
}

function purchaseInfoHasContent(info?: PurchaseInfo): boolean {
  return info !== undefined && (
    (info.storeName !== undefined && info.storeName.length > 0) ||
      info.price !== undefined ||
      (info.purchaseDate !== undefined && info.purchaseDate.length > 0) ||
      (info.note !== undefined && info.note.length > 0)
  );
}

@Component
export struct ClothingDetailPage {
  @Prop item?: ClothingItem = undefined;
  onBack: () => void = () => {};
  onEdit: (item: ClothingItem) => void = () => {};
  @State private showPhotoPreview: boolean = false;
  @State private selectedPhotoIndex: number = 0;

  private photoUris(): string[] {
    return this.item?.photoUris ?? [];
  }

  private photoCount(): number {
    return this.photoUris().length;
  }

  private normalizePhotoIndex(index: number): number {
    const count = this.photoCount();
    if (count === 0) {
      return 0;
    }
    if (index < 0) {
      return 0;
    }
    if (index >= count) {
      return count - 1;
    }

    return index;
  }

  private photoUriAt(index: number): string {
    const photos = this.photoUris();
    if (photos.length === 0) {
      return '';
    }

    return photos[this.normalizePhotoIndex(index)];
  }

  private currentPhotoIndex(): number {
    return this.normalizePhotoIndex(this.selectedPhotoIndex);
  }

  private itemName(): string {
    return visibleItemName(this.item);
  }

  private itemCategoryLabel(): string {
    if (this.item === undefined) {
      return '衣物';
    }

    return labelForCategory(this.item.category);
  }

  private itemNote(): string {
    const note = this.item?.note ?? '';
    return note.length > 0 ? note : '暂未填写备注';
  }

  private photoCountText(): string {
    const count = this.photoCount();
    return count > 0 ? `${count} 张照片` : '暂无照片';
  }

  private createdAtText(): string {
    return this.item === undefined ? '未记录' : formatDateTime(this.item.createdAt);
  }

  private updatedAtText(): string {
    return this.item === undefined ? '未记录' : formatDateTime(this.item.updatedAt);
  }

  private purchaseInfo(): PurchaseInfo | undefined {
    return this.item?.purchaseInfo;
  }

  private selectPhoto(index: number): void {
    this.selectedPhotoIndex = this.normalizePhotoIndex(index);
  }

  private openPhotoPreview(index: number = this.selectedPhotoIndex): void {
    if (this.photoCount() === 0) {
      return;
    }

    this.selectPhoto(index);
    this.showPhotoPreview = true;
  }

  private closePhotoPreview(): void {
    this.showPhotoPreview = false;
  }

  @Builder
  BackIcon() {
    Stack({ alignContent: Alignment.Center }) {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(24)
        .fontColor([YibuqueColor.textPrimary])
    }
    .width(40)
    .height(40)
  }

  @Builder
  EditIcon() {
    Stack({ alignContent: Alignment.Center }) {
      SymbolGlyph($r('sys.symbol.square_and_pencil'))
        .fontSize(23)
        .fontColor([YibuqueColor.textPrimary])
    }
    .width(40)
    .height(40)
  }

  @Builder
  DetailTopBar() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        this.BackIcon()
      }
      .width(48)
      .height(48)
      .borderRadius(YibuqueRadius.full)
      .onClick(() => {
        this.onBack();
      })

      Text('衣物详情')
        .layoutWeight(1)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)
        .textAlign(TextAlign.Center)

      Stack({ alignContent: Alignment.Center }) {
        this.EditIcon()
      }
      .width(48)
      .height(48)
      .borderRadius(YibuqueRadius.full)
      .onClick(() => {
        const item = this.item;
        if (item !== undefined) {
          this.onEdit(item);
        }
      })
    }
    .width('100%')
    .height(96)
    .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.xl })
    .linearGradient({
      angle: 135,
      colors: [['#E6FFF2F8', 0], ['#E6F8D4EF', 1]]
    })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row({ space: YibuqueSpacing.md }) {
      Text(label)
        .width(76)
        .fontSize(13)
        .fontColor(YibuqueColor.textTertiary)

      Text(value)
        .layoutWeight(1)
        .fontSize(15)
        .fontColor(YibuqueColor.textPrimary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(34)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  HeroPhoto() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.photoCount() > 0) {
        Swiper() {
          ForEach(this.photoUris(), (photoUri: string, index: number) => {
            Image(photoUri)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .onClick(() => {
                this.openPhotoPreview(index);
              })
          }, (photoUri: string, index: number) => `${photoUri}-${index}`)
        }
        .width('100%')
        .height('100%')
        .index(this.currentPhotoIndex())
        .indicator(false)
        .loop(this.photoCount() > 1)
        .onChange((index: number) => {
          this.selectPhoto(index);
        })

      } else {
        Column({ space: YibuqueSpacing.sm }) {
          SymbolGlyph($r('sys.symbol.shirt'))
            .fontSize(48)
            .fontColor([YibuqueColor.textPrimary])

          Text('暂无照片')
            .fontSize(14)
            .fontColor(YibuqueColor.textSecondary)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(YibuqueColor.cardMint)
      }

    }
    .width('100%')
    .height(280)
    .borderRadius(YibuqueRadius.xxxl)
    .clip(true)
    .shadow(YibuqueShadow.card)
  }

  @Builder
  PreviewPhotoSwiper() {
    Swiper() {
      ForEach(this.photoUris(), (photoUri: string, index: number) => {
        Image(photoUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
      }, (photoUri: string, index: number) => `${photoUri}-${index}`)
    }
    .width('100%')
    .height('78%')
    .index(this.currentPhotoIndex())
    .indicator(false)
    .loop(this.photoCount() > 1)
    .onChange((index: number) => {
      this.selectPhoto(index);
    })
  }

  @Builder
  PhotoPreviewOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#E6391327')
        .onClick(() => {
          this.closePhotoPreview();
        })

      this.PreviewPhotoSwiper()

      Row() {
        Column({ space: 3 }) {
          Text(this.itemName())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textInverse)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.photoCount() > 1) {
            Text(`${this.currentPhotoIndex() + 1} / ${this.photoCount()}`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textInverse)
              .opacity(0.86)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('关闭')
          .height(40)
          .padding({ left: 18, right: 18 })
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.full)
          .onClick(() => {
            this.closePhotoPreview();
          })
      }
      .width('100%')
      .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.xxl })
      .position({ x: 0, y: 0 })
      .alignItems(VerticalAlign.Center)

      if (this.photoCount() > 1) {
        Text('左右滑动')
          .height(32)
          .padding({ left: 14, right: 14 })
          .fontSize(13)
          .fontColor(YibuqueColor.textInverse)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.overlayDark)
          .borderRadius(YibuqueRadius.full)
          .margin({ bottom: YibuqueSpacing.xxl })
          .align(Alignment.Bottom)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SummaryCard() {
    Column({ space: YibuqueSpacing.md }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.itemName())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.photoCountText())
            .fontSize(13)
            .fontColor(YibuqueColor.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.itemCategoryLabel())
          .height(34)
          .padding({ left: 14, right: 14 })
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.actionBlack)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: YibuqueColor.actionBlack })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.itemNote())
        .width('100%')
        .height(72)
        .padding(YibuqueSpacing.md)
        .fontSize(15)
        .fontColor(YibuqueColor.textPrimary)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
    }
    .width('100%')
    .padding(YibuqueSpacing.lg)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .shadow(YibuqueShadow.card)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PurchaseCard() {
    Column({ space: YibuqueSpacing.md }) {
      Text('购买信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)

      if (purchaseInfoHasContent(this.purchaseInfo())) {
        this.DetailRow('门店', this.purchaseInfo()?.storeName ?? '未记录')
        this.DetailRow('价格', priceText(this.purchaseInfo()?.price) || '未记录')
        this.DetailRow('日期', this.purchaseInfo()?.purchaseDate ?? '未记录')
        this.DetailRow('备注', this.purchaseInfo()?.note ?? '未记录')
      } else {
        Text('暂未填写购买信息')
          .width('100%')
          .height(52)
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.lg)
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
  RecordCard() {
    Column({ space: YibuqueSpacing.md }) {
      Text('记录信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)

      this.DetailRow('创建', this.createdAtText())
      this.DetailRow('更新', this.updatedAtText())
    }
    .width('100%')
    .padding(YibuqueSpacing.lg)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .shadow(YibuqueShadow.card)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    if (this.item === undefined) {
      Column({ space: YibuqueSpacing.lg }) {
        Text('衣物不存在')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)

        Text('可能已经被删除，请返回衣橱重新选择。')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)

        Text('返回')
          .height(44)
          .padding({ left: 24, right: 24 })
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textInverse)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.actionBlack)
          .borderRadius(YibuqueRadius.full)
          .onClick(() => {
            this.onBack();
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(YibuqueColor.bgBlueGray)
    } else {
      Stack() {
        Column() {
          this.DetailTopBar()

          Scroll() {
            Column({ space: YibuqueSpacing.lg }) {
              this.HeroPhoto()
              this.SummaryCard()
              this.PurchaseCard()
              this.RecordCard()
            }
            .width('100%')
            .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.sm, bottom: YibuqueSpacing.section })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(YibuqueColor.bgBlueGray)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(YibuqueColor.bgBlueGray)

        if (this.showPhotoPreview) {
          this.PhotoPreviewOverlay()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(YibuqueColor.bgBlueGray)
    }
  }
}
