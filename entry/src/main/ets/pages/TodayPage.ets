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
  @State private isRefreshing: boolean = false;
  @State private errorMessage: string = '';
  @State private selectedHomeTabIndex: number = 0;

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

  private onRefresh(): void {
    if (this.isRefreshing || this.loading) {
      return;
    }
    this.isRefreshing = true;
    this.loadToday().then(() => {
      this.isRefreshing = false;
    }).catch(() => {
      this.isRefreshing = false;
    });
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
      Column() {
        this.TopNavBar()
        Column() {
          this.TabWardrobe()
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.color.surface)
    }
  }

  @Builder
  TopNavBar() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Text('☰')
            .fontSize(24)
            .fontColor(AppTheme.color.text)
        }
        .width(44)
        .height(44)

        Row({ space: 24 }) {
          this.HomeTopTab(0, '推荐')
          this.HomeTopTab(1, '今日')
          this.HomeTopTab(2, '灵感')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 18, height: 18 })
            .fill('#00000000')
            .stroke(AppTheme.color.text)
            .strokeWidth(2.4)
          Line()
            .startPoint([1, 1])
            .endPoint([11, 11])
            .stroke(AppTheme.color.text)
            .strokeWidth(2.4)
            .margin({ left: 7, top: 7 })
        }
        .width(44)
        .height(44)
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)

      Divider()
        .color(AppTheme.color.border)
        .strokeWidth(0.5)
    }
    .width('100%')
  }

  @Builder
  HomeTopTab(index: number, title: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(this.selectedHomeTabIndex === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selectedHomeTabIndex === index ? AppTheme.color.primaryStrong : AppTheme.color.textMuted)
        .lineHeight(22)
        .margin({ top: 14, bottom: 6 })

      Divider()
        .width(36)
        .strokeWidth(3)
        .color(AppTheme.color.primary)
        .opacity(this.selectedHomeTabIndex === index ? 1 : 0)
    }
    .height(52)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.selectedHomeTabIndex = index;
    })
  }

  @Builder
  TabWardrobe() {
    Column() {
      this.TipBar()

      if (this.errorMessage.length > 0) {
        Row({ space: 8 }) {
          Text(`error / ${this.errorMessage}`)
            .fontSize(14)
            .fontColor(AppTheme.color.danger)
            .layoutWeight(1)
          Button('retry')
            .height(34)
            .fontSize(13)
            .onClick(() => { this.retry(); })
        }
        .width('100%')
        .margin({ top: 12 })
      }

      Refresh({ refreshing: this.isRefreshing }) {
        this.WaterFlowContent()
      }
      .layoutWeight(1)
      .onStateChange((state: RefreshStatus) => {
        if (state === RefreshStatus.Refresh) {
          this.onRefresh();
        }
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 10, right: 10, top: 2, bottom: 92 })
    .backgroundColor(AppTheme.color.surface)
  }

  @Builder
  TabDiscover() {
    Column() {
      Row() { Text('发现页').fontSize(20).fontWeight(FontWeight.Bold) }
        .width('100%').justifyContent(FlexAlign.Center).height('100%')
    }
    .width('100%').height('100%').backgroundColor(AppTheme.color.surface)
  }

  @Builder
  TabAdd() {
    Column() {
      Row() { Text('发布内容').fontSize(20).fontWeight(FontWeight.Bold) }
        .width('100%').justifyContent(FlexAlign.Center).height('100%')
    }
    .width('100%').height('100%').backgroundColor(AppTheme.color.surface)
  }

  @Builder
  TabMessage() {
    Column() {
      Row() { Text('消息页').fontSize(20).fontWeight(FontWeight.Bold) }
        .width('100%').justifyContent(FlexAlign.Center).height('100%')
    }
    .width('100%').height('100%').backgroundColor(AppTheme.color.surface)
  }

  @Builder
  TabProfile() {
    Column() {
      Row() { Text('个人中心').fontSize(20).fontWeight(FontWeight.Bold) }
        .width('100%').justifyContent(FlexAlign.Center).height('100%')
    }
    .width('100%').height('100%').backgroundColor(AppTheme.color.surface)
  }

  @Builder
  TipBar() {
    Row({ space: 8 }) {
      Text('今')
        .width(22).height(22).fontSize(12)
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
    .margin({ top: 6 })
    .onClick(() => { this.recordToday(); })
  }

  @Builder
  WaterFlowContent() {
    WaterFlow() {
      ForEach(this.buildAllItems(), (item: CardItem) => {
        FlowItem() {
          this.CardView(item)
        }
      }, (item: CardItem) => item.id)
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(8)
    .rowsGap(10)
    .padding({ top: 8, bottom: 10 })
    .width('100%')
    .scrollBar(BarState.Off)
  }

  private buildAllItems(): CardItem[] {
    const items: CardItem[] = [];
    let id = 0;

    if (this.selectedHomeTabIndex !== 2) {
      items.push({
        id: '' + id++,
        type: 'today',
        photoUri: this.todaysWearLog !== undefined && this.firstWearLogPhotoUri(this.todaysWearLog) !== ''
          ? this.firstWearLogPhotoUri(this.todaysWearLog) : '',
        placeholder: this.todaysWearLog === undefined ? '衣' : '',
        aspectRatio: 0.8,
        title: this.todaysWearLog === undefined ? '记录一次今日搭配' : this.todaysWearLog.outfitTitleSnapshot,
        subtitle: this.todaysWearLog === undefined ? '穿搭灵感' : (this.todaysWearLog.placeText ?? '今日记录'),
        metaText: '♡',
        metaColor: AppTheme.color.accent,
        iconText: '衣'
      });
    }

    if (this.selectedHomeTabIndex !== 1) {
      if (this.recentOutfits.length === 0) {
        items.push({
          id: '' + id++,
          type: 'outfit-empty',
          photoUri: '',
          placeholder: '搭',
          aspectRatio: 1.2,
          title: '创建套装后，这里会像灵感流一样展示。',
          subtitle: '衣橱灵感',
          metaText: '♡ 0',
          metaColor: AppTheme.color.textMuted,
          iconText: '搭'
        });
      } else {
        const len = this.recentOutfits.length;
        for (let i = 0; i < len; i++) {
          const o = this.recentOutfits[i];
          const photo = this.firstOutfitPhotoUri(o);
          items.push({
            id: 'o' + i,
            type: 'outfit',
            photoUri: photo,
            placeholder: photo === '' ? '套装' : '',
            aspectRatio: photo === '' ? 1.2 : 1.0 + ((i % 3) * 0.2),
            title: o.title,
            subtitle: '衣橱灵感',
            metaText: `${o.clothingItemIds.length} 件`,
            metaColor: AppTheme.color.primary,
            iconText: '搭',
            sourceId: o.id
          });
        }
      }
    }

    if (this.selectedHomeTabIndex !== 2) {
      if (this.recentWearLogs.length === 0) {
        items.push({
          id: '' + id++,
          type: 'wearlog-empty',
          photoUri: '',
          placeholder: '记',
          aspectRatio: 1.5,
          title: '穿搭记录会按时间出现在这里。',
          subtitle: '今日记录',
          metaText: '♡ 0',
          metaColor: AppTheme.color.textMuted,
          iconText: '今'
        });
      } else {
        const len = this.recentWearLogs.length;
        for (let i = 0; i < len; i++) {
          const w = this.recentWearLogs[i];
          const photo = this.firstWearLogPhotoUri(w);
          items.push({
            id: 'w' + i,
            type: 'wearlog',
            photoUri: photo,
            placeholder: photo === '' ? '最近穿过' : '',
            aspectRatio: photo === '' ? 1.5 : 1.25,
            title: w.outfitTitleSnapshot,
            subtitle: w.wornDate,
            metaText: `${w.clothingItemIdsSnapshot.length} 件`,
            metaColor: AppTheme.color.primary,
            iconText: '今'
          });
        }
      }
    }

    return items;
  }

  @Builder
  CardView(item: CardItem) {
    Column({ space: 0 }) {
      if (item.photoUri.length > 0) {
        Image(item.photoUri)
          .width('100%')
          .aspectRatio(item.aspectRatio)
          .objectFit(ImageFit.Cover)
          .backgroundColor(AppTheme.color.surfaceMuted)
          .borderRadius({ topLeft: 10, topRight: 10 })
      } else {
        Column({ space: 6 }) {
          Text(item.placeholder)
            .fontSize(28).fontWeight(FontWeight.Bold).fontColor(AppTheme.color.primary)
          Text(item.title)
            .fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppTheme.color.text)
            .textAlign(TextAlign.Center).maxLines(2)
        }
        .width('100%')
        .aspectRatio(item.aspectRatio)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(AppTheme.color.primarySoft)
        .borderRadius({ topLeft: 10, topRight: 10 })
      }

      Column({ space: 6 }) {
        if (item.photoUri.length > 0) {
          Text(item.title)
            .fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppTheme.color.text)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        }

        Row({ space: 6 }) {
          Text(item.iconText)
            .width(20).height(20).fontSize(11)
            .fontWeight(FontWeight.Bold).fontColor(AppTheme.color.primary)
            .textAlign(TextAlign.Center)
            .backgroundColor(AppTheme.color.primarySoft).borderRadius(10)

          Text(item.subtitle)
            .fontSize(12).fontColor(AppTheme.color.textMuted)
            .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.metaText).fontSize(12).fontColor(item.metaColor)
        }
        .width('100%').height(22)
      }
      .padding({ left: 8, right: 8, bottom: 8 })
    }
    .width('100%')
    .backgroundColor(AppTheme.color.surface)
    .borderRadius(10)
    .shadow({ radius: 8, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      if (item.type === 'today') {
        this.recordToday();
      } else if (item.type === 'outfit' && item.sourceId) {
        const outfit = this.recentOutfits.find((o) => o.id === item.sourceId);
        if (outfit) { this.recordToday(outfit); }
      }
    })
  }
}

interface CardItem {
  id: string
  type: 'today' | 'outfit' | 'outfit-empty' | 'wearlog' | 'wearlog-empty'
  photoUri: string
  placeholder: string
  aspectRatio: number
  title: string
  subtitle: string
  metaText: string
  metaColor: string
  iconText: string
  sourceId?: string
}
