import { OutfitPicker } from '../components/OutfitPicker';
import { PhotoCarousel } from '../components/PhotoCarousel';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
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
import { appendPhotoUris, MAX_USER_PHOTOS, remainingPhotoSlots } from '../utils/photoSelection';
import { userFacingError } from '../utils/userFacingError';

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function padTwoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function formatDateForStorage(date: Date): string {
  return `${date.getFullYear()}-${padTwoDigits(date.getMonth() + 1)}-${padTwoDigits(date.getDate())}`;
}

function dateFromStorage(value: string): Date {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value.trim());
  if (match === null) {
    return new Date();
  }

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) {
    return new Date();
  }

  return new Date(year, month - 1, day);
}

@Component
export struct WearLogEditPage {
  @StorageProp('windowBottomInsetVp') private windowBottomInsetVp: number = YibuqueSpacing.bottomSafe;
  @Prop initialWearLog?: WearLog = undefined;
  @Prop initialOutfitTemplateId: string = '';
  @Prop outfits: OutfitTemplate[] = [];
  wearLogRepository?: WearLogRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onSave: (wearLog: WearLog) => void = () => {};
  onDelete: (wearLog: WearLog) => Promise<void> = async (_wearLog: WearLog): Promise<void> => {};
  onCancel: () => void = () => {};

  @State private outfitTemplateId: string = '';
  @State private wornDate: string = toIsoDate(new Date());
  @State private photoUris: string[] = [];
  @State private placeText: string = '';
  @State private note: string = '';
  @State private isSaving: boolean = false;
  @State private isChoosingPhotos: boolean = false;
  @State private isDeleting: boolean = false;
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
    return !this.isSaving && !this.isChoosingPhotos && !this.isDeleting && this.wornDate.trim().length > 0 &&
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
    if (this.photoPickerAdapter === undefined || this.isChoosingPhotos || this.isSaving || this.isDeleting) {
      return;
    }

