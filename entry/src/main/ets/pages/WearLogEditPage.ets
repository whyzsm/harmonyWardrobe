import { OutfitPicker } from '../components/OutfitPicker';
import { PhotoGrid } from '../components/PhotoGrid';
import {
  CreateWearLogInput,
  UpdateWearLogInput,
  WearLogRepository
} from '../data/repositories/WearLogRepository';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { WearLog } from '../domain/wearLog/WearLogModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';
import { toIsoDate } from '../utils/date';

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

@Component
export struct WearLogEditPage {
  @Prop initialWearLog?: WearLog = undefined;
  @Prop initialOutfitTemplateId: string = '';
  @Prop outfits: OutfitTemplate[] = [];
  wearLogRepository?: WearLogRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onSave: (wearLog: WearLog) => void = () => {};
  onCancel: () => void = () => {};

  @State private outfitTemplateId: string = '';
  @State private wornDate: string = toIsoDate(new Date());
  @State private photoUris: string[] = [];
  @State private placeText: string = '';
  @State private note: string = '';
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialWearLog === undefined) {
      this.outfitTemplateId = this.initialOutfitTemplateId;
      return;
    }

    this.outfitTemplateId = this.initialWearLog.outfitTemplateId ?? '';
    this.wornDate = this.initialWearLog.wornDate;
    this.photoUris = [...this.initialWearLog.photoUris];
    this.placeText = this.initialWearLog.placeText ?? '';
    this.note = this.initialWearLog.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && this.wornDate.trim().length > 0 &&
      (this.photoUris.length > 0 || this.note.trim().length > 0);
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

  private async capturePhoto(): Promise<void> {
    if (this.photoPickerAdapter === undefined) {
      return;
    }

    const source = await this.photoPickerAdapter.captureFromCamera();
    this.photoUris = this.photoUris.concat(await this.copySourcesToLocalUris([source]));
  }

  private createInput(): CreateWearLogInput {
    return {
      outfitTemplateId: this.outfitTemplateId,
      wornDate: this.wornDate,
      photoUris: this.photoUris,
      placeText: optionalText(this.placeText),
      note: optionalText(this.note)
    };
  }

  private updateInput(id: string): UpdateWearLogInput {
    return {
      id,
      outfitTemplateId: this.outfitTemplateId,
      wornDate: this.wornDate,
      photoUris: this.photoUris,
      placeText: optionalText(this.placeText),
      note: optionalText(this.note)
    };
  }

  private async saveWearLog(): Promise<void> {
    if (this.wearLogRepository === undefined || !this.canSave()) {
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';

    try {
      const savedWearLog = this.initialWearLog === undefined
        ? await this.wearLogRepository.createWearLog(this.createInput())
        : await this.wearLogRepository.updateWearLog(this.updateInput(this.initialWearLog.id));
      this.onSave(savedWearLog);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存穿着记录失败';
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 4 }) {
            Text(this.initialWearLog === undefined ? '记录每日穿搭' : '编辑每日穿搭')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textPrimary)

            Text('照片和小记优先，美搭关联可以稍后再补。')
              .fontSize(14)
              .fontColor(YibuqueColor.textSecondary)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Button('取消')
            .height(40)
            .fontSize(14)
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

        OutfitPicker({
          outfits: this.outfits,
          selectedOutfitId: this.outfitTemplateId,
          onSelect: (id: string) => {
            this.outfitTemplateId = id;
          }
        })

        TextInput({ text: this.wornDate, placeholder: 'wornDate / 日期 YYYY-MM-DD' })
          .height(44)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.lg)
          .border({ width: 1, color: YibuqueColor.borderLight })
          .onChange((value: string) => {
            this.wornDate = value;
          })

        PhotoGrid({ photoUris: this.photoUris })

        Row({ space: 10 }) {
          Button('从相册选择')
            .height(40)
            .fontSize(14)
            .backgroundColor(YibuqueColor.actionBlack)
            .fontColor(YibuqueColor.textInverse)
            .borderRadius(YibuqueRadius.full)
            .onClick(() => {
              this.pickGalleryPhotos();
            })

          Button('拍照')
            .height(40)
            .fontSize(14)
            .backgroundColor(YibuqueColor.cardWhite)
            .fontColor(YibuqueColor.textPrimary)
            .borderRadius(YibuqueRadius.full)
            .border({ width: 1, color: YibuqueColor.borderLight })
            .onClick(() => {
              this.capturePhoto();
            })
        }
        .width('100%')

        TextInput({ text: this.placeText, placeholder: 'placeText / 地点' })
          .height(44)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.lg)
          .border({ width: 1, color: YibuqueColor.borderLight })
          .onChange((value: string) => {
            this.placeText = value;
          })

        TextArea({ text: this.note, placeholder: '小记' })
          .height(96)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.lg)
          .border({ width: 1, color: YibuqueColor.borderLight })
          .onChange((value: string) => {
            this.note = value;
          })

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#EF4444')
        }

        Button(this.isSaving ? '保存中...' : '保存记录')
          .height(44)
          .width('100%')
          .fontSize(15)
          .fontColor(YibuqueColor.textInverse)
          .backgroundColor(this.canSave() ? YibuqueColor.actionBlack : YibuqueColor.textDisabled)
          .borderRadius(YibuqueRadius.full)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveWearLog();
          })
      }
      .width('100%')
      .padding(YibuqueSpacing.pageX)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBlueGray)
  }
}
