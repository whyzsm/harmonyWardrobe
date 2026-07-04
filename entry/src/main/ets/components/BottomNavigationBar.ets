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
    .border({ width: { top: 1 }, color: YibuqueColor.borderLight })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CameraIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(30)
        .height(22)
        .backgroundColor(YibuqueColor.textInverse)
        .borderRadius(8)

      Row()
        .width(12)
        .height(5)
        .backgroundColor(YibuqueColor.textInverse)
        .borderRadius(3)
        .margin({ bottom: 24 })

      Circle({ width: 10, height: 10 })
        .fill(YibuqueColor.actionBlack)
    }
    .width(56)
    .height(44)
    .backgroundColor(YibuqueColor.actionBlack)
    .borderRadius(YibuqueRadius.full)
  }

  @Builder
  NavItem(value: string, label: string) {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(this.selected === value ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selected === value ? YibuqueColor.textPrimary : YibuqueColor.textTertiary)

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
