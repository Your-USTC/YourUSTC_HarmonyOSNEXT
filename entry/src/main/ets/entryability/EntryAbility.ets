
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { router, window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

import UnifiedPreferences from '../utils/UnifyPreference';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  routerPath: string = '';
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (error) {
      console.error('onCreate ERROR: ' + JSON.stringify(error))
    }
    UnifiedPreferences.init(this.context);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    if (want?.parameters?.router) {
      this.routerPath = want.parameters.router.toString();
    }
  }

  onDestroy(): void {
    UnifiedPreferences.putSync('FaultOccurred', false);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    if (UnifiedPreferences.getBoolSync('RecoveryMode', false) || UnifiedPreferences.getBoolSync('FaultOccurred', false)) {
      UnifiedPreferences.putSync('RecoveryMode', false)
      windowStage.loadContent('pages/FaultOccurred', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    } else {
      UnifiedPreferences.putSync('FaultOccurred', true);
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
        if (this.routerPath) {
          const mainWindow = windowStage.getMainWindowSync();
          setTimeout(() => {
            mainWindow.getUIContext().getRouter().pushUrl({
              url: this.routerPath
            }, router.RouterMode.Standard);
          }, 100);
        }
      });
    }
  }

  onNewWant(want: Want) {
    if (want.parameters?.router) {
      const windowRouter = this.context.windowStage.getMainWindowSync().getUIContext().getRouter();
      if (!want.parameters?.router.toString().endsWith(windowRouter.getState().name)) {
        windowRouter.pushUrl({
          url: want.parameters?.router.toString()
        }, router.RouterMode.Standard);
      }
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    UnifiedPreferences.putSync('FaultOccurred', true);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    UnifiedPreferences.putSync('FaultOccurred', false);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
