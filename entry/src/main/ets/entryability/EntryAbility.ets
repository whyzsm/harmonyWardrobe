import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { YibuqueColor, YibuqueSpacing } from '../theme/Tokens';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'HarmonyWardrobe', 'Ability onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.configureWindowStage(windowStage);
  }

  private async configureWindowStage(windowStage: window.WindowStage): Promise<void> {
    let mainWindow: window.Window;
    try {
      mainWindow = windowStage.getMainWindowSync();
    } catch (error) {
      hilog.error(0x0000, 'HarmonyWardrobe', 'Failed to get main window: %{public}s', JSON.stringify(error));
      return;
    }

    try {
      await mainWindow.setWindowLayoutFullScreen(true);
      hilog.info(0x0000, 'HarmonyWardrobe', 'Window layout configured for full screen');
    } catch (error) {
      hilog.error(0x0000, 'HarmonyWardrobe', 'Failed to configure full-screen layout: %{public}s', JSON.stringify(error));
    }

    try {
      await mainWindow.setWindowSystemBarProperties({
        statusBarColor: YibuqueColor.bgDefault,
        isStatusBarLightIcon: false,
        navigationBarColor: YibuqueColor.bgDefault,
        isNavigationBarLightIcon: false
      });
      hilog.info(0x0000, 'HarmonyWardrobe', 'System bar properties configured');
    } catch (error) {
      hilog.error(0x0000, 'HarmonyWardrobe', 'Failed to configure system bars: %{public}s', JSON.stringify(error));
    }

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'HarmonyWardrobe', 'Failed to load page: %{public}s', JSON.stringify(err));
        return;
      }

      this.updateWindowInsets(mainWindow);
      try {
        mainWindow.on('avoidAreaChange', (options: window.AvoidAreaOptions) => {
          if (options.type === window.AvoidAreaType.TYPE_SYSTEM ||
            options.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
            this.updateWindowInsets(mainWindow);
          }
        });
      } catch (error) {
        hilog.error(0x0000, 'HarmonyWardrobe', 'Failed to observe window insets: %{public}s', JSON.stringify(error));
      }
    });
  }

  private updateWindowInsets(mainWindow: window.Window): void {
    try {
      const systemAvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      let navigationIndicatorBottomPx = 0;
      try {
        const navigationIndicatorArea = mainWindow.getWindowAvoidArea(
          window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR
        );
        navigationIndicatorBottomPx = navigationIndicatorArea.bottomRect.height;
      } catch (error) {
        hilog.warn(0x0000, 'HarmonyWardrobe', 'Navigation indicator inset is unavailable: %{public}s',
          JSON.stringify(error));
      }

      const uiContext = mainWindow.getUIContext();
      const topInsetVp = uiContext.px2vp(systemAvoidArea.topRect.height);
      const measuredBottomInsetVp = uiContext.px2vp(Math.max(
        systemAvoidArea.bottomRect.height,
        navigationIndicatorBottomPx
      ));
      const bottomInsetVp = Math.max(measuredBottomInsetVp, YibuqueSpacing.bottomSafe);
      AppStorage.setOrCreate('windowTopInsetVp', topInsetVp);
      AppStorage.setOrCreate('windowBottomInsetVp', bottomInsetVp);
      hilog.info(0x0000, 'HarmonyWardrobe', 'Window insets: top=%{public}s vp, bottom=%{public}s vp',
        topInsetVp.toString(), bottomInsetVp.toString());
    } catch (error) {
      hilog.error(0x0000, 'HarmonyWardrobe', 'Failed to read window insets: %{public}s', JSON.stringify(error));
    }
  }
}
