import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem, PurchaseInfo } from '../domain/clothing/ClothingModels';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import {
  YibuqueColor,
  YibuqueMotion,
  YibuqueRadius,
  YibuqueShadow,
  YibuqueSpacing,
  YibuqueTransition
} from '../theme/Tokens';
import { userFacingError } from '../utils/userFacingError';

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
  @StorageProp('windowBottomInsetVp') private windowBottomInsetVp: number = YibuqueSpacing.bottomSafe;
  @Prop item?: ClothingItem = undefined;
  onBack: () => void = () => {};
  onEdit: (item: ClothingItem) => void = () => {};
  onDelete: (item: ClothingItem) => Promise<void> = async (_item: ClothingItem): Promise<void> => {};
  @State private showPhotoPreview: boolean = false;
  @State private showDeleteConfirm: boolean = false;
  @State private isDeleting: boolean = false;
  @State private deleteErrorMessage: string = '';
  @State private selectedPhotoIndex: number = 0;
  private photoPreviewTransitionInProgress: boolean = false;

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
    return this.item?.note?.trim() ?? '';
  }

  private hasItemNote(): boolean {
    return this.itemNote().length > 0;
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
    this.animatePhotoPreview(true);
  }

  private closePhotoPreview(): void {
    this.animatePhotoPreview(false);
  }

  private animatePhotoPreview(visible: boolean): void {
    if (this.photoPreviewTransitionInProgress || this.showPhotoPreview === visible) {
      return;
    }

    this.photoPreviewTransitionInProgress = true;
    this.getUIContext().animateTo({
      duration: YibuqueMotion.fullScreenPageTransition,
      curve: Curve.EaseOut,
      onFinish: () => {
        this.photoPreviewTransitionInProgress = false;
      }
    }, () => {
      this.showPhotoPreview = visible;
    });
  }

  private confirmDelete(): void {
    const item = this.item;
    if (item === undefined || this.isDeleting) {
      return;
    }

    this.showDeleteConfirm = true;
    AlertDialog.show({
      title: '删除衣物',
      message: '确定要删除这件衣物吗？照片也会一并移除。',
      primaryButton: {
        value: '取消',
        action: () => {
          this.showDeleteConfirm = false;
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: YibuqueColor.danger,
        action: () => {
          this.deleteCurrentItem();
        }
      },
      cancel: () => {
        this.showDeleteConfirm = false;
      }
    });
  }

  private async deleteCurrentItem(): Promise<void> {
    const item = this.item;
    if (item === undefined || this.isDeleting) {
      return;
    }

    this.isDeleting = true;
    this.deleteErrorMessage = '';
    try {
      await this.onDelete(item);
      this.showDeleteConfirm = false;
    } catch (error) {
      this.deleteErrorMessage = userFacingError(error, '删除衣物失败');
    } finally {
      this.isDeleting = false;
    }
  }

  @Builder
  DetailTopBar() {
    SecondaryPageHeader({
      title: '衣物详情',
      showEditAction: true,
      backAccessibilityText: '返回衣柜',
      onBack: () => {
        this.onBack();
      },
      onEdit: () => {
        const item = this.item;
        if (item !== undefined) {
          this.onEdit(item);
        }
      }
    })
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
        if (this.photoCount() === 1) {
          Image(this.photoUriAt(0))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              this.openPhotoPreview(0);
            })
        } else {
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
          .loop(true)
          .onChange((index: number) => {
            this.selectPhoto(index);
          })
        }

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
        .backgroundColor(YibuqueColor.cardMuted)
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
    if (this.photoCount() === 1) {
      Image(this.photoUriAt(0))
        .width('100%')
        .height('78%')
        .objectFit(ImageFit.Contain)
    } else {
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
      .loop(true)
      .onChange((index: number) => {
        this.selectPhoto(index);
      })
    }
  }

  @Builder
  PhotoPreviewOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(YibuqueColor.overlayDark)
        .onClick(() => {
          this.closePhotoPreview();
        })

      this.PreviewPhotoSwiper()

      Row() {
        Column({ space: 3 }) {
          Text(this.itemName())
            .fontSize(16)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.photoCount() > 1) {
            Text(`${this.currentPhotoIndex() + 1} / ${this.photoCount()}`)
              .fontSize(12)
              .fontWeight(FontWeight.Regular)
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
          .fontWeight(FontWeight.Regular)
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
    .transition(YibuqueTransition.fullScreenOpacity)
  }

  @Builder
  SummaryCard() {
    Column({ space: YibuqueSpacing.md }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.itemName())
            .fontSize(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .lineHeight(28)

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
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.iconAccent)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.iconAccentSurface)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: YibuqueColor.iconAccentSurface })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.hasItemNote()) {
        Text(this.itemNote())
          .width('100%')
          .height(72)
          .padding(YibuqueSpacing.md)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
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
  PurchaseCard() {
    if (purchaseInfoHasContent(this.purchaseInfo())) {
      Column({ space: YibuqueSpacing.md }) {
        Text('购买信息')
          .fontSize(18)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)

        this.DetailRow('门店', this.purchaseInfo()?.storeName ?? '未记录')
        this.DetailRow('价格', priceText(this.purchaseInfo()?.price) || '未记录')
        this.DetailRow('日期', this.purchaseInfo()?.purchaseDate ?? '未记录')
        if ((this.purchaseInfo()?.note?.trim() ?? '').length > 0) {
          this.DetailRow('备注', this.purchaseInfo()?.note?.trim() ?? '')
        }
      }
      .width('100%')
      .padding(YibuqueSpacing.lg)
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius(YibuqueRadius.xxl)
      .shadow(YibuqueShadow.card)
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  RecordCard() {
    Column({ space: YibuqueSpacing.md }) {
      Text('记录信息')
        .fontSize(18)
        .fontWeight(FontWeight.Regular)
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

  @Builder
  DeleteAction() {
    Column({ space: YibuqueSpacing.sm }) {
      Button() {
        if (this.isDeleting) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color(YibuqueColor.textInverse)
        } else {
          Text('删除衣物')
            .fontSize(15)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)
        }
      }
      .width('100%')
      .height(46)
      .enabled(!this.isDeleting && !this.showDeleteConfirm)
      .backgroundColor(YibuqueColor.danger)
      .borderRadius(YibuqueRadius.full)
      .onClick(() => {
        this.confirmDelete();
      })

      if (this.deleteErrorMessage.length > 0) {
        Text(this.deleteErrorMessage)
          .width('100%')
          .fontSize(13)
          .fontColor(YibuqueColor.danger)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
  }

  build() {
    if (this.item === undefined) {
      Column() {
        SecondaryPageHeader({
          title: '衣物详情',
          backAccessibilityText: '返回衣柜',
          onBack: () => {
            this.onBack();
          }
        })

        Column({ space: YibuqueSpacing.lg }) {
          Text('衣物不存在')
            .fontSize(24)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)

          Text('可能已经被删除，请返回衣柜重新选择。')
            .fontSize(14)
            .fontColor(YibuqueColor.textSecondary)

          Text('返回')
            .height(44)
            .padding({ left: 24, right: 24 })
            .fontSize(15)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)
            .textAlign(TextAlign.Center)
            .backgroundColor(YibuqueColor.actionBlack)
            .borderRadius(YibuqueRadius.full)
            .onClick(() => {
              this.onBack();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(YibuqueColor.bgBase)
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
              this.DeleteAction()
            }
            .width('100%')
            .padding({
              left: YibuqueSpacing.pageX,
              right: YibuqueSpacing.pageX,
              top: YibuqueSpacing.sm,
              bottom: YibuqueSpacing.section + this.windowBottomInsetVp
            })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(YibuqueColor.bgBase)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(YibuqueColor.bgBase)

        if (this.showPhotoPreview) {
          this.PhotoPreviewOverlay()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(YibuqueColor.bgBase)
    }
  }
}
