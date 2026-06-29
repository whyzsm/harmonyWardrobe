@Component
export struct ShoppingPage {
  build() {
    Column({ space: 18 }) {
      Text('逛街')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('记录心仪单品、门店、价格和试穿照片。')
        .fontSize(16)
        .fontColor('#475569')

      Column({ space: 8 }) {
        Text('心仪清单')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')

        Text('逛街记录会在这里显示。')
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
