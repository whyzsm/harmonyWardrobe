import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct QuickCaptureSheet {
  onOpenWardrobe: () => void = () => {};
  onOpenStoreVisit: () => void = () => {};
  onOpenOutfit: () => void = () => {};
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
            .fontColor(YibuqueColor.iconAccent)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.closeSheet();
            })
        }
        .width('100%')
        .height(44)
        .alignItems(VerticalAlign.Center)

        this.ActionCard('衣柜', '新增衣物', 'wardrobe', true, () => {
          this.onOpenWardrobe();
        })

        this.ActionCard('逛店', '新增逛店记录', 'store', false, () => {
          this.onOpenStoreVisit();
        })

        this.ActionCard('穿搭', '新增穿搭', 'outfit', false, () => {
          this.onOpenOutfit();
        })
      }
      .width('100%')
      .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: 22, bottom: 24 })
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius({ topLeft: YibuqueRadius.sheet, topRight: YibuqueRadius.sheet, bottomLeft: 0, bottomRight: 0 })
      .shadow(YibuqueShadow.editorSheet)
      .translate({ y: this.sheetTranslateY })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.scrimMedium)
    .opacity(this.backgroundOpacity)
  }

  @Builder
  ActionIcon(variant: string, primary: boolean) {
    if (variant === 'wardrobe') {
      SymbolGlyph($r('sys.symbol.shirt'))
        .fontSize(22)
        .fontColor([primary ? YibuqueColor.textInverse : YibuqueColor.iconAccent])
    } else if (variant === 'store') {
      SymbolGlyph($r('sys.symbol.store_fill'))
        .fontSize(22)
        .fontColor([primary ? YibuqueColor.textInverse : YibuqueColor.iconAccent])
    } else {
      SymbolGlyph($r('sys.symbol.hanger_and_towels'))
        .fontSize(22)
        .fontColor([primary ? YibuqueColor.textInverse : YibuqueColor.iconAccent])
    }
  }

  @Builder
  ActionCard(title: string, description: string, variant: string, primary: boolean, action: () => void) {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        this.ActionIcon(variant, primary)
      }
      .width(38)
      .height(38)
      .backgroundColor(primary ? YibuqueColor.iconDarkSurface : YibuqueColor.iconAccentSurface)
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
    .height(78)
    .padding({ left: 15, right: 15 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(primary ? YibuqueColor.actionBlack : YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .border({ width: primary ? 0 : 1, color: YibuqueColor.borderMedium })
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
