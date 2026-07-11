import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';

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
    .backgroundColor('#E62D2C2C')
    .borderRadius(28)
    .shadow({ radius: 16, color: '#32000000', offsetX: 0, offsetY: 6 })
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 0 })
  }

  @Builder
  CameraIcon() {
    Column({ space: 1 }) {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.camera_fill'))
          .fontSize(19)
          .fontColor([YibuqueColor.textInverse])
      }
      .width(36)
      .height(36)
      .linearGradient({
        angle: 135,
        colors: [['#F37A59', 0], ['#4578FF', 0.55], ['#56D0FF', 1]]
      })
      .borderRadius(YibuqueRadius.full)
      .shadow({ radius: 18, color: '#735A7CFF', offsetX: 0, offsetY: 0 })

      Text('拍照')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textInverse)
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  NavIcon(value: string) {
    if (value === 'wardrobe') {
      SymbolGlyph($r('sys.symbol.shirt'))
        .fontSize(21)
        .fontColor([this.selected === value ? YibuqueColor.textInverse : '#8D8D92'])
    } else if (value === 'store') {
      SymbolGlyph($r('sys.symbol.store_fill'))
        .fontSize(21)
        .fontColor([this.selected === value ? YibuqueColor.textInverse : '#8D8D92'])
    } else if (value === 'outfit') {
      SymbolGlyph($r('sys.symbol.hanger_and_towels'))
        .fontSize(21)
        .fontColor([this.selected === value ? YibuqueColor.textInverse : '#8D8D92'])
    } else {
      SymbolGlyph($r('sys.symbol.person'))
        .fontSize(21)
        .fontColor([this.selected === value ? YibuqueColor.textInverse : '#8D8D92'])
    }
  }

  @Builder
  NavItem(value: string, label: string) {
    Column({ space: 2 }) {
      Stack({ alignContent: Alignment.Center }) {
        this.NavIcon(value)
      }
      .width(32)
      .height(23)

      Text(label)
        .fontSize(11)
        .fontWeight(this.selected === value ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selected === value ? YibuqueColor.textInverse : '#8D8D92')
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
