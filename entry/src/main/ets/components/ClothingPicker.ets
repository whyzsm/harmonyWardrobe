import { ClothingCategory } from '../domain/clothing/ClothingCategory';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

function clothingCategoryLabel(category: ClothingCategory): string {
  if (category === ClothingCategory.Top) {
    return '上衣';
  }
  if (category === ClothingCategory.Pants) {
    return '裤装';
  }
  if (category === ClothingCategory.Shorts) {
    return '短裤';
  }
  if (category === ClothingCategory.LongSkirt) {
    return '长裙';
  }
  return '半裙';
}

@Component
export struct ClothingPicker {
  @Prop items: ClothingItem[] = [];
  @Prop selectedIds: string[] = [];
  onToggle: (id: string) => void = () => {};

  private isSelected(id: string): boolean {
    return this.selectedIds.includes(id);
  }

  private coverPhotoUri(item: ClothingItem): string {
    return item.photoUris.length > 0 ? item.photoUris[0] : '';
  }

  build() {
    Column({ space: YibuqueSpacing.sm }) {
      Row() {
        Text('选择衣物')
          .fontSize(16)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .layoutWeight(1)

        if (this.selectedIds.length > 0) {
          Text(`${this.selectedIds.length} 件已选`)
            .fontSize(12)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.actionBlack)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.items.length === 0) {
        Text('暂无衣物，可先去衣柜添加。')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
      } else {
        ForEach(this.items, (item: ClothingItem) => {
          Row({ space: 12 }) {
            Stack({ alignContent: Alignment.Center }) {
              if (this.coverPhotoUri(item).length > 0) {
                Image(this.coverPhotoUri(item))
                  .width('100%')
                  .height('100%')
                  .objectFit(ImageFit.Cover)
              } else {
                SymbolGlyph($r('sys.symbol.shirt'))
                  .fontSize(28)
                  .fontColor([YibuqueColor.textTertiary])
              }
            }
            .width(76)
            .height(92)
            .backgroundColor(YibuqueColor.bgGray)
            .borderRadius(YibuqueRadius.xs)
            .clip(true)

            Column({ space: 5 }) {
              Text(item.name)
                .width('100%')
                .fontSize(15)
                .fontWeight(FontWeight.Regular)
                .fontColor(YibuqueColor.textPrimary)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(clothingCategoryLabel(item.category))
                .fontSize(12)
                .fontColor(YibuqueColor.textSecondary)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            if (this.isSelected(item.id)) {
              Stack({ alignContent: Alignment.Center }) {
                SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                  .fontSize(26)
                  .fontColor([YibuqueColor.actionBlack])
              }
              .width(44)
              .height(44)
            } else {
              Text('选择')
                .height(36)
                .padding({ left: 13, right: 13 })
                .fontSize(13)
                .fontWeight(FontWeight.Regular)
                .fontColor(YibuqueColor.textSecondary)
                .textAlign(TextAlign.Center)
                .borderRadius(YibuqueRadius.full)
                .backgroundColor(YibuqueColor.cardWhite)
                .border({ width: 1, color: YibuqueColor.borderMedium })
            }
          }
          .width('100%')
          .padding(8)
          .alignItems(VerticalAlign.Center)
          .borderRadius(YibuqueRadius.lg)
          .backgroundColor(this.isSelected(item.id) ? YibuqueColor.cardWhite : YibuqueColor.cardSoftGray)
          .border({ width: this.isSelected(item.id) ? 2 : 1, color: this.isSelected(item.id) ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
          .accessibilityText(`${item.name}，${clothingCategoryLabel(item.category)}，${this.isSelected(item.id) ? '已选择' : '未选择'}`)
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
