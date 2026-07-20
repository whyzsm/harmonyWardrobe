import { ClothingRepository, ClothingSummary } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { ProfileRepository } from '../data/repositories/ProfileRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import {
  PROFILE_HEIGHT_MAX_CM,
  PROFILE_HEIGHT_MIN_CM,
  PROFILE_WAIST_MAX_CM,
  PROFILE_WAIST_MIN_CM,
  PROFILE_WEIGHT_MAX_KG,
  PROFILE_WEIGHT_MIN_KG,
  UserProfile
} from '../domain/profile/ProfileModels';
import { YibuqueColor, YibuqueMotion, YibuqueRadius, YibuqueShadow } from '../theme/Tokens';
import { userFacingError } from '../utils/userFacingError';

const DEFAULT_FREQUENT_DISTRICTS: string[] = ['静安嘉里', 'iapm', '小众买手店', 'TX 淮海'];
const DEFAULT_SELECTED_FREQUENT_DISTRICTS: string[] = ['静安嘉里', 'iapm', '小众买手店'];
const DEFAULT_COMMON_BUDGETS: number[] = [2400, 3200, 4000];
const MAX_COMMON_ITEMS: number = 3;
const GENERIC_NUMBER_MAX: number = 100000000;

function parseOptionalNumber(value: string, min: number = 0, max: number = GENERIC_NUMBER_MAX): number | undefined {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return undefined;
  }

  const parsed = Number(trimmed);
  return Number.isFinite(parsed) && parsed >= min && parsed <= max ? parsed : undefined;
}

function displayOptionalNumber(value?: number): string {
  return value === undefined ? '' : `${value}`;
}

function isInvalidOptionalNumber(value: string, min: number = 0, max: number = GENERIC_NUMBER_MAX): boolean {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return false;
  }

  const parsed = Number(trimmed);
  return !Number.isFinite(parsed) || parsed < min || parsed > max;
}

function currentYearMonth(): string {
  const now = new Date();
  return `${now.getFullYear()}-${padNumber(now.getMonth() + 1)}`;
}

function formatBudgetAmount(value: number): string {
  const digits = `${Math.round(Math.max(0, value))}`;
  let formatted = '';
  for (let index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 === 0) {
      formatted += ',';
    }
    formatted += digits.charAt(index);
  }
  return `¥${formatted}`;
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
  const sizeParts: string[] = [];
  if (profile.upperSize !== undefined) {
    sizeParts.push(`上衣 ${profile.upperSize}`);
  }
  if (profile.lowerSize !== undefined) {
    sizeParts.push(`裤装 ${profile.lowerSize}`);
  }
  if (profile.shoeSize !== undefined) {
    sizeParts.push(`鞋 ${profile.shoeSize}`);
  }
  if (sizeParts.length > 0) {
    return sizeParts.join(' · ');
  }

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

  return parts.length === 0 ? '填写身形信息后可用于试穿记录' : parts.join(' · ');
}

function describeLocalState(profile: UserProfile): string {
  const updatedAt = formatProfileUpdatedAt(profile.updatedAt);
  if (updatedAt.length === 0) {
    return '衣柜照片、穿搭和逛店记录都保存在本机。';
  }

  return `身形信息更新于 ${updatedAt}，衣柜照片和记录保存在本机。`;
}

@Component
export struct ProfilePage {
  profileRepository?: ProfileRepository = undefined;
  clothingRepository?: ClothingRepository = undefined;
  storeRepository?: StoreRepository = undefined;
  outfitRepository?: OutfitRepository = undefined;
  onOpenWishlist: () => void = () => {};
  onNestedPageVisibilityChange: (visible: boolean) => void = (_visible: boolean) => {};

  @State private heightCm: string = '';
  @State private weightKg: string = '';
  @State private waistCm: string = '';
  @State private upperSize: string = '';
  @State private lowerSize: string = '';
  @State private shoeSize: string = '';
  @State private isLoading: boolean = false;
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';
  @State private savedMessage: string = '';
  @State private isEditingMeasurements: boolean = false;
  @State private isEditingDistricts: boolean = false;
  @State private districtDraft: string[] = [];
  @State private districtInput: string = '';
  private sheetTransitionInProgress: boolean = false;
  @State private frequentDistricts: string[] = [];
  @State private monthlyBudget: number = -1;
  @State private commonBudgets: number[] = DEFAULT_COMMON_BUDGETS.slice();
  @State private monthlySpent: number = 0;
  @State private isEditingBudget: boolean = false;
  @State private budgetDraft: string = '';
  @State private budgetErrorMessage: string = '';
  @State private measurementSummary: string = '填写身形信息后可用于试穿记录';
  @State private localSummary: string = '衣柜照片、穿搭和逛店记录都保存在本机。';
  @State private wardrobeItemCount: number = 0;
  @State private storeVisitCount: number = 0;
  @State private outfitCount: number = 0;
  aboutToAppear(): void {
    this.loadProfile();
    this.loadActivitySummary();
  }

