import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct DeleteImageOverlay {
  @Prop label: string = '删除';
  @Prop deleting: boolean = false;
  @Prop cornerRadius: number = YibuqueRadius.xxl;
  onDelete: () => void = () => {};
  onDismiss: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(YibuqueColor.overlayDark)
        .borderRadius(this.cornerRadius)
        .hitTestBehavior(HitTestMode.Default)
        .onClick(() => {
          if (!this.deleting) {
            this.onDismiss();
          }
        })

      Button() {
        Row({ space: YibuqueSpacing.sm }) {
          if (this.deleting) {
            LoadingProgress()
              .width(18)
              .height(18)
              .color(YibuqueColor.danger)
          } else {
            SymbolGlyph($r('sys.symbol.trash'))
              .fontSize(18)
              .fontColor([YibuqueColor.danger])
          }

          Text(this.deleting ? '删除中...' : this.label)
            .fontSize(15)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.danger)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .height(48)
      .constraintSize({ minWidth: 112 })
      .padding({ left: YibuqueSpacing.md, right: YibuqueSpacing.md })
      .type(ButtonType.Capsule)
      .stateEffect(!this.deleting)
      .enabled(!this.deleting)
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius(YibuqueRadius.full)
      .accessibilityText(this.deleting ? `${this.label}，正在删除` : this.label)
      .onClick(() => {
        if (!this.deleting) {
          this.onDelete();
        }
      })
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.cornerRadius)
  }
}
