import { EmptyState } from '../components/EmptyState';
import { MonthCalendar } from '../components/MonthCalendar';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { monthKey, toIsoDate } from '../utils/date';

@Component
export struct CalendarPage {
  @State private currentMonth: string = monthKey(new Date());
  @State private selectedDate: string = toIsoDate(new Date());
  @State private markedDates: string[] = [];
  @State private selectedDateLogs: WearLog[] = [];
  @State private editingWearLogId: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  private wearLogRepository?: WearLogRepository = undefined;

  private async loadMonthMarkers(): Promise<void> {
    if (this.wearLogRepository === undefined) {
      return;
    }

    this.markedDates = await this.wearLogRepository.listWearLogDatesForMonth(this.currentMonth);
  }

  private async loadSelectedDateLogs(): Promise<void> {
    if (this.wearLogRepository === undefined) {
      return;
    }

    this.selectedDateLogs = await this.wearLogRepository.listWearLogsByDate(this.selectedDate);
  }

  private selectDate(date: string): void {
    this.selectedDate = date;
    this.loadSelectedDateLogs();
  }

  private startBackfillWearLog(): void {
    this.editingWearLogId = '';
  }

  private editWearLog(wearLog: WearLog): void {
    this.editingWearLogId = wearLog.id;
  }

  private retry(): void {
    this.loading = false;
    this.errorMessage = '';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 4 }) {
            Text('日历')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')

            Text('按日期回看穿搭、地点和照片记录。')
              .fontSize(15)
              .fontColor('#475569')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('补录穿着')
            .height(40)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#0F172A')
            .borderRadius(8)
            .onClick(() => {
              this.startBackfillWearLog();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.loading) {
          Text('loading / 正在加载日历...')
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

        Column({ space: 12 }) {
          Text(this.currentMonth)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2937')

          MonthCalendar({
            month: this.currentMonth,
            markedDates: this.markedDates,
            selectedDate: this.selectedDate,
            onSelectDate: (date: string) => {
              this.selectDate(date);
            }
          })
        }
        .width('100%')
        .padding(12)
        .borderRadius(8)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#E2E8F0' })
        .alignItems(HorizontalAlign.Start)

        Text(`${this.selectedDate} 记录`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')

        if (this.selectedDateLogs.length === 0) {
          EmptyState({
            title: '当天没有穿着记录',
            description: '可以补录穿着，回看当天穿过的套装、地点和照片。'
          })
        } else {
          ForEach(this.selectedDateLogs, (wearLog: WearLog) => {
            Row() {
              Column({ space: 4 }) {
                Text(wearLog.outfitTitleSnapshot)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111827')

                Text(wearLog.placeText ?? '未记录地点')
                  .fontSize(13)
                  .fontColor('#64748B')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Button('编辑')
                .height(34)
                .fontSize(13)
                .fontColor('#0F172A')
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .border({ width: 1, color: '#CBD5E1' })
                .onClick(() => {
                  this.editWearLog(wearLog);
                })
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
