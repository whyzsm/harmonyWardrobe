import { YibuqueColor, YibuqueRadius, YibuqueShadow } from '../theme/Tokens';

@Component
export struct QuickCaptureSheet {
  onTakePhoto: () => void = () => {};
  onPickGallery: () => void = () => {};
  onCancel: () => void = () => {};
  @State private sheetTranslateY: number = 300;
  @State private backgroundOpacity: number = 0;
  @State private pressedAction: string = '';
  @State private isClosing: boolean = false;

  aboutToAppear(): void {
    animateTo({
      duration: 240,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.backgroundOpacity = 1;
      this.sheetTranslateY = 0;
    });
  }

  private closeSheet(): void {
    if (this.isClosing) {
      return;
    }

    this.isClosing = true;
    animateTo({
      duration: 180,
      curve: Curve.FastOutSlowIn,
      onFinish: () => {
        this.onCancel();
      }
    }, () => {
      this.backgroundOpacity = 0;
      this.sheetTranslateY = 300;
    });
  }

  build() {
    Column() {
      Blank()
        .layoutWeight(1)
        .onClick(() => {
          this.closeSheet();
        })

      Column({ space: 14 }) {
        Row() {
          Text('快捷录入')
            .fontSize(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .layoutWeight(1)

          Text('取消')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.actionBlack)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.closeSheet();
            })
        }
        .width('100%')
        .height(44)
        .alignItems(VerticalAlign.Center)

        this.ActionCard('拍一张', '打开相机，拍完进入分类保存', 'camera', true, () => {
          this.onTakePhoto();
        })

        this.ActionCard('从相册选择', '批量选择已有照片再归类', 'gallery', false, () => {
          this.onPickGallery();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 22, bottom: 24 })
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius({ topLeft: YibuqueRadius.sheet, topRight: YibuqueRadius.sheet, bottomLeft: YibuqueRadius.sheet, bottomRight: YibuqueRadius.sheet })
      .shadow(YibuqueShadow.floating)
      .margin({ bottom: 16 })
      .translate({ y: this.sheetTranslateY })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.overlayDark)
    .opacity(this.backgroundOpacity)
  }

  @Builder
  ActionIcon(variant: string, primary: boolean) {
    if (variant === 'camera') {
      SymbolGlyph($r('sys.symbol.camera_fill'))
        .fontSize(22)
        .fontColor([primary ? YibuqueColor.textInverse : YibuqueColor.textPrimary])
    } else {
      SymbolGlyph($r('sys.symbol.picture'))
        .fontSize(22)
        .fontColor([primary ? YibuqueColor.textInverse : YibuqueColor.textPrimary])
    }
  }

  @Builder
  ActionCard(title: string, description: string, variant: string, primary: boolean, action: () => void) {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        this.ActionIcon(variant, primary)
      }
      .width(44)
      .height(44)
      .backgroundColor(primary ? YibuqueColor.actionBlack : YibuqueColor.cardBlue)
      .borderRadius(YibuqueRadius.full)

      Column({ space: 3 }) {
        Text(title)
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(primary ? YibuqueColor.textInverse : YibuqueColor.textPrimary)

        Text(description)
          .width('100%')
          .fontSize(13)
          .fontColor(primary ? YibuqueColor.textDisabled : YibuqueColor.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(82)
    .padding({ left: 15, right: 15 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(primary ? YibuqueColor.actionBlack : YibuqueColor.cardSoftGray)
    .borderRadius(YibuqueRadius.xxl)
    .border({ width: primary ? 0 : 1, color: YibuqueColor.borderLight })
    .scale({ x: this.pressedAction === title ? 0.98 : 1.0, y: this.pressedAction === title ? 0.98 : 1.0 })
    .animation({
      duration: 150,
      curve: Curve.EaseInOut,
      playMode: PlayMode.Normal
    })
    .accessibilityText(title)
    .onTouch((event: TouchEvent) => {
      this.pressedAction = event.type === TouchType.Down ? title : '';
    })
    .onClick(() => {
      this.pressedAction = '';
      action();
    })
  }
}
