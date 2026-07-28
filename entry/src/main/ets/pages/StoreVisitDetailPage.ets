import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import { StoreVisit } from '../domain/store/StoreModels';
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
export struct StoreVisitDetailPage {
  @StorageProp('windowBottomInsetVp') private windowBottomInsetVp: number = YibuqueSpacing.bottomSafe;
  @Prop visit?: StoreVisit = undefined;
  @Prop statusLabel: string = '已去';
  onBack: () => void = () => {};
  onEdit: (visit: StoreVisit) => void = () => {};
  onDelete: (visit: StoreVisit) => Promise<void> = async (_visit: StoreVisit): Promise<void> => {};
  @State private showPhotoPreview: boolean = false;
  @State private showDeleteConfirm: boolean = false;
  @State private isDeleting: boolean = false;
  @State private deleteErrorMessage: string = '';
  @State private selectedPhotoIndex: number = 0;
  private photoPreviewTransitionInProgress: boolean = false;

  private photoUris(): string[] {
    return this.visit?.photoUris ?? [];
  }

  private photoCount(): number {
    return this.photoUris().length;
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
    const photos = this.photoUris();
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

  private displayVisitTitle(): string {
    const title = this.visit?.storeNameSnapshot?.trim() ?? '';
    return title.length > 0 ? title : '逛店记录';
  }

  private locationText(): string {
    const location = this.visit?.districtOrAddress?.trim() ?? '';
    return location.length > 0 ? location : '未记录';
  }

  private tagsText(): string {
    const tags = this.visit?.focusTags ?? [];
    return tags.length > 0 ? tags.join(' · ') : '未记录';
  }

  private noteText(): string {
    return this.visit?.note?.trim() ?? '';
  }

  private hasNoteText(): boolean {
    return this.noteText().length > 0;
  }

  private confirmDelete(): void {
    const visit = this.visit;
    if (visit === undefined || this.isDeleting) {
      return;
    }

    this.showDeleteConfirm = true;
    AlertDialog.show({
      title: '删除逛店记录',
      message: '确定要删除这条逛店记录吗？照片也会一并移除。',
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
          this.deleteCurrentVisit();
        }
      },
      cancel: () => {
        this.showDeleteConfirm = false;
      }
    });
  }

  private async deleteCurrentVisit(): Promise<void> {
    const visit = this.visit;
    if (visit === undefined || this.isDeleting) {
      return;
    }

    this.isDeleting = true;
    this.deleteErrorMessage = '';
    try {
      await this.onDelete(visit);
      this.showDeleteConfirm = false;
    } catch (error) {
      this.deleteErrorMessage = userFacingError(error, '删除逛店记录失败');
    } finally {
      this.isDeleting = false;
    }
  }

  private photoCountText(): string {
    const count = this.photoUris().length;
    return count > 0 ? `${count} 张照片` : '暂无照片';
  }

  @Builder
  DetailTopBar() {
    SecondaryPageHeader({
      title: '逛店详情',
      showEditAction: this.visit !== undefined,
      backAccessibilityText: '返回逛店',
      onBack: () => {
        this.onBack();
      },
      onEdit: () => {
        const visit = this.visit;
        if (visit !== undefined) {
          this.onEdit(visit);
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
          SymbolGlyph($r('sys.symbol.store_fill'))
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
          Text(this.displayVisitTitle())
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
  DetailRow(label: string, value: string) {
    Row({ space: YibuqueSpacing.md }) {
      Text(label)
        .width(64)
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
  SummaryCard() {
    Column({ space: YibuqueSpacing.md }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.visit?.storeNameSnapshot ?? '逛店记录')
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

        Text(this.statusLabel)
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

      this.DetailRow('商圈', this.locationText())
      this.DetailRow('日期', this.visit?.visitDate ?? '未记录')
      this.DetailRow('标签', this.tagsText())

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
  DeleteAction() {
    Column({ space: YibuqueSpacing.sm }) {
      Button() {
        if (this.isDeleting) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color(YibuqueColor.textInverse)
        } else {
          Text('删除逛店记录')
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

        if (this.visit === undefined) {
          Column({ space: YibuqueSpacing.lg }) {
            Text('逛店记录不存在')
              .fontSize(24)
              .fontColor(YibuqueColor.textPrimary)

            Text('可能已经被删除，请返回逛店重新选择。')
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
