import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';

const SHEET_BACKGROUND: string = '#FFFFFF';
const SHEET_TEXT: string = '#1D1D1F';
const SHEET_MUTED: string = '#6E6E73';
const SHEET_BORDER: string = '#D2D2D7';
const SHEET_SURFACE: string = '#FBFBFD';
const SHEET_PRIMARY: string = '#1C1C1E';
const SHEET_PRIMARY_ICON: string = '#3A3A3C';
const SHEET_ACCENT: string = '#1D1D1F';
const SHEET_ACCENT_SOFT: string = '#F2F2F7';

@Component
export struct QuickCaptureSheet {
  onOpenWardrobe: () => void = () => {};
  onOpenStoreVisit: () => void = () => {};
  onOpenOutfit: () => void = () => {};
  onCancel: () => void = () => {};
  @State private sheetTranslateY: number = 300;
  @State private backgroundOpacity: number = 0;
  @State private pressedAction: string = '';

  aboutToAppear(): void {
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

      Column({ space: 14 }) {
        Row() {
          Text('快捷录入')
            .fontSize(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(SHEET_TEXT)
            .layoutWeight(1)

          Text('取消')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Regular)
            .fontColor(SHEET_ACCENT)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.onCancel();
            })
        }
        .width('100%')
        .height(44)
        .alignItems(VerticalAlign.Center)

        this.ActionCard('衣柜', '查看和整理我的衣物', 'wardrobe', () => {
          this.onOpenWardrobe();
        })

        this.ActionCard('逛店', '查看店铺和试穿记录', 'store', () => {
          this.onOpenStoreVisit();
        })

        this.ActionCard('套装', '查看和创建穿搭组合', 'outfit', () => {
          this.onOpenOutfit();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 22, bottom: 24 })
      .backgroundColor(SHEET_BACKGROUND)
      .borderRadius({ topLeft: 28, topRight: 28, bottomLeft: 28, bottomRight: 28 })
      .shadow({ radius: 24, color: '#26000000', offsetX: 0, offsetY: 8 })
      .margin({ bottom: 16 })
      .translate({ y: this.sheetTranslateY })
      .animation({
        duration: 300,
        curve: Curve.FastOutSlowIn,
        playMode: PlayMode.Normal
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#521D1D1F')
    .opacity(this.backgroundOpacity)
    .animation({
      duration: 220,
      curve: Curve.Linear,
      playMode: PlayMode.Normal
    })
  }

  @Builder
  ActionCard(title: string, description: string, variant: string, action: () => void) {
    if (variant === 'wardrobe') {
      this.ActionCardContent(title, description, variant, true, action)
    } else {
      this.ActionCardContent(title, description, variant, false, action)
    }
  }

  @Builder
  ActionIcon(variant: string) {
    if (variant === 'wardrobe') {
      SymbolGlyph($r('sys.symbol.shirt'))
        .fontSize(20)
        .fontColor([YibuqueColor.textInverse])
    } else if (variant === 'store') {
      SymbolGlyph($r('sys.symbol.store_fill'))
        .fontSize(20)
        .fontColor([SHEET_ACCENT])
    } else {
      SymbolGlyph($r('sys.symbol.hanger_and_towels'))
        .fontSize(20)
        .fontColor([SHEET_ACCENT])
    }
  }

  @Builder
  ActionCardContent(title: string, description: string, variant: string, primary: boolean, action: () => void) {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        this.ActionIcon(variant)
      }
      .width(38)
      .height(38)
      .backgroundColor(primary ? SHEET_PRIMARY_ICON : SHEET_ACCENT_SOFT)
      .borderRadius(YibuqueRadius.full)

      Column({ space: 2 }) {
        Text(title)
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(primary ? YibuqueColor.textInverse : SHEET_TEXT)

        Text(description)
          .width('100%')
          .fontSize(13)
          .fontColor(primary ? '#B8B8BD' : SHEET_MUTED)
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
    .backgroundColor(primary ? SHEET_PRIMARY : SHEET_SURFACE)
    .borderRadius(18)
    .border({ width: primary ? 0 : 1, color: SHEET_BORDER })
    .scale({ x: this.pressedAction === title ? 0.98 : 1.0, y: this.pressedAction === title ? 0.98 : 1.0 })
    .animation({
      duration: 150,
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
