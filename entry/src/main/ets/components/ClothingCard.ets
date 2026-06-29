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
          .borderRadius(8)
      } else {
        Column() {
          Text('衣')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#64748B')
        }
        .width('100%')
        .aspectRatio(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(8)
        .backgroundColor('#E2E8F0')
      }

      Text(this.name)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111827')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.category)
        .fontSize(12)
        .fontColor('#64748B')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(10)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#E2E8F0' })
  }
}
