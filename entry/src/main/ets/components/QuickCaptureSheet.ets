import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct QuickCaptureSheet {
  onCaptureClothing: () => void = () => {};
  onCaptureOutfit: () => void = () => {};
  onCaptureStore: () => void = () => {};
  onCancel: () => void = () => {};

  build() {
    Column() {
      Blank()
        .layoutWeight(1)
        .onClick(() => {
          this.onCancel();
        })

      Column({ space: YibuqueSpacing.md }) {
        Row() {
          Text('快捷')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)
            .layoutWeight(1)

          Text('取消')
            .height(44)
            .fontSize(15)
            .fontColor(YibuqueColor.textSecondary)
            .onClick(() => {
              this.onCancel();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Button('拍衣服')
          .width('100%')
          .height(56)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textInverse)
          .backgroundColor(YibuqueColor.actionBlack)
          .borderRadius(YibuqueRadius.full)
          .onClick(() => {
            this.onCaptureClothing();
          })

        Button('拍搭配')
          .width('100%')
          .height(56)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .onClick(() => {
            this.onCaptureOutfit();
          })

        Button('拍店铺')
          .width('100%')
          .height(56)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.cardMint)
          .borderRadius(YibuqueRadius.full)
          .onClick(() => {
            this.onCaptureStore();
          })
      }
      .width('100%')
      .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.xl, bottom: 36 })
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius({ topLeft: YibuqueRadius.sheet, topRight: YibuqueRadius.sheet })
      .shadow(YibuqueShadow.floating)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.overlayDark)
  }
}
