import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';

@Component
export struct WishlistCard {
  @Prop title: string = '';
  @Prop storeName: string = '';
  @Prop priceText: string = '';
  @Prop photoUri: string = '';

  build() {
    Row({ space: 12 }) {
      if (this.photoUri.length > 0) {
        Image(this.photoUri)
          .width(72)
          .height(72)
          .objectFit(ImageFit.Cover)
          .borderRadius(YibuqueRadius.md)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.heart_fill'))
            .fontSize(26)
            .fontColor([YibuqueColor.actionBlack])
        }
        .width(72)
        .height(72)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(YibuqueRadius.md)
        .backgroundColor(YibuqueColor.cardSurface)
      }

      Column({ space: 6 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.storeName.length > 0 ? this.storeName : '未记录门店')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.priceText.length > 0 ? this.priceText : '未记录价格')
          .fontSize(13)
          .fontColor(this.priceText.length > 0 ? YibuqueColor.success : YibuqueColor.textDisabled)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .borderRadius(YibuqueRadius.md)
    .backgroundColor(YibuqueColor.cardSoftGray)
    .border({ width: 1, color: YibuqueColor.borderMedium })
  }
}
