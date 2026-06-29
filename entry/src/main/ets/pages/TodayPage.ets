@Component
export struct TodayPage {
  build() {
    Column({ space: 18 }) {
      Text('今日')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('记录今天穿什么、去了哪里、拍了哪些照片。')
        .fontSize(16)
        .fontColor('#475569')

      Column({ space: 8 }) {
        Text('今日穿搭')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')

        Text('还没有记录今天的套装。')
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
