import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct ClothingCard {
  @Prop name: string = '';
  @Prop category: string = '';
  @Prop photoUri: string = '';
  @State private cardScale: number = 0.95;
  @State private cardOpacity: number = 0;
  onClick: () => void = () => {};

  aboutToAppear() {
    setTimeout(() => {
      this.cardOpacity = 1;
      this.cardScale = 1;
    }, 50);
  }

  build() {
    Column({ space: YibuqueSpacing.sm }) {
      if (this.photoUri.length > 0) {
        Image(this.photoUri)
          .width('100%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .borderRadius(YibuqueRadius.xl)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.shirt'))
            .fontSize(28)
            .fontColor([YibuqueColor.textPrimary])
        }
        .width('100%')
        .aspectRatio(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(YibuqueRadius.xl)
        .backgroundColor(YibuqueColor.cardMint)
      }

      Text(this.name)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(YibuqueColor.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.category)
        .fontSize(12)
        .fontColor(YibuqueColor.textSecondary)
        .padding({ left: YibuqueSpacing.sm, right: YibuqueSpacing.sm, top: 3, bottom: 3 })
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.full)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(YibuqueSpacing.sm)
    .borderRadius(YibuqueRadius.xxl)
    .backgroundColor(YibuqueColor.cardWhite)
    .shadow(YibuqueShadow.card)
    .scale({ x: this.cardScale, y: this.cardScale })
    .opacity(this.cardOpacity)
    .animation({
      duration: 300,
      curve: Curve.Smooth,
      playMode: PlayMode.Normal
    })
    .onClick(() => {
      this.cardScale = 1;
      this.onClick();
    })
    .onTouch((event: TouchEvent) => {
      this.cardScale = event.type === TouchType.Down ? 0.97 : 1;
    })
  }
}
