import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct EmptyState {
  @Prop title: string = '';
  @Prop description: string = '';

  build() {
    Column({ space: YibuqueSpacing.sm }) {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)
        .textAlign(TextAlign.Center)

      Text(this.description)
        .fontSize(14)
        .fontColor(YibuqueColor.textSecondary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(YibuqueSpacing.xl)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(YibuqueRadius.xxl)
    .backgroundColor(YibuqueColor.cardWhite)
    .border({ width: 1, color: YibuqueColor.borderLight })
  }
}
