import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';

interface CalendarDay {
  key: string;
  date: string;
  dayNumber: string;
  inMonth: boolean;
  marked: boolean;
}

function pad2(value: number): string {
  return `${value}`.padStart(2, '0');
}

function dateKey(year: number, month: number, day: number): string {
  return `${year}-${pad2(month)}-${pad2(day)}`;
}

function hasMarkedDate(markedDates: string[], date: string): boolean {
  return markedDates.includes(date);
}

function parseMonth(month: string): Date {
  const parts = month.split('-');
  const year = Number(parts[0]);
  const monthNumber = Number(parts[1]);
  if (!Number.isFinite(year) || !Number.isFinite(monthNumber) || monthNumber < 1 || monthNumber > 12) {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1);
  }

  return new Date(year, monthNumber - 1, 1);
}

function buildCalendarDays(month: string, markedDates: string[]): CalendarDay[] {
  const firstDay = parseMonth(month);
  const year = firstDay.getFullYear();
  const monthNumber = firstDay.getMonth() + 1;
  const leadingDays = firstDay.getDay();
  const daysInMonth = new Date(year, monthNumber, 0).getDate();
  const days: CalendarDay[] = [];

  for (let index = 0; index < leadingDays; index += 1) {
    days.push({
      key: `leading-${index}`,
      date: '',
      dayNumber: '',
      inMonth: false,
      marked: false
    });
  }

  for (let day = 1; day <= daysInMonth; day += 1) {
    const date = dateKey(year, monthNumber, day);
    days.push({
      key: date,
      date,
      dayNumber: `${day}`,
      inMonth: true,
      marked: hasMarkedDate(markedDates, date)
    });
  }

  while (days.length % 7 !== 0) {
    days.push({
      key: `trailing-${days.length}`,
      date: '',
      dayNumber: '',
      inMonth: false,
      marked: false
    });
  }

  return days;
}

@Component
export struct MonthCalendar {
  @Prop month: string = '';
  @Prop markedDates: string[] = [];
  @Prop selectedDate: string = '';
  onChangeMonth: (month: string) => void = (_month: string) => {};
  onSelectDate: (date: string) => void = () => {};

  private adjacentMonth(offset: number): string {
    const current = parseMonth(this.month);
    const base = new Date(current.getFullYear(), current.getMonth() + offset, 1);
    return `${base.getFullYear()}-${pad2(base.getMonth() + 1)}`;
  }

  build() {
    Column({ space: 10 }) {
      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(18)
            .fontColor([YibuqueColor.textPrimary])
        }
        .width(44)
        .height(44)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.full)
        .onClick(() => {
          this.onChangeMonth(this.adjacentMonth(-1));
        })

        Text(this.month)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)

        Button() {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(18)
            .fontColor([YibuqueColor.textPrimary])
        }
        .width(44)
        .height(44)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.full)
        .onClick(() => {
          this.onChangeMonth(this.adjacentMonth(1));
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Grid() {
        ForEach(buildCalendarDays(this.month, this.markedDates), (day: CalendarDay) => {
          GridItem() {
            Column({ space: 4 }) {
              Text(day.dayNumber)
                .fontSize(14)
                .fontColor(day.date === this.selectedDate ? YibuqueColor.textInverse : YibuqueColor.textPrimary)

              if (day.marked) {
                Text('•')
                  .fontSize(6)
                  .fontColor(day.date === this.selectedDate ? YibuqueColor.textInverse : YibuqueColor.actionBlack)
              }
            }
            .width('100%')
            .height(44)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .borderRadius(YibuqueRadius.md)
            .backgroundColor(day.date === this.selectedDate ? YibuqueColor.actionBlack : YibuqueColor.cardWhite)
            .border({ width: 1, color: day.marked || day.date === this.selectedDate ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
            .onClick(() => {
              if (day.inMonth) {
                this.onSelectDate(day.date);
              }
            })
          }
        }, (day: CalendarDay) => day.key)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .columnsGap(6)
      .rowsGap(6)
      .width('100%')
    }
    .width('100%')
  }
}
