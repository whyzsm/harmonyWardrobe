import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';
import { ArrayDataSource } from '../utils/ArrayDataSource';
import { OutfitEditPage } from './OutfitEditPage';
import { WearLogEditPage } from './WearLogEditPage';

interface OutfitSceneFilter {
  label: string;
  keywords?: string[];
}

const OUTFIT_SCENE_FILTERS: OutfitSceneFilter[] = [
  { label: '全部' },
  { label: '逛街', keywords: ['逛街', '逛店', '试衣', '购物'] },
  { label: '周末', keywords: ['周末', '休闲', '轻便', '出游'] },
  { label: '通勤', keywords: ['通勤', '上班', '工作', '职场'] }
];

const ERROR = YibuqueColor.danger;
const ERROR_BG = YibuqueColor.cardSoftGray;
const RECORD_WEAR_ACCESSIBILITY_TEXT = '记录一次穿着';
function emptyWearLog(): WearLog {
  return {
    id: '',
    outfitTemplateId: undefined,
    outfitTitleSnapshot: '',
    clothingItemIdsSnapshot: [],
    wornDate: '',
    photoUris: [],
    placeText: undefined,
    note: undefined,
    createdAt: '',
    updatedAt: ''
  };
}

@Component
export struct OutfitsPage {
  @Prop initialOutfitId: string = '';
  @Prop @Watch('onInitialWearLogIdChange') initialWearLogId: string = '';
  outfitRepository?: OutfitRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  wearLogRepository?: WearLogRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onNestedPageVisibilityChange: (visible: boolean) => void = () => {};

  @State private selectedFilterLabel: string = '全部';
  @State private outfits: OutfitTemplate[] = [];
  @State private outfitDataSource: ArrayDataSource<OutfitTemplate> = new ArrayDataSource<OutfitTemplate>();
  @State private clothingItems: ClothingItem[] = [];
  @State private selectedOutfitId: string = '';
  @State private selectedWearLogId: string = '';
  @State private selectedWearLog: WearLog = emptyWearLog();
  @State private showOutfitEditor: boolean = false;
  @State private showWearLogEditor: boolean = false;
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private pressedOutfitCardId: string = '';

  aboutToAppear(): void {
    this.loadOutfits();
  }

  aboutToDisappear(): void {
    this.onNestedPageVisibilityChange(false);
  }

