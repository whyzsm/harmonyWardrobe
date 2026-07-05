import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct CategoryTabs {
  @Prop categories: string[] = [];
  @Prop selected: string = '';
  onSelect: (category: string) => void = () => {};

  build() {
    Scroll() {
      Row({ space: YibuqueSpacing.sm }) {
        ForEach(this.categories, (category: string) => {
          Text(category)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(category === this.selected ? YibuqueColor.actionBlack : YibuqueColor.textTertiary)
            .padding({ left: YibuqueSpacing.md, right: YibuqueSpacing.md, top: YibuqueSpacing.sm, bottom: YibuqueSpacing.sm })
            .backgroundColor(YibuqueColor.cardWhite)
            .borderRadius(YibuqueRadius.full)
            .border({ width: category === this.selected ? 2 : 1, color: category === this.selected ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
            .onClick(() => {
              this.onSelect(category);
            })
        }, (category: string) => category)
      }
      .padding({ right: YibuqueSpacing.xl })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}
