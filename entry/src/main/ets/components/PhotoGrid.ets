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
            .borderRadius(8)
        }
      }, (photoUri: string) => photoUri)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .width('100%')
    .height(this.photoUris.length === 0 ? 0 : 220)
  }
}
