
import UnifiedPreferences, { SCHEDULE_KEY, START_TIME_KEY } from '../utils/UnifyPreference';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import { examAttribute } from '../utils/ExamManager';
import { classAttribute } from '../pages/Schedule';

interface exportClassInfo {
  data: string,
  termBegin: string
}

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
    Scroll() {
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

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center, alignContent: FlexAlign.Start }) {
          Row() {
            Row() {
              PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.Circle})
                .size({ width: 30, height: 30 })
                .onClick((event: ClickEvent, result: PasteButtonOnClickResult, error?: BusinessError<void>) => {
                  if (result === PasteButtonOnClickResult.SUCCESS) {
                    pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                      if (err) {
                        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_failed') });
                        return;
                      }
                      const pasteText: string = pasteData.getPrimaryText();
                      try {
                        const test: exportClassInfo = JSON.parse(pasteText);
                        const checkResult: classAttribute[][][] = JSON.parse(test.data);
                        if (typeof checkResult !== 'object' || checkResult === null) {
                          throw new Error();
                        }
                        for (let layer1 of checkResult)
                          if (layer1 != null)
                            for (let layer2 of layer1)
                              if (layer2 != null)
                                for (let checker of layer2) {
                                  if (checker.name == undefined || checker.teacher == undefined || checker.weekOfTerm == undefined
                                    || checker.timeSpan == undefined || checker.dayOfWeek == undefined || checker.location == undefined
                                    || checker.id == undefined || checker.color == undefined)
                                    throw new Error();
                                }
                        UnifiedPreferences.putSync('scheduleInfo', test.data);
                        UnifiedPreferences.putSync('termStartTime', test.termBegin);
                        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_success') });
                      } catch (error) {
                        this.getUIContext().showAlertDialog({
                          title: $r('app.string.import_failed'),
                          subtitle: $r('app.string.import_from_clipboard_failed'),
                          message: ( pasteText === undefined ) ? $r('app.string.empty_clipboard') : $r('app.string.first_100_char_s', pasteText.slice(0, 100)),
                          confirm:{
                            value: "确认",
                            action: () => {}
                          },
                          cancel: () => {}
                        });
                      }
                    });
                  } else {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_failed') });
                  }
                });
              Text($r('app.string.import_schedule'))
            }
            .margin({ right: 8 })

            Button($r('app.string.export_schedule'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .onClick(() => {
                const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, JSON.stringify({ data: UnifiedPreferences.getSync('scheduleInfo', '[[[]]]'), termBegin: UnifiedPreferences.getSync('termStartTime', '20250721') }));
                const systemPasteboard = pasteboard.getSystemPasteboard();
                systemPasteboard.setData(pasteboardData);
                systemPasteboard.getData().then((data) => {
                  if (data) {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_success'), duration: 1000 });
                  } else {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_failed'), duration: 1000 });
                  }
                });
              });
          }
          .margin({ top: 10 });

          Row() {
            Row() {
              PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.Circle})
                .size({ width: 30, height: 30 })
                .onClick((event: ClickEvent, result: PasteButtonOnClickResult, error?: BusinessError<void>) => {
                  if (result === PasteButtonOnClickResult.SUCCESS) {
                    pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                      if (err) {
                        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_failed') });
                        return;
                      }
                      const pasteText: string = pasteData.getPrimaryText();
                      try {
                        const parsedData: examAttribute[] = JSON.parse(pasteText);
                        if (typeof parsedData !== 'object' || parsedData === null) {
                          throw new Error();
                        }
                        for (let singleData of parsedData)
                          if (singleData.id == undefined || singleData.type == undefined || singleData.name == undefined
                            || singleData.date == undefined || singleData.classroom == undefined
                            || singleData.building == undefined || singleData.campus == undefined
                            || singleData.info == undefined || singleData.beginTimeStamp == undefined
                            || singleData.endTimeStamp == undefined || singleData.beginTimeStamp > singleData.endTimeStamp
                            || !/^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}~\d{2}:\d{2}$/.test(singleData.date)) {
                            throw new Error();
                          }
                        UnifiedPreferences.putSync('examInfo', pasteText);
                        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_success') });
                      } catch (error) {
                        this.getUIContext().showAlertDialog({
                          title: $r('app.string.import_failed'),
                          subtitle: $r('app.string.import_from_clipboard_failed'),
                          message: ( pasteText === undefined ) ? $r('app.string.empty_clipboard') : $r('app.string.first_100_char_s', pasteText.slice(0, 100)),
                          confirm:{
                            value: "确认",
                            action: () => {}
                          },
                          cancel: () => {}
                        });
                      }
                    });
                  } else {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.import_failed') });
                  }
                });
              Text($r('app.string.import_exam'));
            }
            .margin({ right: 8 });

            Button($r('app.string.export_exam'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .onClick(() => {
                const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, `${UnifiedPreferences.getSync('examInfo', '[]')}`);
                const systemPasteboard = pasteboard.getSystemPasteboard();
                systemPasteboard.setData(pasteboardData);
                systemPasteboard.getData().then((data) => {
                  if (data) {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_success'), duration: 1000 });
                  } else {
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_failed'), duration: 1000 });
                  }
                });
              });
          }
          .margin({ top: 10 });
        }
        .width('100%')

        Button($r('app.string.normal_restart'))
          .margin({ top: 10 })
          .onClick(() => {
            UnifiedPreferences.putSync('RecoveryMode', false);
            UnifiedPreferences.putSync('FaultOccurred', false);
            let applicationContext = (this.getUIContext().getHostContext() as common.UIAbilityContext).getApplicationContext();
            let want: Want = {
              bundleName: 'com.nic.yourustc',
              abilityName: 'EntryAbility'
            };
            try {
              applicationContext.restartApp(want);
            } catch (error) {
              console.error(`restartApp fail, error: ${JSON.stringify(error)}`);
              if (error.code === 16000064) {
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                context.terminateSelf((err) => {
                  if (!err) {
                    context.getApplicationContext().killAllProcesses().catch((error: Error) => {
                      console.error(`Quitting ERROR: [${error.name}] ${error.message}`);
                    })
                  }
                });
              }
            }
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
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
  }
}