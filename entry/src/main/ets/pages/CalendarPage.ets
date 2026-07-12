import { EmptyState } from '../components/EmptyState';
import { MonthCalendar } from '../components/MonthCalendar';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { AppTheme } from '../theme/Tokens';
import { monthKey, toIsoDate } from '../utils/date';
import { WearLogEditPage } from './WearLogEditPage';

@Component
export struct CalendarPage {
  outfitRepository?: OutfitRepository = undefined;
  wearLogRepository?: WearLogRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;

  @State private currentMonth: string = monthKey(new Date());
  @State private selectedDate: string = toIsoDate(new Date());
  @State private markedDates: string[] = [];
  @State private selectedDateLogs: WearLog[] = [];
  @State private outfits: OutfitTemplate[] = [];
  @State private editingWearLogId: string = '';
  @State private showWearLogEditor: boolean = false;
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadCalendar();
  }

  private async loadCalendar(): Promise<void> {
    if (this.wearLogRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      if (this.outfitRepository !== undefined) {
        this.outfits = await this.outfitRepository.listOutfits();
      }
      await this.loadMonthMarkers();
      await this.loadSelectedDateLogs();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载日历失败';
    } finally {
      this.loading = false;
    }
  }

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
    this.showWearLogEditor = true;
  }

  private editWearLog(wearLog: WearLog): void {
    this.editingWearLogId = wearLog.id;
    this.showWearLogEditor = true;
  }

  private editingWearLog(): WearLog | undefined {
    if (this.editingWearLogId.length === 0) {
      return undefined;
    }

    for (const wearLog of this.selectedDateLogs) {
      if (wearLog.id === this.editingWearLogId) {
        return wearLog;
      }
    }

    return undefined;
  }

  private closeWearLogEditor(): void {
    this.showWearLogEditor = false;
    this.editingWearLogId = '';
  }

  private retry(): void {
    this.loadCalendar();
  }

  build() {
    if (this.showWearLogEditor) {
      WearLogEditPage({
        initialWearLog: this.editingWearLog(),
        outfits: this.outfits,
        wearLogRepository: this.wearLogRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (_wearLog: WearLog) => {
          this.closeWearLogEditor();
          this.loadCalendar();
        },
        onCancel: () => {
          this.closeWearLogEditor();
        }
      })
    } else {
      Scroll() {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 4 }) {
            Text('日历')
              .fontSize(30)
              .fontWeight(FontWeight.Regular)
              .fontColor(AppTheme.color.text)

            Text('按日期回看穿搭、地点和照片记录。')
              .fontSize(15)
              .fontColor(AppTheme.color.textMuted)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('补录穿着')
            .height(40)
            .fontSize(14)
            .fontColor(AppTheme.color.surface)
            .backgroundColor(AppTheme.color.primary)
            .borderRadius(AppTheme.radius.md)
            .onClick(() => {
              this.startBackfillWearLog();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.loading) {
          Text('loading / 正在加载日历...')
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

        Column({ space: 12 }) {
          Text(this.currentMonth)
            .fontSize(18)
            .fontWeight(FontWeight.Regular)
            .fontColor(AppTheme.color.text)

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
        .borderRadius(AppTheme.radius.lg)
        .backgroundColor(AppTheme.color.surfaceRaised)
        .border({ width: 1, color: AppTheme.color.border })
        .alignItems(HorizontalAlign.Start)

        Text(`${this.selectedDate} 记录`)
          .fontSize(18)
          .fontWeight(FontWeight.Regular)
          .fontColor(AppTheme.color.text)

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
                  .fontWeight(FontWeight.Regular)
                  .fontColor(AppTheme.color.text)

                Text(wearLog.placeText ?? '未记录地点')
                  .fontSize(13)
                  .fontColor(AppTheme.color.textMuted)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Button('编辑')
                .height(34)
                .fontSize(13)
                .fontColor(AppTheme.color.primary)
                .backgroundColor(AppTheme.color.surface)
                .borderRadius(AppTheme.radius.md)
                .border({ width: 1, color: AppTheme.color.primary })
                .onClick(() => {
                  this.editWearLog(wearLog);
                })
            }
            .width('100%')
            .padding(12)
            .borderRadius(AppTheme.radius.lg)
            .backgroundColor(AppTheme.color.surfaceRaised)
            .border({ width: 1, color: AppTheme.color.border })
          }, (wearLog: WearLog) => wearLog.id)
        }
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.color.surfaceMuted)
    }
  }
}
