import { YibuqueColor, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct SecondaryPageHeader {
  @Prop title: string = '';
  @Prop showEditAction: boolean = false;
  @Prop backAccessibilityText: string = '返回';
  onBack: () => void = () => {};
  onEdit: () => void = () => {};

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(24)
          .fontColor([YibuqueColor.textPrimary])
      }
      .width(48)
      .height(48)
      .accessibilityText(this.backAccessibilityText)
      .onClick(() => {
        this.onBack();
      })

      Text(this.title)
        .layoutWeight(1)
        .fontSize(20)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.showEditAction) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(23)
            .fontColor([YibuqueColor.textPrimary])
        }
        .width(48)
        .height(48)
        .accessibilityText('编辑')
        .onClick(() => {
          this.onEdit();
        })
      } else {
        Blank()
          .width(48)
          .height(48)
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX })
    .backgroundColor(YibuqueColor.glassStrong)
    .border({ width: { bottom: 1 }, color: YibuqueColor.borderLight })
    .alignItems(VerticalAlign.Center)
  }
}