  private async loadOutfits(): Promise<void> {
    if (this.outfitRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.outfits = await this.outfitRepository.listOutfits();
      this.refreshOutfitDataSource();
      if (this.clothingRepository !== undefined) {
        this.clothingItems = await this.clothingRepository.listClothing();
      }
      if (this.initialOutfitId.length > 0) {
        for (const outfit of this.outfits) {
          if (outfit.id === this.initialOutfitId) {
            this.onEditOutfit(outfit);
            break;
          }
        }
      }
      if (this.initialWearLogId.length > 0) {
        await this.openWearLogById(this.initialWearLogId);
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载套装失败';
    } finally {
      this.loading = false;
    }
  }

  private selectedSceneFilter(): OutfitSceneFilter | undefined {
    for (const filter of OUTFIT_SCENE_FILTERS) {
      if (filter.label === this.selectedFilterLabel) {
        return filter;
      }
    }

    return undefined;
  }

  private filterOutfits(): OutfitTemplate[] {
    const selectedFilter = this.selectedSceneFilter();

    return this.outfits.filter((outfit: OutfitTemplate) => {
      const searchableText = `${outfit.title} ${outfit.note ?? ''}`.toLowerCase();
      if (selectedFilter?.keywords === undefined) {
        return true;
      }

      for (const keyword of selectedFilter.keywords) {
        if (searchableText.includes(keyword)) {
          return true;
        }
      }

      return false;
    });
  }

  private refreshOutfitDataSource(): void {
    this.outfitDataSource.setData(this.filterOutfits());
  }

  private photoUriAt(outfit: OutfitTemplate, slot: number): string {
    return outfit.photoUris.length > slot ? outfit.photoUris[slot] : '';
  }

  private outfitStackAspectRatio(index: number): number {
    return index % 4 === 2 ? 1 / 1.18 : 1 / 1.48;
  }

  private outfitTopMargin(index: number): number {
    return index > 1 && index % 4 === 3 ? 6 : 0;
  }

  private outfitSceneLabel(outfit: OutfitTemplate): string {
    const searchableText = `${outfit.title} ${outfit.note ?? ''}`.toLowerCase();
    for (const filter of OUTFIT_SCENE_FILTERS) {
      if (filter.keywords === undefined) {
        continue;
      }

      for (const keyword of filter.keywords) {
        if (searchableText.includes(keyword)) {
          return filter.label;
        }
      }
    }

    return '日常';
  }

  private outfitMeta(outfit: OutfitTemplate): string {
    const note = outfit.note?.trim() ?? '';
    const detail = note.length > 0 ? note : `${outfit.clothingItemIds.length} 件单品`;
    return `${this.outfitSceneLabel(outfit)} · ${detail}`;
  }

  private selectedOutfit(): OutfitTemplate | undefined {
    if (this.selectedOutfitId.length === 0) {
      return undefined;
    }

    for (const outfit of this.outfits) {
      if (outfit.id === this.selectedOutfitId) {
        return outfit;
      }
    }

    return undefined;
  }

  private selectedWearLogForEditor(): WearLog | undefined {
    return this.selectedWearLogId.length > 0 ? this.selectedWearLog : undefined;
  }

  private onInitialWearLogIdChange(): void {
    if (this.initialWearLogId.length > 0) {
      this.openWearLogById(this.initialWearLogId);
    }
  }

  private async openWearLogById(wearLogId: string): Promise<void> {
    if (this.wearLogRepository === undefined) {
      return;
    }

    const wearLog = await this.wearLogRepository.getWearLogById(wearLogId);
    if (wearLog === undefined) {
      return;
    }

    this.selectedWearLog = wearLog;
    this.selectedWearLogId = wearLog.id;
    this.selectedOutfitId = wearLog.outfitTemplateId ?? '';
    this.showWearLogEditor = true;
    this.onNestedPageVisibilityChange(true);
  }

  private onEditOutfit(outfit: OutfitTemplate): void {
    this.selectedOutfitId = outfit.id;
    this.showOutfitEditor = true;
    this.onNestedPageVisibilityChange(true);
  }

  private onRecordWear(outfit?: OutfitTemplate): void {
    this.selectedWearLog = emptyWearLog();
    this.selectedWearLogId = '';
    this.selectedOutfitId = outfit?.id ?? '';
    this.showWearLogEditor = true;
    this.onNestedPageVisibilityChange(true);
  }

  private upsertOutfit(savedOutfit: OutfitTemplate): void {
    const nextOutfits: OutfitTemplate[] = [];
    let replaced = false;

    for (const outfit of this.outfits) {
      if (outfit.id === savedOutfit.id) {
        nextOutfits.push(savedOutfit);
        replaced = true;
      } else {
        nextOutfits.push(outfit);
      }
    }

    if (!replaced) {
      nextOutfits.unshift(savedOutfit);
    }

    this.outfits = nextOutfits;
    this.refreshOutfitDataSource();
  }

  private async deleteOutfit(outfit: OutfitTemplate): Promise<void> {
    if (this.outfitRepository === undefined) {
      throw new Error('美搭仓库不可用，请稍后重试');
    }

    await this.outfitRepository.deleteOutfit(outfit.id);
    this.outfits = this.outfits.filter((existingOutfit: OutfitTemplate) => existingOutfit.id !== outfit.id);
    this.refreshOutfitDataSource();
    this.closeOutfitEditor();
  }

  private async deleteWearLog(wearLog: WearLog): Promise<void> {
    if (this.wearLogRepository === undefined) {
      throw new Error('穿着记录仓库不可用，请稍后重试');
    }

    await this.wearLogRepository.deleteWearLog(wearLog.id);
    this.closeWearLogEditor();
  }

  private closeOutfitEditor(): void {
    this.showOutfitEditor = false;
    this.selectedOutfitId = '';
    this.onNestedPageVisibilityChange(false);
  }

  private closeWearLogEditor(): void {
    this.showWearLogEditor = false;
    this.selectedWearLog = emptyWearLog();
    this.selectedWearLogId = '';
    this.selectedOutfitId = '';
    this.onNestedPageVisibilityChange(false);
  }

  private retry(): void {
    this.loadOutfits();
  }

  build() {
    if (this.showOutfitEditor) {
      OutfitEditPage({
        initialOutfit: this.selectedOutfit(),
        clothingItems: this.clothingItems,
        outfitRepository: this.outfitRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (outfit: OutfitTemplate) => {
          this.upsertOutfit(outfit);
          this.closeOutfitEditor();
        },
        onDelete: async (outfit: OutfitTemplate): Promise<void> => {
          await this.deleteOutfit(outfit);
        },
        onCancel: () => {
          this.closeOutfitEditor();
        }
      })
    } else if (this.showWearLogEditor) {
      WearLogEditPage({
        initialWearLog: this.selectedWearLogForEditor(),
        initialOutfitTemplateId: this.selectedOutfitId,
        outfits: this.outfits,
        wearLogRepository: this.wearLogRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (_wearLog: WearLog) => {
          this.closeWearLogEditor();
        },
        onDelete: async (wearLog: WearLog): Promise<void> => {
          await this.deleteWearLog(wearLog);
        },
        onCancel: () => {
          this.closeWearLogEditor();
        }
      })
    } else {
      Column({ space: 0 }) {
        this.FilterStrip()
        this.OutfitGuideCard()

        if (this.loading) {
          Column({ space: 10 }) {
            LoadingProgress()
              .width(22)
              .height(22)
              .color(YibuqueColor.textPrimary)

            Text('正在加载套装...')
              .fontSize(14)
              .fontColor(YibuqueColor.textSecondary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.errorMessage.length > 0) {
          Column({ space: 12 }) {
            Row({ space: 10 }) {
              Text(this.errorMessage)
                .fontSize(14)
                .fontColor(ERROR)
                .layoutWeight(1)
                .maxLines(3)

              Button('重试')
                .height(36)
                .fontSize(13)
                .fontColor(YibuqueColor.textInverse)
                .backgroundColor(ERROR)
                .borderRadius(YibuqueRadius.xxl)
                .onClick(() => {
                  this.retry();
                })
            }
            .width('100%')
            .padding(14)
            .backgroundColor(ERROR_BG)
            .borderRadius(YibuqueRadius.md)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20 })
          .justifyContent(FlexAlign.Center)
        } else if (this.outfits.length === 0) {
          Column({ space: 14 }) {
            this.OutfitEmptyState('还没有套装',
              '拍照或从相册选图后，按分类收进套装。',
              '点底部相机，选择照片后归类为套装',
              '套装会按图片组合流排在这里。')
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20 })
          .justifyContent(FlexAlign.Start)
        } else if (this.filterOutfits().length === 0) {
          Column({ space: 14 }) {
            this.OutfitEmptyState('暂时没有这类套装',
              '当前场景下还没有匹配的套装。',
              '换一个场景看看，或查看全部套装',
              '已有套装会继续按图片组合流排在这里。')

            Button('查看全部')
              .height(44)
              .fontSize(14)
              .fontColor(YibuqueColor.textPrimary)
              .backgroundColor(YibuqueColor.cardSurface)
              .borderRadius(YibuqueRadius.xxxl)
              .onClick(() => {
                this.selectedFilterLabel = '全部';
                this.refreshOutfitDataSource();
              })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20 })
          .justifyContent(FlexAlign.Center)
        } else {
          Grid() {
            LazyForEach(this.outfitDataSource, (outfit: OutfitTemplate, index: number) => {
              GridItem() {
                this.OutfitWallCard(outfit, index)
              }
            }, (outfit: OutfitTemplate) => outfit.id)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(13)
          .rowsGap(18)
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20, bottom: 96 })
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(YibuqueColor.bgDefault)
    }
  }

  @Builder
  OutfitEmptyState(title: string, description: string, guideTitle: string, guideDescription: string) {
    Column({ space: 10 }) {
      Column({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.hanger_and_towels'))
          .fontSize(36)
          .fontColor([YibuqueColor.textPrimary])

        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)

        Text(description)
          .fontSize(13)
          .lineHeight(19)
          .fontColor(YibuqueColor.textSecondary)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(190)
      .padding({ left: 18, right: 18 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: YibuqueColor.borderMedium })

      Text(guideTitle)
        .fontSize(15)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .textAlign(TextAlign.Center)

      Text(guideDescription)
        .fontSize(12)
        .lineHeight(18)
        .fontColor(YibuqueColor.textSecondary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(8)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(YibuqueColor.bgDefault)
    .borderRadius(YibuqueRadius.xxl)
  }

  @Builder
  FilterStrip() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(OUTFIT_SCENE_FILTERS, (filter: OutfitSceneFilter) => {
          Row({ space: 7 }) {
            this.FilterIcon(filter.label)

            Text(filter.label)
              .fontSize(12)
              .fontWeight(this.selectedFilterLabel === filter.label ? FontWeight.Regular : FontWeight.Regular)
              .fontColor(this.selectedFilterLabel === filter.label ? YibuqueColor.textInverse : YibuqueColor.textSecondary)
          }
          .height(44)
          .padding({ left: 12, right: 15 })
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .backgroundColor(this.selectedFilterLabel === filter.label ? YibuqueColor.actionBlack : YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.xxxl)
          .border({ width: 1, color: this.selectedFilterLabel === filter.label ? YibuqueColor.borderStrong : YibuqueColor.borderMedium })
          .onClick(() => {
            this.selectedFilterLabel = filter.label;
            this.refreshOutfitDataSource();
          })
        }, (filter: OutfitSceneFilter) => filter.label)

      }
      .padding({ right: 20, bottom: 4 })
      .alignItems(VerticalAlign.Center)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(50)
    .margin({ top: 2, bottom: 12 })
    .padding({ left: 20 })
  }

  @Builder
  FilterIcon(label: string) {
    if (label === '全部') {
      SymbolGlyph($r('sys.symbol.hanger_and_towels'))
        .fontSize(17)
        .fontColor([this.selectedFilterLabel === label ? YibuqueColor.textInverse : YibuqueColor.textSecondary])
    } else if (label === '逛街') {
      SymbolGlyph($r('sys.symbol.bag'))
        .fontSize(17)
        .fontColor([this.selectedFilterLabel === label ? YibuqueColor.textInverse : YibuqueColor.textSecondary])
    } else if (label === '周末') {
      SymbolGlyph($r('sys.symbol.shirt'))
        .fontSize(17)
        .fontColor([this.selectedFilterLabel === label ? YibuqueColor.textInverse : YibuqueColor.textSecondary])
    } else {
      SymbolGlyph($r('sys.symbol.clothing'))
        .fontSize(17)
        .fontColor([this.selectedFilterLabel === label ? YibuqueColor.textInverse : YibuqueColor.textSecondary])
    }
  }

  @Builder
  OutfitGuideCard() {
    Row() {
      Row({ space: 12 }) {
        Column({ space: 2 }) {
          Text(this.clothingItems.length > 0 ? '从已有单品开始搭配' : '先添加衣物再创建套装')
            .fontSize(15)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .lineHeight(18)

          Text(this.clothingItems.length > 0 ?
            '选择衣橱里的真实单品，组合适合自己的穿搭。' :
            '衣橱中有单品后，就可以在这里创建搭配。')
            .fontSize(12)
            .fontColor(YibuqueColor.textSecondary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(`${this.clothingItems.length} 件`)
          .height(36)
          .padding({ left: 12, right: 12 })
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardSurface)
          .borderRadius(YibuqueRadius.xxl)
      }
      .width('100%')
      .padding(14)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: YibuqueColor.borderLight })
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 16 })
  }

