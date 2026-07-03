import { ClothingPicker } from '../components/ClothingPicker';
import { PhotoGrid } from '../components/PhotoGrid';
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
    this.clothingItemIds = this.initialOutfit.clothingItemIds;
    this.photoUris = this.initialOutfit.photoUris;
    this.note = this.initialOutfit.note ?? '';
  }

  private canSave(): boolean {
    return !this.isSaving && this.title.trim().length > 0 && (this.clothingItemIds.length > 0 || this.photoUris.length > 0);
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
      title: this.title,
      photoUris: this.photoUris,
      clothingItemIds: this.clothingItemIds,
      note: optionalText(this.note)
    };
  }

  private updateInput(id: string): UpdateOutfitInput {
    return {
      id,
      title: this.title,
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

  build() {
    Scroll() {
      Column({ space: YibuqueSpacing.lg }) {
        Row() {
          Column({ space: YibuqueSpacing.xs }) {
            Text(this.initialOutfit === undefined ? '创建美搭' : '编辑美搭')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(YibuqueColor.textPrimary)

            Text('选择衣物、照片和备注，保存为常用搭配。')
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

        Row({ space: YibuqueSpacing.md }) {
          Button('从相册选择')
            .height(48)
            .layoutWeight(1)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(YibuqueColor.actionBlack)
            .fontColor(YibuqueColor.textInverse)
            .borderRadius(YibuqueRadius.full)
            .onClick(() => {
              this.pickGalleryPhotos();
            })

          Button('拍照')
            .height(48)
            .layoutWeight(1)
            .fontSize(15)
            .fontColor(YibuqueColor.textPrimary)
            .backgroundColor(YibuqueColor.cardWhite)
            .borderRadius(YibuqueRadius.full)
            .border({ width: 1, color: YibuqueColor.borderLight })
            .onClick(() => {
              this.capturePhoto();
            })
        }
        .width('100%')

        Column({ space: YibuqueSpacing.md }) {
          Text('美搭信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(YibuqueColor.textPrimary)

          TextInput({ text: this.title, placeholder: '美搭名称' })
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
            .fontColor('#EF4444')
        }

        Button(this.isSaving ? '保存中...' : '保存美搭')
          .height(56)
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textInverse)
          .backgroundColor(this.canSave() ? YibuqueColor.actionBlack : YibuqueColor.textDisabled)
          .borderRadius(YibuqueRadius.full)
          .enabled(this.canSave())
          .onClick(() => {
            this.saveOutfit();
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
