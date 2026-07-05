import { PhotoGrid } from '../components/PhotoGrid';
import {
  StoreRepository,
  UpdateStoreVisitInput
} from '../data/repositories/StoreRepository';
import { StoreVisit } from '../domain/store/StoreModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { toIsoDate } from '../utils/date';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function padTwoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function formatTimeForStoreName(date: Date): string {
  return `${padTwoDigits(date.getMonth() + 1)}-${padTwoDigits(date.getDate())} ${padTwoDigits(date.getHours())}:${padTwoDigits(date.getMinutes())}`;
}

@Component
export struct StoreVisitEditPage {
  @Prop initialVisit?: StoreVisit = undefined;
  storeRepository?: StoreRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onSave: (visit: StoreVisit) => void = () => {};
  onCancel: () => void = () => {};

  @State private storeName: string = '';
  @State private districtOrAddress: string = '';
  @State private visitDate: string = toIsoDate(new Date());
  @State private note: string = '';
  @State private photoUris: string[] = [];
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialVisit === undefined) {
      return;
    }

    this.storeName = this.initialVisit.storeNameSnapshot;
    this.districtOrAddress = this.initialVisit.districtOrAddress ?? '';
    this.visitDate = this.initialVisit.visitDate;
    this.note = this.initialVisit.note ?? '';
    this.photoUris = [...this.initialVisit.photoUris];
  }

  private canSave(): boolean {
    return !this.isSaving && (this.photoUris.length > 0 || this.note.trim().length > 0);
  }

  private generatedStoreName(): string {
    return `逛店 ${formatTimeForStoreName(new Date())}`;
  }

  private normalizedStoreName(): string {
    return optionalText(this.storeName) ?? this.generatedStoreName();
  }

  private async copySourcesToLocalUris(sources: PhotoSource[]): Promise<string[]> {
    if (this.photoStorage === undefined) {
      return [];
    }

    const localUris: string[] = [];
    for (const source of sources) {
      const storedPhoto = await this.photoStorage.copyToAppStorage(source);
      localUris.push(storedPhoto.localUri);
    }

    return localUris;
  }

  private async pickGalleryPhotos(): Promise<void> {
    if (this.photoPickerAdapter === undefined) {
      return;
    }

    const sources = await this.photoPickerAdapter.pickFromGallery({ maxSelectNumber: 6 });
    this.photoUris = this.photoUris.concat(await this.copySourcesToLocalUris(sources));
  }

  private updateInput(id: string, storeId?: string): UpdateStoreVisitInput {
    return {
      id,
      storeId,
      storeNameSnapshot: this.normalizedStoreName(),
      districtOrAddress: optionalText(this.districtOrAddress),
      visitDate: this.visitDate,
      photoUris: this.photoUris,
      note: optionalText(this.note)
    };
  }

  private async saveStoreVisit(): Promise<void> {
    if (this.storeRepository === undefined || !this.canSave()) {
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';

    try {
      const savedVisit = this.initialVisit === undefined
        ? await this.storeRepository.createStoreVisitWithOptionalStore({
          storeName: optionalText(this.storeName),
          storeNameSnapshot: this.normalizedStoreName(),
          districtOrAddress: optionalText(this.districtOrAddress),
          visitDate: this.visitDate,
          photoUris: this.photoUris,
          note: optionalText(this.note)
        })
        : await this.storeRepository.updateStoreVisit(this.updateInput(this.initialVisit.id, this.initialVisit.storeId));
      this.onSave(savedVisit);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存逛店失败';
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: YibuqueSpacing.lg }) {
        Row() {
          Column({ space: YibuqueSpacing.xs }) {
            Text(this.initialVisit === undefined ? '记录逛店' : '编辑逛店')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textPrimary)

            Text('照片和小记优先，店铺信息都可以稍后补。')
              .fontSize(14)
              .fontColor(YibuqueColor.textSecondary)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('取消')
            .height(44)
            .fontSize(15)
            .fontColor(YibuqueColor.textSecondary)
            .backgroundColor(YibuqueColor.cardWhite)
            .borderRadius(YibuqueRadius.full)
            .border({ width: 1, color: YibuqueColor.borderLight })
            .onClick(() => {
              this.onCancel();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        PhotoGrid({ photoUris: this.photoUris })

        Button('选择店铺照片')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textInverse)
          .backgroundColor(YibuqueColor.actionBlack)
          .borderRadius(YibuqueRadius.full)
          .onClick(() => {
            this.pickGalleryPhotos();
          })

        Column({ space: YibuqueSpacing.md }) {
          Text('小记')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)

          TextArea({ text: this.note, placeholder: '写一点小记' })
            .height(96)
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.note = value;
            })

          Text('选填信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)

          TextInput({ text: this.storeName, placeholder: this.generatedStoreName() })
            .height(52)
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.storeName = value;
            })

          TextInput({ text: this.districtOrAddress, placeholder: '地址或商圈' })
            .height(52)
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.districtOrAddress = value;
            })

          TextInput({ text: this.visitDate, placeholder: '日期 YYYY-MM-DD' })
            .height(52)
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.visitDate = value;
            })

        }
        .width('100%')
        .padding(YibuqueSpacing.lg)
        .borderRadius(YibuqueRadius.xxl)
        .backgroundColor(YibuqueColor.cardWhite)
        .shadow(YibuqueShadow.card)
        .alignItems(HorizontalAlign.Start)

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#EF4444')
        }

        Button(this.isSaving ? '保存中...' : '保存逛店')
          .height(56)
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textInverse)
          .backgroundColor(this.canSave() ? YibuqueColor.actionBlack : YibuqueColor.textDisabled)
          .borderRadius(YibuqueRadius.full)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveStoreVisit();
          })
      }
      .width('100%')
      .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.xxl, bottom: YibuqueSpacing.xxl })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBlueGray)
  }
}
