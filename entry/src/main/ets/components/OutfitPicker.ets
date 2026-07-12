import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct OutfitPicker {
  @Prop outfits: OutfitTemplate[] = [];
  @Prop selectedOutfitId: string = '';
  onSelect: (id: string) => void = () => {};

  build() {
    Column({ space: YibuqueSpacing.sm }) {
      Text('选择美搭')
        .fontSize(16)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)

      if (this.outfits.length === 0) {
        Text('暂无美搭，可先记录一套美搭。')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
      } else {
        ForEach(this.outfits, (outfit: OutfitTemplate) => {
          Row() {
            Column({ space: 2 }) {
              Text(outfit.title)
                .fontSize(15)
                .fontWeight(FontWeight.Regular)
                .fontColor(YibuqueColor.textPrimary)

              Text(`${outfit.clothingItemIds.length} 件单品`)
                .fontSize(12)
                .fontColor(YibuqueColor.textSecondary)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(outfit.id === this.selectedOutfitId ? '已选' : '选择')
              .fontSize(13)
              .fontColor(outfit.id === this.selectedOutfitId ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(YibuqueRadius.full)
              .backgroundColor(outfit.id === this.selectedOutfitId ? YibuqueColor.actionBlack : YibuqueColor.cardWhite)
              .border({ width: 1, color: outfit.id === this.selectedOutfitId ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
          }
          .width('100%')
          .padding(10)
          .borderRadius(YibuqueRadius.lg)
          .backgroundColor(YibuqueColor.cardWhite)
          .border({ width: 1, color: outfit.id === this.selectedOutfitId ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
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
