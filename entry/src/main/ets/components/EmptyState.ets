import { AppTheme } from '../theme/Tokens';

@Component
export struct EmptyState {
  @Prop title: string = '';
  @Prop description: string = '';

  build() {
    Column({ space: 8 }) {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.color.text)
        .textAlign(TextAlign.Center)

      Text(this.description)
        .fontSize(14)
        .fontColor(AppTheme.color.textMuted)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(AppTheme.spacing.xl)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(AppTheme.radius.lg)
    .backgroundColor(AppTheme.color.surfaceRaised)
    .border({ width: 1, color: AppTheme.color.border })
  }
}
