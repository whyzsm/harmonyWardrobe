import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct SearchBar {
  @Prop value: string = '';
  @Prop placeholder: string = '搜索';
  onChange: (value: string) => void = () => {};

  build() {
    TextInput({ text: this.value, placeholder: this.placeholder })
      .width('100%')
      .height(44)
      .padding({ left: YibuqueSpacing.md, right: YibuqueSpacing.md })
      .fontSize(15)
      .fontColor(YibuqueColor.textPrimary)
      .placeholderColor(YibuqueColor.textDisabled)
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius(YibuqueRadius.md)
      .border({ width: 1, color: YibuqueColor.borderMedium })
      .onChange((value: string) => {
        this.onChange(value);
      })
  }
}
