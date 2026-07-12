import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct OutfitCard {
  @Prop title: string = '';
  @Prop itemCount: number = 0;
  @Prop photoUri: string = '';

  build() {
    Column({ space: YibuqueSpacing.sm }) {
      if (this.photoUri.length > 0) {
        Image(this.photoUri)
          .width('100%')
          .height(132)
          .objectFit(ImageFit.Cover)
          .borderRadius(5)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.hanger_and_towels'))
            .fontSize(34)
            .fontColor([YibuqueColor.textPrimary])
        }
        .width('100%')
        .height(132)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(5)
        .backgroundColor(YibuqueColor.cardBlue)
      }

      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`${this.itemCount} 件单品`)
        .fontSize(12)
        .fontColor(YibuqueColor.textSecondary)
        .padding({ left: YibuqueSpacing.sm, right: YibuqueSpacing.sm, top: 3, bottom: 3 })
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.full)
    }
    .width('100%')
    .padding(YibuqueSpacing.sm)
    .borderRadius(YibuqueRadius.xxl)
    .backgroundColor(YibuqueColor.cardWhite)
    .shadow(YibuqueShadow.card)
  }
}