  aboutToDisappear(): void {
    this.onNestedPageVisibilityChange(false);
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
      this.errorMessage = userFacingError(error, '加载个人信息失败');
    } finally {
      this.isLoading = false;
    }
  }

  private applyProfile(profile: UserProfile): void {
    this.heightCm = displayOptionalNumber(profile.heightCm);
    this.weightKg = displayOptionalNumber(profile.weightKg);
    this.waistCm = displayOptionalNumber(profile.waistCm);
    this.upperSize = profile.upperSize ?? '';
    this.lowerSize = profile.lowerSize ?? '';
    this.shoeSize = profile.shoeSize ?? '';
    this.frequentDistricts = profile.frequentDistricts.slice(0, MAX_COMMON_ITEMS);
    this.monthlyBudget = profile.monthlyBudget ?? -1;
    this.commonBudgets = profile.commonBudgets.slice(0, MAX_COMMON_ITEMS);
    this.measurementSummary = describeMeasurements(profile);
    this.localSummary = describeLocalState(profile);
  }

  private currentMeasurementSummary(): string {
    const sizeParts: string[] = [];
    const upperSize = this.upperSize.trim();
    const lowerSize = this.lowerSize.trim();
    const shoeSize = this.shoeSize.trim();
    if (upperSize.length > 0) {
      sizeParts.push(`上衣 ${upperSize}`);
    }
    if (lowerSize.length > 0) {
      sizeParts.push(`裤装 ${lowerSize}`);
    }
    if (shoeSize.length > 0) {
      sizeParts.push(`鞋 ${shoeSize}`);
    }
    if (sizeParts.length > 0) {
      return sizeParts.join(' · ');
    }

    const bodyParts: string[] = [];
    const height = this.parseHeightCm();
    const weight = this.parseWeightKg();
    const waist = this.parseWaistCm();
    if (height !== undefined) {
      bodyParts.push(`身高 ${height}cm`);
    }
    if (weight !== undefined) {
      bodyParts.push(`体重 ${weight}kg`);
    }
    if (waist !== undefined) {
      bodyParts.push(`腰围 ${waist}cm`);
    }
    return bodyParts.length > 0 ? bodyParts.join(' · ') : '填写身形信息后可用于试穿记录';
  }

  private currentDistrictSummary(): string {
    return this.frequentDistricts.length > 0 ? this.frequentDistricts.join(' · ') : '尚未设置';
  }

  private async loadActivitySummary(): Promise<void> {
    try {
      let clothingSummary: ClothingSummary = { totalCount: 0, monthlySpent: 0 };
      let storeVisitCount = 0;
      let outfitCount = 0;

      if (this.clothingRepository !== undefined) {
        clothingSummary = await this.clothingRepository.getClothingSummary(currentYearMonth());
      }
      if (this.storeRepository !== undefined) {
        storeVisitCount = await this.storeRepository.getStoreVisitCount();
      }
      if (this.outfitRepository !== undefined) {
        outfitCount = await this.outfitRepository.getOutfitCount();
      }

      this.wardrobeItemCount = clothingSummary.totalCount;
      this.monthlySpent = clothingSummary.monthlySpent;
      this.storeVisitCount = storeVisitCount;
      this.outfitCount = outfitCount;
    } catch (_error) {
      this.wardrobeItemCount = 0;
      this.monthlySpent = 0;
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
      this.errorMessage = '请检查身高、体重、腰围，填写合理数字。';
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';
    this.savedMessage = '';

    try {
      const savedProfile = await this.profileRepository.saveProfile({
        heightCm: this.parseHeightCm(),
        weightKg: this.parseWeightKg(),
        waistCm: this.parseWaistCm(),
        upperSize: this.upperSize,
        lowerSize: this.lowerSize,
        shoeSize: this.shoeSize,
        frequentDistricts: this.frequentDistricts,
        monthlyBudget: this.monthlyBudget >= 0 ? this.monthlyBudget : undefined,
        commonBudgets: this.commonBudgets
      });
      this.applyProfile(savedProfile);
      this.savedMessage = '已保存个人信息';
      this.closeMeasurementEditor();
    } catch (error) {
      this.errorMessage = userFacingError(error, '保存个人信息失败');
    } finally {
      this.isSaving = false;
    }
  }

  private hasInvalidMeasurements(): boolean {
    return isInvalidOptionalNumber(this.heightCm, PROFILE_HEIGHT_MIN_CM, PROFILE_HEIGHT_MAX_CM) ||
      isInvalidOptionalNumber(this.weightKg, PROFILE_WEIGHT_MIN_KG, PROFILE_WEIGHT_MAX_KG) ||
      isInvalidOptionalNumber(this.waistCm, PROFILE_WAIST_MIN_CM, PROFILE_WAIST_MAX_CM);
  }

  private parseHeightCm(): number | undefined {
    return parseOptionalNumber(this.heightCm, PROFILE_HEIGHT_MIN_CM, PROFILE_HEIGHT_MAX_CM);
  }

  private parseWeightKg(): number | undefined {
    return parseOptionalNumber(this.weightKg, PROFILE_WEIGHT_MIN_KG, PROFILE_WEIGHT_MAX_KG);
  }

  private parseWaistCm(): number | undefined {
    return parseOptionalNumber(this.waistCm, PROFILE_WAIST_MIN_CM, PROFILE_WAIST_MAX_CM);
  }

  private measurementMin(label: string): number {
    if (label === '身高') {
      return PROFILE_HEIGHT_MIN_CM;
    }
    if (label === '体重') {
      return PROFILE_WEIGHT_MIN_KG;
    }
    return PROFILE_WAIST_MIN_CM;
  }

  private measurementMax(label: string): number {
    if (label === '身高') {
      return PROFILE_HEIGHT_MAX_CM;
    }
    if (label === '体重') {
      return PROFILE_WEIGHT_MAX_KG;
    }
    return PROFILE_WAIST_MAX_CM;
  }

  private measurementError(label: string, value: string, unit: string): string {
    const trimmed = value.trim();
    if (trimmed.length === 0) {
      return '';
    }

    const parsed = Number(trimmed);
    if (!Number.isFinite(parsed)) {
      return '请输入数字';
    }
    if (parsed < this.measurementMin(label) || parsed > this.measurementMax(label)) {
      return `请输入 ${this.measurementMin(label)}-${this.measurementMax(label)}${unit}`;
    }
    return '';
  }

  private animateSheetChange(change: () => void): void {
    if (this.sheetTransitionInProgress) {
      return;
    }

    this.sheetTransitionInProgress = true;
    this.getUIContext().animateTo({
      duration: YibuqueMotion.sheetTransition,
      curve: Curve.EaseOut,
      onFinish: () => {
        this.sheetTransitionInProgress = false;
      }
    }, () => {
      change();
    });
  }

  private openMeasurementEditor(): void {
    this.errorMessage = '';
    this.savedMessage = '';
    this.animateSheetChange(() => {
      this.isEditingMeasurements = true;
      this.onNestedPageVisibilityChange(true);
    });
  }

  private closeMeasurementEditor(): void {
    this.animateSheetChange(() => {
      this.isEditingMeasurements = false;
      this.onNestedPageVisibilityChange(false);
    });
  }

  private cancelMeasurementEditor(): void {
    this.closeMeasurementEditor();
    this.errorMessage = '';
    this.savedMessage = '';
    this.loadProfile();
  }

  private openBudgetEditor(): void {
    this.budgetDraft = this.monthlyBudget >= 0 ? `${this.monthlyBudget}` : '';
    this.budgetErrorMessage = '';
    this.errorMessage = '';
    this.savedMessage = '';
    this.animateSheetChange(() => {
      this.isEditingBudget = true;
      this.onNestedPageVisibilityChange(true);
    });
  }

  private closeBudgetEditor(): void {
    this.animateSheetChange(() => {
      this.isEditingBudget = false;
      this.onNestedPageVisibilityChange(false);
    });
    this.budgetErrorMessage = '';
  }

  private cancelBudgetEditor(): void {
    this.closeBudgetEditor();
    this.errorMessage = '';
    this.savedMessage = '';
    this.loadProfile();
  }

  private selectBudget(value: number): void {
    if (this.isSaving) {
      return;
    }

    this.budgetDraft = `${value}`;
    this.budgetErrorMessage = '';
  }

  private removeBudget(value: number): void {
    if (this.isSaving) {
      return;
    }

    this.commonBudgets = this.commonBudgets.filter((item: number) => item !== value);
    if (this.budgetDraft === `${value}`) {
      this.budgetDraft = '';
    }
    this.budgetErrorMessage = '';
  }

  private budgetProgressPercent(): number {
    if (this.monthlyBudget < 0 || this.monthlyBudget === 0) {
      return 0;
    }

    return Math.min(100, Math.round((this.monthlySpent / this.monthlyBudget) * 100));
  }

  private budgetRemaining(): number {
    return Math.max(0, this.monthlyBudget - this.monthlySpent);
  }

  private async saveBudget(): Promise<void> {
    if (this.profileRepository === undefined || this.isSaving) {
      return;
    }

    const inputAmount = parseOptionalNumber(this.budgetDraft);
    const amount = inputAmount ?? (this.monthlyBudget >= 0 ? this.monthlyBudget : undefined);
    if (amount === undefined || amount < 500) {
      this.budgetErrorMessage = '预算至少为 ¥500。';
      return;
    }

    this.isSaving = true;
    this.budgetErrorMessage = '';
    this.errorMessage = '';
    try {
      const nextCommonBudgets = inputAmount === undefined
        ? this.commonBudgets
        : [Math.round(amount)].concat(this.commonBudgets.filter((value: number) => value !== Math.round(amount)))
          .slice(0, MAX_COMMON_ITEMS);
      const saved = await this.profileRepository.saveProfile({
        heightCm: this.parseHeightCm(),
        weightKg: this.parseWeightKg(),
        waistCm: this.parseWaistCm(),
        upperSize: this.upperSize,
        lowerSize: this.lowerSize,
        shoeSize: this.shoeSize,
        frequentDistricts: this.frequentDistricts,
        monthlyBudget: Math.round(amount),
        commonBudgets: nextCommonBudgets
      });
      this.applyProfile(saved);
      this.showNotice('本月预算已保存。');
      this.closeBudgetEditor();
    } catch (error) {
      this.budgetErrorMessage = userFacingError(error, '保存预算失败');
    } finally {
      this.isSaving = false;
    }
  }

  private openDistrictEditor(): void {
    this.districtDraft = this.frequentDistricts.length > 0
      ? this.frequentDistricts.slice()
      : DEFAULT_SELECTED_FREQUENT_DISTRICTS.slice();
    this.districtInput = '';
    this.errorMessage = '';
    this.savedMessage = '';
    this.animateSheetChange(() => {
      this.isEditingDistricts = true;
      this.onNestedPageVisibilityChange(true);
    });
  }

  private closeDistrictEditor(): void {
    this.animateSheetChange(() => {
      this.isEditingDistricts = false;
      this.onNestedPageVisibilityChange(false);
    });
  }

  private cancelDistrictEditor(): void {
    this.closeDistrictEditor();
    this.errorMessage = '';
    this.savedMessage = '';
    this.loadProfile();
  }

  private availableDistricts(): string[] {
    const districts: string[] = [];
    const candidates = parseDistrictInput(this.districtInput)
      .concat(this.districtDraft)
      .concat(this.frequentDistricts)
      .concat(DEFAULT_FREQUENT_DISTRICTS);
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
      const nextDistricts = this.districtDraft.filter((item: string) => item !== district);
      if (nextDistricts.length >= MAX_COMMON_ITEMS) {
        nextDistricts.shift();
      }
      this.districtDraft = nextDistricts.concat([district]);
    }
  }

  private async saveDistricts(): Promise<void> {
    if (this.profileRepository === undefined || this.isSaving) {
      return;
    }

    const typedDistricts = parseDistrictInput(this.districtInput);
    const nextDistricts: string[] = [];
    for (const district of typedDistricts.concat(this.districtDraft)) {
      if (!nextDistricts.includes(district) && nextDistricts.length < MAX_COMMON_ITEMS) {
        nextDistricts.push(district);
      }
    }
    this.frequentDistricts = nextDistricts;
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
        heightCm: this.parseHeightCm(),
        weightKg: this.parseWeightKg(),
        waistCm: this.parseWaistCm(),
        upperSize: this.upperSize,
        lowerSize: this.lowerSize,
        shoeSize: this.shoeSize,
        frequentDistricts: this.frequentDistricts,
        monthlyBudget: this.monthlyBudget >= 0 ? this.monthlyBudget : undefined,
        commonBudgets: this.commonBudgets
      });
      this.applyProfile(saved);
      this.showNotice(message);
    } catch (error) {
      this.errorMessage = userFacingError(error, '保存个人偏好失败');
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
          this.LocalStorageSection()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 2, bottom: 132 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .backgroundColor(YibuqueColor.bgDefault)

      if (this.isEditingMeasurements || this.isEditingDistricts || this.isEditingBudget) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(YibuqueColor.scrimLight)
          .hitTestBehavior(HitTestMode.Block)
          .transition(TransitionEffect.OPACITY)
          .onClick(() => {
            if (this.isEditingMeasurements) {
              this.cancelMeasurementEditor();
            } else if (this.isEditingDistricts) {
              this.cancelDistrictEditor();
            } else {
              this.cancelBudgetEditor();
            }
          })
      }

      if (this.isEditingMeasurements) {
        this.MeasurementSheet()
      }

      if (this.isEditingDistricts) {
        this.DistrictSheet()
      }

      if (this.isEditingBudget) {
        this.BudgetSheet()
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
        Column() {
          Text('我的衣柜档案')
            .height(30)
            .padding({ left: 11, right: 11 })
            .fontSize(12)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .textAlign(TextAlign.Center)
            .backgroundColor(YibuqueColor.cardWhite)
            .borderRadius(YibuqueRadius.full)

          Blank()

          Column({ space: 6 }) {
            Text('周末逛店计划')
              .width('100%')
              .fontSize(24)
              .lineHeight(28)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textPrimary)
              .maxLines(1)

            Text('尺码、预算、常逛商圈和购买备注，都集中在这里管理。')
              .width('100%')
              .fontSize(13)
              .lineHeight(18)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textSecondary)
              .maxLines(2)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .height('100%')
        .padding(16)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(YibuqueColor.transparent)
    }
    .width('100%')
    .height(176)
    .backgroundColor(YibuqueColor.profileHeroSurface)
    .borderRadius(YibuqueRadius.sheet)
    .clip(true)
    .shadow(YibuqueShadow.floating)
  }

  @Builder
  ProfileStats() {
    Row({ space: 8 }) {
      this.StatItem('clothing', '件单品')
      this.StatItem('store', '次逛店')
      this.StatItem('outfit', '套搭配')
    }
    .width('100%')
    .margin({ top: 14, bottom: 14 })
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
      this.SectionHeading('我的偏好', '用于记录和整理')

      Column() {
        this.PreferenceRow('常用尺码', '', 'size')
        Divider().strokeWidth(1).color(YibuqueColor.borderLight)
        this.PreferenceRow('常逛商圈', '', 'shops')
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
  WishlistSection() {
    Column() {
      this.SectionHeading('我的清单', '计划购买')

      Column() {
        this.PreferenceRow('心愿清单', '记录想买的单品、门店和价格', 'wishlist')
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
        } else if (action === 'shops') {
          SymbolGlyph($r('sys.symbol.mappin_and_rectangle'))
            .fontSize(19)
            .fontColor([YibuqueColor.iconAccent])
        } else {
          SymbolGlyph($r('sys.symbol.heart_fill'))
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
        Text(action === 'size' ? this.currentMeasurementSummary() :
          action === 'shops' ? this.currentDistrictSummary() : subtitle)
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
        Button('编辑')
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
      Button(action === 'wishlist' ? '查看' : this.isLoading ? '加载中' : '编辑')
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
          } else if (action === 'wishlist') {
            this.onOpenWishlist();
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
      this.SectionHeading('预算提醒', this.monthlyBudget >= 0
        ? `本月 ${formatBudgetAmount(this.monthlyBudget)}`
        : '未设置')

      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Column({ space: 3 }) {
            Text('本月逛店预算')
              .width('100%')
              .fontSize(14)
              .lineHeight(17)
              .fontWeight(FontWeight.Regular)
              .fontColor(YibuqueColor.textPrimary)
            Text(this.monthlyBudget >= 0
              ? (this.budgetRemaining() > 0
                ? `还可用 ${formatBudgetAmount(this.budgetRemaining())}，适合再留一件主单品。`
                : '已达到本月预算。')
              : (this.storeVisitCount > 0 ? `已记录 ${this.storeVisitCount} 次逛店，预算尚未设置。` : '预算尚未设置。'))
              .width('100%')
              .fontSize(12)
              .lineHeight(16)
              .fontColor(YibuqueColor.textSecondary)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(this.monthlyBudget >= 0 ? formatBudgetAmount(this.budgetRemaining()) : '--')
            .fontSize(20)
            .lineHeight(22)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .accessibilityText(this.monthlyBudget >= 0
              ? `本月剩余预算 ${formatBudgetAmount(this.budgetRemaining())}`
              : '尚未设置预算')
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        if (this.monthlyBudget >= 0) {
          Row() {
            Blank()
              .width(`${this.budgetProgressPercent()}%`)
              .height(8)
              .backgroundColor(YibuqueColor.iconAccent)
              .borderRadius(YibuqueRadius.full)
          }
          .width('100%')
          .height(8)
          .backgroundColor(YibuqueColor.borderLight)
          .borderRadius(YibuqueRadius.full)
        }

        Row({ space: 10 }) {
          Text(this.monthlyBudget >= 0 ? `预算 ${formatBudgetAmount(this.monthlyBudget)}` : '消费记录将用于预算统计')
            .layoutWeight(1)
            .fontSize(12)
            .fontColor(YibuqueColor.textSecondary)

          Button('调整')
            .height(40)
            .padding({ left: 18, right: 18 })
            .fontSize(13)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
            .backgroundColor(YibuqueColor.bgDefault)
            .borderRadius(YibuqueRadius.full)
            .border({ width: 1, color: YibuqueColor.borderMedium })
            .enabled(!this.isSaving)
            .onClick(() => {
              this.openBudgetEditor();
            })
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
  BudgetChip(value: number, selected: boolean) {
    Row({ space: 0 }) {
      Button(formatBudgetAmount(value))
        .height(40)
        .padding({ left: 16, right: 12 })
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(selected ? YibuqueColor.textInverse : YibuqueColor.textPrimary)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .border({ width: 0, color: Color.Transparent })
        .enabled(!this.isSaving)
        .accessibilityText(`${formatBudgetAmount(value)}，选择预算`)
        .onClick(() => {
          this.selectBudget(value);
        })

      Button() {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(11)
          .fontColor([selected ? YibuqueColor.textInverse : YibuqueColor.textSecondary])
      }
        .width(32)
        .height(40)
        .padding({ left: 0, right: 0 })
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .border({ width: 0, color: Color.Transparent })
        .enabled(!this.isSaving)
        .accessibilityText(`删除常用预算 ${formatBudgetAmount(value)}`)
        .onClick(() => {
          this.removeBudget(value);
        })
    }
    .height(40)
    .backgroundColor(selected ? YibuqueColor.textPrimary : YibuqueColor.bgDefault)
    .borderRadius(YibuqueRadius.full)
    .border({ width: 1, color: selected ? YibuqueColor.textPrimary : YibuqueColor.borderMedium })
    .margin({ right: 8, bottom: 8 })
  }

  @Builder
  BudgetSheet() {
    Column() {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('调整本月预算')
            .width('100%')
            .fontSize(23)
            .lineHeight(27)
            .fontWeight(FontWeight.Regular)
            .fontColor(YibuqueColor.textPrimary)
          Text('保存后可以查看本月预算余量。')
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
            this.cancelBudgetEditor();
          })
      }
      .width('100%')
      .margin({ bottom: 14 })
      .alignItems(VerticalAlign.Top)

      Column({ space: 13 }) {
        Text('常用预算')
          .width('100%')
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)

        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.commonBudgets, (value: number) => {
            this.BudgetChip(value, this.budgetDraft === `${value}`)
          }, (value: number) => `${value}`)
        }
        .width('100%')

        Text('自定义金额')
          .width('100%')
          .fontSize(12)
          .fontWeight(FontWeight.Regular)
          .fontColor(YibuqueColor.textPrimary)

        TextInput({ text: this.budgetDraft, placeholder: '输入预算金额' })
          .width('100%')
          .height(48)
          .padding({ left: 14, right: 14 })
          .fontSize(14)
          .fontColor(YibuqueColor.textPrimary)
          .backgroundColor(YibuqueColor.bgDefault)
          .borderRadius(YibuqueRadius.md)
          .border({ width: 1, color: this.budgetErrorMessage.length > 0 ? YibuqueColor.danger : YibuqueColor.borderMedium })
          .type(InputType.Number)
          .enabled(!this.isSaving)
          .onChange((value: string) => {
            this.budgetDraft = value;
            this.budgetErrorMessage = '';
          })

        Text(this.budgetErrorMessage.length > 0 ? this.budgetErrorMessage : '至少 ¥500。保存后会更新本月预算余量和进度条。')
          .width('100%')
          .fontSize(12)
          .lineHeight(17)
          .fontColor(this.budgetErrorMessage.length > 0 ? YibuqueColor.danger : YibuqueColor.textSecondary)
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
          .enabled(!this.isSaving)
          .onClick(() => {
            this.cancelBudgetEditor();
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
            this.saveBudget();
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
    .transition(TransitionEffect.OPACITY)
  }

  @Builder
  LocalStorageSection() {
    Column() {
      this.SectionHeading('本地存储', '本地保存正常')

      Column() {
        this.LocalStateRow()
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
          Text('保存后可在逛店记录页快速筛选路线。')
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
          }, (district: string) => `${district}-${this.districtDraft.includes(district) ? 'selected' : 'available'}`)
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
    .transition(TransitionEffect.OPACITY)
  }

  @Builder
  DistrictChip(label: string, selected: boolean) {
    Button() {
      Row({ space: 6 }) {
        Text(label)
          .fontSize(13)
          .fontWeight(FontWeight.Regular)
          .fontColor(selected ? YibuqueColor.textInverse : YibuqueColor.textPrimary)

        if (selected) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(11)
            .fontColor([YibuqueColor.textInverse])
        }
      }
    }
    .height(40)
    .padding({ left: 14, right: selected ? 11 : 14 })
    .margin({ right: 8, bottom: 8 })
    .fontWeight(FontWeight.Regular)
    .backgroundColor(selected ? YibuqueColor.textPrimary : YibuqueColor.bgDefault)
    .borderRadius(YibuqueRadius.full)
    .border({ width: 1, color: selected ? YibuqueColor.textPrimary : YibuqueColor.borderMedium })
    .enabled(!this.isSaving)
    .accessibilityText(`${label}${selected ? '，删除已选地点' : '，选择地点'}`)
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

      Text('常用衣物尺码')
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .margin({ top: 16, bottom: 2 })

      Row({ space: 10 }) {
        this.SizeField('上衣', this.upperSize, '例如 M')
        this.SizeField('裤装', this.lowerSize, '例如 27')
        this.SizeField('鞋', this.shoeSize, '例如 38')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text('保存后会显示在“我的偏好”的常用尺码中。')
        .width('100%')
        .fontSize(12)
        .lineHeight(17)
        .fontColor(YibuqueColor.textSecondary)
        .margin({ top: 8 })

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
    .transition(TransitionEffect.OPACITY)
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
        .border({ width: 1, color: this.measurementError(label, value, unit).length > 0 ? YibuqueColor.danger : YibuqueColor.borderMedium })
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

      if (this.measurementError(label, value, unit).length > 0) {
        Text(this.measurementError(label, value, unit))
          .width('100%')
          .fontSize(11)
          .lineHeight(15)
          .fontColor(YibuqueColor.danger)
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SizeField(label: string, value: string, placeholder: string) {
    Column({ space: 6 }) {
      Text(label)
        .width('100%')
        .fontSize(12)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)

      TextInput({ text: value, placeholder: placeholder })
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor(YibuqueColor.textPrimary)
        .placeholderColor(YibuqueColor.textTertiary)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.md)
        .border({ width: 1, color: YibuqueColor.borderMedium })
        .type(InputType.Normal)
        .onChange((nextValue: string) => {
          this.errorMessage = '';
          if (label === '上衣') {
            this.upperSize = nextValue;
          } else if (label === '裤装') {
            this.lowerSize = nextValue;
          } else {
            this.shoeSize = nextValue;
          }
        })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
}
