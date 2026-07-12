import { YibuqueSpacing } from '../theme/Tokens';

@Component
export struct PhotoGrid {
  @Prop photoUris: string[] = [];

  build() {
    Grid() {
      ForEach(this.photoUris, (photoUri: string) => {
        GridItem() {
          Image(photoUri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .borderRadius(5)
        }
      }, (photoUri: string) => photoUri)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(YibuqueSpacing.sm)
    .rowsGap(YibuqueSpacing.sm)
    .width('100%')
    .height(this.photoUris.length === 0 ? 0 : 220)
  }
}
