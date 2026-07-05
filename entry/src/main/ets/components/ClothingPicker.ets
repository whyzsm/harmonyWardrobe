import { ClothingItem } from '../domain/clothing/ClothingModels';
import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct ClothingPicker {
  @Prop items: ClothingItem[] = [];
  @Prop selectedIds: string[] = [];
  onToggle: (id: string) => void = () => {};

  private isSelected(id: string): boolean {
    return this.selectedIds.includes(id);
  }

  build() {
    Column({ space: YibuqueSpacing.sm }) {
      Text('选择衣物')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)

      if (this.items.length === 0) {
        Text('暂无衣物，可先去衣橱添加。')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
      } else {
        ForEach(this.items, (item: ClothingItem) => {
          Row() {
            Column({ space: 2 }) {
              Text(item.name)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(YibuqueColor.textPrimary)

              Text(item.category)
                .fontSize(12)
                .fontColor(YibuqueColor.textSecondary)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(this.isSelected(item.id) ? '已选' : '选择')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isSelected(item.id) ? YibuqueColor.textInverse : YibuqueColor.textSecondary)
              .padding({ left: 12, right: 12, top: 7, bottom: 7 })
              .borderRadius(YibuqueRadius.full)
              .backgroundColor(this.isSelected(item.id) ? YibuqueColor.actionBlack : YibuqueColor.cardWhite)
              .border({ width: 1, color: this.isSelected(item.id) ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
          }
          .width('100%')
          .padding({ left: 14, right: 12, top: 12, bottom: 12 })
          .borderRadius(YibuqueRadius.lg)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .border({ width: 1, color: this.isSelected(item.id) ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
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
