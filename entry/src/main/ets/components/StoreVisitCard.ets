import { StoreVisit } from '../domain/store/StoreModels';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

@Component
export struct StoreVisitCard {
  @Prop visit: StoreVisit = {
    id: '',
    storeNameSnapshot: '',
    visitDate: '',
    photoUris: [],
    createdAt: '',
    updatedAt: ''
  };

  private coverPhotoUri(): string {
    return this.visit.photoUris.length > 0 ? this.visit.photoUris[0] : '';
  }

  build() {
    Column({ space: YibuqueSpacing.sm }) {
      if (this.coverPhotoUri().length > 0) {
        Image(this.coverPhotoUri())
          .width('100%')
          .height(150)
          .objectFit(ImageFit.Cover)
          .borderRadius(24)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.store_fill'))
            .fontSize(34)
            .fontColor([YibuqueColor.textPrimary])
        }
        .width('100%')
        .height(150)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(YibuqueColor.cardMint)
        .borderRadius(24)
      }

      Text(this.visit.storeNameSnapshot)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(`${this.visit.visitDate}${this.visit.districtOrAddress === undefined ? '' : ` · ${this.visit.districtOrAddress}`}`)
        .fontSize(13)
        .fontColor(YibuqueColor.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      if (this.visit.note !== undefined && this.visit.note.length > 0) {
        Text(this.visit.note)
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
    }
    .width('100%')
    .padding(YibuqueSpacing.md)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .shadow(YibuqueShadow.card)
  }
}
