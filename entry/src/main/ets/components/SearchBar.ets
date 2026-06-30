import { AppTheme } from '../theme/Tokens';

@Component
export struct SearchBar {
  @Prop value: string = '';
  @Prop placeholder: string = '搜索';
  onChange: (value: string) => void = () => {};

  build() {
    TextInput({ text: this.value, placeholder: this.placeholder })
      .width('100%')
      .height(44)
      .padding({ left: AppTheme.spacing.md, right: AppTheme.spacing.md })
      .fontSize(15)
      .fontColor(AppTheme.color.text)
      .placeholderColor(AppTheme.color.disabled)
      .backgroundColor(AppTheme.color.surface)
      .borderRadius(AppTheme.radius.md)
      .border({ width: 1, color: AppTheme.color.border })
      .onChange((value: string) => {
        this.onChange(value);
      })
  }
}