  @Builder
  OutfitWallCard(outfit: OutfitTemplate, index: number) {
    Column({ space: 8 }) {
      Column({ space: 6 }) {
        this.OutfitPhoto(outfit, 0, 1.18)
        this.OutfitPhoto(outfit, 1, 0.92)
      }
      .width('100%')
      .aspectRatio(this.outfitStackAspectRatio(index))
      .onClick(() => {
        this.onEditOutfit(outfit);
      })

      Row({ space: 8 }) {
        Text(outfit.title)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .lineHeight(17)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .onClick(() => {
            this.onEditOutfit(outfit);
          })

        Text(this.outfitMeta(outfit))
          .fontSize(11)
          .fontColor(YibuqueColor.textTertiary)
          .lineHeight(15)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .accessibilityText(RECORD_WEAR_ACCESSIBILITY_TEXT)
          .onClick(() => {
            this.onRecordWear(outfit);
          })
      }
      .width('100%')
      .constraintSize({ minHeight: 44 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .margin({ top: this.outfitTopMargin(index) })
    .scale({ x: this.pressedOutfitCardId === outfit.id ? 0.98 : 1.0, y: this.pressedOutfitCardId === outfit.id ? 0.98 : 1.0 })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedOutfitCardId = outfit.id;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedOutfitCardId = '';
      }
    })
  }

  @Builder
  OutfitPhoto(outfit: OutfitTemplate, slot: number, weight: number) {
    if (this.photoUriAt(outfit, slot).length === 0) {
      Column({ space: 5 }) {
        SymbolGlyph($r('sys.symbol.picture'))
          .fontSize(24)
          .fontColor([YibuqueColor.textSecondary])

        Text('暂无照片')
          .fontSize(10)
          .fontColor(YibuqueColor.textTertiary)
      }
        .width('100%')
        .layoutWeight(weight)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.xs)
        .border({ width: 1, color: YibuqueColor.borderLight })
    } else {
      Image(this.photoUriAt(outfit, slot))
        .width('100%')
        .layoutWeight(weight)
        .objectFit(ImageFit.Cover)
        .borderRadius(YibuqueRadius.xs)
        .border({ width: 1, color: YibuqueColor.borderLight })
    }
  }
}
