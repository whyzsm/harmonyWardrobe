import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { ProfileRepository } from '../data/repositories/ProfileRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { UserProfile } from '../domain/profile/ProfileModels';
import { YibuqueColor, YibuqueRadius, YibuqueShadow } from '../theme/Tokens';

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
  @State private searchQuery: string = '';
  @State private isEditingMeasurements: boolean = false;
  @State private fittingPreferenceEnabled: boolean = false;
  @State private commuteSelected: boolean = false;
  @State private casualSelected: boolean = false;
  @State private datingSelected: boolean = false;
  @State private walkingSelected: boolean = false;
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
    this.fittingPreferenceEnabled = profile.fittingPreferenceEnabled;
    this.commuteSelected = profile.styleTags.includes('通勤');
    this.casualSelected = profile.styleTags.includes('休闲');
    this.datingSelected = profile.styleTags.includes('约会');
    this.walkingSelected = profile.styleTags.includes('好走路');
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
        waistCm: parseOptionalNumber(this.waistCm)
        , fittingPreferenceEnabled: this.fittingPreferenceEnabled,
        styleTags: this.selectedStyleTags(),
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

  private showNotice(message: string): void {
    this.errorMessage = '';
    this.savedMessage = message;
  }

  private selectedStyleTags(): string[] {
    const tags: string[] = [];
    if (this.commuteSelected) tags.push('通勤');
    if (this.casualSelected) tags.push('休闲');
    if (this.datingSelected) tags.push('约会');
    if (this.walkingSelected) tags.push('好走路');
    return tags;
  }

  private fittingPreferenceSummary(): string {
    if (!this.fittingPreferenceEnabled) {
      return '尚未启用';
    }

    const tags = this.selectedStyleTags();
    return tags.length > 0 ? tags.join(' · ') : '已启用';
  }

  private async persistPreferences(message: string): Promise<void> {
    if (this.profileRepository === undefined || this.isSaving) return;
    this.isSaving = true;
    try {
      const saved = await this.profileRepository.saveProfile({
        heightCm: parseOptionalNumber(this.heightCm),
        weightKg: parseOptionalNumber(this.weightKg),
        waistCm: parseOptionalNumber(this.waistCm),
        fittingPreferenceEnabled: this.fittingPreferenceEnabled,
        styleTags: this.selectedStyleTags(),
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

  private hasSearchResult(): boolean {
    const query = this.searchQuery.trim().toLowerCase();
    if (query.length === 0) {
      return true;
    }

    return '尺码 身高 体重 腰围 偏好 商场 商圈 风格 预算 回购 花费 提醒 工具 拍照 逛店 套装 心愿 导出 本地 隐私'.includes(query);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          this.ProfileHero()
          this.ProfileStats()
          this.ProfileSearch()
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

      if (this.isEditingMeasurements) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(YibuqueColor.scrimLight)
          .onClick(() => {
            this.cancelMeasurementEditor();
          })

        this.MeasurementSheet()
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
      .opacity(0.76)

      Column() {
        Text('我的衣柜档案')
          .height(30)
          .padding({ left: 11, right: 11 })
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textInverse)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.glassLight)
          .borderRadius(YibuqueRadius.full)

        Blank()

        Column({ space: 6 }) {
          Text('周末逛店计划')
            .width('100%')
            .fontSize(28)
            .lineHeight(30)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textInverse)

          Text('尺码、预算、常逛商圈和回购提醒，都集中在这里管理。')
            .width(270)
            .fontSize(13)
            .lineHeight(18)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.glassMedium)
            .maxLines(2)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(YibuqueColor.scrimMedium)
    }
    .width('100%')
    .height(176)
    .backgroundColor(YibuqueColor.textPrimary)
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
        .backgroundColor(index === 0 ? YibuqueColor.borderLight : YibuqueColor.cardSurface)
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
  ProfileSearch() {
    Column({ space: 14 }) {
      Row({ space: 9 }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(18)
          .fontColor([YibuqueColor.textSecondary])

        TextInput({ text: this.searchQuery, placeholder: '找尺码、预算、商场、提醒' })
          .height(46)
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)
          .placeholderColor(YibuqueColor.textTertiary)
          .backgroundColor(Color.Transparent)
          .enterKeyType(EnterKeyType.Search)
          .onChange((value: string) => {
            this.searchQuery = value;
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 14, right: 14 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(YibuqueColor.bgDefault)
      .borderRadius(YibuqueRadius.md)
      .border({ width: 1, color: YibuqueColor.borderMedium })

      if (!this.hasSearchResult()) {
        Column({ space: 4 }) {
          Text('没找到这项设置')
            .width('100%')
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
          Text('换个关键词，或从下面的工具入口继续管理。')
            .width('100%')
            .fontSize(12)
            .lineHeight(18)
            .fontColor(YibuqueColor.textSecondary)
        }
        .width('100%')
        .padding(18)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.xxl)
        .border({ width: 1, color: YibuqueColor.borderMedium })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PreferenceSection() {
    Column() {
      this.SectionHeading('我的偏好', '用于推荐和记录')

      Column() {
        this.PreferenceRow('常用尺码', this.measurementSummary, 'size')
        Divider().strokeWidth(1).color(YibuqueColor.borderLight)
        this.PreferenceRow('试穿偏好', this.fittingPreferenceSummary(), 'preference')
        Divider().strokeWidth(1).color(YibuqueColor.borderLight)
        this.PreferenceRow('常逛商圈', this.frequentDistricts.length > 0 ? this.frequentDistricts.join(' · ') : '尚未设置', 'shops')
        this.StyleTags()
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
            .fontColor([YibuqueColor.actionBlack])
        } else if (action === 'preference') {
          SymbolGlyph($r('sys.symbol.heart'))
            .fontSize(19)
            .fontColor([YibuqueColor.actionBlack])
        } else {
          SymbolGlyph($r('sys.symbol.mappin_and_rectangle'))
            .fontSize(19)
            .fontColor([YibuqueColor.actionBlack])
        }
      }
      .width(44)
      .height(44)
      .backgroundColor(YibuqueColor.cardSurface)
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
        Text(this.frequentDistricts.length > 0 ? `${this.frequentDistricts.length} 个` : '未设置')
          .fontSize(12)
          .fontColor(YibuqueColor.textSecondary)
      } else {
      Button(action === 'size' ? (this.isLoading ? '加载中' : '编辑') :
        (this.fittingPreferenceEnabled ? '已启用' : '未启用'))
        .height(44)
        .padding({ left: 13, right: 13 })
        .fontSize(12)
        .fontWeight(FontWeight.Regular)
        .fontColor(action === 'preference' && this.fittingPreferenceEnabled ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
        .backgroundColor(action === 'preference' && this.fittingPreferenceEnabled ? YibuqueColor.textPrimary : YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.full)
        .border({
          width: 1,
          color: action === 'preference' && this.fittingPreferenceEnabled ? YibuqueColor.textPrimary : YibuqueColor.borderMedium
        })
        .enabled(!this.isSaving && (action !== 'size' || !this.isLoading))
        .onClick(() => {
          if (this.isSaving) {
            return;
          }
          if (action === 'size') {
            this.openMeasurementEditor();
          } else if (action === 'preference') {
            this.fittingPreferenceEnabled = !this.fittingPreferenceEnabled;
            this.persistPreferences('试穿偏好已保存。');
          }
        })
      }
    }
    .width('100%')
    .height(64)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  StyleTags() {
    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      this.StyleTag('通勤', this.commuteSelected, 'commute')
      this.StyleTag('休闲', this.casualSelected, 'casual')
      this.StyleTag('约会', this.datingSelected, 'dating')
      this.StyleTag('好走路', this.walkingSelected, 'walking')
    }
    .width('100%')
    .padding({ top: 11 })
  }

  @Builder
  StyleTag(label: string, selected: boolean, key: string) {
    Text(label)
      .constraintSize({ minHeight: 44 })
      .padding({ left: 12, right: 12 })
      .margin({ right: 8, bottom: 8 })
      .fontSize(12)
      .fontWeight(FontWeight.Regular)
      .fontColor(selected ? YibuqueColor.textInverse : YibuqueColor.textSecondary)
      .textAlign(TextAlign.Center)
      .backgroundColor(selected ? YibuqueColor.textPrimary : YibuqueColor.cardSoftGray)
      .borderRadius(YibuqueRadius.full)
      .border({ width: 1, color: selected ? YibuqueColor.textPrimary : YibuqueColor.borderMedium })
      .enabled(!this.isSaving)
      .onClick(() => {
        if (this.isSaving) {
          return;
        }
        if (key === 'commute') {
          this.commuteSelected = !this.commuteSelected;
        } else if (key === 'casual') {
          this.casualSelected = !this.casualSelected;
        } else if (key === 'dating') {
          this.datingSelected = !this.datingSelected;
        } else {
          this.walkingSelected = !this.walkingSelected;
        }
        this.persistPreferences('风格偏好已保存。');
      })
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
            .fontColor([YibuqueColor.actionBlack])
        }
      }
      .width(40)
      .height(40)
      .backgroundColor((action === 'outfit' || action === 'wishlist') ? YibuqueColor.cardSurface : YibuqueColor.iconDarkSurface)
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
