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
            .fontColor('#475569')
        }
        .width('100%')
        .height(132)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(8)
        .backgroundColor('#E2E8F0')
      }

      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111827')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`${this.itemCount} 件单品`)
        .fontSize(13)
        .fontColor('#64748B')
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#E2E8F0' })
  }
}
