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

function isInvalidOptionalNumber(value: string): boolean {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    return false;
  }

  const parsed = Number(trimmed);
  return !Number.isFinite(parsed) || parsed < 0;
}

@Component
export struct ProfilePage {
  profileRepository?: ProfileRepository = undefined;
  onClose: () => void = () => {};

  @State private heightCm: string = '';
  @State private weightKg: string = '';
  @State private waistCm: string = '';
  @State private isLoading: boolean = false;
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';
  @State private savedMessage: string = '';

  aboutToAppear(): void {
    this.loadProfile();
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
      });
      this.applyProfile(savedProfile);
      this.savedMessage = '已保存个人信息';
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
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(46)
            .fontColor([YibuqueColor.textPrimary])
        }
          .width(112)
          .height(112)
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

      if (this.isLoading) {
        Text('正在加载个人信息...')
          .fontSize(13)
          .fontColor(YibuqueColor.textSecondary)
      }

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor('#EF4444')
      }

      if (this.savedMessage.length > 0) {
        Text(this.savedMessage)
          .fontSize(13)
          .fontColor(YibuqueColor.success)
      }

      Button(this.isSaving ? '保存中...' : '保存')
        .height(56)
        .width('100%')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(YibuqueColor.textInverse)
        .backgroundColor(this.hasInvalidMeasurements() ? YibuqueColor.textDisabled : YibuqueColor.actionBlack)
        .borderRadius(YibuqueRadius.full)
        .enabled(!this.isSaving && !this.hasInvalidMeasurements())
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
    Column({ space: YibuqueSpacing.xs }) {
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
          .border({ width: this.measurementError(value).length > 0 ? 1 : 0, color: '#EF4444' })
          .onChange((nextValue: string) => {
            this.errorMessage = '';
            this.savedMessage = '';
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

      if (this.measurementError(value).length > 0) {
        Text(this.measurementError(value))
          .fontSize(12)
          .fontColor('#EF4444')
          .margin({ left: 72 })
      } else {
        Text(`${label} 可留空`)
          .fontSize(12)
          .fontColor(YibuqueColor.textTertiary)
          .margin({ left: 72 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
