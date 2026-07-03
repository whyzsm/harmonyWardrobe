import { AppTheme } from '../theme/Tokens';

@Component
export struct ClothingCard {
  @Prop name: string = '';
  @Prop category: string = '';
  @Prop photoUri: string = '';
  @State private cardScale: number = 0.95;
  @State private cardOpacity: number = 0;
  onClick: () => void = () => {};

  aboutToAppear() {
    setTimeout(() => {
      this.cardOpacity = 1;
      this.cardScale = 1;
    }, 50);
  }

  build() {
    Column({ space: 8 }) {
      if (this.photoUri.length > 0) {
        Image(this.photoUri)
          .width('100%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
      } else {
        Column() {
          Text('衣')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.primary)
        }
        .width('100%')
        .aspectRatio(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(8)
        .backgroundColor(AppTheme.color.primarySoft)
      }

      Text(this.name)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.color.text)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.category)
        .fontSize(12)
        .fontColor(AppTheme.color.primary)
        .padding({ left: AppTheme.spacing.sm, right: AppTheme.spacing.sm, top: 3, bottom: 3 })
        .backgroundColor(AppTheme.color.primarySoft)
        .borderRadius(AppTheme.radius.sm)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(8)
    .borderRadius(AppTheme.radius.lg)
    .backgroundColor(AppTheme.color.surfaceRaised)
    .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 3 })
    .scale({ x: this.cardScale, y: this.cardScale })
    .opacity(this.cardOpacity)
    .animation({
      duration: 300,
      curve: Curve.Smooth,
      playMode: PlayMode.Normal
    })
    .onClick(() => {
      this.cardScale = 1;
      this.onClick();
    })
    .onTouch((event: TouchEvent) => {
      this.cardScale = event.type === TouchType.Down ? 0.97 : 1;
    })
  }
}
