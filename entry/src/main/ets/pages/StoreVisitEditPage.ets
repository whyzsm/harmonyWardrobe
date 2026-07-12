import {
  StoreRepository,
  UpdateStoreVisitInput
} from '../data/repositories/StoreRepository';
import { SecondaryPageHeader } from '../components/SecondaryPageHeader';
import { StoreVisit, StoreVisitStatus } from '../domain/store/StoreModels';
import { PhotoSource } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { YibuqueColor, YibuqueRadius } from '../theme/Tokens';
import { toIsoDate } from '../utils/date';

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
    return !this.isSaving;
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
    if (this.photoPickerAdapter === undefined || this.isSaving) {
      return;
    }

    try {
      const sources = await this.photoPickerAdapter.pickFromGallery({ maxSelectNumber: 6 });
      this.photoUris = this.photoUris.concat(await this.copySourcesToLocalUris(sources));
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '选择照片失败，请重试';
    }
  }

  private async captureStorePhoto(): Promise<void> {
    if (this.photoPickerAdapter === undefined || this.isSaving) {
      return;
    }

    try {
      const source = await this.photoPickerAdapter.captureFromCamera();
      const localUris = await this.copySourcesToLocalUris([source]);
      if (localUris.length === 0) {
        throw new Error('照片保存服务不可用，请稍后重试');
      }
      this.photoUris = this.photoUris.concat(localUris);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '拍照失败，请重试';
    }
  }

  private toggleFocusTag(tag: string): void {
    if (this.selectedTags.includes(tag)) {
      this.selectedTags = this.selectedTags.filter((item: string) => item !== tag);
      return;
    }
    this.selectedTags = this.selectedTags.concat(tag);
  }

  private updateInput(id: string, storeId?: string): UpdateStoreVisitInput {
    return {
      id,
      storeId,
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
    if (this.storeRepository === undefined || this.isSaving || !this.validateForm()) {
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
        : await this.storeRepository.updateStoreVisit(this.updateInput(this.initialVisit.id, this.initialVisit.storeId));

      this.onSave(savedVisit);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存逛店失败';
    } finally {
      this.isSaving = false;
    }
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
                  .fontColor('#DC2626')
                Text('先补上店名和商圈，再保存这条逛店记录。')
                  .fontSize(12)
                  .fontColor(YibuqueColor.textPrimary)
              }
              .width('100%')
              .padding({ left: 13, right: 13, top: 12, bottom: 12 })
              .alignItems(HorizontalAlign.Start)
              .backgroundColor('#FFF7F7')
              .borderRadius(YibuqueRadius.md)
              .border({ width: 1, color: '#F3B8B8' })
            }

            this.BasicInfoCard()
            this.StatusCard()

            if (this.errorMessage.length > 0 && !this.isStoreNameInvalid() && !this.isAddressInvalid()) {
              Text(this.errorMessage)
                .width('100%')
                .fontSize(12)
                .fontColor('#DC2626')
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
    .backgroundColor('#FBF9F9')
  }

  @Builder
  PhotoUploader() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.photoUris.length === 0) {
        Image($r('app.media.store_visit_cover'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else {
        Image(this.photoUris[0])
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      if (this.photoUris.length > 0) {
        Column()
          .width('100%')
          .height('60%')
          .linearGradient({
            angle: 180,
            colors: [['#00000000', 0], ['#99000000', 1]]
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
              .fontColor('#FFFFFF')

            Text('招牌、试衣间或想回看的单品都可以')
              .fontSize(14)
              .lineHeight(20)
              .fontColor('#D9FFFFFF')

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
    .backgroundColor('#E4E2E2')
    .borderRadius(24)
    .border({ width: 1, color: '#4DC4C7C7' })
    .clip(true)
    .accessibilityText(this.photoUris.length > 0 ? `已选择 ${this.photoUris.length} 张店铺照片` : '添加店铺照片')
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
      this.captureStorePhoto();
    })
  }

  @Builder
  GalleryAction() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.picture'))
        .fontSize(18)
        .fontColor(['#000000'])
      Text(this.photoUris.length > 1 ? `已选择 ${this.photoUris.length} 张` : '选择照片')
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

  @Builder
  BasicInfoCard() {
    Column({ space: 24 }) {
      Column({ space: 10 }) {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.store_fill'))
            .fontSize(18)
            .fontColor(['#444748'])
          Text('店名 / 品牌')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor('#444748')
        }

        TextInput({ text: this.storeName, placeholder: '例如：静安嘉里 COS' })
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .fontColor('#1B1C1C')
          .placeholderColor('#C4C7C7')
          .backgroundColor(this.isStoreNameInvalid() ? '#FFF0F0' : '#F5F3F3')
          .borderRadius(24)
          .border({ width: this.isStoreNameInvalid() ? 1 : 0, color: '#BA1A1A' })
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
            .fontColor('#DC2626')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 10 }) {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.mappin_and_rectangle'))
            .fontSize(18)
            .fontColor(['#444748'])
          Text('商圈 / 地址')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor('#444748')
        }

        TextInput({ text: this.districtOrAddress, placeholder: '例如：静安寺 · 二楼女装区' })
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .fontColor('#1B1C1C')
          .placeholderColor('#C4C7C7')
          .backgroundColor(this.isAddressInvalid() ? '#FFF0F0' : '#F5F3F3')
          .borderRadius(24)
          .border({ width: this.isAddressInvalid() ? 1 : 0, color: '#BA1A1A' })
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
            .fontColor('#DC2626')
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
            .backgroundColor('#000000')
          Text('逛店状态')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor('#444748')
        }
        Row({ space: 12 }) {
          ForEach(VISIT_STATUS_OPTIONS, (option: VisitStatusOption) => {
            Text(option.label)
              .height(48)
              .layoutWeight(1)
              .fontSize(14)
              .fontWeight(FontWeight.Regular)
              .fontColor(this.selectedStatus === option.value ? '#FFFFFF' : '#444748')
              .textAlign(TextAlign.Center)
              .backgroundColor(this.selectedStatus === option.value ? '#000000' : '#00FFFFFF')
              .borderRadius(24)
              .border({ width: 1, color: this.selectedStatus === option.value ? '#000000' : '#C4C7C7' })
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
            .backgroundColor('#000000')
          Text('这次要记什么')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor('#444748')
        }
        Grid() {
          ForEach(VISIT_FOCUS_TAGS, (tag: string) => {
            GridItem() {
              Row({ space: 10 }) {
                this.FocusIcon(tag)
                Text(tag)
                  .fontSize(14)
                  .fontWeight(FontWeight.Regular)
                  .fontColor(this.selectedTags.includes(tag) ? '#FFFFFF' : '#1B1C1C')
              }
              .width('100%')
              .height(52)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.selectedTags.includes(tag) ? '#000000' : '#00FFFFFF')
              .borderRadius(24)
              .border({ width: 1, color: this.selectedTags.includes(tag) ? '#000000' : '#C4C7C7' })
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
        .fontColor([this.selectedTags.includes(tag) ? '#FFFFFF' : '#000000'])
    } else if (tag === '想回看') {
      SymbolGlyph($r('sys.symbol.eye'))
        .fontSize(18)
        .fontColor([this.selectedTags.includes(tag) ? '#FFFFFF' : '#000000'])
    } else if (tag === '需比价') {
      SymbolGlyph($r('sys.symbol.creditcard'))
        .fontSize(18)
        .fontColor([this.selectedTags.includes(tag) ? '#FFFFFF' : '#000000'])
    } else {
      SymbolGlyph($r('sys.symbol.bag'))
        .fontSize(18)
        .fontColor([this.selectedTags.includes(tag) ? '#FFFFFF' : '#000000'])
    }
  }

  @Builder
  ActionRow() {
    Row() {
      Button(this.isSaving ? '保存中…' : '保存记录')
        .height(56)
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor('#FFFFFF')
        .backgroundColor('#000000')
        .borderRadius(28)
        .enabled(this.canSave())
        .onClick(() => {
          this.saveStoreVisit();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 16 })
    .backgroundColor('#F7FBF9F9')
    .shadow({ radius: 24, color: '#12000000', offsetX: 0, offsetY: -6 })
  }
}
