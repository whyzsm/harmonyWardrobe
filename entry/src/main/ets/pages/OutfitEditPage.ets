import { ClothingPicker } from '../components/ClothingPicker';
import { PhotoCarousel } from '../components/PhotoCarousel';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import {
  CreateOutfitInput,
  OutfitRepository,
  UpdateOutfitInput
} from '../data/repositories/OutfitRepository';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitDisplaySource, OutfitTemplate } from '../domain/outfit/OutfitModels';
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

const OUTFIT_DISPLAY_SOURCE_PHOTO = OutfitDisplaySource.Photo;
const OUTFIT_DISPLAY_SOURCE_WARDROBE = OutfitDisplaySource.Wardrobe;

@Component
export struct OutfitEditPage {
  @Prop initialOutfit?: OutfitTemplate = undefined;
  @Prop clothingItems: ClothingItem[] = [];
  outfitRepository?: OutfitRepository = undefined;
  photoPickerAdapter?: PhotoPickerAdapter = undefined;
  photoStorage?: PhotoStorage = undefined;
  onSave: (outfit: OutfitTemplate) => void = () => {};
  onCancel: () => void = () => {};

  @State private title: string = '';
  @State private clothingItemIds: string[] = [];
  @State private photoUris: string[] = [];
  @State private selectedPhotoIndex: number = 0;
  @State private displaySource: OutfitDisplaySource = OUTFIT_DISPLAY_SOURCE_PHOTO;
  @State private note: string = '';
  @State private isSaving: boolean = false;
  @State private isChoosingPhotos: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialOutfit === undefined) {
      return;
    }

    this.title = this.initialOutfit.title;
    this.clothingItemIds = [...this.initialOutfit.clothingItemIds];
    this.photoUris = [...this.initialOutfit.photoUris];
    this.selectedPhotoIndex = 0;
    this.displaySource = this.initialOutfit.displaySource;
    if (this.photoUris.length === 0 && this.clothingItemIds.length > 0) {
      this.displaySource = OUTFIT_DISPLAY_SOURCE_WARDROBE;
    }
    this.note = this.initialOutfit.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && !this.isChoosingPhotos && this.hasRequiredSourcePhoto();
  }

  private hasSelectedPhoto(): boolean {
    return this.photoUris.length > 0;
  }

  private hasDisplayPhoto(): boolean {
    return this.displayPhotoUris().length > 0;
  }

  private hasRequiredSourcePhoto(): boolean {
    if (this.displaySource === OUTFIT_DISPLAY_SOURCE_WARDROBE) {
      return this.linkedClothingPhotoUris().length > 0;
    }

    return this.hasSelectedPhoto();
  }

  private saveButtonLabel(): string {
    if (this.hasRequiredSourcePhoto()) {
      return '保存穿搭';
    }

    return this.displaySource === OUTFIT_DISPLAY_SOURCE_WARDROBE ? '先选有照片的衣物' : '先添加照片';
  }

  private normalizedTitle(): string {
    const trimmedTitle = this.title.trim();
    return trimmedTitle.length > 0 ? trimmedTitle : `穿搭 ${formatTimeForTitle(new Date())}`;
  }

  private linkedClothingPhotoUris(): string[] {
    const photoUris: string[] = [];
    for (const id of this.clothingItemIds) {
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

  private displayPhotoUris(): string[] {
    const clothingPhotoUris = this.linkedClothingPhotoUris();
    if (this.displaySource === OUTFIT_DISPLAY_SOURCE_WARDROBE) {
      return clothingPhotoUris.length > 0 ? clothingPhotoUris : this.photoUris;
    }

    return this.photoUris.length > 0 ? this.photoUris : clothingPhotoUris;
  }

  private selectPhoto(index: number): void {
    if (index >= 0 && index < this.photoUris.length) {
      this.selectedPhotoIndex = index;
    }
  }

  private removePhoto(index: number): void {
    if (index < 0 || index >= this.photoUris.length || this.isSaving || this.isChoosingPhotos) {
      return;
    }

    this.photoUris = this.photoUris.filter((_photoUri: string, photoIndex: number) => photoIndex !== index);
    if (this.photoUris.length === 0) {
      this.selectedPhotoIndex = 0;
    } else if (this.selectedPhotoIndex >= this.photoUris.length) {
      this.selectedPhotoIndex = this.photoUris.length - 1;
    }
  }

  private toggleClothingItem(id: string): void {
    let nextIds: string[];
    if (this.clothingItemIds.includes(id)) {
      nextIds = this.clothingItemIds.filter((itemId: string) => itemId !== id);
    } else {
      nextIds = this.clothingItemIds.concat([id]);
    }

    this.clothingItemIds = nextIds;
  }

  private async copySourcesToLocalUris(sources: PhotoSource[]): Promise<string[]> {
    if (this.photoStorage === undefined) {
      throw new Error('照片保存能力不可用');
    }

    const localUris: string[] = [];
    for (const source of sources) {
      const storedPhoto = await this.photoStorage.copyToAppStorage(source);
      localUris.push(storedPhoto.localUri);
    }

    return localUris;
  }

  private async pickGalleryPhotos(): Promise<void> {
    if (this.photoPickerAdapter === undefined || this.isChoosingPhotos || this.isSaving) {
      if (this.photoPickerAdapter === undefined) {
        this.errorMessage = '照片选择能力不可用';
      }
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
      if (sources.length === 0) {
        return;
      }

      try {
        const localUris = await this.copySourcesToLocalUris(sources);
        if (localUris.length > 0) {
          this.photoUris = appendPhotoUris(this.photoUris, localUris);
        } else {
          this.errorMessage = '照片复制失败，请重试';
        }
      } catch (copyError) {
        const detail = copyError instanceof Error ? copyError.message : '未知错误';
        this.errorMessage = `照片保存失败：${detail}`;
      }
    } catch (error) {
      this.errorMessage = userFacingError(error, '选择照片失败');
    } finally {
      this.isChoosingPhotos = false;
    }
  }

  private async capturePhoto(): Promise<void> {
    if (this.photoPickerAdapter === undefined || this.isChoosingPhotos || this.isSaving) {
      if (this.photoPickerAdapter === undefined) {
        this.errorMessage = '拍照能力不可用';
      }
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
      try {
        const localUris = await this.copySourcesToLocalUris([source]);
        if (localUris.length > 0) {
          this.photoUris = appendPhotoUris(this.photoUris, localUris);
        } else {
          this.errorMessage = '照片复制失败，请重试';
        }
      } catch (copyError) {
        const detail = copyError instanceof Error ? copyError.message : '未知错误';
        this.errorMessage = `照片保存失败：${detail}`;
      }
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
      displaySource: this.displaySource,
      note: optionalText(this.note)
    };
  }

  private updateInput(id: string): UpdateOutfitInput {
    return {
      id,
      title: this.normalizedTitle(),
      photoUris: this.photoUris,
      clothingItemIds: this.clothingItemIds,
      displaySource: this.displaySource,
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

  @Builder
  PhotoSelector(title: string, description: string) {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.hasSelectedPhoto()) {
        PhotoCarousel({
          photoUris: this.photoUris,
          activeIndex: this.selectedPhotoIndex,
          onSelect: (index: number) => {
            this.selectPhoto(index);
          }
        })
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
          Text(title)
            .fontSize(20)
            .lineHeight(28)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)

          Text(description)
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

      if (this.photoUris.length > 0) {
        Column({ space: 8 }) {
          Text(`已选照片 ${this.photoUris.length}/${MAX_USER_PHOTOS}`)
            .fontSize(13)
            .fontColor(YibuqueColor.textSecondary)

          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.photoUris, (photoUri: string, index: number) => {
                Stack({ alignContent: Alignment.TopEnd }) {
                  Image(photoUri)
                    .width(72)
                    .height(72)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(YibuqueRadius.md)

                  Stack({ alignContent: Alignment.Center }) {
                    SymbolGlyph($r('sys.symbol.xmark'))
                      .fontSize(12)
                      .fontColor([YibuqueColor.textInverse])
                  }
                  .width(24)
                  .height(24)
                  .margin(4)
                  .backgroundColor(YibuqueColor.overlayDark)
                  .borderRadius(YibuqueRadius.full)
                  .enabled(!this.isChoosingPhotos && !this.isSaving)
                  .accessibilityText(`删除第 ${index + 1} 张照片`)
                  .onClick(() => {
                    this.removePhoto(index);
                  })
                }
                .width(76)
                .height(76)
                .padding(2)
                .borderRadius(YibuqueRadius.lg)
                .border({
                  width: this.selectedPhotoIndex === index ? 2 : 1,
                  color: this.selectedPhotoIndex === index ? YibuqueColor.actionBlack : YibuqueColor.borderLight
                })
                .accessibilityText(`选择第 ${index + 1} 张照片`)
                .onClick(() => {
                  this.selectPhoto(index);
                })
              }, (photoUri: string, index: number) => `${photoUri}-${index}`)
            }
            .height(80)
          }
          .width('100%')
          .height(80)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .padding({ left: 4, right: 4 })
        .alignItems(HorizontalAlign.Start)
      }
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
    .enabled(!this.isChoosingPhotos && !this.isSaving)
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
      Text(this.isChoosingPhotos ? '选择中...' :
        (this.photoUris.length > 1 ? `已选择 ${this.photoUris.length} 张` :
          (this.hasSelectedPhoto() ? '继续选图' : '选择照片')))
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.actionBlack)
    }
    .width(164)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.full)
    .enabled(!this.isChoosingPhotos && !this.isSaving)
    .accessibilityText('选择照片')
    .onClick(() => {
      this.pickGalleryPhotos();
    })
  }

  @Builder
  DisplaySourceSelector() {
    Column({ space: 10 }) {
      Text('展示内容')
        .fontSize(16)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)

      Row({ space: 8 }) {
        this.DisplaySourceTab('上传照片', '展示穿搭实拍图', OUTFIT_DISPLAY_SOURCE_PHOTO)
        this.DisplaySourceTab('选衣柜单品', '展示衣柜单品图', OUTFIT_DISPLAY_SOURCE_WARDROBE)
      }
      .width('100%')
      .height(52)
    }
    .width('100%')
    .padding(YibuqueSpacing.md)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.xxl)
    .border({ width: 1, color: YibuqueColor.borderLight })
  }

  @Builder
  DisplaySourceTab(label: string, description: string, value: OutfitDisplaySource) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(this.displaySource === value ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
        .textAlign(TextAlign.Center)

      Text(description)
        .fontSize(11)
        .fontColor(this.displaySource === value ? YibuqueColor.glassMedium : YibuqueColor.textSecondary)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.displaySource === value ? YibuqueColor.actionBlack : YibuqueColor.cardSoftGray)
    .borderRadius(YibuqueRadius.lg)
    .border({ width: 1, color: this.displaySource === value ? YibuqueColor.actionBlack : YibuqueColor.borderLight })
    .accessibilityText(`${label}${this.displaySource === value ? '，已选中' : ''}`)
    .onClick(() => {
      this.displaySource = value;
    })
  }

  @Builder
  OutfitInfoCard(clothingTitle: string, clothingDescription: string) {
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
        title: clothingTitle,
        description: clothingDescription,
        items: this.clothingItems,
        selectedIds: this.clothingItemIds,
        onToggle: (id: string) => {
          this.toggleClothingItem(id);
        }
      })

      Column({ space: 8 }) {
        Text('小记（选填）')
          .fontSize(14)
          .fontColor(YibuqueColor.textSecondary)

        TextArea({ text: this.note, placeholder: '记录场景、试穿感受或搭配想法' })
          .height(104)
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.lg)
          .onChange((value: string) => {
            this.note = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(YibuqueSpacing.lg)
    .borderRadius(YibuqueRadius.xxl)
    .backgroundColor(YibuqueColor.cardWhite)
    .shadow(YibuqueShadow.card)
    .alignItems(HorizontalAlign.Start)
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
          this.DisplaySourceSelector()

          if (this.displaySource === OUTFIT_DISPLAY_SOURCE_PHOTO) {
            this.PhotoSelector('上传这套穿搭照片', '整体、细节或上身效果都可以')
            this.OutfitInfoCard('关联衣柜单品（选填）', '可以把这套穿搭关联到已有衣服，方便以后回看。')
          } else {
            this.OutfitInfoCard('选择衣柜单品', '至少选择一件有照片的衣物，也可以补充上传穿搭照片。')
            this.PhotoSelector('补充穿搭照片（选填）', '有整体照或上身照时可以放这里')
          }

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(13)
              .fontColor(YibuqueColor.danger)
          }

          Button() {
            if (this.isSaving) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(YibuqueColor.textInverse)
            } else {
              Text(this.saveButtonLabel())
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
