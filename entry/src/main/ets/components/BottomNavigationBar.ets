import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct BottomNavigationBar {
  @Prop selected: string = 'wardrobe';
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
      .onClick(() => {
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
    Column() {
      Text(label)
        .fontSize(15)
        .fontWeight(this.selected === value ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selected === value ? YibuqueColor.textPrimary : YibuqueColor.textTertiary)
    }
    .layoutWeight(1)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (value === 'wardrobe') {
        this.onSelectWardrobe();
      } else {
        this.onSelectStore();
      }
    })
  }
}
