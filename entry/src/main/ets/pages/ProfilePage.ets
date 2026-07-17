import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { ProfileRepository } from '../data/repositories/ProfileRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { UserProfile } from '../domain/profile/ProfileModels';
import { YibuqueColor, YibuqueRadius, YibuqueShadow } from '../theme/Tokens';

const DEFAULT_FREQUENT_DISTRICTS: string[] = ['静安嘉里', 'iapm', '小众买手店', 'TX 淮海'];
const DEFAULT_SELECTED_FREQUENT_DISTRICTS: string[] = ['静安嘉里', 'iapm', '小众买手店'];

function parseOptionalNumber(value: string): number | undefined {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return undefined;
  }

  const parsed = Number(trimmed);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : undefined;
}

function displayOptionalNumber(value?: number): string {
  return value === undefined ? '' : `${value}`;
}

function isInvalidOptionalNumber(value: string): boolean {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return false;
  }

  const parsed = Number(trimmed);
  return !Number.isFinite(parsed) || parsed < 0;
}

function parseDistrictInput(value: string): string[] {
  const districts: string[] = [];
  for (const item of value.split(/[\n,，、]/)) {
    const district = item.trim();
    if (district.length > 0 && !districts.includes(district)) {
      districts.push(district);
    }
  }
  return districts;
}

function padNumber(value: number): string {
  return `${value}`.padStart(2, '0');
}

function formatProfileUpdatedAt(value: string): string {
  if (value.trim().length === 0) {
    return '';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return '';
  }

  return `${date.getFullYear()}-${padNumber(date.getMonth() + 1)}-${padNumber(date.getDate())} ` +
    `${padNumber(date.getHours())}:${padNumber(date.getMinutes())}`;
}

function describeMeasurements(profile: UserProfile): string {
  const parts: string[] = [];

  if (profile.heightCm !== undefined) {
    parts.push(`身高 ${profile.heightCm}cm`);
  }
  if (profile.weightKg !== undefined) {
    parts.push(`体重 ${profile.weightKg}kg`);
  }
  if (profile.waistCm !== undefined) {
    parts.push(`腰围 ${profile.waistCm}cm`);
  }

  return parts.length === 0 ? '填写身形信息后可用于试穿推荐' : parts.join(' · ');
}

function describeLocalState(profile: UserProfile): string {
  const updatedAt = formatProfileUpdatedAt(profile.updatedAt);
  if (updatedAt.length === 0) {
    return '衣柜照片、套装和逛店记录都保存在本机。';
  }

  return `身形信息更新于 ${updatedAt}，衣柜照片和记录保存在本机。`;
}

@Component
export struct ProfilePage {
  profileRepository?: ProfileRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  storeRepository?: StoreRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  onOpenStoreEditor: () => void = () => {};
  onOpenCapture: () => void = () => {};
  onOpenOutfits: () => void = () => {};
  onOpenWishlist: () => void = () => {};
  onNestedPageVisibilityChange: (visible: boolean) => void = (_visible: boolean) => {};

  @State private heightCm: string = '';
  @State private weightKg: string = '';
  @State private waistCm: string = '';
  @State private isLoading: boolean = false;
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';
  @State private savedMessage: string = '';
  @State private isEditingMeasurements: boolean = false;
  @State private isEditingDistricts: boolean = false;
  @State private districtDraft: string[] = [];
  @State private districtInput: string = '';
  @State private privacyModeEnabled: boolean = false;
  @State private frequentDistricts: string[] = [];
  @State private monthlyBudget: number = -1;
  @State private measurementSummary: string = '填写身形信息后可用于试穿推荐';
  @State private localSummary: string = '衣柜照片、套装和逛店记录都保存在本机。';
  @State private wardrobePhotoUris: string[] = [];
  @State private wardrobeItemCount: number = 0;
  @State private storeVisitCount: number = 0;
  @State private outfitCount: number = 0;

  aboutToAppear(): void {
    this.loadProfile();
    this.loadWardrobeSummary();
    this.loadActivitySummary();
  }

