import { YibuqueColor, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct SavedFilterNotice {
  @Prop visible: boolean = false;
  onViewAll: () => void = () => {};

  build() {
    if (this.visible) {
      Row({ space: YibuqueSpacing.sm }) {
        Text('已保存，当前筛选未显示')
          .layoutWeight(1)
          .fontSize(12)
          .fontColor(YibuqueColor.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button('查看全部')
          .height(44)
          .padding({ left: YibuqueSpacing.sm, right: YibuqueSpacing.sm })
          .fontSize(13)
          .fontColor(YibuqueColor.selectionAccent)
          .backgroundColor(YibuqueColor.transparent)
          .accessibilityText('查看全部记录')
          .onClick(() => {
            this.onViewAll();
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
    }
  }
}
