@Component
export struct SearchBar {
  @Prop value: string = '';
  @Prop placeholder: string = '搜索';
  onChange: (value: string) => void = () => {};

  build() {
    TextInput({ text: this.value, placeholder: this.placeholder })
      .width('100%')
      .height(44)
      .padding({ left: 14, right: 14 })
      .fontSize(15)
      .fontColor('#111827')
      .placeholderColor('#94A3B8')
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .border({ width: 1, color: '#E2E8F0' })
      .onChange((value: string) => {
        this.onChange(value);
      })
  }
}
