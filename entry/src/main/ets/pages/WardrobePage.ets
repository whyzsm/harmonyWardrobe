@Component
export struct WardrobePage {
  build() {
    Column({ space: 18 }) {
      Text('衣橱')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('管理上衣、裤装、裙装、外套、鞋包和配饰。')
        .fontSize(16)
        .fontColor('#475569')

      Column({ space: 8 }) {
        Text('衣物列表')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')

        Text('添加衣服后会在这里显示。')
          .fontSize(14)
          .fontColor('#64748B')
      }
      .width('100%')
      .padding(16)
      .borderRadius(8)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#F8FAFC')
  }
}
