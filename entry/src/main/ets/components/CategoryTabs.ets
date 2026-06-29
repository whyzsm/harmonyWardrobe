@Component
export struct CategoryTabs {
  @Prop categories: string[] = [];
  @Prop selected: string = '';

  build() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.categories, (category: string) => {
          Text(category)
            .fontSize(14)
            .fontColor(category === this.selected ? '#FFFFFF' : '#334155')
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor(category === this.selected ? '#0F172A' : '#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: category === this.selected ? '#0F172A' : '#E2E8F0' })
        }, (category: string) => category)
      }
      .padding({ right: 20 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}
