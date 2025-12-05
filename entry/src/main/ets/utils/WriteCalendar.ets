
import { calendarManager } from "@kit.CalendarKit";
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, bundleManager, PermissionRequestResult } from "@kit.AbilityKit";

import * as tools from './tools';
import examManager from "./ExamManager";
import scheduleManager from '../utils/TimeTable';
import * as ScheduleSources from '../constants/ScheduleSources';


class WriteCalendar {
  calendarMgr: calendarManager.CalendarManager | null = null;
  context: UIContext | null = null;
  readonly atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  readonly tokenID: number = bundleManager.getBundleInfoForSelfSync(0x00000001/*GET_BUNDLE_INFO_WITH_APPLICATION*/).appInfo.accessTokenId;
  grantReadCalendar: boolean = false;
  grantWriteCalendar: boolean = false;

  readonly calendarAccount: calendarManager.CalendarAccount = {
    name: 'YourUSTC.class_notification',
    type: calendarManager.CalendarType.LOCAL,
    // 日历账户显示名称，该字段如果不填，创建的日历账户在界面显示为空字符串。
    displayName: "你的科大上课提醒"
  };
  readonly calendarAccount_exam: calendarManager.CalendarAccount = {
    name: 'YourUSTC.exam_notification',
    type: calendarManager.CalendarType.LOCAL,
    // 日历账户显示名称，该字段如果不填，创建的日历账户在界面显示为空字符串。
    displayName: "你的科大考试提醒"
  };

  initializeCalendar(newContext: UIContext) {
    this.context = newContext;
  }

  showMessage(message: string | ResourceStr, duration?: number) {
    try {
      this.context?.getPromptAction().showToast({
        message: message,
        duration: duration
      });
    } catch (error) {
      console.error(`ShowToast ERROR: [${error.name}] ${error.message}`);
    }
  }


