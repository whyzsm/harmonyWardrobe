import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct BottomNavigationBar {
  @Prop selected: string = 'wardrobe';
  @State private addButtonScale: number = 1.0;
  @State private pressedTab: string = '';
  onSelectWardrobe: () => void = () => {};
  onOpenQuickActions: () => void = () => {};
  onSelectStore: () => void = () => {};

  build() {
    Row() {
      this.NavItem('wardrobe', '衣橱')

      Stack({ alignContent: Alignment.Center }) {
        Text('+')
          .width(56)
          .height(44)
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textInverse)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.actionBlack)
          .borderRadius(YibuqueRadius.full)
      }
      .layoutWeight(1)
      .height(64)
      .scale({ x: this.addButtonScale, y: this.addButtonScale })
      .animation({
        duration: 200,
        curve: Curve.EaseInOut,
        playMode: PlayMode.Normal
      })
      .onTouch((event: TouchEvent) => {
        this.addButtonScale = event.type === TouchType.Down ? 0.9 : 1.0;
      })
      .onClick(() => {
        this.addButtonScale = 1.0;
        this.onOpenQuickActions();
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
