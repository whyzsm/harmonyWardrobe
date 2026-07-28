import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitDisplaySource, OutfitTemplate } from '../domain/outfit/OutfitModels';
import {
  YibuqueColor,
  YibuqueMotion,
  YibuqueRadius,
  YibuqueShadow,
  YibuqueSpacing,
  YibuqueTransition
} from '../theme/Tokens';
import { userFacingError } from '../utils/userFacingError';

@Component
export struct OutfitDetailPage {
  @StorageProp('windowBottomInsetVp') private windowBottomInsetVp: number = YibuqueSpacing.bottomSafe;
  @Prop outfit?: OutfitTemplate = undefined;
  @Prop clothingItems: ClothingItem[] = [];
  onBack: () => void = () => {};
  onEdit: (outfit: OutfitTemplate) => void = () => {};
  onDelete: (outfit: OutfitTemplate) => Promise<void> = async (_outfit: OutfitTemplate): Promise<void> => {};
  @State private showPhotoPreview: boolean = false;
  @State private showDeleteConfirm: boolean = false;
  @State private isDeleting: boolean = false;
  @State private deleteErrorMessage: string = '';
  @State private selectedPhotoIndex: number = 0;
  private photoPreviewTransitionInProgress: boolean = false;

  private photoUris(): string[] {
    return this.outfit?.photoUris ?? [];
  }

  private selectedClothingItems(): ClothingItem[] {
    const ids = this.outfit?.clothingItemIds ?? [];
    const selected: ClothingItem[] = [];
    for (const item of this.clothingItems) {
      if (ids.includes(item.id)) {
        selected.push(item);
      }
    }
    return selected;
  }

  private selectedClothingPhotoUris(): string[] {
    const photoUris: string[] = [];
    for (const item of this.selectedClothingItems()) {
      if (item.photoUris.length > 0 && item.photoUris[0].trim().length > 0) {
        photoUris.push(item.photoUris[0]);
      }
    }
    return photoUris;
  }

  private detailPhotoUris(): string[] {
    const uploadedPhotoUris = this.photoUris();
    const clothingPhotoUris = this.selectedClothingPhotoUris();
    if (this.outfit?.displaySource === OutfitDisplaySource.Wardrobe) {
      return clothingPhotoUris.length > 0 ? clothingPhotoUris : uploadedPhotoUris;
    }

    return uploadedPhotoUris.length > 0 ? uploadedPhotoUris : clothingPhotoUris;
  }

  private photoCount(): number {
    return this.detailPhotoUris().length;
  }

  private normalizePhotoIndex(index: number): number {
    const count = this.photoCount();
    if (count === 0 || index < 0) {
      return 0;
    }
    if (index >= count) {
      return count - 1;
    }

    return index;
  }

  private photoUriAt(index: number): string {
    const photos = this.detailPhotoUris();
    if (photos.length === 0) {
      return '';
    }

    return photos[this.normalizePhotoIndex(index)];
  }

