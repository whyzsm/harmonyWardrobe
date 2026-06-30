import { AppTheme } from '../theme/Tokens';

@Component
export struct CategoryTabs {
  @Prop categories: string[] = [];
  @Prop selected: string = '';
  onSelect: (category: string) => void = () => {};

  build() {
    Scroll() {
      Row({ space: AppTheme.spacing.sm }) {
        ForEach(this.categories, (category: string) => {
          Text(category)
            .fontSize(14)
            .fontColor(category === this.selected ? AppTheme.color.surface : AppTheme.color.textMuted)
            .padding({ left: AppTheme.spacing.md, right: AppTheme.spacing.md, top: AppTheme.spacing.sm, bottom: AppTheme.spacing.sm })
            .backgroundColor(category === this.selected ? AppTheme.color.primary : AppTheme.color.surface)
            .borderRadius(AppTheme.radius.lg)
            .border({ width: 1, color: category === this.selected ? AppTheme.color.primary : AppTheme.color.border })
            .onClick(() => {
              this.onSelect(category);
            })
        }, (category: string) => category)
      }
      .padding({ right: AppTheme.spacing.xl })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}
