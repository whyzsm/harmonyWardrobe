import { YibuqueColor, YibuqueRadius, YibuqueShadow } from '../theme/Tokens';

@Component
export struct BottomNavigationBar {
  @Prop selected: string = 'wardrobe';
  @State private captureButtonScale: number = 1.0;
  @State private pressedTab: string = '';
  onSelectWardrobe: () => void = () => {};
  onOpenCapture: () => void = () => {};
  onSelectStore: () => void = () => {};
  onSelectOutfit: () => void = () => {};
  onOpenProfile: () => void = () => {};

  build() {
    Row() {
      this.NavItem('wardrobe', '衣柜')
      this.NavItem('store', '逛店')

      Stack({ alignContent: Alignment.Center }) {
        this.CameraIcon()
      }
      .layoutWeight(1)
      .height(52)
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

      this.NavItem('outfit', '套装')
      this.NavItem('profile', '我的')
    }
    .width('90%')
    .height(56)
    .padding({ left: 12, right: 12, top: 2, bottom: 2 })
    .backgroundColor('#E62D2C2C') // 保留: 深色半透明导航底(ARGB)无匹配 token
    .borderRadius(YibuqueRadius.sheet)
    .shadow(YibuqueShadow.soft) // 近似: 原 radius16/offsetY6/#32 → soft radius16/offsetY5/#18
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 0 })
  }

  @Builder
  CameraIcon() {
    Stack({ alignContent: Alignment.Center }) {
      SymbolGlyph($r('sys.symbol.camera_fill'))
        .fontSize(20)
        .fontColor([YibuqueColor.textInverse])
    }
    .width(40)
    .height(40)
    .linearGradient({
      angle: 135,
      colors: [['#4578FF', 0], ['#56D0FF', 1]] // P0-6: 去橙色, 蓝→青蓝渐变(保留蓝色入口设计)
    })
    .borderRadius(YibuqueRadius.full)
    .shadow({ radius: 18, color: '#26000000', offsetX: 0, offsetY: 0 }) // 保留: offsetY=0 光晕效果, floating(offsetY8)会变投影改变视觉
  }

  @Builder
  NavIcon(value: string) {
    if (value === 'wardrobe') {
      SymbolGlyph($r('sys.symbol.shirt'))
        .fontSize(20)
        .fontColor([this.selected === value ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    } else if (value === 'store') {
      SymbolGlyph($r('sys.symbol.store_fill'))
        .fontSize(20)
        .fontColor([this.selected === value ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    } else if (value === 'outfit') {
      SymbolGlyph($r('sys.symbol.hanger_and_towels'))
        .fontSize(20)
        .fontColor([this.selected === value ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    } else {
      SymbolGlyph($r('sys.symbol.person'))
        .fontSize(20)
        .fontColor([this.selected === value ? YibuqueColor.textInverse : YibuqueColor.textTertiary])
    }
  }

  @Builder
  NavItem(value: string, label: string) {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        this.NavIcon(value)
      }
      .width(32)
      .height(22)

      Text(label)
        .fontSize(11)
        .lineHeight(15)
        .fontWeight(this.selected === value ? FontWeight.Regular : FontWeight.Regular)
        .fontColor(this.selected === value ? YibuqueColor.textInverse : YibuqueColor.textTertiary)
    }
    .layoutWeight(1)
    .height(52)
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
      } else if (value === 'store') {
        this.onSelectStore();
      } else if (value === 'outfit') {
        this.onSelectOutfit();
      } else {
        this.onOpenProfile();
      }
    })
  }
}