  askForCalendar(index: number): boolean {
    if (this.grantReadCalendar && this.grantWriteCalendar) {
      if (this.calendarMgr === null) {
        this.calendarMgr = calendarManager.getCalendarManager(this.context?.getHostContext());
      }
      return true;
    }
    if (this.atManager.checkAccessTokenSync(this.tokenID, 'ohos.permission.READ_CALENDAR') === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      this.grantReadCalendar = true;
    }
    if (this.atManager.checkAccessTokenSync(this.tokenID, 'ohos.permission.WRITE_CALENDAR') === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      this.grantWriteCalendar = true;
    }
    if (this.grantReadCalendar && this.grantWriteCalendar) {
      if (this.calendarMgr === null){
        this.calendarMgr = calendarManager.getCalendarManager(this.context?.getHostContext());
      }
      return true;
    }

    this.atManager.requestPermissionsFromUser(this.context?.getHostContext(), ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'], (err: BusinessError, data: PermissionRequestResult) => {
      if (err) {
        console.error(`requestPermissionsFromUser fail, code: ${err.code}, message: ${err.message}`);
        return false;
      } else {
        // console.info(`requestPermissionsFromUser success, result: ${data}`);
        // console.info('requestPermissionsFromUser data permissions:' + data.permissions);
        // console.info('requestPermissionsFromUser data authResults:' + data.authResults);
        // console.info('requestPermissionsFromUser data dialogShownResults:' + data.dialogShownResults);
        if (data.authResults[0] + data.authResults[1] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          // 两个权限都获取了
          this.grantReadCalendar = true;
          this.grantWriteCalendar = true;
          if (this.calendarMgr === null) {
            this.calendarMgr = calendarManager.getCalendarManager(this.context?.getHostContext());
          }
          this.executeCorresponding(index);
          return true;
        } else {
          // 没获取
          if (data.dialogShownResults !== undefined && data.dialogShownResults[0] === true && data.dialogShownResults[1] === true) {
            // 如果用户授权过
            this.showMessage($r('app.string.denied_calendar_permission'));
            return false;
          } else {
            // 如果用户没授权过
            this.calendar_permission_denied({ code: 1, name: 'test', message: 'GetCalendar error!' }, index);
            return false;
          }
        }
      }
    });
    return false;
  }

  calendar_permission_denied(error: BusinessError, index: number) {
    this.context?.showAlertDialog({
      title: $r('app.string.error_occurred'),
      subtitle: `${error.message}`,
      message: $r('app.string.need_calendar_permission'),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {}
      },
      secondaryButton: {
        enabled: true,
        defaultFocus: true,
        style: DialogButtonStyle.HIGHLIGHT,
        value: $r('app.string.goto_system_settings'),
        action: () => {
          this.atManager.requestPermissionOnSetting(this.context?.getHostContext(), ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'])
            .then((data: Array<abilityAccessCtrl.GrantStatus>) => {
              if (data[0] + data[1] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
                this.calendarMgr = calendarManager.getCalendarManager(this.context?.getHostContext());
                this.executeCorresponding(index)
              } else {
                this.showMessage($r('app.string.denied_calendar_permission'));
              }
            }).catch((err: BusinessError) => {
            console.error(`requestPermissionOnSetting fail, code: ${err.code}, message: ${err.message}`);
          });
        }
      },
      cancel: () => {},
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
          dismissDialogAction.dismiss();
        }
        if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
          dismissDialogAction.dismiss();
        }
      }
    });
  }

  executeCorresponding(index: number) {
    switch (index) {
      case 1:
        this.deleteCalendar();
        break;
      case 2:
        this.setClassCalendar();
        break;
      case 3:
        this.setExamCalendar();
        break;
    }
  }

  deleteCalendar() { // index 1
    this.calendarMgr?.getCalendar(this.calendarAccount).then((data: calendarManager.Calendar) => {
      // console.log('requestPermissionsFrom success',JSON.stringify(data))
      let calendar: calendarManager.Calendar | undefined = data;
      if (calendar !== undefined) {
        // == undefined 时无你的科大创建的日程
        this.calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
          this.showMessage($r('app.string.denied_calendar_permission'));
        });
        calendar = undefined;
      }
    }).catch((err: BusinessError) => {
      // console.log('requestPermissionsFrom success',JSON.stringify(err))
      if (err.message == 'GetCalendar failed!') {
        // this.showMessage($r('app.string.clear_success'));
      } else {
        this.showMessage($r('app.string.denied_calendar_permission'));
      }
    });
    setTimeout(() => {
      this.calendarMgr?.getCalendar(this.calendarAccount_exam).then((data: calendarManager.Calendar) => {
        let calendar: calendarManager.Calendar | undefined = data;
        if (calendar != undefined) {
          this.calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
            this.showMessage($r('app.string.denied_calendar_permission'));
          });
          calendar = undefined;
        }
      }).catch((err: BusinessError) => {
        if (err.message == 'GetCalendar failed!') {
          // this.showMessage($r('app.string.clear_success'));
        } else {
          this.showMessage($r('app.string.denied_calendar_permission'));
        }
      });
    }, 500);
    this.showMessage($r('app.string.clear_success'));
  }

  setClassCalendar() { // index 2
    let selected3: number = 0;
    switch (ScheduleSources.remindBefore[0]) {
      case 10: selected3 = 1; break;
      case 20: selected3 = 2; break;
      case 30: selected3 = 3; break;
      case 45: selected3 = 4; break;
      case 60: selected3 = 5; break;
      case 90: selected3 = 6; break;
      case 120: selected3 = 7; break;
    }
    // 在上课几分钟前提醒
    this.context?.showTextPickerDialog({
      selected: selected3,
      range: ['不提醒', '上课前 10 分钟', '上课前 20 分钟', "上课前 30 分钟",
        "上课前 45 分钟", "上课前 1 小时", "上课前 90 分钟", "上课前 2 小时"],
      defaultPickerItemHeight: 36,
      canLoop: false,
      onAccept: (value: TextPickerResult) => {
        // 删除日程
        this.calendarMgr?.getCalendar(this.calendarAccount).then((data: calendarManager.Calendar) => {
          let calendar: calendarManager.Calendar | undefined = data;
          if (calendar != undefined) {
            this.calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
              this.showMessage($r('app.string.denied_calendar_permission'));
            });
            calendar = undefined;
          }
        }).catch((err: BusinessError) => {
          if (err.message == 'GetCalendar error!') {
            this.showMessage($r('app.string.denied_calendar_permission'));
          }
        });

        //创建日程
        setTimeout(() => {
          this.calendarMgr?.createCalendar(this.calendarAccount).then((data: calendarManager.Calendar) => {
            let calendar: calendarManager.Calendar | undefined = data;
            // 确保日历账户创建成功后，再进行后续相关操作
            // 将课程写入日历
            if (calendar != undefined) {
              //获取日历账户
              this.calendarMgr?.getCalendar(this.calendarAccount, (err, data) => {
                if (err) {
                  this.showMessage($r('app.string.denied_calendar_permission'));
                } else {
                  const config: calendarManager.CalendarConfig = {
                    enableReminder: true, // 打开日程提醒
                    color: '#BCC7DF' // 设置日历账户颜色
                  };
                  data.setConfig(config).then(() => { // 设置日历配置信息
                    let valueData: number[] = [-1, 10, 20, 30, 45, 60, 90, 120]
                    ScheduleSources.setRemindBefore(valueData[Number(value.index)]);
                    if (value.index == 0) {
                      this.showMessage('已更改为 不提醒');
                    } else {
                      this.showMessage(`已更改为 在${value.value}提醒`);
                    }
                    let eventId: number | undefined = undefined;
                    for (let layer1 = 0; layer1 <= 6; layer1++) // 星期几 -1{
                      if (scheduleManager.parsedSchedule[layer1] != undefined) // 防止不存在元素
                        for (let layer2 of scheduleManager.parsedSchedule[layer1]) // 星期几的每一节课
                          if (layer2 != undefined)
                            for (let layer3 of layer2) { // 叠课判断
                              // 确保数组有序
                              layer3.weekOfTerm.sort((a, b) => a - b);
                              layer3.timeSpan.sort((a, b) => a - b);
                              // 非上课周排除
                              let excludeDates: number[] = [];
                              for (let i = 1; i < layer3.weekOfTerm.length; i++) {
                                for (let j = layer3.weekOfTerm[i - 1] + 1; j < layer3.weekOfTerm[i]; j++) {
                                  excludeDates.push(tools.getClassTimestamp(scheduleManager.termStart, j,
                                    (layer3.dayOfWeek + 1) % 7, ScheduleSources.commonClassStamp[layer3.timeSpan[0]][0]));
                                }
                              }
                              console.log('abcdefg', excludeDates);
                              // 设置日程
                              const event: calendarManager.Event = {
                                title: layer3.name, // 日程标题
                                location: { location: layer3.location },
                                type: calendarManager.EventType.NORMAL, // 日程类型
                                startTime: tools.getClassTimestamp(scheduleManager.termStart,
                                  layer3.weekOfTerm[0],
                                  (layer3.dayOfWeek + 1) % 7,
                                  ScheduleSources.commonClassStamp[layer3.timeSpan[0]][0]), // 日程开始时间
                                endTime: tools.getClassTimestamp(scheduleManager.termStart,
                                  layer3.weekOfTerm[0],
                                  (layer3.dayOfWeek + 1) % 7,
                                  ScheduleSources.commonClassStamp[layer3.timeSpan[1]][1]), // 日程结束时间
                                reminderTime: ScheduleSources.remindBefore, // 距开始时间提前remindBefore分钟提醒
                                recurrenceRule: {
                                  // 日程重复规则
                                  recurrenceFrequency: calendarManager.RecurrenceFrequency.WEEKLY, // 日程重复规则类型
                                  count: layer3.weekOfTerm.length + excludeDates.length, // 日程重复次数，该字段和expire属性只需要填写一个，如果两个都填写按照count属性计算。
                                  interval: 1, // 重复日程间隔时间，以recurrenceFrequency为单位
                                  // expire: date.getTime() + 60 * 60 * 1000 * 3, 日程过期时间，该字段和count属性只需要填写一个，如果两个都填写按照count属性计算。
                                  excludedDates: excludeDates // 日程排除日期，将该日期从重复日程中排除掉
                                }
                              };
                              if (calendar != undefined) {
                                calendar.addEvent(event).then((data: number) => {
                                  eventId = data;
                                });
                              }
                            }
                  }).catch((err: BusinessError) => {
                    this.showMessage($r('app.string.denied_calendar_permission'));
                  });
                }
              });
            }
          }).catch((error: BusinessError) => {
            this.showMessage($r('app.string.denied_calendar_permission'));
          });
        }, 500);
      }
    })
  }

  setExamCalendar() { // index 3
    let selected4: number = 0;
    switch (ScheduleSources.examRemindBefore[0]) {
      case 30: selected4 = 1; break;
      case 60: selected4 = 2; break;
      case 120: selected4 = 3; break;
      case 1440: selected4 = 4; break;
      case 2880: selected4 = 5; break;
      case 10080: selected4 = 6; break;
    }
    // 在上课几分钟前提醒
    this.context?.showTextPickerDialog({
      selected: selected4,
      range: ['不提醒', "考试前 30 分钟", "考试前 1 小时", "考试前 2 小时", "考试前 1 天",
        "考试前 2 天", "考试前 1 周"],
      defaultPickerItemHeight: 36,
      canLoop: false,
      onAccept: (value: TextPickerResult) => {
        // 删除原日程
        let getPermission: boolean = true;
        this.calendarMgr?.getCalendar(this.calendarAccount_exam).then((data: calendarManager.Calendar) => {
          let calendar: calendarManager.Calendar | undefined = data;
          if (calendar != undefined) {
            this.calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
              getPermission = false;
              this.showMessage($r('app.string.denied_calendar_permission'));
            });
            calendar = undefined;
          }
        }).catch((err: BusinessError) => {
          if (err.message == 'GetCalendar error!') {
            getPermission = false;
            this.showMessage($r('app.string.denied_calendar_permission'));
          }
        });

        // 创建日程
        setTimeout(() => {
          if (getPermission)
            this.calendarMgr?.createCalendar(this.calendarAccount_exam).then((data: calendarManager.Calendar) => {
              let calendar: calendarManager.Calendar | undefined = data;
              // 确保日历账户创建成功后，再进行后续相关操作
              // 将课程写入日历
              if (calendar != undefined) {
                //获取日历账户
                this.calendarMgr?.getCalendar(this.calendarAccount_exam, (err, data) => {
                  if (err) {
                    this.showMessage($r('app.string.denied_calendar_permission'));
                  } else {
                    const config: calendarManager.CalendarConfig = {
                      enableReminder: true, // 打开日程提醒
                      color: '#FFCECB' // 设置日历账户颜色
                    };
                    data.setConfig(config).then(() => { // 设置日历配置信息
                      const valueData: number[] = [-1, 30, 60, 120, 1440, 2880, 10080];
                      ScheduleSources.setExamRemindBefore(valueData[Number(value.index)]);
                      if (value.index == 0) {
                        this.showMessage('已更改为 不提醒');
                      } else {
                        this.showMessage(`已更改为 在${value.value}提醒`);
                      }
                      let eventId: number | undefined = undefined;
                      for (let layer1 of examManager.allExamInfo) {
                        // 设置日程
                        const event: calendarManager.Event = {
                          title: layer1.name, // 日程标题
                          location: { location: layer1.building + layer1.classroom },
                          type: calendarManager.EventType.NORMAL, // 日程类型
                          startTime: new Date(layer1.date.slice(0, 16)).getTime(), // 日程开始时间
                          endTime: new Date(layer1.date.slice(0, 11) +
                          layer1.date.slice(17, 22)).getTime(), // 日程结束时间
                          reminderTime: ScheduleSources.examRemindBefore, // 距开始时间提前remindBefore分钟提醒
                        };
                        if (calendar != undefined) {
                          calendar.addEvent(event).then((data: number) => {
                            eventId = data;
                          });
                        }
                      }
                    }).catch((err: BusinessError) => {
                      this.showMessage($r('app.string.denied_calendar_permission'));
                    });
                  }
                });
              }
            }).catch((error: BusinessError) => {
              this.showMessage($r('app.string.denied_calendar_permission'));
            });
        }, 500);
      }
    })
  }
}

export default new WriteCalendar();