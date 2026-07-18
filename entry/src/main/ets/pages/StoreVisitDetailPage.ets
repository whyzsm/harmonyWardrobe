import { PhotoCarousel } from '../components/PhotoCarousel';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import { StoreVisit } from '../domain/store/StoreModels';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct StoreVisitDetailPage {
  @Prop visit?: StoreVisit = undefined;
  @Prop statusLabel: string = '已去';
  onBack: () => void = () => {};
  onEdit: (visit: StoreVisit) => void = () => {};

  private photoUris(): string[] {
    return this.visit?.photoUris ?? [];
  }

  private locationText(): string {
    const location = this.visit?.districtOrAddress?.trim() ?? '';
    return location.length > 0 ? location : '未记录';
  }

  private tagsText(): string {
    const tags = this.visit?.focusTags ?? [];
    return tags.length > 0 ? tags.join(' · ') : '未记录';
  }

  private noteText(): string {
    const note = this.visit?.note?.trim() ?? '';
    return note.length > 0 ? note : '暂未填写备注';
  }

  private photoCountText(): string {
    const count = this.photoUris().length;
    return count > 0 ? `${count} 张照片` : '暂无照片';
  }

  @Builder
  DetailTopBar() {
    SecondaryPageHeader({
      title: '逛店详情',
      showEditAction: this.visit !== undefined,
      backAccessibilityText: '返回逛店',
      onBack: () => {
        this.onBack();
      },
      onEdit: () => {
        const visit = this.visit;
        if (visit !== undefined) {
          this.onEdit(visit);
        }
      }
    })
  }

  @Builder
  HeroPhoto() {
    if (this.photoUris().length > 0) {
      PhotoCarousel({
        photoUris: this.photoUris(),
        cornerRadius: YibuqueRadius.xxxl
      })
        .width('100%')
        .height(280)
    } else {
      Column({ space: YibuqueSpacing.sm }) {
        SymbolGlyph($r('sys.symbol.store_fill'))
          .fontSize(48)
          .fontColor([YibuqueColor.textPrimary])

        Text('暂无照片')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
      }
      .width('100%')
      .height(280)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(YibuqueColor.cardMuted)
      .borderRadius(YibuqueRadius.xxxl)
    }
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row({ space: YibuqueSpacing.md }) {
      Text(label)
        .width(64)
        .fontSize(13)
        .fontColor(YibuqueColor.textTertiary)

      Text(value)
        .layoutWeight(1)
        .fontSize(15)
        .fontColor(YibuqueColor.textPrimary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(34)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SummaryCard() {
    Column({ space: YibuqueSpacing.md }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.visit?.storeNameSnapshot ?? '逛店记录')
            .fontSize(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.photoCountText())
            .fontSize(13)
            .fontColor(YibuqueColor.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.statusLabel)
          .height(34)
          .padding({ left: 14, right: 14 })
          .fontSize(14)
          .fontColor(YibuqueColor.actionBlack)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: YibuqueColor.actionBlack })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      this.DetailRow('商圈', this.locationText())
      this.DetailRow('日期', this.visit?.visitDate ?? '未记录')
      this.DetailRow('标签', this.tagsText())

      Text(this.noteText())
        .width('100%')
        .padding(YibuqueSpacing.md)
        .fontSize(15)
        .fontColor(YibuqueColor.textPrimary)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.lg)
    }
    .width('100%')
    .padding(YibuqueSpacing.lg)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .shadow(YibuqueShadow.card)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      this.DetailTopBar()

      if (this.visit === undefined) {
        Column({ space: YibuqueSpacing.lg }) {
          Text('逛店记录不存在')
            .fontSize(24)
            .fontColor(YibuqueColor.textPrimary)

          Text('可能已经被删除，请返回逛店重新选择。')
            .fontSize(14)
            .fontColor(YibuqueColor.textSecondary)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: YibuqueSpacing.lg }) {
            this.HeroPhoto()
            this.SummaryCard()
          }
          .width('100%')
          .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.sm, bottom: YibuqueSpacing.section })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBase)
  }
}
