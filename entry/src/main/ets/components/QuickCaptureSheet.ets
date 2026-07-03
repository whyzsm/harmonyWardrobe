import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct QuickCaptureSheet {
  onCaptureClothing: () => void = () => {};
  onCaptureOutfit: () => void = () => {};
  onCaptureStore: () => void = () => {};
  onCancel: () => void = () => {};
  @State private sheetTranslateY: number = 300;
  @State private backgroundOpacity: number = 0;
  @State private pressedAction: string = '';

  aboutToAppear() {
    setTimeout(() => {
      this.backgroundOpacity = 1;
      this.sheetTranslateY = 0;
    }, 50);
  }

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

        this.ActionRow(
          '拍衣服',
          '选择图片并保存到衣裤分类',
          YibuqueColor.actionBlack,
          YibuqueColor.textInverse,
          '#CCFFFFFF',
          () => {
            this.onCaptureClothing();
          }
        )

        this.ActionRow(
          '拍搭配',
          '保存一组美搭照片和备注',
          YibuqueColor.cardSoftGray,
          YibuqueColor.textPrimary,
          YibuqueColor.textSecondary,
          () => {
            this.onCaptureOutfit();
          }
        )

        this.ActionRow(
          '拍店铺',
          '记录店铺、日期和试穿感受',
          YibuqueColor.cardMint,
          YibuqueColor.textPrimary,
          YibuqueColor.textSecondary,
          () => {
            this.onCaptureStore();
          }
        )
      }
      .width('100%')
      .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.xl, bottom: 36 })
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius({ topLeft: YibuqueRadius.sheet, topRight: YibuqueRadius.sheet })
      .shadow(YibuqueShadow.floating)
      .translate({ y: this.sheetTranslateY })
      .animation({
        duration: 350,
        curve: Curve.FastOutSlowIn,
        playMode: PlayMode.Normal
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.overlayDark)
    .opacity(this.backgroundOpacity)
    .animation({
      duration: 300,
      curve: Curve.Linear,
      playMode: PlayMode.Normal
    })
  }

  @Builder
  ActionRow(title: string, description: string, backgroundColor: string, titleColor: string, descriptionColor: string, action: () => void) {
    Row() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(titleColor)
          .width('100%')

        Text(description)
          .fontSize(13)
          .fontColor(descriptionColor)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(64)
    .padding({ left: YibuqueSpacing.lg, right: YibuqueSpacing.lg })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(backgroundColor)
    .borderRadius(YibuqueRadius.xxl)
    .scale({ x: this.pressedAction === title ? 0.98 : 1.0, y: this.pressedAction === title ? 0.98 : 1.0 })
    .animation({
      duration: 160,
      curve: Curve.EaseInOut,
      playMode: PlayMode.Normal
    })
    .onTouch((event: TouchEvent) => {
      this.pressedAction = event.type === TouchType.Down ? title : '';
    })
    .onClick(() => {
      this.pressedAction = '';
      action();
    })
  }
}
