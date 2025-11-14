
import {
  abilityAccessCtrl,
  AbilityConstant, common, ConfigurationConstant,
  PermissionRequestResult,
  Permissions, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router, window } from '@kit.ArkUI';
import { calendarManager } from '@kit.CalendarKit';
import { BusinessError } from '@kit.BasicServicesKit';

import UnifiedPreferences from '../utils/UnifyPreference';

const DOMAIN = 0x0000;

// 日历相关
export let calendarMgr: calendarManager.CalendarManager | null = null;
export let mContext: common.UIAbilityContext | null = null;

export default class EntryAbility extends UIAbility {
  routerPath: string = '';
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (error) {
      console.error('onCreate ERROR: ' + JSON.stringify(error))
    }
    UnifiedPreferences.init(this.context)
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
      });
    }

    // 日历相关
    mContext = this.context;
    const permissions: Permissions[] = ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'];
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(mContext, permissions).then((result: PermissionRequestResult) => {
      console.info(`成功获取权限: ${JSON.stringify(result)}`);
      calendarMgr = calendarManager.getCalendarManager(mContext);
    }).catch((error: BusinessError) => {
      console.error(`获取权限失败。Code: ${error.code}, message: ${error.message}`);
    })

    if (this.routerPath) {
      windowStage.loadContent(this.routerPath, (err) => {
        if (err.code) {
          console.error('Failed to load content. Error:' + JSON.stringify(err));
          return;
        }
        if (this.routerPath) {
          router.pushUrl({
            url: 'pages/Index'
          }).catch((err: Error) => {
            console.error(`路由跳转失败: ${err.name} ${err.message}`);
          });
        }
      });
    } else {
      windowStage.loadContent('pages/Index', (err) => {  });
    }
  }

  onNewWant(want: Want) {
    if (want?.parameters?.router) {
      router.pushUrl({
        url: want.parameters.router.toString()
      }).catch((err: Error) => {
        console.error(`路由跳转失败: ${err.name} ${err.message}`);
      });
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
