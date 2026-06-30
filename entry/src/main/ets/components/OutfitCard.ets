import { AppTheme } from '../theme/Tokens';

@Component
export struct OutfitCard {
  @Prop title: string = '';
  @Prop itemCount: number = 0;
  @Prop photoUri: string = '';

  build() {
    Column({ space: 10 }) {
      if (this.photoUri.length > 0) {
        Image(this.photoUri)
          .width('100%')
          .height(132)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
      } else {
        Column() {
          Text('套装')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.primary)
        }
        .width('100%')
        .height(132)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(8)
        .backgroundColor(AppTheme.color.primarySoft)
      }

      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.color.text)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`${this.itemCount} 件单品`)
        .fontSize(12)
        .fontColor(AppTheme.color.primary)
        .padding({ left: AppTheme.spacing.sm, right: AppTheme.spacing.sm, top: 3, bottom: 3 })
        .backgroundColor(AppTheme.color.primarySoft)
        .borderRadius(AppTheme.radius.sm)
    }
    .width('100%')
    .padding(8)
    .borderRadius(AppTheme.radius.lg)
    .backgroundColor(AppTheme.color.surfaceRaised)
    .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 3 })
  }
}
