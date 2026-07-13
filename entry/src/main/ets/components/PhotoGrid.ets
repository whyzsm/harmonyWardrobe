import { YibuqueSpacing } from '../theme/Tokens';

@Component
export struct PhotoGrid {
  @Prop photoUris: string[] = [];

  build() {
    if (this.photoUris.length === 0) {
      Image($r('app.media.default_fashion_cover'))
        .width('100%')
        .height(220)
        .objectFit(ImageFit.Cover)
        .borderRadius(5)
    } else {
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
      .height(220)
    }
  }
}
