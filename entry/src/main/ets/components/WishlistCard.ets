import { AppTheme } from '../theme/Tokens';

@Component
export struct WishlistCard {
  @Prop title: string = '';
  @Prop storeName: string = '';
  @Prop priceText: string = '';
  @Prop photoUri: string = '';

  build() {
    Row({ space: 12 }) {
      if (this.photoUri.length > 0) {
        Image(this.photoUri)
          .width(72)
          .height(72)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppTheme.radius.lg)
      } else {
        Column() {
          Text('愿')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.accent)
        }
        .width(72)
        .height(72)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(AppTheme.radius.lg)
        .backgroundColor(AppTheme.color.primarySoft)
      }

      Column({ space: 6 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.color.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.storeName.length > 0 ? this.storeName : '未记录门店')
          .fontSize(13)
          .fontColor(AppTheme.color.textMuted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.priceText.length > 0 ? this.priceText : '未记录价格')
          .fontSize(13)
          .fontColor(this.priceText.length > 0 ? AppTheme.color.success : AppTheme.color.textDisabled)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .borderRadius(AppTheme.radius.lg)
    .backgroundColor(AppTheme.color.surfaceRaised)
    .border({ width: 1, color: AppTheme.color.border })
  }
}
