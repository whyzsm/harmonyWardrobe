import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { AppTheme } from '../theme/Tokens';
import { toIsoDate } from '../utils/date';
import { WearLogEditPage } from './WearLogEditPage';

@Component
export struct TodayPage {
  outfitRepository?: OutfitRepository = undefined;
  wearLogRepository?: WearLogRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;

  @State private todayIsoDate: string = toIsoDate(new Date());
  @State private todaysWearLog?: WearLog = undefined;
  @State private recentOutfits: OutfitTemplate[] = [];
  @State private recentWearLogs: WearLog[] = [];
  @State private selectedOutfitId: string = '';
  @State private showWearLogEditor: boolean = false;
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadToday();
  }

  private async loadToday(): Promise<void> {
    if (this.outfitRepository === undefined || this.wearLogRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.recentOutfits = await this.outfitRepository.listOutfits();
      this.recentWearLogs = await this.wearLogRepository.listWearLogsByDate(this.todayIsoDate);
      this.todaysWearLog = this.recentWearLogs.length > 0 ? this.recentWearLogs[0] : undefined;
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载今日穿搭失败';
    } finally {
      this.loading = false;
    }
  }

  private firstOutfitPhotoUri(outfit: OutfitTemplate): string {
    return outfit.photoUris.length > 0 ? outfit.photoUris[0] : '';
  }

  private firstWearLogPhotoUri(wearLog: WearLog): string {
    return wearLog.photoUris.length > 0 ? wearLog.photoUris[0] : '';
  }

  private recordToday(outfit?: OutfitTemplate): void {
    this.selectedOutfitId = outfit?.id ?? '';
    this.showWearLogEditor = true;
  }

  private closeWearLogEditor(): void {
    this.showWearLogEditor = false;
    this.selectedOutfitId = '';
  }

  private retry(): void {
    this.loadToday();
  }

  build() {
    if (this.showWearLogEditor) {
      WearLogEditPage({
        initialOutfitTemplateId: this.selectedOutfitId,
        outfits: this.recentOutfits,
        wearLogRepository: this.wearLogRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (_wearLog: WearLog) => {
          this.closeWearLogEditor();
          this.loadToday();
        },
        onCancel: () => {
          this.closeWearLogEditor();
        }
      })
    } else {
      Scroll() {
      Column({ space: 14 }) {
        Row() {
          Text(this.todayIsoDate)
            .fontSize(14)
            .fontColor(AppTheme.color.textMuted)
            .layoutWeight(1)

          Row({ space: 18 }) {
            Column({ space: 4 }) {
              Text('推荐')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.color.text)

              Column()
                .width(28)
                .height(3)
                .backgroundColor(AppTheme.color.primary)
                .borderRadius(2)
            }
            .alignItems(HorizontalAlign.Center)

            Text('今日')
              .fontSize(18)
              .fontColor(AppTheme.color.textMuted)

            Text('灵感')
              .fontSize(18)
              .fontColor(AppTheme.color.textMuted)
          }

          Text('⌕')
            .fontSize(24)
            .fontColor(AppTheme.color.text)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text('首页')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.color.text)

        if (this.loading) {
          Text('loading / 正在加载今日穿搭...')
            .fontSize(14)
            .fontColor(AppTheme.color.textMuted)
        }

        if (this.errorMessage.length > 0) {
          Row({ space: 8 }) {
            Text(`error / ${this.errorMessage}`)
              .fontSize(14)
              .fontColor(AppTheme.color.danger)
              .layoutWeight(1)

            Button('retry')
              .height(34)
              .fontSize(13)
              .onClick(() => {
                this.retry();
              })
          }
          .width('100%')
        }

        Grid() {
          GridItem() {
            Column({ space: 8 }) {
              if (this.todaysWearLog !== undefined && this.firstWearLogPhotoUri(this.todaysWearLog).length > 0) {
                Image(this.firstWearLogPhotoUri(this.todaysWearLog))
                  .width('100%')
                  .height(168)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
              } else {
                Column({ space: 8 }) {
                  Text('衣')
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.color.primary)

                  Text('今天穿什么？')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppTheme.color.text)
                }
                .width('100%')
                .height(168)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor(AppTheme.color.primarySoft)
                .borderRadius(8)
              }

              Text(this.todaysWearLog === undefined ? '记录一次今日搭配' : this.todaysWearLog.outfitTitleSnapshot)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppTheme.color.text)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Row() {
                Text(this.todaysWearLog === undefined ? '今日灵感' : (this.todaysWearLog.placeText ?? '今日穿搭'))
                  .fontSize(12)
                  .fontColor(AppTheme.color.textMuted)
                  .layoutWeight(1)

                Text('♡ 记录')
                  .fontSize(12)
                  .fontColor(AppTheme.color.accent)
              }
            }
            .width('100%')
            .padding(8)
            .borderRadius(AppTheme.radius.lg)
            .backgroundColor(AppTheme.color.surfaceRaised)
            .onClick(() => {
              this.recordToday();
            })
          }

          if (this.recentOutfits.length === 0) {
            GridItem() {
              Column({ space: 8 }) {
                Column({ space: 8 }) {
                  Text('搭')
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.color.primary)

                  Text('从最近套装里挑一套')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppTheme.color.text)
                    .textAlign(TextAlign.Center)
                }
                .width('100%')
                .height(190)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor(AppTheme.color.primarySoft)
                .borderRadius(8)

                Text('创建套装后，这里会像灵感流一样展示。')
                  .fontSize(15)
                  .fontColor(AppTheme.color.text)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text('♡ 0')
                  .fontSize(12)
                  .fontColor(AppTheme.color.textMuted)
              }
              .width('100%')
              .padding(8)
              .borderRadius(AppTheme.radius.lg)
              .backgroundColor(AppTheme.color.surfaceRaised)
            }
          } else {
            ForEach(this.recentOutfits, (outfit: OutfitTemplate) => {
              GridItem() {
                Column({ space: 8 }) {
                  if (this.firstOutfitPhotoUri(outfit).length > 0) {
                    Image(this.firstOutfitPhotoUri(outfit))
                      .width('100%')
                      .height(190)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                  } else {
                    Column() {
                      Text('套装')
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppTheme.color.primary)
                    }
                    .width('100%')
                    .height(190)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .backgroundColor(AppTheme.color.primarySoft)
                    .borderRadius(8)
                  }

                  Text(outfit.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppTheme.color.text)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row() {
                    Text('从最近套装里挑一套')
                      .fontSize(12)
                      .fontColor(AppTheme.color.textMuted)
                      .layoutWeight(1)

                    Text(`${outfit.clothingItemIds.length} 件`)
                      .fontSize(12)
                      .fontColor(AppTheme.color.primary)
                  }
                }
                .width('100%')
                .padding(8)
                .borderRadius(AppTheme.radius.lg)
                .backgroundColor(AppTheme.color.surfaceRaised)
                .onClick(() => {
                  this.recordToday(outfit);
                })
              }
            }, (outfit: OutfitTemplate) => outfit.id)
          }

          if (this.recentWearLogs.length === 0) {
            GridItem() {
              Column({ space: 8 }) {
                Column({ space: 8 }) {
                  Text('记')
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.color.primary)

                  Text('最近穿过')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppTheme.color.text)
                }
                .width('100%')
                .height(150)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor(AppTheme.color.primarySoft)
                .borderRadius(8)

                Text('穿搭记录会按时间出现在这里。')
                  .fontSize(15)
                  .fontColor(AppTheme.color.text)

                Text('♡ 0')
                  .fontSize(12)
                  .fontColor(AppTheme.color.textMuted)
              }
              .width('100%')
              .padding(8)
              .borderRadius(AppTheme.radius.lg)
              .backgroundColor(AppTheme.color.surfaceRaised)
            }
          } else {
            ForEach(this.recentWearLogs, (wearLog: WearLog) => {
              GridItem() {
                Column({ space: 8 }) {
                  if (this.firstWearLogPhotoUri(wearLog).length > 0) {
                    Image(this.firstWearLogPhotoUri(wearLog))
                      .width('100%')
                      .height(150)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                  } else {
                    Column() {
                      Text('最近穿过')
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppTheme.color.primary)
                    }
                    .width('100%')
                    .height(150)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .backgroundColor(AppTheme.color.primarySoft)
                    .borderRadius(8)
                  }

                  Text(wearLog.outfitTitleSnapshot)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppTheme.color.text)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row() {
                    Text(wearLog.wornDate)
                      .fontSize(12)
                      .fontColor(AppTheme.color.textMuted)
                      .layoutWeight(1)

                    Text(`${wearLog.clothingItemIdsSnapshot.length} 件`)
                      .fontSize(12)
                      .fontColor(AppTheme.color.primary)
                  }
                }
                .width('100%')
                .padding(8)
                .borderRadius(AppTheme.radius.lg)
                .backgroundColor(AppTheme.color.surfaceRaised)
              }
            }, (wearLog: WearLog) => wearLog.id)
          }
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(12)
        .width('100%')
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 18, bottom: 92 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.color.surfaceMuted)
    }
  }
}
