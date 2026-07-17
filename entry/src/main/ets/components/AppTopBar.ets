import { YibuqueColor, YibuqueFontSize, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct AppTopBar {
  @State private profilePressed: boolean = false;
  onOpenProfile: () => void = () => {};

  build() {
    Row() {
      Row({ space: YibuqueSpacing.sm }) {
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(30)
            .height(30)
            .backgroundColor(YibuqueColor.cardSurface)
            .borderRadius(YibuqueRadius.md)

          SymbolGlyph($r('sys.symbol.shirt'))
            .fontSize(20)
            .fontColor([YibuqueColor.actionBlack])
        }
        .width(36)
        .height(36)
        .backgroundColor(YibuqueColor.transparent)
        .borderRadius(YibuqueRadius.lg)
        .shadow(YibuqueShadow.appTopBar)

        Text('衣不缺')
          .fontSize(20)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      Row({ space: YibuqueSpacing.xs }) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(17)
            .fontColor([YibuqueColor.textInverse])
        }
        .width(30)
        .height(30)
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.full)

        Text('我的')
          .height(44)
          .fontSize(YibuqueFontSize.meta)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
      }
      .height(48)
      .padding({ left: YibuqueSpacing.sm, right: YibuqueSpacing.md })
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius(YibuqueRadius.full)
      .border({ width: 1, color: YibuqueColor.borderLight })
      .scale({ x: this.profilePressed ? 0.96 : 1.0, y: this.profilePressed ? 0.96 : 1.0 })
      .animation({
        duration: 160,
        curve: Curve.EaseInOut,
        playMode: PlayMode.Normal
      })
      .onTouch((event: TouchEvent) => {
        this.profilePressed = event.type === TouchType.Down;
      })
      .onClick(() => {
        this.profilePressed = false;
        this.onOpenProfile();
      })
    }
    .width('100%')
    .height(60)
    .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX })
    .backgroundColor(YibuqueColor.cardWhite)
    .border({ width: { bottom: 1 }, color: YibuqueColor.borderLight })
    .alignItems(VerticalAlign.Center)
  }
}
