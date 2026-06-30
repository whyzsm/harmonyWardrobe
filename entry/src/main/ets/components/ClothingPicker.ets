import { ClothingItem } from '../domain/clothing/ClothingModels';
import { AppTheme } from '../theme/Tokens';

@Component
export struct ClothingPicker {
  @Prop items: ClothingItem[] = [];
  @Prop selectedIds: string[] = [];
  onToggle: (id: string) => void = () => {};

  private isSelected(id: string): boolean {
    return this.selectedIds.includes(id);
  }

  build() {
    Column({ space: 8 }) {
      Text('选择衣物')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.color.text)

      if (this.items.length === 0) {
        Text('暂无衣物，可先去衣橱添加。')
          .fontSize(14)
          .fontColor(AppTheme.color.textMuted)
      } else {
        ForEach(this.items, (item: ClothingItem) => {
          Row() {
            Column({ space: 2 }) {
              Text(item.name)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppTheme.color.text)

              Text(item.category)
                .fontSize(12)
                .fontColor(AppTheme.color.textMuted)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(this.isSelected(item.id) ? '已选' : '选择')
              .fontSize(13)
              .fontColor(this.isSelected(item.id) ? AppTheme.color.surface : AppTheme.color.primary)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(AppTheme.radius.md)
              .backgroundColor(this.isSelected(item.id) ? AppTheme.color.primary : AppTheme.color.surface)
              .border({ width: 1, color: this.isSelected(item.id) ? AppTheme.color.primary : AppTheme.color.border })
          }
          .width('100%')
          .padding(10)
          .borderRadius(AppTheme.radius.md)
          .backgroundColor(AppTheme.color.surface)
          .border({ width: 1, color: this.isSelected(item.id) ? AppTheme.color.primary : AppTheme.color.border })
          .onClick(() => {
            this.onToggle(item.id);
          })
        }, (item: ClothingItem) => item.id)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
