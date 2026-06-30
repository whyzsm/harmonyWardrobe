import { OutfitTemplate } from '../domain/outfit/OutfitModels';

@Component
export struct OutfitPicker {
  @Prop outfits: OutfitTemplate[] = [];
  @Prop selectedOutfitId: string = '';
  onSelect: (id: string) => void = () => {};

  build() {
    Column({ space: 8 }) {
      Text('选择套装')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2937')

      if (this.outfits.length === 0) {
        Text('暂无套装，可先创建套装。')
          .fontSize(14)
          .fontColor('#64748B')
      } else {
        ForEach(this.outfits, (outfit: OutfitTemplate) => {
          Row() {
            Column({ space: 2 }) {
              Text(outfit.title)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827')

              Text(`${outfit.clothingItemIds.length} 件单品`)
                .fontSize(12)
                .fontColor('#64748B')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(outfit.id === this.selectedOutfitId ? '已选' : '选择')
              .fontSize(13)
              .fontColor(outfit.id === this.selectedOutfitId ? '#FFFFFF' : '#0F172A')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(8)
              .backgroundColor(outfit.id === this.selectedOutfitId ? '#0F172A' : '#FFFFFF')
              .border({ width: 1, color: outfit.id === this.selectedOutfitId ? '#0F172A' : '#CBD5E1' })
          }
          .width('100%')
          .padding(10)
          .borderRadius(8)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: outfit.id === this.selectedOutfitId ? '#0F172A' : '#E2E8F0' })
          .onClick(() => {
            this.onSelect(outfit.id);
          })
        }, (outfit: OutfitTemplate) => outfit.id)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
