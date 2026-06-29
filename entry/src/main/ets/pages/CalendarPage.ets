@Component
export struct CalendarPage {
  build() {
    Column({ space: 18 }) {
      Text('日历')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('按日期回看穿搭、地点和照片记录。')
        .fontSize(16)
        .fontColor('#475569')

      Column({ space: 8 }) {
        Text('穿搭日历')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')

        Text('有穿搭记录的日期会在这里标记。')
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
