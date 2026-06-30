import { ClothingItem } from '../domain/clothing/ClothingModels';

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
        .fontColor('#1F2937')

      if (this.items.length === 0) {
        Text('暂无衣物，可先去衣橱添加。')
          .fontSize(14)
          .fontColor('#64748B')
      } else {
        ForEach(this.items, (item: ClothingItem) => {
          Row() {
            Column({ space: 2 }) {
              Text(item.name)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827')

              Text(item.category)
                .fontSize(12)
                .fontColor('#64748B')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(this.isSelected(item.id) ? '已选' : '选择')
              .fontSize(13)
              .fontColor(this.isSelected(item.id) ? '#FFFFFF' : '#0F172A')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(8)
              .backgroundColor(this.isSelected(item.id) ? '#0F172A' : '#FFFFFF')
              .border({ width: 1, color: this.isSelected(item.id) ? '#0F172A' : '#CBD5E1' })
          }
          .width('100%')
          .padding(10)
          .borderRadius(8)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: this.isSelected(item.id) ? '#0F172A' : '#E2E8F0' })
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
