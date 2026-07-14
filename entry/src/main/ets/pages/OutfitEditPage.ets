import { ClothingPicker } from '../components/ClothingPicker';
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
  onCancel: () => void = () => {};

  @State private title: string = '';
  @State private clothingItemIds: string[] = [];
  @State private photoUris: string[] = [];
  @State private note: string = '';
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialOutfit === undefined) {
      return;
    }

    this.title = this.initialOutfit.title;
    this.clothingItemIds = [...this.initialOutfit.clothingItemIds];
    this.photoUris = [...this.initialOutfit.photoUris];
    this.note = this.initialOutfit.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && this.photoUris.length > 0;
  }

  private hasSelectedPhoto(): boolean {
    return this.photoUris.length > 0;
  }

  private normalizedTitle(): string {
    const trimmedTitle = this.title.trim();
    return trimmedTitle.length > 0 ? trimmedTitle : `美搭 ${formatTimeForTitle(new Date())}`;
  }

  private toggleClothingItem(id: string): void {
    if (this.clothingItemIds.includes(id)) {
      this.clothingItemIds = this.clothingItemIds.filter((itemId: string) => itemId !== id);
      return;
    }

    this.clothingItemIds = this.clothingItemIds.concat([id]);
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
      this.onSave(savedOutfit);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存美搭失败';
    } finally {
      this.isSaving = false;
    }
  }

  @Builder
  PhotoSelector() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.hasSelectedPhoto()) {
        Image(this.photoUris[0])
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
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
          colors: [['#00000000', 0], ['#99000000', 1]]
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
          Text('记录这套美搭的第一眼')
            .fontSize(20)
            .lineHeight(28)
            .fontWeight(FontWeight.Regular)
            .fontColor('#FFFFFF')

          Text('整体、细节或上身效果都可以')
            .fontSize(14)
            .lineHeight(20)
            .fontColor('#D9FFFFFF')

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
    .backgroundColor('#E4E2E2')
    .borderRadius(24)
    .border({ width: 1, color: '#4DC4C7C7' })
    .clip(true)
    .accessibilityText(this.hasSelectedPhoto() ? `已选择 ${this.photoUris.length} 张美搭照片` : '添加美搭照片')
  }

  @Builder
  CameraAction() {
    Stack({ alignContent: Alignment.Center }) {
      SymbolGlyph($r('sys.symbol.camera_fill'))
        .fontSize(24)
        .fontColor(['#000000'])
    }
    .width(48)
    .height(48)
    .backgroundColor('#F2FFFFFF')
    .borderRadius(24)
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
        .fontColor(['#000000'])
      Text(this.photoUris.length > 1 ? `已选择 ${this.photoUris.length} 张` : (this.hasSelectedPhoto() ? '继续选图' : '选择照片'))
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor('#000000')
    }
    .width(164)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .accessibilityText('选择照片')
    .onClick(() => {
      this.pickGalleryPhotos();
    })
  }

  build() {
    Column() {
      SecondaryPageHeader({
        title: this.initialOutfit === undefined ? '创建美搭' : '编辑美搭',
        backAccessibilityText: '返回套装',
        onBack: () => {
          this.onCancel();
        }
      })

      Scroll() {
        Column({ space: YibuqueSpacing.lg }) {
        this.PhotoSelector()

        Column({ space: YibuqueSpacing.md }) {
          Text('美搭信息（选填）')
            .fontSize(18)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)

          TextInput({ text: this.title, placeholder: '美搭名称，可不填' })
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

        Button(this.isSaving ? '保存中...' : (this.hasSelectedPhoto() ? '保存美搭' : '先添加照片'))
          .height(56)
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textInverse)
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
    .backgroundColor(YibuqueColor.bgBlueGray)
  }
}
