import { YibuqueColor, YibuqueFontSize, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct AppTopBar {
  onOpenProfile: () => void = () => {};

  build() {
    Row() {
      Row({ space: YibuqueSpacing.sm }) {
        Stack({ alignContent: Alignment.Center }) {
          Text('衣')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textInverse)
        }
        .width(32)
        .height(32)
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.full)

        Text('衣不缺')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      Row({ space: YibuqueSpacing.xs }) {
        Text('我')
          .width(28)
          .height(28)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)

        Text('我的')
          .height(44)
          .fontSize(YibuqueFontSize.meta)
          .fontWeight(FontWeight.Medium)
          .fontColor(YibuqueColor.textPrimary)
      }
      .height(48)
      .padding({ left: YibuqueSpacing.sm, right: YibuqueSpacing.sm })
      .borderRadius(YibuqueRadius.full)
      .onClick(() => {
        this.onOpenProfile();
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX })
    .backgroundColor(YibuqueColor.bgDefault)
    .alignItems(VerticalAlign.Center)
  }
}
