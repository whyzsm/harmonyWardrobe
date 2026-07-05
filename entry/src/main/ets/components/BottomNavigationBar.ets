import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct BottomNavigationBar {
  @Prop selected: string = 'wardrobe';
  @State private captureButtonScale: number = 1.0;
  @State private pressedTab: string = '';
  onSelectWardrobe: () => void = () => {};
  onOpenCapture: () => void = () => {};
  onSelectStore: () => void = () => {};

  build() {
    Row() {
      this.NavItem('wardrobe', '衣橱')

      Stack({ alignContent: Alignment.Center }) {
        this.CameraIcon()
      }
      .layoutWeight(1)
      .height(64)
      .scale({ x: this.captureButtonScale, y: this.captureButtonScale })
      .animation({
        duration: 200,
        curve: Curve.EaseInOut,
        playMode: PlayMode.Normal
      })
      .onTouch((event: TouchEvent) => {
        this.captureButtonScale = event.type === TouchType.Down ? 0.9 : 1.0;
      })
      .onClick(() => {
        this.captureButtonScale = 1.0;
        this.onOpenCapture();
      })

      this.NavItem('store', '逛店')
    }
    .width('100%')
    .height(76 + YibuqueSpacing.bottomSafe)
    .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.sm, bottom: YibuqueSpacing.bottomSafe })
    .backgroundColor(YibuqueColor.cardWhite)
    .border({ width: { top: 1 }, color: '#66F2C7DA' })
    .shadow({ radius: 24, color: '#1AB11B68', offsetX: 0, offsetY: -6 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CameraIcon() {
    Stack({ alignContent: Alignment.Center }) {
      SymbolGlyph($r('sys.symbol.camera_fill'))
        .fontSize(29)
        .fontColor([YibuqueColor.textInverse])
    }
    .width(58)
    .height(46)
    .linearGradient({
      angle: 135,
      colors: [[YibuqueColor.actionBlack, 0], ['#D83E8E', 1]]
    })
    .borderRadius(YibuqueRadius.full)
    .shadow({ radius: 20, color: '#3AB11B68', offsetX: 0, offsetY: 8 })
  }

  @Builder
  NavItem(value: string, label: string) {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(this.selected === value ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selected === value ? YibuqueColor.actionBlack : YibuqueColor.textTertiary)

      Row()
        .width(this.selected === value ? 18 : 4)
        .height(4)
        .backgroundColor(this.selected === value ? YibuqueColor.actionBlack : '#00000000')
        .borderRadius(YibuqueRadius.full)
    }
    .layoutWeight(1)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .scale({ x: this.pressedTab === value ? 0.96 : 1.0, y: this.pressedTab === value ? 0.96 : 1.0 })
    .animation({
      duration: 160,
      curve: Curve.EaseInOut,
      playMode: PlayMode.Normal
    })
    .onTouch((event: TouchEvent) => {
      this.pressedTab = event.type === TouchType.Down ? value : '';
    })
    .onClick(() => {
      this.pressedTab = '';
      if (value === 'wardrobe') {
        this.onSelectWardrobe();
      } else {
        this.onSelectStore();
      }
    })
  }
}
