import { EmptyState } from '../components/EmptyState';
import { OutfitCard } from '../components/OutfitCard';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
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
      Column({ space: 16 }) {
        Column({ space: 4 }) {
          Text('今天')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')

          Text(this.todayIsoDate)
            .fontSize(15)
            .fontColor('#475569')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (this.loading) {
          Text('loading / 正在加载今日穿搭...')
            .fontSize(14)
            .fontColor('#64748B')
        }

        if (this.errorMessage.length > 0) {
          Row({ space: 8 }) {
            Text(`error / ${this.errorMessage}`)
              .fontSize(14)
              .fontColor('#B91C1C')
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

        if (this.todaysWearLog === undefined) {
          EmptyState({
            title: '今天还没有穿搭记录',
            description: '选择套装记录今天，也可以稍后补照片、地点和备注。'
          })
        } else {
          Column({ space: 8 }) {
            Text('今日穿搭')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2937')

            if (this.firstWearLogPhotoUri(this.todaysWearLog).length > 0) {
              Image(this.firstWearLogPhotoUri(this.todaysWearLog))
                .width('100%')
                .height(180)
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
            }

            Text(this.todaysWearLog.outfitTitleSnapshot)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')

            Text(this.todaysWearLog.placeText ?? '未记录地点')
              .fontSize(14)
              .fontColor('#64748B')
          }
          .width('100%')
          .padding(14)
          .borderRadius(8)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E2E8F0' })
          .alignItems(HorizontalAlign.Start)
        }

        Text('最近套装')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')

        if (this.recentOutfits.length === 0) {
          EmptyState({
            title: '暂无最近套装',
            description: '创建套装后，可以从这里快速记录今天。'
          })
        } else {
          Grid() {
            ForEach(this.recentOutfits, (outfit: OutfitTemplate) => {
              GridItem() {
                Column({ space: 8 }) {
                  OutfitCard({
                    title: outfit.title,
                    itemCount: outfit.clothingItemIds.length,
                    photoUri: this.firstOutfitPhotoUri(outfit)
                  })

                  Button('选择套装记录今天')
                    .height(36)
                    .width('100%')
                    .fontSize(13)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#0F172A')
                    .borderRadius(8)
                    .onClick(() => {
                      this.recordToday(outfit);
                    })
                }
              }
            }, (outfit: OutfitTemplate) => outfit.id)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .width('100%')
        }

        Text('最近记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')

        if (this.recentWearLogs.length === 0) {
          EmptyState({
            title: '暂无穿着记录',
            description: '记录后会按时间显示最近穿过的套装。'
          })
        } else {
          ForEach(this.recentWearLogs, (wearLog: WearLog) => {
            Row() {
              Column({ space: 4 }) {
                Text(wearLog.outfitTitleSnapshot)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111827')

                Text(`${wearLog.wornDate} ${wearLog.placeText ?? ''}`)
                  .fontSize(13)
                  .fontColor('#64748B')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Text(`${wearLog.clothingItemIdsSnapshot.length} 件`)
                .fontSize(13)
                .fontColor('#64748B')
            }
            .width('100%')
            .padding(12)
            .borderRadius(8)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#E2E8F0' })
          }, (wearLog: WearLog) => wearLog.id)
        }
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8FAFC')
    }
  }
}
