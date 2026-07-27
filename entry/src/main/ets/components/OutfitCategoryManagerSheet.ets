import { OutfitCategory } from '../domain/outfit/OutfitModels';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';
import { userFacingError } from '../utils/userFacingError';

@Component
export struct OutfitCategoryManagerSheet {
  @Prop categories: OutfitCategory[] = [];
  onClose: () => void = () => {};
  onDelete: (category: OutfitCategory) => Promise<void> = async (_category: OutfitCategory): Promise<void> => {};

  @State private deletingCategoryId: string = '';
  @State private errorMessage: string = '';

  private confirmDelete(category: OutfitCategory): void {
    if (this.deletingCategoryId.length > 0) {
      return;
    }

    const message = category.usageCount > 0
      ? `该分类下有 ${category.usageCount} 套穿搭，删除后会归入全部。`
      : '确定删除这个分类吗？';
    AlertDialog.show({
      title: '删除分类',
      message,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: YibuqueColor.danger,
        action: () => {
          this.deleteCategory(category);
        }
      }
    });
  }

  private async deleteCategory(category: OutfitCategory): Promise<void> {
    this.deletingCategoryId = category.id;
    this.errorMessage = '';
    try {
      await this.onDelete(category);
    } catch (error) {
      this.errorMessage = userFacingError(error, '删除分类失败');
    } finally {
      this.deletingCategoryId = '';
    }
  }

  @Builder
  CategoryRow(category: OutfitCategory) {
    Row({ space: YibuqueSpacing.md }) {
      Column({ space: 3 }) {
        Text(category.name)
          .width('100%')
          .fontSize(15)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${category.usageCount} 套穿搭`)
          .width('100%')
          .fontSize(12)
          .fontColor(YibuqueColor.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button() {
        if (this.deletingCategoryId === category.id) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color(YibuqueColor.danger)
        } else {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(18)
            .fontColor([YibuqueColor.danger])
        }
      }
      .width(44)
      .height(44)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.full)
      .enabled(this.deletingCategoryId.length === 0)
      .accessibilityText(`删除分类 ${category.name}`)
      .onClick(() => {
        this.confirmDelete(category);
      })
    }
    .width('100%')
    .height(62)
    .padding({ left: 14, right: 10 })
    .backgroundColor(YibuqueColor.cardSoftGray)
    .borderRadius(YibuqueRadius.lg)
    .border({ width: 1, color: YibuqueColor.borderLight })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(YibuqueColor.overlayDark)
        .onClick(() => {
          if (this.deletingCategoryId.length === 0) {
            this.onClose();
          }
        })

      Column({ space: YibuqueSpacing.md }) {
        Row({ space: YibuqueSpacing.md }) {
          Text('管理穿搭分类')
            .layoutWeight(1)
            .fontSize(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)

          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(17)
              .fontColor([YibuqueColor.textPrimary])
          }
          .width(44)
          .height(44)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .enabled(this.deletingCategoryId.length === 0)
          .accessibilityText('关闭分类管理')
          .onClick(() => {
            this.onClose();
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.categories.length === 0) {
          Column({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.list_bullet'))
              .fontSize(30)
              .fontColor([YibuqueColor.textSecondary])

            Text('暂无自定义分类')
              .fontSize(15)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          Scroll() {
            Column({ space: 10 }) {
              ForEach(this.categories, (category: OutfitCategory) => {
                this.CategoryRow(category)
              }, (category: OutfitCategory) => category.id)
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .width('100%')
            .fontSize(13)
            .fontColor(YibuqueColor.danger)
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .height('62%')
      .padding({
        left: YibuqueSpacing.pageX,
        right: YibuqueSpacing.pageX,
        top: YibuqueSpacing.lg,
        bottom: YibuqueSpacing.xxl
      })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius({
        topLeft: YibuqueRadius.sheet,
        topRight: YibuqueRadius.sheet,
        bottomLeft: 0,
        bottomRight: 0
      })
      .shadow(YibuqueShadow.editorSheet)
    }
    .width('100%')
    .height('100%')
  }
}
