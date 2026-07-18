import { ClothingPicker } from '../components/ClothingPicker';
import { PhotoCarousel } from '../components/PhotoCarousel';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import {
  CreateOutfitInput,
  OutfitRepository,
  UpdateOutfitInput
} from '../data/repositories/OutfitRepository';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';
import { appendPhotoUris, MAX_USER_PHOTOS, remainingPhotoSlots } from '../utils/photoSelection';
import { userFacingError } from '../utils/userFacingError';

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function padTwoDigits(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function formatTimeForTitle(date: Date): string {
  return `${padTwoDigits(date.getMonth() + 1)}-${padTwoDigits(date.getDate())} ${padTwoDigits(date.getHours())}:${padTwoDigits(date.getMinutes())}`;
}

@Component
export struct OutfitEditPage {
  @Prop initialOutfit?: OutfitTemplate = undefined;
  @Prop clothingItems: ClothingItem[] = [];
  outfitRepository?: OutfitRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onSave: (outfit: OutfitTemplate) => void = () => {};
  onDelete: (outfit: OutfitTemplate) => Promise<void> = async (_outfit: OutfitTemplate): Promise<void> => {};
  onCancel: () => void = () => {};

  @State private title: string = '';
  @State private clothingItemIds: string[] = [];
  @State private photoUris: string[] = [];
  @State private note: string = '';
  @State private isSaving: boolean = false;
  @State private isChoosingPhotos: boolean = false;
  @State private isDeleting: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialOutfit === undefined) {
      return;
    }

    this.title = this.initialOutfit.title;
    this.clothingItemIds = [...this.initialOutfit.clothingItemIds];
    const selectedPhotoUris = this.firstPhotoUrisForClothingItemIds(this.clothingItemIds);
    this.photoUris = selectedPhotoUris.length > 0
      ? selectedPhotoUris
      : [...this.initialOutfit.photoUris];
    this.note = this.initialOutfit.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && !this.isChoosingPhotos && !this.isDeleting && this.photoUris.length > 0;
  }

  private hasSelectedPhoto(): boolean {
    return this.photoUris.length > 0;
  }

  private normalizedTitle(): string {
    const trimmedTitle = this.title.trim();
    return trimmedTitle.length > 0 ? trimmedTitle : `穿搭 ${formatTimeForTitle(new Date())}`;
  }

  private firstPhotoUrisForClothingItemIds(ids: string[]): string[] {
    const photoUris: string[] = [];
    for (const id of ids) {
      for (const item of this.clothingItems) {
        if (item.id !== id || item.photoUris.length === 0) {
          continue;
        }

        const photoUri = item.photoUris[0].trim();
        if (photoUri.length > 0) {
          photoUris.push(photoUri);
        }
        break;
      }
    }
    return photoUris;
  }

  private toggleClothingItem(id: string): void {
    let nextIds: string[];
    if (this.clothingItemIds.includes(id)) {
      nextIds = this.clothingItemIds.filter((itemId: string) => itemId !== id);
    } else {
      nextIds = this.clothingItemIds.concat([id]);
    }

    this.clothingItemIds = nextIds;
    if (this.initialOutfit !== undefined) {
      this.photoUris = this.firstPhotoUrisForClothingItemIds(nextIds);
    }
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

  private createInput(): CreateOutfitInput {
    return {
      title: this.normalizedTitle(),
      photoUris: this.photoUris,
      clothingItemIds: this.clothingItemIds,
      note: optionalText(this.note)
    };
  }

  private updateInput(id: string): UpdateOutfitInput {
    return {
      id,
      title: this.normalizedTitle(),
      photoUris: this.photoUris,
      clothingItemIds: this.clothingItemIds,
      note: optionalText(this.note)
    };
  }

  private async saveOutfit(): Promise<void> {
    if (this.outfitRepository === undefined || !this.canSave()) {
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';

    try {
      const savedOutfit = this.initialOutfit === undefined
        ? await this.outfitRepository.createOutfit(this.createInput())
        : await this.outfitRepository.updateOutfit(this.updateInput(this.initialOutfit.id));
      this.showSaveToast('穿搭已保存');
      this.onSave(savedOutfit);
    } catch (error) {
      this.errorMessage = userFacingError(error, '保存穿搭失败');
    } finally {
      this.isSaving = false;
    }
  }

  private showSaveToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message });
  }

  private confirmDeleteOutfit(): void {
    const outfit = this.initialOutfit;
    if (outfit === undefined || this.isSaving || this.isDeleting) {
      return;
    }

    AlertDialog.show({
      title: '删除穿搭',
      message: '确定要删除这套穿搭吗？照片也会一并移除。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: YibuqueColor.danger,
        action: () => {
          this.deleteOutfit();
        }
      }
    });
  }

  private async deleteOutfit(): Promise<void> {
    const outfit = this.initialOutfit;
    if (outfit === undefined || this.isDeleting) {
      return;
    }

    this.isDeleting = true;
    this.errorMessage = '';
    try {
      await this.onDelete(outfit);
    } catch (error) {
      this.errorMessage = userFacingError(error, '删除穿搭失败');
    } finally {
      this.isDeleting = false;
    }
  }

  @Builder
  PhotoSelector() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.hasSelectedPhoto()) {
        PhotoCarousel({ photoUris: this.photoUris })
          .width('100%')
          .height('100%')
      } else {
        Image($r('app.media.default_fashion_cover'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      Column()
        .width('100%')
        .height('60%')
        .linearGradient({
          angle: 180,
          colors: [[YibuqueColor.transparentBlack, 0], [YibuqueColor.scrimStrong, 1]]
        })

      Column() {
        Row() {
          Blank()
          this.CameraAction()
        }
        .width('100%')
        .padding({ top: 16, right: 16 })

        Blank()

        Column({ space: 8 }) {
          Text('记录这套穿搭的第一眼')
            .fontSize(20)
            .lineHeight(28)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)

          Text('整体、细节或上身效果都可以')
            .fontSize(14)
            .lineHeight(20)
            .fontColor(YibuqueColor.glassMedium)

          this.GalleryAction()
        }
        .width('100%')
        .padding({ left: 24, right: 24, bottom: 24 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .aspectRatio(530 / 386)
    .backgroundColor(YibuqueColor.borderLight)
    .borderRadius(YibuqueRadius.sheet)
    .border({ width: 1, color: YibuqueColor.borderLight })
    .clip(true)
    .accessibilityText(this.hasSelectedPhoto() ? `已选择 ${this.photoUris.length} 张穿搭照片` : '添加穿搭照片')
  }

  @Builder
  CameraAction() {
    Stack({ alignContent: Alignment.Center }) {
      SymbolGlyph($r('sys.symbol.camera_fill'))
        .fontSize(24)
        .fontColor([YibuqueColor.actionBlack])
    }
    .width(48)
    .height(48)
    .backgroundColor(YibuqueColor.glassStrong)
    .borderRadius(YibuqueRadius.full)
    .enabled(!this.isChoosingPhotos && !this.isSaving && !this.isDeleting)
    .accessibilityText('拍照')
    .onClick(() => {
      this.capturePhoto();
    })
  }

  @Builder
  GalleryAction() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.picture'))
        .fontSize(18)
        .fontColor([YibuqueColor.actionBlack])
      Text(this.photoUris.length > 1 ? `已选择 ${this.photoUris.length} 张` : (this.hasSelectedPhoto() ? '继续选图' : '选择照片'))
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.actionBlack)
    }
    .width(164)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.full)
    .enabled(!this.isChoosingPhotos && !this.isSaving && !this.isDeleting)
    .accessibilityText('选择照片')
    .onClick(() => {
      this.pickGalleryPhotos();
    })
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: this.initialOutfit === undefined ? '创建穿搭' : '编辑穿搭',
        backAccessibilityText: '返回穿搭',
        onBack: () => {
          this.onCancel();
        }
      })

      Scroll() {
        Column({ space: YibuqueSpacing.lg }) {
        this.PhotoSelector()

        Column({ space: YibuqueSpacing.md }) {
          Text('穿搭信息（选填）')
            .fontSize(18)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)

          TextInput({ text: this.title, placeholder: '穿搭名称，可不填' })
            .height(52)
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.title = value;
            })

          ClothingPicker({
            items: this.clothingItems,
            selectedIds: this.clothingItemIds,
            onToggle: (id: string) => {
              this.toggleClothingItem(id);
            }
          })

          TextInput({ text: this.note, placeholder: '备注' })
            .height(56)
            .fontSize(16)
            .fontColor(YibuqueColor.textPrimary)
            .placeholderColor(YibuqueColor.textTertiary)
            .backgroundColor(YibuqueColor.cardSoftGray)
            .borderRadius(YibuqueRadius.lg)
            .onChange((value: string) => {
              this.note = value;
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
            .fontColor(YibuqueColor.danger)
        }

        if (this.initialOutfit !== undefined) {
          Button() {
            if (this.isDeleting) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(YibuqueColor.textInverse)
            } else {
              Text('删除穿搭')
                .fontSize(15)
                .fontColor(YibuqueColor.textInverse)
            }
          }
            .height(46)
            .width('100%')
            .backgroundColor(YibuqueColor.danger)
            .borderRadius(YibuqueRadius.full)
            .enabled(!this.isSaving && !this.isDeleting)
            .onClick(() => {
              this.confirmDeleteOutfit();
            })
        }

        Button() {
          if (this.isSaving) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(YibuqueColor.textInverse)
          } else {
            Text(this.hasSelectedPhoto() ? '保存穿搭' : '先添加照片')
              .fontSize(17)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textInverse)
          }
        }
          .height(56)
          .width('100%')
          .backgroundColor(this.canSave() ? YibuqueColor.actionBlack : YibuqueColor.textDisabled)
          .borderRadius(YibuqueRadius.full)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveOutfit();
          })
        }
        .width('100%')
        .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.lg, bottom: YibuqueSpacing.xxl })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgBase)
  }
}
