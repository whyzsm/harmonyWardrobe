import { ProfileRepository } from '../data/repositories/ProfileRepository';
import { UserProfile } from '../domain/profile/ProfileModels';
import { YibuqueColor, YibuqueRadius, YibuqueSpacing } from '../theme/Tokens';

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

@Component
export struct ProfilePage {
  profileRepository?: ProfileRepository = undefined;
  onClose: () => void = () => {};

  @State private heightCm: string = '';
  @State private weightKg: string = '';
  @State private waistCm: string = '';
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';

  aboutToAppear(): void {
    this.loadProfile();
  }

  private async loadProfile(): Promise<void> {
    if (this.profileRepository === undefined) {
      return;
    }

    try {
      const profile = await this.profileRepository.getProfile();
      this.applyProfile(profile);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载个人信息失败';
    }
  }

  private applyProfile(profile: UserProfile): void {
    this.heightCm = displayOptionalNumber(profile.heightCm);
    this.weightKg = displayOptionalNumber(profile.weightKg);
    this.waistCm = displayOptionalNumber(profile.waistCm);
  }

  private async saveProfile(): Promise<void> {
    if (this.profileRepository === undefined || this.isSaving) {
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';

    try {
      const savedProfile = await this.profileRepository.saveProfile({
        heightCm: parseOptionalNumber(this.heightCm),
        weightKg: parseOptionalNumber(this.weightKg),
        waistCm: parseOptionalNumber(this.waistCm)
      });
      this.applyProfile(savedProfile);
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '保存个人信息失败';
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Column({ space: YibuqueSpacing.xl }) {
      Row() {
        Text('我的')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
          .layoutWeight(1)

        Button('关闭')
          .height(44)
          .fontSize(15)
          .fontColor(YibuqueColor.textSecondary)
          .backgroundColor(YibuqueColor.cardWhite)
          .borderRadius(YibuqueRadius.full)
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: YibuqueSpacing.md }) {
        Text('我')
          .width(112)
          .height(112)
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
          .textAlign(TextAlign.Center)
          .backgroundColor(YibuqueColor.cardSoftGray)
          .borderRadius(56)

        Text('个人信息')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(YibuqueColor.textPrimary)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Column({ space: YibuqueSpacing.md }) {
        this.MeasurementField('身高', this.heightCm, 'cm')
        this.MeasurementField('体重', this.weightKg, 'kg')
        this.MeasurementField('腰围', this.waistCm, 'cm')
      }
      .width('100%')
      .padding(YibuqueSpacing.lg)
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius(YibuqueRadius.xxl)

      Column() {
        Text('设置')
          .height(74)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(YibuqueColor.textSecondary)
          .width('100%')
      }
      .width('100%')
      .padding({ left: YibuqueSpacing.lg, right: YibuqueSpacing.lg })
      .backgroundColor(YibuqueColor.cardWhite)
      .borderRadius(28)

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor('#EF4444')
      }

      Button(this.isSaving ? '保存中...' : '保存')
        .height(56)
        .width('100%')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textInverse)
        .backgroundColor(YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.full)
        .enabled(!this.isSaving)
        .onClick(() => {
          this.saveProfile();
        })
    }
    .width('100%')
    .height('100%')
    .padding(YibuqueSpacing.pageX)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(YibuqueColor.bgBlueGray)
  }

  @Builder
  MeasurementField(label: string, value: string, unit: string) {
    Row({ space: YibuqueSpacing.md }) {
      Text(label)
        .width(56)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(YibuqueColor.textPrimary)

      TextInput({ text: value, placeholder: unit })
        .height(48)
        .layoutWeight(1)
        .fontSize(16)
        .backgroundColor(YibuqueColor.cardSoftGray)
        .borderRadius(YibuqueRadius.md)
        .onChange((nextValue: string) => {
          if (label === '身高') {
            this.heightCm = nextValue;
          } else if (label === '体重') {
            this.weightKg = nextValue;
          } else {
            this.waistCm = nextValue;
          }
        })

      Text(unit)
        .width(28)
        .fontSize(14)
        .fontColor(YibuqueColor.textSecondary)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
