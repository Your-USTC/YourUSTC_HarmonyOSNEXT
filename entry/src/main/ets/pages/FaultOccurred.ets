
import UnifiedPreferences, {CONSECUTIVE_DAYS_KEY, LAST_DAY_KEY,
  PREF_NAME,SCHEDULE_KEY, START_TIME_KEY, TOTAL_DAYS_KEY } from '../utils/UnifyPreference';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct FaultOccurred {
  private button1ClickTimes: number = 0;
  private button2ClickTimes: number = 0;
  private button3ClickTimes: number = 0;
  @State button1Text: ResourceStr = $r('app.string.delete_schedule');
  @State button2Text: ResourceStr = $r('app.string.delete_all_data');
  @State button3Text: ResourceStr = $r('app.string.delete_exam_info');

  build() {
    Column() {
      Image($r('app.media.fault_occurred'))    // 仅占位
        .height(100)
        .draggable(false)
      Text($r('app.string.runtime_error'))
        .fontColor($r('app.color.normal_text'))
        .fontSize(20)
        .margin({ bottom: 10 })
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center);
      Text($r('app.string.dangerous_behavior'))
        .fontSize(24)
        .fontWeight(FontWeight.Bolder)
        .fontColor($r('app.color.red'));
      Flex() {
        Button(this.button1Text)
          .backgroundColor($r('app.color.red'))
          .onClick(() => {
            this.button1ClickTimes++;
            if (this.button1ClickTimes == 2) {
              UnifiedPreferences.deleteSync(LAST_DAY_KEY);
              UnifiedPreferences.deleteSync(TOTAL_DAYS_KEY);
              UnifiedPreferences.deleteSync(CONSECUTIVE_DAYS_KEY);
              UnifiedPreferences.deleteSync(SCHEDULE_KEY);
              UnifiedPreferences.deleteSync(START_TIME_KEY);
              this.button1Text = $r('app.string.clear_success');
            } else if (this.button1ClickTimes == 1) {
              this.button1Text = $r('app.string.click_again_to_delete');
            }
          });
        Button(this.button2Text)
          .backgroundColor($r('app.color.red'))
          .margin({ left: 8 })
          .onClick(() => {
            this.button2ClickTimes++;
            if (this.button2ClickTimes == 2) {
              UnifiedPreferences.clear();
              this.button2Text = $r('app.string.clear_success');
            } else if (this.button2ClickTimes == 1) {
              this.button2Text = $r('app.string.click_again_to_delete');
            }
          });
        Button(this.button3Text)
          .backgroundColor($r('app.color.red'))
          .margin({ left: 8 })
          .onClick(() => {
            this.button3ClickTimes++;
            if (this.button3ClickTimes == 2) {
              UnifiedPreferences.deleteSync('examInfo');
              this.button3Text = $r('app.string.clear_success');
            } else if (this.button3ClickTimes == 1) {
              this.button3Text = $r('app.string.click_again_to_delete');
            }
          });
      }
      .borderStyle(BorderStyle.Solid)
      .width('auto')
      .borderWidth(2)
      .borderColor($r('app.color.red'))
      .padding({ top: 10, bottom: 10, left: 10, right: 10 });
      Row() {
        Button($r('app.string.import_schedule'))
          .margin({ right: 8 })
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {});
        Button($r('app.string.export_schedule'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {});
      }
      .margin({ top: 10 });
      Row() {
        Button($r('app.string.import_exam'))
          .margin({ right: 8 })
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {});
        Button($r('app.string.export_exam'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {});
      }
      .margin({ top: 10 });
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
        .buttonStyle(ButtonStyleMode.NORMAL)
        .margin({ top: 10})
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