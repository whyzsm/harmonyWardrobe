@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('Harmony Wardrobe')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2933')

      Text('Local wardrobe journal')
        .fontSize(16)
        .fontColor('#52616B')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F7F3EF')
  }
}
