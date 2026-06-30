import { AppTheme } from '../theme/Tokens';

@Component
export struct ClothingCard {
  @Prop name: string = '';
  @Prop category: string = '';
  @Prop photoUri: string = '';

  build() {
    Column({ space: 8 }) {
      if (this.photoUri.length > 0) {
        Image(this.photoUri)
          .width('100%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppTheme.radius.lg)
      } else {
        Column() {
          Text('衣')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.primary)
        }
        .width('100%')
        .aspectRatio(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(AppTheme.radius.lg)
        .backgroundColor(AppTheme.color.primarySoft)
      }

      Text(this.name)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.color.text)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.category)
        .fontSize(12)
        .fontColor(AppTheme.color.primary)
        .padding({ left: AppTheme.spacing.sm, right: AppTheme.spacing.sm, top: 3, bottom: 3 })
        .backgroundColor(AppTheme.color.primarySoft)
        .borderRadius(AppTheme.radius.sm)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(12)
    .borderRadius(AppTheme.radius.lg)
    .backgroundColor(AppTheme.color.surfaceRaised)
    .border({ width: 1, color: AppTheme.color.border })
  }
}