  private async loadProfile(): Promise<void> {
    if (this.profileRepository === undefined) {
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    this.savedMessage = '';

    try {
      const profile = await this.profileRepository.getProfile();
      this.applyProfile(profile);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载个人信息失败';
    } finally {
      this.isLoading = false;
    }
  }

  private applyProfile(profile: UserProfile): void {
    this.heightCm = displayOptionalNumber(profile.heightCm);
    this.weightKg = displayOptionalNumber(profile.weightKg);
    this.waistCm = displayOptionalNumber(profile.waistCm);
    this.frequentDistricts = profile.frequentDistricts;
    this.monthlyBudget = profile.monthlyBudget ?? -1;
    this.privacyModeEnabled = profile.privacyModeEnabled;
    this.measurementSummary = describeMeasurements(profile);
    this.localSummary = describeLocalState(profile);
  }

  private async loadWardrobeSummary(): Promise<void> {
    if (this.clothingRepository === undefined) {
      return;
    }

    try {
      const items = await this.clothingRepository.listClothing();
      const photoUris: string[] = [];
      for (const item of items) {
        for (const photoUri of item.photoUris) {
          if (photoUris.length < 3 && photoUri.length > 0) {
            photoUris.push(photoUri);
          }
        }
      }
      this.wardrobeItemCount = items.length;
      this.wardrobePhotoUris = photoUris;
    } catch (_error) {
      this.wardrobeItemCount = 0;
      this.wardrobePhotoUris = [];
    }
  }

  private async loadActivitySummary(): Promise<void> {
    try {
      if (this.storeRepository !== undefined) {
        this.storeVisitCount = (await this.storeRepository.listStoreVisits()).length;
      }
      if (this.outfitRepository !== undefined) {
        this.outfitCount = (await this.outfitRepository.listOutfits()).length;
      }
    } catch (_error) {
      this.storeVisitCount = 0;
      this.outfitCount = 0;
    }
  }

  private async saveProfile(): Promise<void> {
    if (this.profileRepository === undefined || this.isSaving) {
      return;
    }

    if (this.hasInvalidMeasurements()) {
      this.savedMessage = '';
      this.errorMessage = '请检查身高、体重、腰围，只填写 0 以上数字。';
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';
    this.savedMessage = '';

    try {
      const savedProfile = await this.profileRepository.saveProfile({
        heightCm: parseOptionalNumber(this.heightCm),
        weightKg: parseOptionalNumber(this.weightKg),
        waistCm: parseOptionalNumber(this.waistCm),
        frequentDistricts: this.frequentDistricts,
        monthlyBudget: this.monthlyBudget >= 0 ? this.monthlyBudget : undefined,
        privacyModeEnabled: this.privacyModeEnabled
      });
      this.applyProfile(savedProfile);
      this.savedMessage = '已保存个人信息';
      this.closeMeasurementEditor();
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存个人信息失败';
    } finally {
      this.isSaving = false;
    }
  }

  private hasInvalidMeasurements(): boolean {
    return isInvalidOptionalNumber(this.heightCm) ||
      isInvalidOptionalNumber(this.weightKg) ||
      isInvalidOptionalNumber(this.waistCm);
  }

  private measurementError(value: string): string {
    const trimmed = value.trim();
    if (trimmed.length === 0) {
      return '';
    }

    const parsed = Number(trimmed);
    if (!Number.isFinite(parsed)) {
      return '请输入数字';
    }
    if (parsed < 0) {
      return '不能小于 0';
    }
    return '';
  }

  private openMeasurementEditor(): void {
    this.isEditingMeasurements = true;
    this.errorMessage = '';
    this.savedMessage = '';
    this.onNestedPageVisibilityChange(true);
  }

  private closeMeasurementEditor(): void {
    this.isEditingMeasurements = false;
    this.onNestedPageVisibilityChange(false);
  }

  private cancelMeasurementEditor(): void {
    this.closeMeasurementEditor();
    this.errorMessage = '';
    this.savedMessage = '';
    this.loadProfile();
  }

  private openDistrictEditor(): void {
    this.districtDraft = this.frequentDistricts.length > 0
      ? this.frequentDistricts.slice()
      : DEFAULT_SELECTED_FREQUENT_DISTRICTS.slice();
    this.districtInput = this.frequentDistricts
      .filter((district: string) => !DEFAULT_FREQUENT_DISTRICTS.includes(district))
      .join('、');
    this.errorMessage = '';
    this.savedMessage = '';
    this.isEditingDistricts = true;
    this.onNestedPageVisibilityChange(true);
  }

  private closeDistrictEditor(): void {
    this.isEditingDistricts = false;
    this.onNestedPageVisibilityChange(false);
  }

  private cancelDistrictEditor(): void {
    this.closeDistrictEditor();
    this.errorMessage = '';
    this.savedMessage = '';
    this.loadProfile();
  }

  private availableDistricts(): string[] {
    const districts: string[] = DEFAULT_FREQUENT_DISTRICTS.slice();
    const candidates = this.frequentDistricts.concat(parseDistrictInput(this.districtInput));
    for (const district of candidates) {
      if (!districts.includes(district)) {
        districts.push(district);
      }
    }
    return districts;
  }

  private toggleDistrict(district: string): void {
    if (this.isSaving) {
      return;
    }

    if (this.districtDraft.includes(district)) {
      this.districtDraft = this.districtDraft.filter((item: string) => item !== district);
    } else {
      this.districtDraft = this.districtDraft.concat([district]);
    }
  }

  private async saveDistricts(): Promise<void> {
    if (this.profileRepository === undefined || this.isSaving) {
      return;
    }

    const available = this.availableDistricts();
    this.frequentDistricts = this.districtDraft.filter((district: string) => available.includes(district));
    await this.persistPreferences('常逛商圈已保存。');
    if (this.errorMessage.length === 0) {
      this.closeDistrictEditor();
    }
  }

  private showNotice(message: string): void {
    this.errorMessage = '';
    this.savedMessage = message;
  }

  private async persistPreferences(message: string): Promise<void> {
    if (this.profileRepository === undefined || this.isSaving) return;
    this.isSaving = true;
    try {
      const saved = await this.profileRepository.saveProfile({
        heightCm: parseOptionalNumber(this.heightCm),
        weightKg: parseOptionalNumber(this.weightKg),
        waistCm: parseOptionalNumber(this.waistCm),
        frequentDistricts: this.frequentDistricts,
        monthlyBudget: this.monthlyBudget >= 0 ? this.monthlyBudget : undefined,
        privacyModeEnabled: this.privacyModeEnabled
      });
      this.applyProfile(saved);
      this.showNotice(message);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存个人偏好失败';
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          this.ProfileHero()
          this.ProfileStats()
          this.PreferenceSection()

          if (this.errorMessage.length > 0 && !this.isEditingMeasurements) {
            this.NoticeText(this.errorMessage, YibuqueColor.danger)
          }
          if (this.savedMessage.length > 0) {
            this.NoticeText(this.savedMessage, YibuqueColor.actionBlack)
          }

          this.BudgetSection()
          this.ToolSection()
          this.ReminderSection()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 2, bottom: 132 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .backgroundColor(YibuqueColor.bgDefault)

      if (this.isEditingMeasurements || this.isEditingDistricts) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(YibuqueColor.scrimLight)
          .onClick(() => {
            if (this.isEditingMeasurements) {
              this.cancelMeasurementEditor();
            } else {
              this.cancelDistrictEditor();
            }
          })
      }

      if (this.isEditingMeasurements) {
        this.MeasurementSheet()
      }

      if (this.isEditingDistricts) {
        this.DistrictSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(YibuqueColor.bgDefault)
  }

  @Builder
  ProfileHero() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        Stack() {
          this.HeroPhoto(0)
        }
        .height('100%')
        .layoutWeight(11)

        Column() {
          Stack() {
            this.HeroPhoto(1)
          }
          .width('100%')
          .layoutWeight(1)

          Stack() {
            this.HeroPhoto(2)
          }
          .width('100%')
          .layoutWeight(1)
        }
        .height('100%')
        .layoutWeight(9)
      }
      .width('100%')
      .height('100%')
      .opacity(this.wardrobePhotoUris.length > 0 ? 0.76 : 1)

      Column() {
        Text('我的衣柜档案')
          .height(30)
          .padding({ left: 11, right: 11 })
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(this.wardrobePhotoUris.length > 0 ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.wardrobePhotoUris.length > 0 ? YibuqueColor.glassLight : YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.full)

        Blank()

        Column({ space: 6 }) {
          Text('周末逛店计划')
            .width('100%')
            .fontSize(28)
            .lineHeight(30)
            .fontWeight(FontWeight.Regular)
            .fontColor(this.wardrobePhotoUris.length > 0 ? YibuqueColor.textInverse : YibuqueColor.textPrimary)

          Text('尺码、预算、常逛商圈和回购提醒，都集中在这里管理。')
            .width(270)
            .fontSize(13)
            .lineHeight(18)
            .fontWeight(FontWeight.Regular)
            .fontColor(this.wardrobePhotoUris.length > 0 ? YibuqueColor.glassMedium : YibuqueColor.textSecondary)
            .maxLines(2)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(this.wardrobePhotoUris.length > 0 ? YibuqueColor.scrimMedium : YibuqueColor.transparent)
    }
    .width('100%')
    .height(176)
    .backgroundColor(this.wardrobePhotoUris.length > 0 ? YibuqueColor.cardWhite : YibuqueColor.iconAccentSurface)
    .borderRadius(YibuqueRadius.sheet)
    .clip(true)
    .shadow(YibuqueShadow.floating)
  }

  @Builder
  HeroPhoto(index: number) {
    if (this.wardrobePhotoUris.length > index) {
      Image(this.wardrobePhotoUris[index])
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    } else {
      Column() {
        SymbolGlyph($r('sys.symbol.hanger_and_towels'))
          .fontSize(index === 0 ? 34 : 24)
          .fontColor([YibuqueColor.textTertiary])
      }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.wardrobePhotoUris.length > 0
          ? (index === 0 ? YibuqueColor.cardWhite : YibuqueColor.cardSoftGray)
          : YibuqueColor.iconAccentSurface)
    }
  }

  @Builder
  ProfileStats() {
    Row({ space: 8 }) {
      this.StatItem('clothing', '件单品')
      this.StatItem('store', '次逛店')
      this.StatItem('outfit', '套搭配')
    }
    .width('100%')
    .margin({ top: 10, bottom: 14 })
  }

  @Builder
  StatItem(type: string, label: string) {
    Column({ space: 2 }) {
      Text(type === 'clothing' ? `${this.wardrobeItemCount}` :
        type === 'store' ? `${this.storeVisitCount}` : `${this.outfitCount}`)
        .width('100%')
        .fontSize(18)
        .lineHeight(20)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
      Text(label)
        .width('100%')
        .fontSize(11)
        .lineHeight(14)
        .fontColor(YibuqueColor.textSecondary)
    }
    .height(52)
    .layoutWeight(1)
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(YibuqueColor.bgDefault)
    .borderRadius(YibuqueRadius.xxl)
    .border({ width: 1, color: YibuqueColor.borderLight })
  }

  @Builder
  PreferenceSection() {
    Column() {
      this.SectionHeading('我的偏好', '用于推荐和记录')

      Column() {
        this.PreferenceRow('常用尺码', this.measurementSummary, 'size')
        Divider().strokeWidth(1).color(YibuqueColor.borderLight)
        this.PreferenceRow('常逛商圈', this.frequentDistricts.length > 0 ? this.frequentDistricts.join(' · ') : '尚未设置', 'shops')
      }
      .width('100%')
      .padding(14)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: YibuqueColor.borderLight })
    }
    .width('100%')
    .margin({ top: 14 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SectionHeading(title: string, meta: string) {
    Row({ space: 12 }) {
      Text(title)
        .layoutWeight(1)
        .fontSize(19)
        .lineHeight(23)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
      Text(meta)
        .fontSize(12)
        .lineHeight(18)
        .fontColor(YibuqueColor.textSecondary)
        .maxLines(1)
    }
    .width('100%')
    .margin({ bottom: 10 })
    .alignItems(VerticalAlign.Bottom)
  }

  @Builder
  PreferenceRow(title: string, subtitle: string, action: string) {
    Row({ space: 11 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (action === 'size') {
          SymbolGlyph($r('sys.symbol.shirt'))
            .fontSize(19)
            .fontColor([YibuqueColor.iconAccent])
        } else {
          SymbolGlyph($r('sys.symbol.mappin_and_rectangle'))
            .fontSize(19)
            .fontColor([YibuqueColor.iconAccent])
        }
      }
      .width(44)
      .height(44)
      .backgroundColor(YibuqueColor.iconAccentSurface)
      .borderRadius(YibuqueRadius.lg)

      Column({ space: 3 }) {
        Text(title)
          .width('100%')
          .fontSize(14)
          .lineHeight(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
        Text(subtitle)
          .width('100%')
          .fontSize(12)
          .lineHeight(16)
          .fontColor(YibuqueColor.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (action === 'shops') {
        Button('路线')
          .height(44)
          .padding({ left: 13, right: 13 })
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: YibuqueColor.borderMedium })
          .enabled(!this.isSaving)
          .onClick(() => {
            this.openDistrictEditor();
          })
      } else {
      Button(this.isLoading ? '加载中' : '编辑')
        .height(44)
        .padding({ left: 13, right: 13 })
        .fontSize(12)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.full)
        .border({
          width: 1,
          color: YibuqueColor.borderMedium
        })
        .enabled(!this.isSaving && (action !== 'size' || !this.isLoading))
        .onClick(() => {
          if (this.isSaving) {
            return;
          }
          if (action === 'size') {
            this.openMeasurementEditor();
          }
        })
      }
    }
    .width('100%')
    .height(64)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  NoticeText(message: string, color: string) {
    Text(message)
      .width('100%')
      .fontSize(12)
      .lineHeight(18)
      .fontColor(color)
      .margin({ top: 10 })
  }

  @Builder
  BudgetSection() {
    Column() {
      this.SectionHeading('预算提醒', this.monthlyBudget >= 0 ? `¥${this.monthlyBudget}` : '未设置')

      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Column({ space: 3 }) {
            Text('本月逛街预算')
              .width('100%')
              .fontSize(14)
              .lineHeight(17)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textPrimary)
            Text(this.storeVisitCount > 0 ? `已记录 ${this.storeVisitCount} 次逛店，预算尚未设置。` : '预算尚未设置。')
              .width('100%')
              .fontSize(12)
              .lineHeight(16)
              .fontColor(YibuqueColor.textSecondary)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(this.monthlyBudget >= 0 ? `¥${this.monthlyBudget}` : '--')
            .fontSize(20)
            .lineHeight(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row({ space: 10 }) {
          Text('消费记录暂未接入预算统计')
            .layoutWeight(1)
            .fontSize(12)
            .fontColor(YibuqueColor.textSecondary)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(15)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: YibuqueColor.borderLight })
    }
    .width('100%')
    .margin({ top: 14 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ToolSection() {
    Column() {
      this.SectionHeading('今天常用', '3 个入口')

      Grid() {
        GridItem() { this.ToolCard('新增逛店', '记录店铺、试穿和价格', 'store') }
        GridItem() { this.ToolCard('拍照录入', '把衣物照片补进衣柜', 'capture') }
        GridItem() { this.ToolCard('套装清单', '按通勤、约会、好走路', 'outfit') }
        GridItem() { this.ToolCard('心愿清单', '记下想买的心仪好物', 'wishlist') }
      }
      .width('100%')
      .height(218)
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
    }
    .width('100%')
    .margin({ top: 14 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ToolCard(title: string, subtitle: string, action: string) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        if (action === 'store') {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(22)
            .fontColor([YibuqueColor.textInverse])
        } else if (action === 'capture') {
          SymbolGlyph($r('sys.symbol.camera_fill'))
            .fontSize(20)
            .fontColor([YibuqueColor.textInverse])
        } else if (action === 'wishlist') {
          SymbolGlyph($r('sys.symbol.heart_fill'))
            .fontSize(20)
            .fontColor([YibuqueColor.actionBlack])
        } else {
          SymbolGlyph($r('sys.symbol.bag'))
            .fontSize(20)
            .fontColor([YibuqueColor.iconAccent])
        }
      }
      .width(40)
      .height(40)
      .backgroundColor(action === 'outfit'
        ? YibuqueColor.iconAccentSurface
        : action === 'wishlist' ? YibuqueColor.cardSurface : YibuqueColor.iconDarkSurface)
      .borderRadius(YibuqueRadius.lg)

      Blank()

      Column({ space: 3 }) {
        Text(title)
          .width('100%')
          .fontSize(14)
          .lineHeight(17)
          .fontWeight(FontWeight.Regular)
          .fontColor((action === 'outfit' || action === 'wishlist') ? YibuqueColor.textPrimary : YibuqueColor.textInverse)
        Text(subtitle)
          .width('100%')
          .fontSize((action === 'outfit' || action === 'wishlist') ? 9 : 11)
          .lineHeight(14)
          .fontColor((action === 'outfit' || action === 'wishlist') ? YibuqueColor.textSecondary : YibuqueColor.textDisabled)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor((action === 'outfit' || action === 'wishlist') ? YibuqueColor.cardSoftGray : YibuqueColor.cardDark)
    .borderRadius(YibuqueRadius.xxl)
    .border({ width: (action === 'outfit' || action === 'wishlist') ? 1 : 0, color: YibuqueColor.borderLight })
    .onClick(() => {
      if (action === 'store') {
        this.onOpenStoreEditor();
      } else if (action === 'capture') {
        this.onOpenCapture();
      } else if (action === 'wishlist') {
        this.onOpenWishlist();
      } else {
        this.onOpenOutfits();
      }
    })
  }

  @Builder
  ReminderSection() {
    Column() {
      this.SectionHeading('本地与隐私', '本地保存正常')

      Column() {
        this.LocalStateRow()
        Divider().strokeWidth(1).color(YibuqueColor.borderLight)
        this.ToggleRow('隐私模式', '隐藏价格和商场位置，适合给朋友看衣柜。', this.privacyModeEnabled, 'privacy')
      }
      .width('100%')
      .padding(14)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: YibuqueColor.borderLight })
    }
    .width('100%')
    .margin({ top: 14 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ToggleRow(title: string, subtitle: string, enabled: boolean, action: string) {
    Row({ space: 12 }) {
      Column({ space: 3 }) {
        Text(title)
          .width('100%')
          .fontSize(14)
          .lineHeight(17)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
        Text(subtitle)
          .width('100%')
          .fontSize(12)
          .lineHeight(16)
          .fontColor(YibuqueColor.textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        if (enabled) {
          Blank().layoutWeight(1)
        }
        Circle()
          .width(26)
          .height(26)
          .fill(YibuqueColor.bgDefault)
          .shadow(YibuqueShadow.soft)
        if (!enabled) {
          Blank().layoutWeight(1)
        }
      }
      .width(52)
      .height(32)
      .padding(3)
      .backgroundColor(enabled ? YibuqueColor.textPrimary : YibuqueColor.borderMedium)
      .borderRadius(YibuqueRadius.full)
      .enabled(!this.isSaving)
      .onClick(() => {
        if (this.isSaving) {
          return;
        }
        if (action === 'privacy') {
          this.privacyModeEnabled = !this.privacyModeEnabled;
          this.persistPreferences('隐私模式已保存。');
        }
      })
    }
    .width('100%')
    .height(74)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  LocalStateRow() {
    Column({ space: 3 }) {
      Text('本地照片与记录').width('100%').fontSize(14).fontColor(YibuqueColor.textPrimary)
      Text(this.localSummary).width('100%').fontSize(12).lineHeight(16).fontColor(YibuqueColor.textSecondary)
    }
    .width('100%')
    .height(74)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DistrictSheet() {
    Column() {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('管理常逛商圈')
            .width('100%')
            .fontSize(23)
            .lineHeight(27)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
          Text('会同步到逛店记录页，方便快速筛选路线。')
            .width('100%')
            .fontSize(12)
            .lineHeight(17)
            .fontColor(YibuqueColor.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('取消')
          .height(44)
          .padding({ left: 0, right: 0 })
          .fontSize(15)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.iconAccent)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.cancelDistrictEditor();
          })
      }
      .width('100%')
      .margin({ bottom: 14 })
      .alignItems(VerticalAlign.Top)

      Column({ space: 13 }) {
        Text('常逛地点')
          .width('100%')
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)

        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.availableDistricts(), (district: string) => {
            this.DistrictChip(district, this.districtDraft.includes(district))
          }, (district: string) => district)
        }
        .width('100%')

        Text('补充地点')
          .width('100%')
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)

        TextArea({ text: this.districtInput, placeholder: '例如：安福路、长乐路、武康路' })
          .width('100%')
          .height(86)
          .padding(12)
          .fontSize(14)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .backgroundColor(YibuqueColor.bgDefault)
          .borderRadius(YibuqueRadius.md)
          .border({ width: 1, color: YibuqueColor.borderMedium })
          .onChange((value: string) => {
            this.districtInput = value;
          })
      }
      .width('100%')
      .padding(13)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.xxl)
      .border({ width: 1, color: YibuqueColor.borderLight })

      Row({ space: 10 }) {
        Button('稍后')
          .height(44)
          .layoutWeight(1)
          .fontSize(13)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: YibuqueColor.borderMedium })
          .onClick(() => {
            this.cancelDistrictEditor();
          })

        Button() {
          if (this.isSaving) {
            LoadingProgress()
              .width(18)
              .height(18)
              .color(YibuqueColor.textInverse)
          } else {
            Text('保存')
              .fontSize(13)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textInverse)
          }
        }
          .height(44)
          .layoutWeight(1)
          .backgroundColor(YibuqueColor.textPrimary)
          .borderRadius(YibuqueRadius.full)
          .enabled(!this.isSaving)
          .onClick(() => {
            this.saveDistricts();
          })
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 34 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(YibuqueColor.bgDefault)
    .borderRadius({ topLeft: YibuqueRadius.sheet, topRight: YibuqueRadius.sheet, bottomLeft: 0, bottomRight: 0 })
    .shadow(YibuqueShadow.editorSheet)
  }

  @Builder
  DistrictChip(label: string, selected: boolean) {
    Button(label)
      .height(40)
      .padding({ left: 14, right: 14 })
      .margin({ right: 8, bottom: 8 })
      .fontSize(13)
      .fontWeight(FontWeight.Regular)
      .fontColor(selected ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
      .backgroundColor(selected ? YibuqueColor.textPrimary : YibuqueColor.bgDefault)
      .borderRadius(YibuqueRadius.full)
      .border({ width: 1, color: selected ? YibuqueColor.textPrimary : YibuqueColor.borderMedium })
      .enabled(!this.isSaving)
      .onClick(() => {
        this.toggleDistrict(label);
      })
  }

  @Builder
  MeasurementSheet() {
    Column() {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('编辑常用尺码')
            .width('100%')
            .fontSize(23)
            .lineHeight(27)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
          Text('保存后用于试穿记录和衣柜信息。')
            .width('100%')
            .fontSize(12)
            .lineHeight(17)
            .fontColor(YibuqueColor.textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('取消')
          .height(44)
          .padding({ left: 0, right: 0 })
          .fontSize(15)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.actionBlack)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.cancelMeasurementEditor();
          })
      }
      .width('100%')
      .margin({ bottom: 14 })
      .alignItems(VerticalAlign.Top)

      Row({ space: 10 }) {
        this.MeasurementField('身高', this.heightCm, 'cm')
        this.MeasurementField('体重', this.weightKg, 'kg')
        this.MeasurementField('腰围', this.waistCm, 'cm')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor(YibuqueColor.danger)
          .margin({ top: 10 })
      }

      Row({ space: 10 }) {
        Button('稍后')
          .height(44)
          .layoutWeight(1)
          .fontSize(13)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(YibuqueRadius.full)
          .border({ width: 1, color: YibuqueColor.borderMedium })
          .onClick(() => {
            this.cancelMeasurementEditor();
          })

        Button() {
          if (this.isSaving) {
            LoadingProgress()
              .width(18)
              .height(18)
              .color(YibuqueColor.textInverse)
          } else {
            Text('保存')
              .fontSize(13)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textInverse)
          }
        }
          .height(44)
          .layoutWeight(1)
          .backgroundColor(this.hasInvalidMeasurements() ? YibuqueColor.textTertiary : YibuqueColor.textPrimary)
          .borderRadius(YibuqueRadius.full)
          .enabled(!this.isSaving && !this.hasInvalidMeasurements())
          .onClick(() => {
            this.saveProfile();
          })
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 34 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(YibuqueColor.bgDefault)
    .borderRadius({ topLeft: YibuqueRadius.sheet, topRight: YibuqueRadius.sheet, bottomLeft: 0, bottomRight: 0 })
    .shadow(YibuqueShadow.sheetHandle)
  }

  @Builder
  MeasurementField(label: string, value: string, unit: string) {
    Column({ space: 6 }) {
      Text(label)
        .width('100%')
        .fontSize(12)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)

      TextInput({ text: value, placeholder: unit })
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .placeholderColor(YibuqueColor.textTertiary)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.md)
        .border({ width: 1, color: this.measurementError(value).length > 0 ? YibuqueColor.danger : YibuqueColor.borderMedium })
        .type(InputType.Number)
        .onChange((nextValue: string) => {
          this.errorMessage = '';
          if (label === '身高') {
            this.heightCm = nextValue;
          } else if (label === '体重') {
            this.weightKg = nextValue;
          } else {
            this.waistCm = nextValue;
          }
        })

      if (this.measurementError(value).length > 0) {
        Text(this.measurementError(value))
          .width('100%')
          .fontSize(11)
          .lineHeight(15)
          .fontColor(YibuqueColor.danger)
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
}
