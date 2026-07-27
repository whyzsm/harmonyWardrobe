import { ClothingPicker } from '../components/ClothingPicker';
import { PhotoCarousel } from '../components/PhotoCarousel';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import {
  CreateOutfitInput,
  OutfitRepository,
  UpdateOutfitInput
} from '../data/repositories/OutfitRepository';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import {
  OUTFIT_CATEGORY_MAX_LENGTH,
  OutfitCategory,
  OutfitDisplaySource,
  OutfitTemplate
} from '../domain/outfit/OutfitModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueRadius, YibuqueShadow, YibuqueSpacing } from '../theme/Tokens';
import { appendPhotoUris, MAX_USER_PHOTOS, remainingPhotoSlots } from '../utils/photoSelection';
import { normalizeSearchText } from '../utils/text';
import { userFacingError } from '../utils/userFacingError';

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function editableOutfitTitle(title: string): string {
  const trimmedTitle = title.trim();
  const autoTitlePattern = /^(穿搭|美搭) \d{2}-\d{2} \d{2}:\d{2}$/;
  const match = autoTitlePattern.exec(trimmedTitle);
  return match === null ? title : match[1];
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
  onCategoriesChange: () => Promise<void> = async (): Promise<void> => {};

  @State private title: string = '';
  @State private clothingItemIds: string[] = [];
  @State private photoUris: string[] = [];
  @State private selectedPhotoIndex: number = 0;
  @State private displaySource: OutfitDisplaySource = OUTFIT_DISPLAY_SOURCE_PHOTO;
  @State private categories: OutfitCategory[] = [];
  @State private categoryNames: string[] = [];
  @State private categoryDraft: string = '';
  @State private showCustomCategoryInput: boolean = false;
  @State private deletingCategoryId: string = '';
  @State private note: string = '';
  @State private isSaving: boolean = false;
  @State private isChoosingPhotos: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadOutfitCategories();
    if (this.initialOutfit === undefined) {
      return;
    }

    this.title = editableOutfitTitle(this.initialOutfit.title);
    this.clothingItemIds = [...this.initialOutfit.clothingItemIds];
    this.photoUris = [...this.initialOutfit.photoUris];
    this.selectedPhotoIndex = 0;
    this.displaySource = this.initialOutfit.displaySource;
    if (this.photoUris.length === 0 && this.clothingItemIds.length > 0) {
      this.displaySource = OUTFIT_DISPLAY_SOURCE_WARDROBE;
    }
    this.categoryNames = [...this.initialOutfit.categoryNames];
    this.note = this.initialOutfit.note ?? '';
  }

  private async loadOutfitCategories(): Promise<void> {
    if (this.outfitRepository === undefined) {
      return;
    }

    try {
      this.categories = await this.outfitRepository.listOutfitCategories();
      if (this.initialOutfit === undefined && this.categoryNames.length === 0) {
        for (const category of this.categories) {
          if (normalizeSearchText(category.name) === normalizeSearchText('通勤')) {
            this.categoryNames = [category.name];
            break;
          }
        }
      }
      if (this.categories.length === 0 && this.categoryNames.length === 0) {
        this.showCustomCategoryInput = true;
      }
    } catch (error) {
      this.errorMessage = userFacingError(error, '加载分类失败');
    }
  }

  private normalizedCategoryName(): string {
    return this.categoryDraft.normalize('NFKC').trim().replace(/\s+/g, ' ');
  }

  private categoryValidationError(): string {
    const name = this.normalizedCategoryName();
    if (name.length === 0) {
      return '';
    }
    if (name.length > OUTFIT_CATEGORY_MAX_LENGTH) {
      return `分类名称最多 ${OUTFIT_CATEGORY_MAX_LENGTH} 个字符`;
    }

    const normalizedName = normalizeSearchText(name);
    if (normalizedName === normalizeSearchText('全部') || normalizedName === normalizeSearchText('未分类')) {
      return '不能使用“全部”或“未分类”';
    }

    return '';
  }

  private isCategorySelected(category: OutfitCategory): boolean {
    const normalizedName = normalizeSearchText(category.name);
    for (const categoryName of this.categoryNames) {
      if (normalizeSearchText(categoryName) === normalizedName) {
        return true;
      }
    }
    return false;
  }

  private selectCategory(category: OutfitCategory): void {
    if (this.isSaving || this.deletingCategoryId.length > 0) {
      return;
    }

    if (this.isCategorySelected(category)) {
      const normalizedName = normalizeSearchText(category.name);
      this.categoryNames = this.categoryNames.filter((categoryName: string) => {
        return normalizeSearchText(categoryName) !== normalizedName;
      });
    } else {
      this.categoryNames = this.categoryNames.concat([category.name]);
    }
  }

  private openCustomCategoryInput(): void {
    if (this.isSaving || this.deletingCategoryId.length > 0) {
      return;
    }

    this.showCustomCategoryInput = true;
  }

  private updateCategoryDraft(value: string): void {
    this.categoryDraft = value;
  }

  private categoryNamesForSave(): string[] {
    const names = [...this.categoryNames];
    const draft = this.normalizedCategoryName();
    if (draft.length === 0) {
      return names;
    }

    const normalizedDraft = normalizeSearchText(draft);
    for (const name of names) {
      if (normalizeSearchText(name) === normalizedDraft) {
        return names;
      }
    }
    names.push(draft);
    return names;
  }

  private confirmDeleteOutfitCategory(category: OutfitCategory): void {
    if (this.isSaving || this.deletingCategoryId.length > 0) {
      return;
    }

    const message = category.usageCount > 0
      ? `该分类下有 ${category.usageCount} 套穿搭，删除后会移除这些穿搭与该分类的关联。`
      : `确定删除“${category.name}”分类吗？`;
    AlertDialog.show({
      title: '删除分类',
      message,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: YibuqueColor.danger,
        action: () => {
          this.deleteOutfitCategory(category);
        }
      }
    });
  }

  private async deleteOutfitCategory(category: OutfitCategory): Promise<void> {
    if (this.outfitRepository === undefined || this.deletingCategoryId.length > 0) {
      return;
    }

    this.deletingCategoryId = category.id;
    this.errorMessage = '';
    try {
      await this.outfitRepository.deleteOutfitCategory(category.id);
      if (this.isCategorySelected(category)) {
        const normalizedName = normalizeSearchText(category.name);
        this.categoryNames = this.categoryNames.filter((categoryName: string) => {
          return normalizeSearchText(categoryName) !== normalizedName;
        });
      }
      if (normalizeSearchText(this.normalizedCategoryName()) === normalizeSearchText(category.name)) {
        this.categoryDraft = '';
      }
      this.categories = await this.outfitRepository.listOutfitCategories();
      await this.onCategoriesChange();
      this.getUIContext().getPromptAction().showToast({ message: '分类已删除' });
    } catch (error) {
      this.errorMessage = userFacingError(error, '删除分类失败');
    } finally {
      this.deletingCategoryId = '';
    }
  }

  private canSave(): boolean {
    return !this.isSaving && !this.isChoosingPhotos && this.hasRequiredSourcePhoto() &&
      this.deletingCategoryId.length === 0 &&
      this.categoryValidationError().length === 0;
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
    if (this.categoryValidationError().length > 0) {
      return '检查分类名称';
    }
    if (this.hasRequiredSourcePhoto()) {
      return '保存穿搭';
    }

    return this.displaySource === OUTFIT_DISPLAY_SOURCE_WARDROBE ? '先选有照片的衣物' : '先添加照片';
  }

  private normalizedTitle(): string {
    const trimmedTitle = this.title.trim();
    return trimmedTitle.length > 0 ? trimmedTitle : '穿搭';
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
      categoryNames: this.categoryNamesForSave(),
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
      categoryNames: this.categoryNamesForSave(),
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
          .align(Alignment.Start)
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
  CategoryChip(category: OutfitCategory) {
    Row() {
      Button() {
        Text(category.name)
          .fontSize(13)
          .fontWeight(FontWeight.Regular)
          .fontColor(this.isCategorySelected(category) ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .height(44)
      .constraintSize({ minWidth: 0, maxWidth: 168 })
      .padding({ left: 14, right: 8 })
      .backgroundColor(YibuqueColor.transparent)
      .stateEffect(false)
      .enabled(!this.isSaving && this.deletingCategoryId.length === 0)
      .accessibilityText(`${category.name}${this.isCategorySelected(category) ? '，已选中' : '，选择分类'}`)
      .onClick(() => {
        this.selectCategory(category);
      })

      Button() {
        if (this.deletingCategoryId === category.id) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color(this.isCategorySelected(category) ? YibuqueColor.textInverse : YibuqueColor.danger)
            .offset({ x: -8 })
        } else {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(11)
            .fontColor([
              this.isCategorySelected(category) ? YibuqueColor.textInverse : YibuqueColor.textSecondary
            ])
            .offset({ x: -8 })
        }
      }
      .width(24)
      .height(44)
      .padding({ left: 0, right: 0 })
      .responseRegion({ x: -8, y: 0, width: 44, height: 44 })
      .backgroundColor(YibuqueColor.transparent)
      .stateEffect(this.deletingCategoryId.length === 0)
      .enabled(!this.isSaving && this.deletingCategoryId.length === 0)
      .accessibilityText(`删除分类 ${category.name}`)
      .onClick(() => {
        this.confirmDeleteOutfitCategory(category);
      })
    }
    .height(44)
    .margin({ right: 12, bottom: 8 })
    .backgroundColor(this.isCategorySelected(category) ? YibuqueColor.actionBlack : YibuqueColor.cardSoftGray)
    .borderRadius(YibuqueRadius.full)
    .border({
      width: 1,
      color: this.isCategorySelected(category) ? YibuqueColor.borderStrong : YibuqueColor.borderMedium
    })
  }

  @Builder
  OutfitCategoryField() {
    Column({ space: 10 }) {
      Text('分类（选填）')
        .width('100%')
        .fontSize(14)
        .fontColor(YibuqueColor.textSecondary)

      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.categories, (category: OutfitCategory) => {
          this.CategoryChip(category)
        }, (category: OutfitCategory) => category.id)

        Button('自定义分类')
          .height(44)
          .padding({ left: 14, right: 14 })
          .margin({ right: 8, bottom: 8 })
          .fontSize(13)
          .fontWeight(FontWeight.Regular)
          .fontColor(this.showCustomCategoryInput ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
          .backgroundColor(this.showCustomCategoryInput ? YibuqueColor.actionBlack : YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .border({
            width: 1,
            color: this.showCustomCategoryInput ? YibuqueColor.borderStrong : YibuqueColor.borderMedium
          })
          .enabled(!this.isSaving && this.deletingCategoryId.length === 0)
          .onClick(() => {
            this.openCustomCategoryInput();
          })
      }
      .width('100%')

      if (this.showCustomCategoryInput) {
        TextInput({ text: this.categoryDraft, placeholder: '输入分类名称' })
          .width('100%')
          .height(48)
          .padding({ left: 14, right: 14 })
          .fontSize(15)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.lg)
          .border({
            width: 1,
            color: this.categoryValidationError().length > 0 ? YibuqueColor.danger : YibuqueColor.borderMedium
          })
          .enabled(!this.isSaving && this.deletingCategoryId.length === 0)
          .onChange((value: string) => {
            this.updateCategoryDraft(value);
          })

        if (this.categoryValidationError().length > 0) {
          Text(this.categoryValidationError())
            .width('100%')
            .fontSize(12)
            .fontColor(YibuqueColor.danger)
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
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

      this.OutfitCategoryField()

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

  @Builder
  SaveAction() {
    Row() {
      if (this.isSaving) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(YibuqueColor.textInverse)
        }
        .height(56)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.sheet)
      } else if (this.canSave()) {
        Button() {
          Text(this.saveButtonLabel())
            .fontSize(17)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)
        }
        .height(56)
        .width('100%')
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.sheet)
        .onClick(() => {
          this.saveOutfit();
        })
      } else {
        Row() {
          Text(this.saveButtonLabel())
            .fontSize(17)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
        }
        .height(56)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(YibuqueColor.textDisabled)
        .borderRadius(YibuqueRadius.sheet)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 16 })
    .backgroundColor(YibuqueColor.cardWhite)
    .shadow(YibuqueShadow.editorSheet)
  }

  build() {
    Stack() {
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

          }
          .width('100%')
          .padding({ left: YibuqueSpacing.pageX, right: YibuqueSpacing.pageX, top: YibuqueSpacing.lg, bottom: 112 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })

        this.SaveAction()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(YibuqueColor.bgBase)

    }
    .width('100%')
    .height('100%')
  }
}
