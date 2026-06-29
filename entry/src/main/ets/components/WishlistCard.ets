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
          .borderRadius(8)
      } else {
        Column() {
          Text('愿')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#64748B')
        }
        .width(72)
        .height(72)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(8)
        .backgroundColor('#E2E8F0')
      }

      Column({ space: 6 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.storeName.length > 0 ? this.storeName : '未记录门店')
          .fontSize(13)
          .fontColor('#64748B')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.priceText.length > 0 ? this.priceText : '未记录价格')
          .fontSize(13)
          .fontColor('#0F766E')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#E2E8F0' })
  }
}
