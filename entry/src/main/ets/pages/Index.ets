
import { abilityAccessCtrl, common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { calendarManager } from '@kit.CalendarKit'
import { BusinessError } from '@kit.BasicServicesKit'

import * as Schedule from './Schedule'
import * as tools from '../utils/tools'
import * as FunctionOrder from '../utils/FunctionOrder'
import { classAttribute } from './Schedule'
import { CheckInTools } from '../utils/CheckIn'
import { calendarMgr } from '../entryability/EntryAbility'
import { ListDataConstants } from '../constants/ListDataConstants'
import { GridData, otherGridDataList } from '../constants/GridListDataSources'
import ItemData from '../view/SettingsComponent'
import GridComponent from '../view/GridComponent'
import SettingsData from '../constants/SettingsSources'
import UnifiedPreference from '../utils/UnifyPreference'
import scheduleManager from '../utils/TimeTable'

// 日历初始化
let calendar: calendarManager.Calendar | undefined = undefined;
// 指定日历账户信息
const calendarAccount: calendarManager.CalendarAccount = {
  name: 'YourUSTC.class_notification',
  type: calendarManager.CalendarType.LOCAL,
  // 日历账户显示名称，该字段如果不填，创建的日历账户在界面显示为空字符串。
  displayName: "你的科大上课提醒"
};
export let calendarAccess: boolean = false;

// 滚动条参数
enum ScrollPosition {
  start = 0,
  center = 1,
  end = 2
}

// 主界面UI
@Entry
@Component
struct Index {

  @State currentIndex: number = 0; // 当前标签索引 (从0开始), 初始值即为默认标签索引
  private tabsController: TabsController = new TabsController();

  /**
   * 函数: 构建 Tab 按钮
   * @param title 按钮文字
   * @param index 标签索引 (从0开始)
   * @param selectedImg 按钮图片 (选中时)
   * @param normalImg 按钮图片 (未选中时)
   */
  @Builder
  tabBuilder(title: string | Resource, index: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      // 按钮图片
      Image(this.currentIndex === index ? selectedImg : normalImg)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
      // 按钮文字
      Text(title)
        .margin({ top: 4 })
        .fontSize(10)
        .fontColor(this.currentIndex === index ? $r('app.color.active_text') : $r('app.color.normal_text'))
    }
    .justifyContent(FlexAlign.Center)
    .height(52)
    .width('100%')
    .onClick(() => {
      this.currentIndex = index
      this.tabsController.changeIndex(this.currentIndex)
      this.refreshTabGrid(this.currentIndex)
    })
  }

  /**
   * 全局资源: 首页
   */
  @State checkInTotal: number = 0;
  @State checkInConsecutive: number = 0;
  @State checkedInToday: boolean = false;
  @State checkInContent: string = ''; // 签到后展示的随机内容

  @State showRecentCourse: boolean = true;
  @State todayCourse: classAttribute[] = [];
  @State tomorrowCourse: classAttribute[] = [];
  private todayCourseLeftIndex: number = 0;


  @State showCheckIn: boolean = true;
  @State showExamDetail: boolean = true;

  private context: Context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private currentTime: Date = new Date();

  aboutToAppear(): void {
    Schedule.initSchedulePre(this.context);
    const GeneratedDestructArray_1 = CheckInTools.loadCheckInOnStartup();
    this.checkInTotal = GeneratedDestructArray_1[0];
    this.checkInConsecutive = GeneratedDestructArray_1[1];
    this.checkedInToday = GeneratedDestructArray_1[2];
    this.checkInContent = this.checkedInToday ? GeneratedDestructArray_1[3] : '';
    scheduleManager.getFormattedSchedule(); // 初始化首页课表
    this.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
    this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed + Math.floor((scheduleManager.today + 1) / 7)][(scheduleManager.today + 1) % 7];
    this.showCheckIn = UnifiedPreference.getBoolSync('showCheckIn', true);// 是否显示
    this.showRecentCourse = UnifiedPreference.getBoolSync('showRecentCourse', true);// 是否显示
    this.showExamDetail = UnifiedPreference.getBoolSync('showExamDetail', true);// 是否显示
  }

  /**
   * 全局资源: 功能
   */
  @State listPosition: number = ScrollPosition.start;
  @State scrollPosition: number = ScrollPosition.start;
  @State currentListIndex: number = 0;
  private scrollerForScroll: Scroller = new Scroller();
  private scrollerForList: Scroller = new Scroller();
  private scrollerForTitle: Scroller = new Scroller();

  @Builder
  listBuilder() {
    Row() {
      List({ space: 16, scroller: this.scrollerForTitle }) {
        ForEach(ListDataConstants.TITLE_LIST, (item: string, index) => {
          ListItem() {
            Column() {
              Text(item)
                .fontColor(this.currentListIndex === index ? $r('app.color.active_text') :
                  $r('app.color.normal_text'))
                .fontSize('16fp')
                .fontWeight(this.currentListIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .margin({ top: '16vp' })

              if (this.currentListIndex === index) {
                Divider()
                  .color($r('app.color.active_text'))
                  .strokeWidth(2)
                  .width('84vp')
                  .margin({ top: '7vp' })
              }
            }
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.scrollerForList.scrollToIndex(index);
              this.scrollerForScroll.scrollEdge(Edge.Bottom);
              this.scrollerForTitle.scrollToIndex(index);
              this.currentListIndex = index;
            })
          }
        }, (item: string, index: number) => index + JSON.stringify(item))
      }
      .width('100%')
      .height('56vp')
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
    }
    .margin({ top: '16vp' })
    .padding({ left: '28vp', right: '28vp' })
  }

  @State copyMostUsedFunc: GridData = FunctionOrder.mostUsedFunc;
  onPageShow(): void {
    this.refreshTabGrid(1)
  }
  private async refreshTabGrid(tabIndex: number){
    switch(tabIndex){
      case 1:
        FunctionOrder.refreshFunc(this.context); // 刷新点击次数显示
        this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
        break;
    }
  }

  /**
   * 全局资源: 设置
   */
  @Builder
  settingCell(item: ItemData) {
    Row() {
      Row() {
        Image(item.img)
          .height('22vp')
          .margin({
            left: '16vp',
            right: '12vp'
          })
        Text(item.title)
          .fontSize('16fp')
          .fontColor($r('app.color.normal_text'))
      }

      if (item.others === undefined) {
        Image($r('app.media.right_arrow'))
          .width('12vp')
          .height('12vp')
      } else if (item.id == 0) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showCheckIn })
          .onClick(() => {
            this.showCheckIn = !this.showCheckIn;
            UnifiedPreference.putSync('showRecentCourse', this.showCheckIn);
          });
      } else if (item.id == 1) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showRecentCourse })
          .onClick(() => {
            this.showRecentCourse = !this.showRecentCourse;
            UnifiedPreference.putSync('showRecentCourse', this.showRecentCourse);
          });
      } else {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showExamDetail })
          .onClick(() => {
            this.showExamDetail = !this.showExamDetail;
            UnifiedPreference.putSync('showExamDetail', this.showExamDetail);
          });
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding({
      left: '8vp',
      right: '22vp'
    })
  }

  showMessage(message: string | ResourceStr, duration: number) {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message,
        duration: duration
      });
    } catch (error) {
      console.error(`ShowToast ERROR: [${error.name}] ${error.message}`);
    }
  }
  calendar_permission_denied(error: BusinessError) {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.error_occurred'),
      subtitle: `${error.message}`,
      message: $r('app.string.need_calendar_permission'),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
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
          let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
          atManager.requestPermissionOnSetting(this.context, ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR']).then((data: Array<abilityAccessCtrl.GrantStatus>) => {
            console.info(`requestPermissionOnSetting success, result: ${data}`);
          }).catch((err: BusinessError) => {
            console.error(`requestPermissionOnSetting fail, code: ${err.code}, message: ${err.message}`);
          });
        }
      },
      cancel: () => { console.info('Closed callbacks'); },
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
          dismissDialogAction.dismiss();
        }
        if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
          dismissDialogAction.dismiss();
        }
      }
    })}

  /**
   * 页面: 首页
   */
  @Builder
  pageStart() {
    List({ space: 10 }) {
      // 每日签到
      if (this.showCheckIn) {
        ListItem() {
          Column() {
            Row() {
              Text($r('app.string.daily_checkin'))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.normal_text'))
            }
            .width('100%')
            .margin({ top: 15, bottom: 10 })
            .justifyContent(FlexAlign.Center)

            Row() {
              Text(this.checkInContent)
                .fontColor($r('app.color.active_text'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .textShadow({ radius: 1 })
            }
            .width('80%')
            .height(60)
            .margin({ bottom: 10 })
            .justifyContent(FlexAlign.Center)

            Row() {
              Button(this.checkedInToday ? $r('app.string.checked_in') : $r('app.string.check_in'))
                .buttonStyle(this.checkedInToday ? ButtonStyleMode.NORMAL : ButtonStyleMode.EMPHASIZED)
                .enabled(!this.checkedInToday)
                .onClick(() => {
                  const GeneratedDestructArray_1 = CheckInTools.doCheckIn()
                  this.checkInTotal = GeneratedDestructArray_1[0]
                  this.checkedInToday = true
                  this.checkInConsecutive = GeneratedDestructArray_1[1]
                  this.checkInContent = GeneratedDestructArray_1[2]
                })
            }
            .width('90%')
            .margin({ bottom: 10 })
            .justifyContent(FlexAlign.Center)

            Row() {
              Text($r('app.string.checkin_count_d', this.checkInTotal))
                .fontSize(12)
                .align(Alignment.Start)

              Blank()

              Text($r('app.string.checkin_consecutive_d', this.checkInConsecutive))
                .fontSize(12)
                .align(Alignment.End)
            }
            .width('80%')
            .margin({ bottom: 10 })
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .borderRadius(20)
        .backgroundColor($r('app.color.grid_background'))
      }

      // 你的课表
      ListItem() {
        Column() {
          Row() {
            if (this.showRecentCourse) {
              Image($r('app.media.refresh'))
                .height(20)
                .width(24)
                .objectFit(ImageFit.Contain)
                .onClick(() => {
                  scheduleManager.getFormattedSchedule(); // 初始化首页课表
                  this.todayCourse =
                    scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
                  this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed +
                  Math.floor((scheduleManager.today + 1) / 7)][(scheduleManager.today + 1) % 7];
                });
            } else {
              Image($r('app.media.empty'))
                .height(20)
                .width(24)
                .objectFit(ImageFit.Contain)
            }

            Blank()

            Text($r('app.string.your_schedule'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.normal_text'))

            Blank()

            Image($r('app.media.right_arrow'))
              .height(24)
              .width(24)
              .objectFit(ImageFit.Contain)
          }
          .width('100%')
          .margin({ top: 15, bottom: 10 })
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Schedule' })
              .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) })
          })

          if (this.showRecentCourse) {
            Divider();
            if (this.todayCourse.length == 0) {
              Column() {
                Image($r('app.media.no_course_today'))
                  .height(50);
                Text($r('app.string.no_class_today'));
              }
              .margin({ top: 12, bottom: 12 });
            } else {
              ForEach(this.todayCourse, (course: classAttribute, index: number) => {
                if (
                  this.currentTime.getTime() <
                    (scheduleManager.weekStart + 57600000)
                      + scheduleManager.today * 86400000
                      + Schedule.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]
                      + 1800000
                ) {
                  Row() {
                    Column() {
                      Text(course.name)
                        .textAlign(TextAlign.Start)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis });

                      if (this.currentTime.getTime() <
                        (scheduleManager.weekStart + 57600000) + scheduleManager.today * 86400000
                          + Schedule.commonClassStamp[course.timeSpan[0]][0] &&
                        this.currentTime.getTime() > (scheduleManager.weekStart + 57600000)
                          + scheduleManager.today * 86400000 + Schedule.commonClassStamp[course.timeSpan[0]][0] -
                          1800000) {
                        Text($r('app.string.class_soon'))
                          .fontColor($r('app.color.green'));
                      } else if (this.currentTime.getTime() >
                        (scheduleManager.weekStart + 57600000) + scheduleManager.today * 86400000
                          + Schedule.commonClassStamp[course.timeSpan[0]][0] &&
                        this.currentTime.getTime() < (scheduleManager.weekStart + 57600000)
                          + scheduleManager.today * 86400000 +
                        Schedule.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]) {
                        Text($r('app.string.class_in_session'))
                          .fontColor($r('app.color.bright_blue'));
                      } else if (this.currentTime.getTime() >
                        (scheduleManager.weekStart + 57600000) + scheduleManager.today * 86400000
                          + Schedule.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]) {
                        Text($r('app.string.class_end'))
                          .fontColor($r('app.color.red'));
                      } else {
                        Text($r('app.string.class_not_start'))
                          .fontColor($r('app.color.green'));
                      }
                    }
                    .width('50%')
                    .alignItems(HorizontalAlign.Start)
                    .padding({ right: 10 });

                    Column() {
                      Row() {
                        Text('\udb81\uddf3 ')
                        Text(course.teacher == '' ? $r('app.string.temporary_null') : course.teacher)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)
                      }

                      Row() {
                        Text('\udb80\uddb8 ')
                        Text(course.location == '' ? $r('app.string.temporary_null') : course.location)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)
                      }

                      Row() {
                        Text('\udb80\udfdc ')
                        Text(`${Schedule.commonClassTime[course.timeSpan[0]][0]} - ${Schedule.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)
                      }
                    }
                    .width('50%')
                    .alignItems(HorizontalAlign.Start);
                  }
                  .width('90%')
                  .margin({ top: 7, bottom: 7 });

                  if (index < this.todayCourse.length - 1) {
                    Divider()
                      .width('95%');
                  }
                }
              });
            }

            if (this.tomorrowCourse.length > 0) {
              Row() {
                Text($r('app.string.tomorrow_class'))
                  .fontSize(15)
                  .margin({left: 10, right: 10})
                  .fontColor($r('app.color.pink'));
                Divider();
              }

              ForEach(this.tomorrowCourse, (course: classAttribute, index) => {
                if (index > 0) {
                  Divider()
                    .width('95%');
                }
                Row() {
                  Column() {
                    Text(course.name)
                      .textAlign(TextAlign.Start)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis });
                  }
                  .width('50%')
                  .alignItems(HorizontalAlign.Start)
                  .padding({ right: 10 });

                  Column() {
                    Text('\udb81\uddf3 ' + (course.teacher == '' ? $r('app.string.temporary_null') : course.teacher))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text('\udb80\uddb8 ' + (course.location == '' ? $r('app.string.temporary_null') : course.location))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`\udb80\udfdc ${Schedule.commonClassTime[course.timeSpan[0]][0]} - ${Schedule.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('50%')
                  .alignItems(HorizontalAlign.Start);
                }
                .width('90%')
                .margin({ top: 7, bottom: 7 })
              });
            }
          }
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .borderRadius(20)
      .margin({ top: 5 })
      .backgroundColor($r('app.color.grid_background'))

      // 考试信息
      ListItem() {
        Column() {
          Row() {
            if (this.showExamDetail) {
              Image($r('app.media.refresh'))
                .height(20)
                .width(24)
                .objectFit(ImageFit.Contain)
                .onClick(() => {
                  scheduleManager.getFormattedSchedule(); // 初始化首页课表
                  this.todayCourse =
                    scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
                  this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed +
                  Math.floor((scheduleManager.today + 1) / 7)][(scheduleManager.today + 1) % 7];
                });
            } else {
              Image($r('app.media.empty'))
                .height(20)
                .width(24)
                .objectFit(ImageFit.Contain)
            }
            
            Blank()

            Text($r('app.string.exam_detail'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.normal_text'))

            Blank()

            Image($r('app.media.right_arrow'))
              .height(24)
              .width(24)
              .objectFit(ImageFit.Contain)
          }
          .width('100%')
          .margin({ top: 15, bottom: 10 })
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/ExamDetail' })
              .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) })
          })
        }
      }
      .width('100%')
      .borderRadius(20)
      .margin({ top: 5 })
      .backgroundColor($r('app.color.grid_background'));
    }
    .width('100%')
    .height('100%')
    .padding({ top: 20, bottom: 40, left: 20, right: 20 })
  }

  /**
   * 页面: 功能
   */
  @Builder
  pageFunction() {
    Column() {
      Stack({ alignContent: Alignment.Top }) {
        Scroll(this.scrollerForScroll) {
          Column() {
            // 常用区 Grid
            GridComponent({ gridData: this.copyMostUsedFunc, gridIndex: -1 })
            // 常用区下面的所有功能区 GridComponent
            this.listBuilder();
            List({ scroller: this.scrollerForList }) {
              ForEach(otherGridDataList, (item: GridData, index: number) => {
                GridComponent({ gridData: item, isLastItem: index === otherGridDataList.length - 1, gridIndex: index })
              }, (item: GridData,index:number) => index + JSON.stringify(item))
            }
            .padding({ bottom: '40vp' })
            .width('100%')
            .edgeEffect(EdgeEffect.None)
            .scrollBar(BarState.Off)
            .onReachStart(() => {
              this.listPosition = ScrollPosition.start;
            })
            .onReachEnd(() => {
              this.listPosition = ScrollPosition.end;
            })
            .onScrollIndex((start: number) => {
              this.currentListIndex = start
              this.scrollerForTitle.scrollToIndex(this.currentListIndex);
            })
            .onScrollFrameBegin((offset: number) => {
              if (this.currentListIndex === ListDataConstants.TITLE_LIST.length - 1 && offset > 0) {
                return { offsetRemain: 0 }
              }
              if (!((this.listPosition === ScrollPosition.start && offset < 0) ||
                (this.listPosition === ScrollPosition.end && offset > 0))) {
                this.listPosition = ScrollPosition.center;
              }
              if (this.scrollPosition === ScrollPosition.end &&
                (this.listPosition != ScrollPosition.start || offset > 0)) {
                return { offsetRemain: offset };
              } else {
                this.scrollerForScroll.scrollBy(0, offset)
                return { offsetRemain: offset };
              }
            })
            .width('100%')
            .height("calc(100% - 56vp)")
          }
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.Fade)
        .onWillScroll((yOffset: number) => {
          if (!((this.scrollPosition === ScrollPosition.start && yOffset < 0)
            || (this.scrollPosition === ScrollPosition.end && yOffset > 0))) {
            this.scrollPosition = ScrollPosition.center;
          }
        })
        .onScrollEdge((side: Edge) => {
          if (side === Edge.Top) {
            this.scrollPosition = ScrollPosition.start;
          } else if (side === Edge.Bottom) {
            this.scrollPosition = ScrollPosition.end;
          }
        })
        .onScrollFrameBegin(offset => {
          if (this.scrollPosition === ScrollPosition.end) {
            return { offsetRemain: 0 };
          } else {
            return { offsetRemain: offset };
          }
        })
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor($r('app.color.normal_background'))
  }

  /**
   * 页面: 设置
   */
  @Builder
  pageSettings() {
    Column() {
      List({ space: 12 }) {
        ForEach(SettingsData.getSettingListData(), (item: ItemData[], index: number) => {
          ListItemGroup() {
            ForEach(item, (cell: ItemData, cellIndex) => {
              ListItem() {
                this.settingCell(cell)
              }
              .height('48vp')
              .onClick(() => {
                switch (cell.id) { // 根据 cell.id 区分设置项
                  case 0:
                    this.showCheckIn = !this.showCheckIn;
                    UnifiedPreference.putSync('showCheckIn', this.showCheckIn);
                    break;
                  case 1:
                    this.showRecentCourse = !this.showRecentCourse;
                    UnifiedPreference.putSync('showRecentCourse', this.showRecentCourse);
                    break;
                  case 2:
                    this.showExamDetail = !this.showExamDetail;
                    UnifiedPreference.putSync('showExamDetail', this.showExamDetail);
                    break;
                  case 3:
                    // 选择最近使用
                    let maxRecordPre: preferences.Preferences = preferences.getPreferencesSync(this.context, { name: 'FunctionOrderNum' });
                    let selected1: number | number[] = maxRecordPre.getSync('maxRecord', 8) as number - 1;
                    this.getUIContext().showTextPickerDialog({
                      selected: selected1,
                      range: tools.getContArray([[1, 20]], true) as string[], // 在此处修改允许用户选择的最大显示数量上限！！（现在是20）
                      defaultPickerItemHeight: 36,
                      canLoop: false,
                      onAccept: (value: TextPickerResult) => {
                        try {
                          this.showMessage(`已更改为 ${value.value}`, 500);
                        } catch (error) {
                          console.error(`CheckIn load ERROR: [${error.name}] ${error.message}`);
                        }
                        try {
                          maxRecordPre.putSync('maxRecord', Number(value.value));
                          maxRecordPre.flush().catch((error: Error) => {
                            console.error(`Flush ERROR: [${error.name}] ${error.message}`);
                          });
                        } catch (error) {
                          console.error(`Preference load ERROR: [${error.name}] ${error.message}`);
                        }
                        this.refreshTabGrid(1);
                      }
                    })
                    break;
                  case 4:
                    // 重置最近使用
                    FunctionOrder.resetFunc(this.context);
                    this.refreshTabGrid(1);
                    try {
                      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.have_cleared'), duration: 500 })
                    } catch (error) {
                      console.error(`ShowToast ERROR: [${error.name}] ${error.message}`);
                    }
                    break;
                  case 5:
                    // 清除日历中的所有课程信息
                    calendarMgr?.getCalendar(calendarAccount).then((data: calendarManager.Calendar) => {
                      calendar = data;
                      if (calendar == undefined){
                        this.showMessage($r('app.string.calendar_null'), 500);
                      } else {
                        calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
                          this.calendar_permission_denied(error);
                        });
                        this.showMessage($r('app.string.clear_success'), 500);
                        calendar = undefined;
                      }
                    }).catch((err: BusinessError) => {
                      if (err.message == 'GetCalendar failed!')
                        this.showMessage($r('app.string.clear_success'), 500);
                      else
                        this.calendar_permission_denied(err);
                    });
                    break;
                  case 6:
                    let selected3: number = 0;
                    switch (Schedule.remindBefore[0]) {
                      case 10: selected3 = 1; break;
                      case 20: selected3 = 2; break;
                      case 30: selected3 = 3; break;
                      case 45: selected3 = 4; break;
                      case 60: selected3 = 5; break;
                      case 90: selected3 = 6; break;
                      case 120: selected3 = 7; break;
                    }
                    // 在上课几分钟前提醒
                    this.getUIContext().showTextPickerDialog({
                      selected: selected3,
                      range: ['不提醒', '上课前 10 分钟', '上课前 20 分钟', "上课前 30 分钟",
                        "上课前 45 分钟", "上课前 1 小时", "上课前 90 分钟", "上课前 2 小时"],
                      defaultPickerItemHeight: 36,
                      canLoop: false,
                      onAccept: (value: TextPickerResult) => {
                        // 删除日程
                        if (calendar != undefined)
                          calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => { this.calendar_permission_denied(error); });
                        calendarMgr?.createCalendar(calendarAccount).then((data: calendarManager.Calendar) => {
                          calendar = data;
                          // 确保日历账户创建成功后，再进行后续相关操作
                          // 上课提醒，后续需要加一个循环！！
                          let eventId: number | undefined = undefined;
                          // 获取课程详情，需要改为使用preference！！
                          let classInfo: classAttribute = {
                            name: '计算机程序设计',
                            teacher: '李卫海',
                            location: '3A212',
                            id: 'CS1003.H2',
                            weekOfTerm: tools.getContArray([[2, 10], [13, 16]]) as number[],
                            timeSpan: [6, 7],
                            dayOfWeek: 1
                          };
                          const termBeginDate: string = '2025-09-07' + ' 00:00';
                          // 确保数组有序
                          classInfo.weekOfTerm.sort((a, b) => a - b);
                          classInfo.timeSpan.sort((a, b) => a - b);
                          // 非上课周排除
                          let excludeDates: number[] = [];
                          for (let i = 1; i < classInfo.weekOfTerm.length; i++) {
                            for (let j = classInfo.weekOfTerm[i - 1] + 1; j < classInfo.weekOfTerm[i]; j++) {
                              excludeDates.push(tools.getClassTimestamp(termBeginDate, j, classInfo.dayOfWeek,
                                Schedule.commonClassStamp[classInfo.timeSpan[0]][0]));
                            }
                          }
                          // 将课程写入日历
                          if (calendar != undefined) {
                            //获取日历账户
                            calendarMgr?.getCalendar(calendarAccount, (err, data) => {
                              if (err) {
                                this.calendar_permission_denied(err);
                              } else {
                                const config: calendarManager.CalendarConfig = {
                                  enableReminder: true, // 打开日程提醒
                                  color: '#BCC7DF' // 设置日历账户颜色
                                };
                                data.setConfig(config).then(() => { // 设置日历配置信息
                                  let valueData: number[] = [-1, 10, 20, 30, 45, 60, 90, 120]
                                  Schedule.setRemindBefore(Number(valueData[Number(value.index)]));
                                  if (value.index == 0)
                                    this.showMessage('已更改为 不提醒', 500);
                                  else
                                    this.showMessage(`已更改为 在${value.value}提醒`, 500);
                                  const event: calendarManager.Event = {
                                    title: `${classInfo.name} ${classInfo.location}`, // 日程标题
                                    type: calendarManager.EventType.NORMAL, // 日程类型
                                    startTime: tools.getClassTimestamp(termBeginDate, classInfo.weekOfTerm[0],
                                      classInfo.dayOfWeek, Schedule.commonClassStamp[classInfo.timeSpan[0]][0]), // 日程开始时间
                                    endTime: tools.getClassTimestamp(termBeginDate, classInfo.weekOfTerm[0],
                                      classInfo.dayOfWeek, Schedule.commonClassStamp[classInfo.timeSpan[1]][1]), // 日程结束时间
                                    reminderTime: Schedule.remindBefore, // 距开始时间提前remindBefore分钟提醒
                                    recurrenceRule: {
                                      // 日程重复规则
                                      recurrenceFrequency: calendarManager.RecurrenceFrequency.WEEKLY, // 日程重复规则类型
                                      count: classInfo.weekOfTerm.length, // 日程重复次数，该字段和expire属性只需要填写一个，如果两个都填写按照count属性计算。
                                      interval: 1, // 重复日程间隔时间，以recurrenceFrequency为单位
                                      // expire: date.getTime() + 60 * 60 * 1000 * 3, 日程过期时间，该字段和count属性只需要填写一个，如果两个都填写按照count属性计算。
                                      excludedDates: excludeDates // 日程排除日期，将该日期从重复日程中排除掉
                                    }
                                  };
                                  if (calendar != undefined)
                                    calendar.addEvent(event).then((data: number) => {eventId = data;});
                                }).catch((err: BusinessError) => {
                                  this.calendar_permission_denied(err);
                                })
                              }
                            });
                          }
                        }).catch((error: BusinessError) => { this.calendar_permission_denied(error); });
                      }
                    })
                    break;
                  case 7:
                    // 帮助
                    this.getUIContext().getRouter().pushUrl({ url: 'pages/Help' })
                      .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
                    break;
                  case 8:
                    // 关于
                    this.getUIContext().getRouter().pushUrl({ url: 'pages/About' })
                      .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
                    break;
                  default:
                   this.showMessage($r('app.string.WorkingOn'), 500);
                }
              })
            })
          }
          .divider({
            strokeWidth: '1vp',
            color: $r('app.color.grid_border'),
            startMargin: '12vp',
            endMargin: '12vp'
          })
          .backgroundColor($r('app.color.grid_background'))
          .borderRadius('16vp')

        }, (item: ItemData) => JSON.stringify(item))
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({
        top: '4vp',
        bottom: '4vp'
      })

      Blank()

      Button($r('app.string.exit_app'), { type: ButtonType.Capsule })
        .buttonStyle(ButtonStyleMode.NORMAL)
        .width('80%')
        .fontColor(Color.Red)
        .onClick(() => {
          const context = getContext(this) as common.UIAbilityContext
          context.terminateSelf((err) => {
            if (!err) {
              context.getApplicationContext().killAllProcesses().catch((error: Error) => {
                console.error(`Quitting ERROR: [${error.name}] ${error.message}`);
              })
            }
          })
        })
    }
    .height('100%')
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .justifyContent(FlexAlign.Center)
  }

  /**
   * Tabs 主控程序
   */
  build() {
    Tabs({
      barPosition: BarPosition.End,
      controller: this.tabsController
    }) {

      /**
       * Tab: 首页
       */
      TabContent() { this.pageStart() }
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_start'), 0, $r('app.media.tab0_selected'), $r('app.media.tab0_unselected')))

      /**
       * Tab: 功能
       */
      TabContent() { this.pageFunction() }
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_function'), 1, $r('app.media.tab1_selected'), $r('app.media.tab1_unselected')))

      /**
       * Tab: 设置
       */
      TabContent() { this.pageSettings() }
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_settings'), 2, $r('app.media.tab2_selected'), $r('app.media.tab2_unselected')))

    }
    .width('100%')
    .backgroundColor($r('app.color.shaded_background'))
    .barHeight(52)
    .barMode(BarMode.Fixed)
    .onAnimationStart((index: number, targetIndex: number) => {
      this.currentIndex = targetIndex;
    })
  }
}
