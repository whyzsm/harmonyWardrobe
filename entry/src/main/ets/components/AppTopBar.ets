import { YibuqueColor, YibuqueFontSize, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

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
            .linearGradient({
              angle: 135,
              colors: [[YibuqueColor.cardMint, 0], [YibuqueColor.cardBlue, 1]]
            })
            .borderRadius(12)

          Text('衣')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.actionBlack)

          Circle({ width: 14, height: 14 })
            .fill('#66FFFFFF')
            .stroke('#F7A0BC')
            .strokeWidth(2)
            .margin({ left: -19, top: -18 })
        }
        .width(36)
        .height(36)
        .backgroundColor('#00FFFFFF')
        .borderRadius(YibuqueRadius.lg)
        .shadow({ radius: 14, color: '#24B11B68', offsetX: 0, offsetY: 6 })

        Text('衣不缺')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      Row({ space: YibuqueSpacing.xs }) {
        Stack({ alignContent: Alignment.Center }) {
          Text('我')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textInverse)
            .textAlign(TextAlign.Center)
        }
        .width(30)
        .height(30)
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.full)

        Text('我的')
          .height(44)
          .fontSize(YibuqueFontSize.meta)
          .fontWeight(FontWeight.Medium)
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
    .linearGradient({
      angle: 135,
      colors: [[YibuqueColor.bgDefault, 0], [YibuqueColor.bgHeaderBlue, 1]]
    })
    .alignItems(VerticalAlign.Center)
  }
}