  private currentPhotoIndex(): number {
    return this.normalizePhotoIndex(this.selectedPhotoIndex);
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

  private noteText(): string {
    return this.outfit?.note?.trim() ?? '';
  }

  private hasNoteText(): boolean {
    return this.noteText().length > 0;
  }

  private confirmDelete(): void {
    const outfit = this.outfit;
    if (outfit === undefined || this.isDeleting) {
      return;
    }

    this.showDeleteConfirm = true;
    AlertDialog.show({
      title: '删除穿搭',
      message: '确定要删除这套穿搭吗？照片也会一并移除。',
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
          this.deleteCurrentOutfit();
        }
      },
      cancel: () => {
        this.showDeleteConfirm = false;
      }
    });
  }

  private async deleteCurrentOutfit(): Promise<void> {
    const outfit = this.outfit;
    if (outfit === undefined || this.isDeleting) {
      return;
    }

    this.isDeleting = true;
    this.deleteErrorMessage = '';
    try {
      await this.onDelete(outfit);
      this.showDeleteConfirm = false;
    } catch (error) {
      this.deleteErrorMessage = userFacingError(error, '删除穿搭失败');
    } finally {
      this.isDeleting = false;
    }
  }

  private displayOutfitTitle(): string {
    const title = this.outfit?.title?.trim() ?? '';
    if (title.length === 0) {
      return '穿搭详情';
    }

    const autoTitlePattern = /^(穿搭|美搭) \d{2}-\d{2} \d{2}:\d{2}$/;
    const match = autoTitlePattern.exec(title);
    return match === null ? title : match[1];
  }

  private photoCountText(): string {
    const count = this.detailPhotoUris().length;
    return count > 0 ? `${count} 张照片` : '暂无照片';
  }

  private categoryText(): string {
    const categoryNames = this.outfit?.categoryNames ?? [];
    return categoryNames.length > 0 ? categoryNames.join('、') : '未分类';
  }

  @Builder
  DetailTopBar() {
    SecondaryPageHeader({
      title: '穿搭详情',
      showEditAction: this.outfit !== undefined,
      backAccessibilityText: '返回穿搭',
      onBack: () => {
        this.onBack();
      },
      onEdit: () => {
        const outfit = this.outfit;
        if (outfit !== undefined) {
          this.onEdit(outfit);
        }
      }
    })
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
            ForEach(this.detailPhotoUris(), (photoUri: string, index: number) => {
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
          SymbolGlyph($r('sys.symbol.hanger_and_towels'))
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
        ForEach(this.detailPhotoUris(), (photoUri: string, index: number) => {
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
          Text(this.displayOutfitTitle())
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
          Text(this.displayOutfitTitle())
            .fontSize(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .lineHeight(28)

          Text(`${this.categoryText()} · ${this.photoCountText()}`)
            .fontSize(13)
            .fontColor(YibuqueColor.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(`${this.outfit?.clothingItemIds.length ?? 0} 件单品`)
          .height(34)
          .padding({ left: 14, right: 14 })
          .fontSize(14)
          .fontColor(YibuqueColor.iconAccent)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.iconAccentSurface)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: YibuqueColor.iconAccentSurface })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.hasNoteText()) {
        Text(this.noteText())
          .width('100%')
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
  ClothingItemsCard() {
    Column({ space: YibuqueSpacing.md }) {
      Text('搭配单品')
        .fontSize(18)
        .fontColor(YibuqueColor.textPrimary)

      if (this.selectedClothingItems().length === 0) {
        Text('暂未关联衣柜单品')
          .width('100%')
          .height(52)
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.lg)
      } else {
        Column({ space: YibuqueSpacing.sm }) {
          ForEach(this.selectedClothingItems(), (item: ClothingItem) => {
            Row({ space: YibuqueSpacing.sm }) {
              if (item.photoUris.length > 0) {
                Image(item.photoUris[0])
                  .width(48)
                  .height(48)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(YibuqueRadius.md)
              } else {
                Stack({ alignContent: Alignment.Center }) {
                  SymbolGlyph($r('sys.symbol.shirt'))
                    .fontSize(20)
                    .fontColor([YibuqueColor.textSecondary])
                }
                .width(48)
                .height(48)
                .backgroundColor(YibuqueColor.cardMuted)
                .borderRadius(YibuqueRadius.md)
              }

              Text(item.name)
                .layoutWeight(1)
                .fontSize(15)
                .fontColor(YibuqueColor.textPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .height(52)
            .alignItems(VerticalAlign.Center)
          }, (item: ClothingItem) => item.id)
        }
        .width('100%')
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
  DeleteAction() {
    Column({ space: YibuqueSpacing.sm }) {
      Button() {
        if (this.isDeleting) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color(YibuqueColor.textInverse)
        } else {
          Text('删除穿搭')
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
    Stack() {
      Column() {
        this.DetailTopBar()

        if (this.outfit === undefined) {
          Column({ space: YibuqueSpacing.lg }) {
            Text('穿搭不存在')
              .fontSize(24)
              .fontColor(YibuqueColor.textPrimary)

            Text('可能已经被删除，请返回穿搭重新选择。')
              .fontSize(14)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Scroll() {
            Column({ space: YibuqueSpacing.lg }) {
              this.HeroPhoto()
              this.SummaryCard()
              this.ClothingItemsCard()
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
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        }
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
