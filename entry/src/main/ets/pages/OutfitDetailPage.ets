import { PhotoCarousel } from '../components/PhotoCarousel';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct OutfitDetailPage {
  @Prop outfit?: OutfitTemplate = undefined;
  @Prop clothingItems: ClothingItem[] = [];
  onBack: () => void = () => {};
  onEdit: (outfit: OutfitTemplate) => void = () => {};

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
    const clothingPhotoUris = this.selectedClothingPhotoUris();
    return clothingPhotoUris.length > 0 ? clothingPhotoUris : this.photoUris();
  }

  private noteText(): string {
    const note = this.outfit?.note?.trim() ?? '';
    return note.length > 0 ? note : '暂未填写备注';
  }

  private photoCountText(): string {
    const count = this.detailPhotoUris().length;
    return count > 0 ? `${count} 张照片` : '暂无照片';
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
    if (this.detailPhotoUris().length > 0) {
      PhotoCarousel({
        photoUris: this.detailPhotoUris(),
        cornerRadius: YibuqueRadius.xxxl
      })
        .width('100%')
        .height(280)
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
      .height(280)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(YibuqueColor.cardMuted)
      .borderRadius(YibuqueRadius.xxxl)
    }
  }

  @Builder
  SummaryCard() {
    Column({ space: YibuqueSpacing.md }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.outfit?.title ?? '穿搭详情')
            .fontSize(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.photoCountText())
            .fontSize(13)
            .fontColor(YibuqueColor.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(`${this.outfit?.clothingItemIds.length ?? 0} 件单品`)
          .height(34)
          .padding({ left: 14, right: 14 })
          .fontSize(14)
          .fontColor(YibuqueColor.actionBlack)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: YibuqueColor.actionBlack })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.noteText())
        .width('100%')
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

  build() {
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
          }
          .width('100%')
          .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.sm, bottom: YibuqueSpacing.section })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBase)
  }
}
