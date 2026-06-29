@Component
export struct EmptyState {
  @Prop title: string = '';
  @Prop description: string = '';

  build() {
    Column({ space: 8 }) {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2937')
        .textAlign(TextAlign.Center)

      Text(this.description)
        .fontSize(14)
        .fontColor('#64748B')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#E2E8F0' })
  }
}