    this.isChoosingPhotos = true;
    this.errorMessage = '';
    try {
      const availableSlots = remainingPhotoSlots(this.photoUris);
      if (availableSlots === 0) {
        this.errorMessage = `最多添加 ${MAX_USER_PHOTOS} 张照片。`;
        return;
      }
      const sources = await this.photoPickerAdapter.pickFromGallery({ maxSelectNumber: availableSlots });
      this.photoUris = appendPhotoUris(this.photoUris, await this.copySourcesToLocalUris(sources));
    } catch (error) {
      this.errorMessage = userFacingError(error, '选择照片失败');
    } finally {
      this.isChoosingPhotos = false;
    }
  }

  private async capturePhoto(): Promise<void> {
    if (this.photoPickerAdapter === undefined || this.isChoosingPhotos || this.isSaving || this.isDeleting) {
      return;
    }

    this.isChoosingPhotos = true;
    this.errorMessage = '';
    try {
      if (remainingPhotoSlots(this.photoUris) === 0) {
        this.errorMessage = `最多添加 ${MAX_USER_PHOTOS} 张照片。`;
        return;
      }
      const source = await this.photoPickerAdapter.captureFromCamera();
      this.photoUris = appendPhotoUris(this.photoUris, await this.copySourcesToLocalUris([source]));
    } catch (error) {
      this.errorMessage = userFacingError(error, '拍照失败');
    } finally {
      this.isChoosingPhotos = false;
    }
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
      this.showSaveToast('穿着记录已保存');
      this.onSave(savedWearLog);
    } catch (error) {
      this.errorMessage = userFacingError(error, '保存穿着记录失败');
    } finally {
      this.isSaving = false;
    }
  }

  private showSaveToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message });
  }

  private openWornDatePicker(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(),
      selected: dateFromStorage(this.wornDate),
      onDateAccept: (date: Date) => {
        this.wornDate = formatDateForStorage(date);
      }
    });
  }

  private confirmDeleteWearLog(): void {
    const wearLog = this.initialWearLog;
    if (wearLog === undefined || this.isSaving || this.isDeleting) {
      return;
    }

    AlertDialog.show({
      title: '删除穿着记录',
      message: '确定要删除这条穿着记录吗？照片也会一并移除。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: YibuqueColor.danger,
        action: () => {
          this.deleteWearLog();
        }
      }
    });
  }

  private async deleteWearLog(): Promise<void> {
    const wearLog = this.initialWearLog;
    if (wearLog === undefined || this.isDeleting) {
      return;
    }

    this.isDeleting = true;
    this.errorMessage = '';
    try {
      await this.onDelete(wearLog);
    } catch (error) {
      this.errorMessage = userFacingError(error, '删除穿着记录失败');
    } finally {
      this.isDeleting = false;
    }
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: this.initialWearLog === undefined ? '记录每日穿搭' : '编辑每日穿搭',
        backAccessibilityText: '返回穿搭',
        onBack: () => {
          this.onCancel();
        }
      })

      Scroll() {
        Column({ space: 16 }) {
        OutfitPicker({
          outfits: this.outfits,
          selectedOutfitId: this.outfitTemplateId,
          onSelect: (id: string) => {
            this.outfitTemplateId = id;
          }
        })

        Text('穿搭日期')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

        Row() {
          Text(this.wornDate)
            .fontSize(15)
            .fontColor(YibuqueColor.textPrimary)
        }
          .width('100%')
          .height(44)
          .padding({ left: 12, right: 12 })
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.lg)
          .border({ width: 1, color: YibuqueColor.borderLight })
          .onClick(() => {
            this.openWornDatePicker();
          })

        if (this.photoUris.length > 0) {
          PhotoCarousel({ photoUris: this.photoUris })
            .width('100%')
            .height(220)
        } else {
          Image($r('app.media.default_fashion_cover'))
            .width('100%')
            .height(220)
            .objectFit(ImageFit.Cover)
            .borderRadius(YibuqueRadius.xs)
        }

        Row({ space: 10 }) {
          Button('从相册选择')
            .height(40)
            .fontSize(14)
            .backgroundColor(YibuqueColor.actionBlack)
            .fontColor(YibuqueColor.textInverse)
            .borderRadius(YibuqueRadius.full)
            .enabled(!this.isChoosingPhotos && !this.isSaving && !this.isDeleting)
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
            .enabled(!this.isChoosingPhotos && !this.isSaving && !this.isDeleting)
            .onClick(() => {
              this.capturePhoto();
            })
        }
        .width('100%')

        Text('地点')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

        TextInput({ text: this.placeText, placeholder: '地点' })
          .height(44)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.lg)
          .border({ width: 1, color: YibuqueColor.borderLight })
          .onChange((value: string) => {
            this.placeText = value;
          })

        Text('小记')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)

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
            .fontColor(YibuqueColor.danger)
        }

        if (this.initialWearLog !== undefined) {
          Button() {
            if (this.isDeleting) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(YibuqueColor.textInverse)
            } else {
              Text('删除记录')
                .fontSize(15)
                .fontColor(YibuqueColor.textInverse)
            }
          }
            .height(44)
            .width('100%')
            .backgroundColor(YibuqueColor.danger)
            .borderRadius(YibuqueRadius.full)
            .enabled(!this.isSaving && !this.isDeleting)
            .onClick(() => {
              this.confirmDeleteWearLog();
            })
        }

        Button() {
          if (this.isSaving) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(YibuqueColor.textInverse)
          } else {
            Text('保存记录')
              .fontSize(15)
              .fontColor(YibuqueColor.textInverse)
          }
        }
          .height(44)
          .width('100%')
          .backgroundColor(this.canSave() ? YibuqueColor.actionBlack : YibuqueColor.textDisabled)
          .borderRadius(YibuqueRadius.full)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveWearLog();
          })
        }
        .width('100%')
        .padding({
          left: YibuqueSpacing.pageX,
          right: YibuqueSpacing.pageX,
          top: YibuqueSpacing.pageX,
          bottom: YibuqueSpacing.pageX + this.windowBottomInsetVp
        })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBase)
  }
}
