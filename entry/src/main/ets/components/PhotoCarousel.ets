import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';

@Component
export struct PhotoCarousel {
  @Prop photoUris: string[] = [];
  @Prop @Watch('onActiveIndexChange') activeIndex: number = 0;
  onSelect: (index: number) => void = () => {};
  @Prop cornerRadius: number = YibuqueRadius.xs;
  @State private selectedIndex: number = 0;

  aboutToAppear(): void {
    this.selectedIndex = this.normalizeIndex(this.activeIndex);
  }

  onActiveIndexChange(): void {
    this.selectedIndex = this.normalizeIndex(this.activeIndex);
  }

  private normalizeIndex(index: number): number {
    if (this.photoUris.length === 0 || index < 0) {
      return 0;
    }
    return index >= this.photoUris.length ? this.photoUris.length - 1 : index;
  }

  private selectPhoto(index: number): void {
    this.selectedIndex = this.normalizeIndex(index);
    this.onSelect(this.selectedIndex);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.photoUris.length === 1) {
        Image(this.photoUris[0])
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else if (this.photoUris.length > 1) {
        Swiper() {
          ForEach(this.photoUris, (photoUri: string, index: number) => {
            Image(photoUri)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
          }, (photoUri: string, index: number) => `${photoUri}-${index}`)
        }
        .width('100%')
        .height('100%')
        .index(this.normalizeIndex(this.selectedIndex))
        .indicator(false)
        .loop(true)
        .onChange((index: number) => {
          this.selectPhoto(index);
        })
      }

      if (this.photoUris.length > 1) {
        Text(`${this.normalizeIndex(this.selectedIndex) + 1} / ${this.photoUris.length}`)
          .height(28)
          .padding({ left: 10, right: 10 })
          .fontSize(12)
          .fontColor(YibuqueColor.textInverse)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.overlayDark)
          .borderRadius(YibuqueRadius.full)
          .margin({ right: 12, bottom: 12 })
      }
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.cornerRadius)
    .clip(true)
    .accessibilityText(this.photoUris.length > 1
      ? `第 ${this.normalizeIndex(this.selectedIndex) + 1} 张，共 ${this.photoUris.length} 张照片`
      : '照片')
  }
}
