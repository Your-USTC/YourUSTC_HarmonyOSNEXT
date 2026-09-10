
import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router, window } from '@kit.ArkUI';

import UnifiedPreferences from '../utils/UnifyPreference';
import * as FunctionOrder from '../utils/FunctionOrder';
import * as ScheduleStorage from '../utils/ScheduleStorage';
import * as ExamStorage from '../utils/ExamStorage';
import { migrate } from '../utils/MigrationManager';
import BackgroundImage from '../utils/BgImageManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  routerPath: string = '';
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (error) {
      console.error('onCreate ERROR: ' + JSON.stringify(error))
    }
    UnifiedPreferences.init(this.context); // 最先加载确保能读取配置
    FunctionOrder.init(this.context);
    ScheduleStorage.init(this.context);
    ExamStorage.init(this.context);
    BackgroundImage.init(this.context);
    migrate();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    if (want?.parameters?.router) {
      this.routerPath = want.parameters.router.toString();
    }
  }

  // 跟随系统时深浅色变化通过此回调同步darkMode缓存（手动setColorMode不触发，由ThemeSetting自行同步）
  onConfigurationUpdate(newConfig: Configuration): void {
    BackgroundImage.syncDarkMode(this.context);
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
      try {
        this.context.getApplicationContext()
          .setColorMode(UnifiedPreferences.getNumberSync('ColorMode',
            ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET));
      } catch (error) {
        // 改变深浅色失败，不管它了
      }
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
        if (this.routerPath) {
          setTimeout(() => this.context.eventHub.emit('navigation', this.routerPath), 0);
        }
      });
    }
  }

  // 热启动
  onNewWant(want: Want) {
    if (want.parameters?.router) {
      this.routerPath = want.parameters.router.toString();
      this.context.eventHub.emit('navigation', this.routerPath);
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
