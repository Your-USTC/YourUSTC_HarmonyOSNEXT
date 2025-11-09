
import UnifiedPreferences, {CONSECUTIVE_DAYS_KEY, LAST_DAY_KEY,
  PREF_NAME,SCHEDULE_KEY, START_TIME_KEY, TOTAL_DAYS_KEY } from '../utils/UnifyPreference';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct FaultOccurred {
  private button1ClickTimes: number = 0;
  private button2ClickTimes: number = 0;
  @State button1Text: ResourceStr = $r('app.string.delete_schedule');
  @State button2Text: ResourceStr = $r('app.string.delete_all_data');

  build() {
    Column() {
      Text($r('app.string.runtime_error'))
        .fontColor($r('app.color.normal_text'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center);
      Button(this.button1Text)
        .backgroundColor($r('app.color.red'))
        .margin({ top: 20})
        .onClick(() => {
          this.button1ClickTimes++;
          if (this.button1ClickTimes == 2) {
            UnifiedPreferences.deleteSync(LAST_DAY_KEY);
            UnifiedPreferences.deleteSync(TOTAL_DAYS_KEY);
            UnifiedPreferences.deleteSync(CONSECUTIVE_DAYS_KEY);
            UnifiedPreferences.deleteSync(SCHEDULE_KEY);
            UnifiedPreferences.deleteSync(START_TIME_KEY);
            this.button1Text = $r('app.string.clear_success');
          } else if (this.button1ClickTimes == 1){
            this.button1Text = $r('app.string.click_again_to_delete');
          }
        });
      Button(this.button2Text)
        .backgroundColor($r('app.color.red'))
        .margin({ top: 20, bottom: 10 })
        .onClick(() => {
          this.button2ClickTimes++;
          if (this.button2ClickTimes == 2) {
            UnifiedPreferences.clear();
            this.button2Text = $r('app.string.clear_success');
          } else if (this.button2ClickTimes == 1){
            this.button2Text = $r('app.string.click_again_to_delete');
          }
        });
      Text($r('app.string.dangerous_behavior'))
        .fontSize(24)
        .fontWeight(FontWeight.Bolder)
        .fontColor($r('app.color.red'));
      Button($r('app.string.normal_restart'))
        .margin({ top: 10 })
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          context.terminateSelf((err: BusinessError) => {
            if (!err) {
              context.getApplicationContext().killAllProcesses().catch((error: Error) => {
                console.error(`Quitting ERROR: [${error.name}] ${error.message}`);
              })
            }
          })
        })
      Button($r('app.string.contact_developer'))
        .margin({ top: 20})
        .onClick(() => {
          (this.getUIContext().getHostContext() as common.UIAbilityContext).startAbility({
            action: 'ohos.want.action.viewData',
            entities: ['entity.system.browsable'],
            uri: 'https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT/issues'
          }).catch((err: BusinessError) => {
            console.error(`startAbility failed, code is ${err.code}, message is ${err.message}`);
          })
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}