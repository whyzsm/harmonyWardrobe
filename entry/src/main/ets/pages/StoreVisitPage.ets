import { StoreVisitCard } from '../components/StoreVisitCard';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { StoreVisit } from '../domain/store/StoreModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';
import { StoreVisitEditPage } from './StoreVisitEditPage';

@Component
export struct StoreVisitPage {
  storeRepository?: StoreRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;

  @State private visits: StoreVisit[] = [];
  @State private searchQuery: string = '';
  @State private showEditor: boolean = false;
  @State private editingVisitId: string = '';
  @State private loading: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadStoreVisits();
  }

  private async loadStoreVisits(): Promise<void> {
    if (this.storeRepository === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      this.visits = await this.storeRepository.listStoreVisits();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载逛店失败';
    } finally {
      this.loading = false;
    }
  }

  private filterStoreVisits(): StoreVisit[] {
    const query = this.searchQuery.trim().toLowerCase();
    if (query.length === 0) {
      return this.visits;
    }

    return this.visits.filter((visit: StoreVisit) => {
      return visit.storeNameSnapshot.toLowerCase().includes(query) ||
        (visit.districtOrAddress !== undefined && visit.districtOrAddress.toLowerCase().includes(query)) ||
        (visit.note !== undefined && visit.note.toLowerCase().includes(query));
    });
  }

  private editingVisit(): StoreVisit | undefined {
    if (this.editingVisitId.length === 0) {
      return undefined;
    }

    for (const visit of this.visits) {
      if (visit.id === this.editingVisitId) {
        return visit;
      }
    }

    return undefined;
  }

  private openCreateEditor(): void {
    this.editingVisitId = '';
    this.showEditor = true;
  }

  private closeEditor(): void {
    this.showEditor = false;
    this.editingVisitId = '';
  }

  private retry(): void {
    this.loadStoreVisits();
  }

  private visitSummaryText(): string {
    const visibleCount = this.filterStoreVisits().length;
    if (this.searchQuery.trim().length > 0) {
      return `找到 ${visibleCount} 条逛店记录`;
    }

    return `${this.visits.length} 条逛店记录`;
  }

  private isSearching(): boolean {
    return this.searchQuery.trim().length > 0;
  }

  private upsertVisit(savedVisit: StoreVisit): void {
    const nextVisits: StoreVisit[] = [];
    let replaced = false;

    for (const visit of this.visits) {
      if (visit.id === savedVisit.id) {
        nextVisits.push(savedVisit);
        replaced = true;
      } else {
        nextVisits.push(visit);
      }
    }

    if (!replaced) {
      nextVisits.unshift(savedVisit);
    }

    this.visits = nextVisits;
  }

  build() {
    if (this.showEditor) {
      StoreVisitEditPage({
        initialVisit: this.editingVisit(),
        storeRepository: this.storeRepository,
        photoPickerAdapter: this.photoPickerAdapter,
        photoStorage: this.photoStorage,
        onSave: (visit: StoreVisit) => {
          this.upsertVisit(visit);
          this.closeEditor();
        },
        onCancel: () => {
          this.closeEditor();
        }
      })
    } else {
      Column({ space: YibuqueSpacing.lg }) {
        Row() {
          Text('逛店')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)
            .layoutWeight(1)

          Button('拍店铺')
            .height(44)
            .fontSize(15)
            .fontColor(YibuqueColor.textInverse)
            .backgroundColor(YibuqueColor.actionBlack)
            .borderRadius(YibuqueRadius.full)
            .onClick(() => {
              this.openCreateEditor();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.visitSummaryText())
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)
          .width('100%')

        TextInput({ text: this.searchQuery, placeholder: '搜索店铺、地址、备注' })
          .height(48)
          .fontSize(16)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .onChange((value: string) => {
            this.searchQuery = value;
          })

        if (this.loading) {
          Text('正在加载逛店记录...')
            .fontSize(14)
            .fontColor(YibuqueColor.textSecondary)
        }

        if (this.errorMessage.length > 0) {
          Row({ space: YibuqueSpacing.sm }) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#EF4444')
              .layoutWeight(1)

            Button('重试')
              .height(34)
              .fontSize(13)
              .fontColor(YibuqueColor.textInverse)
              .backgroundColor(YibuqueColor.actionBlack)
              .borderRadius(YibuqueRadius.full)
              .onClick(() => {
                this.retry();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }

        if (this.filterStoreVisits().length === 0) {
          Column({ space: YibuqueSpacing.lg }) {
            Row() {
              Column({ space: YibuqueSpacing.xs }) {
                Text(this.isSearching() ? '没有找到相关逛店记录' : '还没有逛店记录')
                  .fontSize(21)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(YibuqueColor.textPrimary)

                Text(this.isSearching() ? '试试店铺名、商圈或备注关键词。' : '点右上角「拍店铺」记录这次逛店。')
                  .fontSize(15)
                  .fontColor(YibuqueColor.textSecondary)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Stack({ alignContent: Alignment.Center }) {
                Text('店')
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(YibuqueColor.textPrimary)
              }
              .width(64)
              .height(64)
              .backgroundColor(YibuqueColor.cardMint)
              .borderRadius(YibuqueRadius.xl)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            if (!this.isSearching()) {
              Button('拍店铺')
                .height(48)
                .width('100%')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(YibuqueColor.textInverse)
                .backgroundColor(YibuqueColor.actionBlack)
                .borderRadius(YibuqueRadius.full)
                .onClick(() => {
                  this.openCreateEditor();
                })
            }
          }
          .width('100%')
          .padding(YibuqueSpacing.xl)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.xxl)
          .border({ width: 1, color: YibuqueColor.borderLight })
        } else {
          Scroll() {
            Column({ space: YibuqueSpacing.md }) {
              ForEach(this.filterStoreVisits(), (visit: StoreVisit) => {
                StoreVisitCard({ visit })
                  .onClick(() => {
                    this.editingVisitId = visit.id;
                    this.showEditor = true;
                  })
              }, (visit: StoreVisit) => visit.id)
            }
            .width('100%')
            .padding({ bottom: 16 })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.lg, bottom: YibuqueSpacing.sm })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(YibuqueColor.bgDefault)
    }
  }
}
