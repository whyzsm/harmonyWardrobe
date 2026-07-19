import {
  StoreRepository,
  UpdateStoreVisitWithOptionalStoreInput
} from '../data/repositories/StoreRepository';
import { PhotoCarousel } from '../components/PhotoCarousel';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import { StoreVisit, StoreVisitStatus } from '../domain/store/StoreModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueRadius, YibuqueShadow } from '../theme/Tokens';
import { toIsoDate } from '../utils/date';
import { appendPhotoUris, MAX_USER_PHOTOS, remainingPhotoSlots } from '../utils/photoSelection';
import { userFacingError } from '../utils/userFacingError';

interface VisitStatusOption {
  label: string;
  value: StoreVisitStatus;
}

const VISIT_STATUS_OPTIONS: VisitStatusOption[] = [
  { label: '已去', value: StoreVisitStatus.Visited },
  { label: '想去', value: StoreVisitStatus.WantToVisit },
  { label: '回购', value: StoreVisitStatus.Repurchase }
];

const VISIT_FOCUS_TAGS: string[] = ['试穿', '想回看', '需比价', '已购买'];

function optionalText(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
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
  @State private selectedStatus: StoreVisitStatus = StoreVisitStatus.Visited;
  @State private selectedTags: string[] = [];
  @State private note: string = '';
  @State private photoUris: string[] = [];
  @State private isSaving: boolean = false;
  @State private isChoosingPhotos: boolean = false;
  @State private submitted: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    if (this.initialVisit === undefined) {
      return;
    }

    this.storeName = this.initialVisit.storeNameSnapshot;
    this.districtOrAddress = this.initialVisit.districtOrAddress ?? '';
    this.visitDate = this.initialVisit.visitDate;
    this.selectedStatus = this.initialVisit.status ?? StoreVisitStatus.Visited;
    this.selectedTags = this.initialVisit.focusTags !== undefined && this.initialVisit.focusTags.length > 0
      ? [...this.initialVisit.focusTags]
      : [];
    this.note = this.initialVisit.note ?? '';
    this.photoUris = [...this.initialVisit.photoUris];
  }

  private isStoreNameInvalid(): boolean {
    return this.submitted && this.storeName.trim().length === 0;
  }

  private isAddressInvalid(): boolean {
    return this.submitted && this.districtOrAddress.trim().length === 0;
  }

  private validateForm(): boolean {
    this.submitted = true;
    const isValid = this.storeName.trim().length > 0 && this.districtOrAddress.trim().length > 0;
    this.errorMessage = isValid ? '' : '先补上店名和商圈，再保存这条逛店记录。';
    return isValid;
  }

  private canSave(): boolean {
    return !this.isSaving && !this.isChoosingPhotos;
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
    if (this.photoPickerAdapter === undefined || this.isSaving || this.isChoosingPhotos) {
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
      const localUris = await this.copySourcesToLocalUris(sources);
      if (sources.length > 0 && localUris.length === 0) {
        throw new Error('照片保存服务不可用，请稍后重试');
      }
      this.photoUris = appendPhotoUris(this.photoUris, localUris);
    } catch (error) {
      this.errorMessage = userFacingError(error, '选择照片失败，请重试');
    } finally {
      this.isChoosingPhotos = false;
    }
  }

  private async captureStorePhoto(): Promise<void> {
    if (this.photoPickerAdapter === undefined || this.isSaving || this.isChoosingPhotos) {
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
      const localUris = await this.copySourcesToLocalUris([source]);
      if (localUris.length === 0) {
        throw new Error('照片保存服务不可用，请稍后重试');
      }
      this.photoUris = appendPhotoUris(this.photoUris, localUris);
    } catch (error) {
      this.errorMessage = userFacingError(error, '拍照失败，请重试');
    } finally {
      this.isChoosingPhotos = false;
    }
  }

  private toggleFocusTag(tag: string): void {
    if (this.selectedTags.includes(tag)) {
      this.selectedTags = this.selectedTags.filter((item: string) => item !== tag);
      return;
    }
    this.selectedTags = this.selectedTags.concat(tag);
  }

  private updateInput(id: string): UpdateStoreVisitWithOptionalStoreInput {
    return {
      id,
      storeName: this.storeName.trim(),
      storeNameSnapshot: this.storeName.trim(),
      districtOrAddress: this.districtOrAddress.trim(),
      visitDate: this.visitDate,
      photoUris: this.photoUris,
      status: this.selectedStatus,
      focusTags: this.selectedTags,
      note: optionalText(this.note)
    };
  }

  private async saveStoreVisit(): Promise<void> {
    if (this.storeRepository === undefined || this.isSaving || this.isChoosingPhotos || !this.validateForm()) {
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';
    try {
      const savedVisit = this.initialVisit === undefined
        ? await this.storeRepository.createStoreVisitWithOptionalStore({
          storeName: this.storeName.trim(),
          storeNameSnapshot: this.storeName.trim(),
          districtOrAddress: this.districtOrAddress.trim(),
          visitDate: this.visitDate,
          photoUris: this.photoUris,
          status: this.selectedStatus,
          focusTags: this.selectedTags,
          note: optionalText(this.note)
        })
        : await this.storeRepository.updateStoreVisitWithOptionalStore(this.updateInput(this.initialVisit.id));

      this.showSaveToast('逛店记录已保存');
      this.onSave(savedVisit);
    } catch (error) {
      this.errorMessage = userFacingError(error, '保存逛店失败');
    } finally {
      this.isSaving = false;
    }
  }

  private showSaveToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        SecondaryPageHeader({
          title: this.initialVisit === undefined ? '新增逛店' : '编辑逛店',
          backAccessibilityText: '返回逛店记录',
          onBack: () => {
            this.onCancel();
          }
        })

        Scroll() {
          Column({ space: 32 }) {
            this.PhotoUploader()

            if (this.submitted && (this.isStoreNameInvalid() || this.isAddressInvalid())) {
              Column({ space: 2 }) {
                Text('还有信息没填完')
                  .fontSize(13)
                  .fontWeight(FontWeight.Regular)
                  .fontColor(YibuqueColor.danger)
                Text('先补上店名和商圈，再保存这条逛店记录。')
                  .fontSize(12)
                  .fontColor(YibuqueColor.textPrimary)
              }
              .width('100%')
              .padding({ left: 13, right: 13, top: 12, bottom: 12 })
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(YibuqueColor.bgGray)
              .borderRadius(YibuqueRadius.md)
              .border({ width: 1, color: YibuqueColor.danger })
            }

            this.BasicInfoCard()
            this.StatusCard()
            if (this.errorMessage.length > 0 && !this.isStoreNameInvalid() && !this.isAddressInvalid()) {
              Text(this.errorMessage)
                .width('100%')
                .fontSize(12)
                .fontColor(YibuqueColor.danger)
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 28, bottom: 112 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')

      this.ActionRow()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgDefault)
  }

  @Builder
  PhotoUploader() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.photoUris.length === 0) {
        Image($r('app.media.default_store_cover'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else {
        PhotoCarousel({ photoUris: this.photoUris })
          .width('100%')
          .height('100%')
      }

      if (this.photoUris.length > 0) {
        Column()
          .width('100%')
          .height('60%')
          .linearGradient({
            angle: 180,
            colors: [[YibuqueColor.transparentBlack, 0], [YibuqueColor.scrimStrong, 1]]
          })
      }

      Column() {
        Row() {
          Blank()
          this.CameraAction()
        }
        .width('100%')
        .padding({ top: 16, right: 16 })

        Blank()

        if (this.photoUris.length > 0) {
          Column({ space: 8 }) {
            Text('拍下这家店的第一眼')
              .fontSize(20)
              .lineHeight(28)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textInverse)

            Text('招牌、试衣间或想回看的单品都可以')
              .fontSize(14)
              .lineHeight(20)
              .fontColor(YibuqueColor.glassMedium)

            this.GalleryAction()
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 24 })
          .alignItems(HorizontalAlign.Start)
        } else {
          Row() {
            this.GalleryAction()
          }
          .width('100%')
          .padding({ left: 24, bottom: 24 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .aspectRatio(530 / 386)
    .backgroundColor(YibuqueColor.bgGray)
    .borderRadius(YibuqueRadius.xxxl)
    .border({ width: 1, color: YibuqueColor.borderLight })
    .clip(true)
    .accessibilityText(this.photoUris.length > 0 ? `已选择 ${this.photoUris.length} 张店铺照片` : '添加店铺照片')
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
    .accessibilityText('拍照')
    .enabled(!this.isSaving && !this.isChoosingPhotos)
    .onClick(() => {
      this.captureStorePhoto();
    })
  }

  @Builder
  GalleryAction() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.picture'))
        .fontSize(18)
        .fontColor([YibuqueColor.actionBlack])
      Text(this.isChoosingPhotos ? '选择中...' : (this.photoUris.length > 1 ? `已选择 ${this.photoUris.length} 张` : '选择照片'))
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.actionBlack)
    }
    .width(164)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(YibuqueColor.cardWhite)
    .borderRadius(YibuqueRadius.full)
    .accessibilityText('选择照片')
    .enabled(!this.isSaving && !this.isChoosingPhotos)
    .onClick(() => {
      this.pickGalleryPhotos();
    })
  }

  @Builder
  BasicInfoCard() {
    Column({ space: 24 }) {
      Column({ space: 10 }) {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.store_fill'))
            .fontSize(18)
            .fontColor([YibuqueColor.textSecondary])
          Text('店名 / 品牌')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textSecondary)
        }

        TextInput({ text: this.storeName, placeholder: '例如：静安嘉里 COS' })
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textDisabled)
          .backgroundColor(this.isStoreNameInvalid() ? YibuqueColor.bgGray : YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.xxxl)
          .border({ width: this.isStoreNameInvalid() ? 1 : 0, color: YibuqueColor.danger })
          .onChange((value: string) => {
            this.storeName = value;
            if (this.submitted && value.trim().length > 0 && this.districtOrAddress.trim().length > 0) {
              this.errorMessage = '';
            }
          })
        .width('100%')
        if (this.isStoreNameInvalid()) {
          Text('请输入这家店或品牌名称。')
            .fontSize(12)
            .fontColor(YibuqueColor.danger)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 10 }) {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.mappin_and_rectangle'))
            .fontSize(18)
            .fontColor([YibuqueColor.textSecondary])
          Text('商圈 / 地址')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textSecondary)
        }

        TextInput({ text: this.districtOrAddress, placeholder: '例如：静安寺 · 二楼女装区' })
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textDisabled)
          .backgroundColor(this.isAddressInvalid() ? YibuqueColor.bgGray : YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.xxxl)
          .border({ width: this.isAddressInvalid() ? 1 : 0, color: YibuqueColor.danger })
          .onChange((value: string) => {
            this.districtOrAddress = value;
            if (this.submitted && value.trim().length > 0 && this.storeName.trim().length > 0) {
              this.errorMessage = '';
            }
          })
        .width('100%')
        if (this.isAddressInvalid()) {
          Text('请输入商圈、商场或大概位置。')
            .fontSize(12)
            .fontColor(YibuqueColor.danger)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StatusCard() {
    Column({ space: 32 }) {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Row()
            .width(2)
            .height(20)
            .backgroundColor(YibuqueColor.actionBlack)
          Text('逛店状态')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textSecondary)
        }
        Row({ space: 12 }) {
          ForEach(VISIT_STATUS_OPTIONS, (option: VisitStatusOption) => {
            Text(option.label)
              .height(48)
              .layoutWeight(1)
              .fontSize(14)
              .fontWeight(FontWeight.Regular)
              .fontColor(this.selectedStatus === option.value ? YibuqueColor.textInverse : YibuqueColor.textSecondary)
              .textAlign(TextAlign.Center)
              .backgroundColor(this.selectedStatus === option.value ? YibuqueColor.actionBlack : YibuqueColor.transparent)
              .borderRadius(YibuqueRadius.full)
              .border({ width: 1, color: this.selectedStatus === option.value ? YibuqueColor.actionBlack : YibuqueColor.borderMedium })
              .accessibilityText(`${option.label}${this.selectedStatus === option.value ? '，已选中' : ''}`)
              .onClick(() => {
                this.selectedStatus = option.value;
              })
          }, (option: VisitStatusOption) => option.value)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Row()
            .width(2)
            .height(20)
            .backgroundColor(YibuqueColor.actionBlack)
          Text('这次要记什么')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textSecondary)
        }
        Grid() {
          ForEach(VISIT_FOCUS_TAGS, (tag: string) => {
            GridItem() {
              Row({ space: 10 }) {
                this.FocusIcon(tag)
                Text(tag)
                  .fontSize(14)
                  .fontWeight(FontWeight.Regular)
                  .fontColor(this.selectedTags.includes(tag) ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.selectedTags.includes(tag) ? YibuqueColor.actionBlack : YibuqueColor.transparent)
              .borderRadius(YibuqueRadius.full)
              .border({ width: 1, color: this.selectedTags.includes(tag) ? YibuqueColor.actionBlack : YibuqueColor.borderMedium })
              .accessibilityText(`${tag}${this.selectedTags.includes(tag) ? '，已选中' : ''}`)
              .onClick(() => {
                this.toggleFocusTag(tag);
              })
            }
          }, (tag: string) => tag)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
        .height(116)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FocusIcon(tag: string) {
    if (tag === '试穿') {
      SymbolGlyph($r('sys.symbol.shirt'))
        .fontSize(18)
        .fontColor([this.selectedTags.includes(tag) ? YibuqueColor.textInverse : YibuqueColor.actionBlack])
    } else if (tag === '想回看') {
      SymbolGlyph($r('sys.symbol.eye'))
        .fontSize(18)
        .fontColor([this.selectedTags.includes(tag) ? YibuqueColor.textInverse : YibuqueColor.actionBlack])
    } else if (tag === '需比价') {
      SymbolGlyph($r('sys.symbol.creditcard'))
        .fontSize(18)
        .fontColor([this.selectedTags.includes(tag) ? YibuqueColor.textInverse : YibuqueColor.actionBlack])
    } else {
      SymbolGlyph($r('sys.symbol.bag'))
        .fontSize(18)
        .fontColor([this.selectedTags.includes(tag) ? YibuqueColor.textInverse : YibuqueColor.actionBlack])
    }
  }

  @Builder
  ActionRow() {
    Row() {
      Button() {
        if (this.isSaving) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(YibuqueColor.textInverse)
        } else {
          Text('保存记录')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)
        }
      }
        .height(56)
        .width('100%')
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.sheet)
        .enabled(this.canSave())
        .onClick(() => {
          this.saveStoreVisit();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 16 })
    .backgroundColor(YibuqueColor.cardWhite)
    .shadow(YibuqueShadow.editorSheet)
  }
}
