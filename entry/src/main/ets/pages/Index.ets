import { TodayPage } from './TodayPage';
import { WardrobePage } from './WardrobePage';
import { OutfitsPage } from './OutfitsPage';
import { CalendarPage } from './CalendarPage';
import { ShoppingPage } from './ShoppingPage';
import { AppTheme } from '../theme/Tokens';

@Entry
@Component
struct Index {
  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        TodayPage()
      }
      .tabBar('今日')

      TabContent() {
        WardrobePage()
      }
      .tabBar('衣橱')

      TabContent() {
        OutfitsPage()
      }
      .tabBar('套装')

      TabContent() {
        CalendarPage()
      }
      .tabBar('日历')

      TabContent() {
        ShoppingPage()
      }
      .tabBar('逛街')
    }
    .width('100%')
    .height('100%')
    .barMode(BarMode.Fixed)
    .backgroundColor(AppTheme.color.surfaceMuted)
  }
}
