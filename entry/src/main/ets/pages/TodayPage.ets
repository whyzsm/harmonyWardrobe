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
      Column({ space: 8 }) {
        Row() {
          Text('☰')
            .width(44)
            .height(44)
            .fontSize(30)
            .fontColor(AppTheme.color.text)
            .textAlign(TextAlign.Center)

          Row({ space: 26 }) {
            Column({ space: 4 }) {
              Text('推荐')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.color.text)

              Column()
                .width(34)
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
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)

          Text('⌕')
            .width(44)
            .height(44)
            .fontSize(34)
            .fontColor(AppTheme.color.text)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(56)
        .alignItems(VerticalAlign.Center)

        Divider()
          .color(AppTheme.color.border)
          .strokeWidth(0.5)

        Row({ space: 8 }) {
          Text('今')
            .width(22)
            .height(22)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.color.primary)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppTheme.color.primarySoft)
            .borderRadius(11)

          Text(this.todaysWearLog === undefined ? '今天穿什么？从最近套装里挑一套' : '今日记录已保存，可以继续补充照片')
            .fontSize(13)
            .fontColor(AppTheme.color.textMuted)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .height(38)
        .padding({ left: 10, right: 10 })
        .backgroundColor(AppTheme.color.surfaceMuted)
        .borderRadius(14)
        .onClick(() => {
          this.recordToday();
        })

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

        Scroll() {
          Grid() {
            GridItem() {
              Column({ space: 7 }) {
                if (this.todaysWearLog !== undefined && this.firstWearLogPhotoUri(this.todaysWearLog).length > 0) {
                  Image(this.firstWearLogPhotoUri(this.todaysWearLog))
                    .width('100%')
                    .height(198)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(10)
                    .border({ width: 1, color: '#1A000000' })
                } else {
                  Column({ space: 8 }) {
                    Text('衣')
                      .fontSize(30)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppTheme.color.primary)

                    Text('今天穿什么？')
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppTheme.color.text)
                  }
                  .width('100%')
                  .height(198)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .backgroundColor(AppTheme.color.primarySoft)
                  .borderRadius(10)
                  .border({ width: 1, color: '#1A000000' })
                }

                Text(this.todaysWearLog === undefined ? '记录一次今日搭配' : this.todaysWearLog.outfitTitleSnapshot)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppTheme.color.text)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Row({ space: 5 }) {
                  Text('衣')
                    .width(20)
                    .height(20)
                    .fontSize(11)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.color.primary)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(AppTheme.color.primarySoft)
                    .borderRadius(10)

                  Text(this.todaysWearLog === undefined ? '穿搭灵感' : (this.todaysWearLog.placeText ?? '今日记录'))
                    .fontSize(12)
                    .fontColor(AppTheme.color.textMuted)
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text('♡')
                    .fontSize(14)
                    .fontColor(AppTheme.color.accent)
                }
                .height(22)
              }
              .width('100%')
              .onClick(() => {
                this.recordToday();
              })
            }

            if (this.recentOutfits.length === 0) {
              GridItem() {
                Column({ space: 7 }) {
                  Column({ space: 8 }) {
                    Text('搭')
                      .fontSize(30)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppTheme.color.primary)

                    Text('从最近套装里挑一套')
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppTheme.color.text)
                      .textAlign(TextAlign.Center)
                  }
                  .width('100%')
                  .height(226)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .backgroundColor(AppTheme.color.primarySoft)
                  .borderRadius(10)
                  .border({ width: 1, color: '#1A000000' })

                  Text('创建套装后，这里会像灵感流一样展示。')
                    .fontSize(14)
                    .fontColor(AppTheme.color.text)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row({ space: 5 }) {
                    Text('搭')
                      .width(20)
                      .height(20)
                      .fontSize(11)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppTheme.color.primary)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(AppTheme.color.primarySoft)
                      .borderRadius(10)

                    Text('衣橱灵感')
                      .fontSize(12)
                      .fontColor(AppTheme.color.textMuted)
                      .layoutWeight(1)

                    Text('♡ 0')
                      .fontSize(12)
                      .fontColor(AppTheme.color.textMuted)
                  }
                  .height(22)
                }
                .width('100%')
              }
            } else {
              ForEach(this.recentOutfits, (outfit: OutfitTemplate) => {
                GridItem() {
                  Column({ space: 7 }) {
                    if (this.firstOutfitPhotoUri(outfit).length > 0) {
                      Image(this.firstOutfitPhotoUri(outfit))
                        .width('100%')
                        .height(226)
                        .objectFit(ImageFit.Cover)
                        .borderRadius(10)
                        .border({ width: 1, color: '#1A000000' })
                    } else {
                      Column() {
                        Text('套装')
                          .fontSize(20)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(AppTheme.color.primary)
                      }
                      .width('100%')
                      .height(226)
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .backgroundColor(AppTheme.color.primarySoft)
                      .borderRadius(10)
                      .border({ width: 1, color: '#1A000000' })
                    }

                    Text(outfit.title)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppTheme.color.text)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Row({ space: 5 }) {
                      Text('搭')
                        .width(20)
                        .height(20)
                        .fontSize(11)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppTheme.color.primary)
                        .textAlign(TextAlign.Center)
                        .backgroundColor(AppTheme.color.primarySoft)
                        .borderRadius(10)

                      Text('衣橱灵感')
                        .fontSize(12)
                        .fontColor(AppTheme.color.textMuted)
                        .layoutWeight(1)

                      Text(`${outfit.clothingItemIds.length} 件`)
                        .fontSize(12)
                        .fontColor(AppTheme.color.primary)
                    }
                    .height(22)
                  }
                  .width('100%')
                  .onClick(() => {
                    this.recordToday(outfit);
                  })
                }
              }, (outfit: OutfitTemplate) => outfit.id)
            }

            if (this.recentWearLogs.length === 0) {
              GridItem() {
                Column({ space: 7 }) {
                  Column({ space: 8 }) {
                    Text('记')
                      .fontSize(30)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppTheme.color.primary)

                    Text('最近穿过')
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppTheme.color.text)
                  }
                  .width('100%')
                  .height(176)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .backgroundColor(AppTheme.color.primarySoft)
                  .borderRadius(10)
                  .border({ width: 1, color: '#1A000000' })

                  Text('穿搭记录会按时间出现在这里。')
                    .fontSize(14)
                    .fontColor(AppTheme.color.text)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row({ space: 5 }) {
                    Text('今')
                      .width(20)
                      .height(20)
                      .fontSize(11)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppTheme.color.primary)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(AppTheme.color.primarySoft)
                      .borderRadius(10)

                    Text('今日记录')
                      .fontSize(12)
                      .fontColor(AppTheme.color.textMuted)
                      .layoutWeight(1)

                    Text('♡ 0')
                      .fontSize(12)
                      .fontColor(AppTheme.color.textMuted)
                  }
                  .height(22)
                }
                .width('100%')
              }
            } else {
              ForEach(this.recentWearLogs, (wearLog: WearLog) => {
                GridItem() {
                  Column({ space: 7 }) {
                    if (this.firstWearLogPhotoUri(wearLog).length > 0) {
                      Image(this.firstWearLogPhotoUri(wearLog))
                        .width('100%')
                        .height(176)
                        .objectFit(ImageFit.Cover)
                        .borderRadius(10)
                        .border({ width: 1, color: '#1A000000' })
                    } else {
                      Column() {
                        Text('最近穿过')
                          .fontSize(18)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(AppTheme.color.primary)
                      }
                      .width('100%')
                      .height(176)
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .backgroundColor(AppTheme.color.primarySoft)
                      .borderRadius(10)
                      .border({ width: 1, color: '#1A000000' })
                    }

                    Text(wearLog.outfitTitleSnapshot)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppTheme.color.text)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Row({ space: 5 }) {
                      Text('今')
                        .width(20)
                        .height(20)
                        .fontSize(11)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(AppTheme.color.primary)
                        .textAlign(TextAlign.Center)
                        .backgroundColor(AppTheme.color.primarySoft)
                        .borderRadius(10)

                      Text(wearLog.wornDate)
                        .fontSize(12)
                        .fontColor(AppTheme.color.textMuted)
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text(`${wearLog.clothingItemIdsSnapshot.length} 件`)
                        .fontSize(12)
                        .fontColor(AppTheme.color.primary)
                    }
                    .height(22)
                  }
                  .width('100%')
                }
              }, (wearLog: WearLog) => wearLog.id)
            }
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(8)
          .rowsGap(12)
          .padding({ bottom: 92 })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 10, right: 10, top: 2 })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(AppTheme.color.surface)
    }
  }
}
