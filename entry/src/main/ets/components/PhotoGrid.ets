import { AppTheme } from '../theme/Tokens';

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
            .borderRadius(AppTheme.radius.md)
        }
      }, (photoUri: string) => photoUri)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(AppTheme.spacing.sm)
    .rowsGap(AppTheme.spacing.sm)
    .width('100%')
    .height(this.photoUris.length === 0 ? 0 : 220)
  }
}
