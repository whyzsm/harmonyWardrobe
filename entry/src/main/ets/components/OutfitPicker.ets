import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { AppTheme } from '../theme/Tokens';

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
        .fontColor(AppTheme.color.text)

      if (this.outfits.length === 0) {
        Text('暂无套装，可先创建套装。')
          .fontSize(14)
          .fontColor(AppTheme.color.textMuted)
      } else {
        ForEach(this.outfits, (outfit: OutfitTemplate) => {
          Row() {
            Column({ space: 2 }) {
              Text(outfit.title)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppTheme.color.text)

              Text(`${outfit.clothingItemIds.length} 件单品`)
                .fontSize(12)
                .fontColor(AppTheme.color.textMuted)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(outfit.id === this.selectedOutfitId ? '已选' : '选择')
              .fontSize(13)
              .fontColor(outfit.id === this.selectedOutfitId ? AppTheme.color.surface : AppTheme.color.primary)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(AppTheme.radius.md)
              .backgroundColor(outfit.id === this.selectedOutfitId ? AppTheme.color.primary : AppTheme.color.surface)
              .border({ width: 1, color: outfit.id === this.selectedOutfitId ? AppTheme.color.primary : AppTheme.color.border })
          }
          .width('100%')
          .padding(10)
          .borderRadius(AppTheme.radius.md)
          .backgroundColor(AppTheme.color.surface)
          .border({ width: 1, color: outfit.id === this.selectedOutfitId ? AppTheme.color.primary : AppTheme.color.border })
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
