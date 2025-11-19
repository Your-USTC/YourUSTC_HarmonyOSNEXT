
import { abilityAccessCtrl, common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { calendarManager } from '@kit.CalendarKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { LengthUnit } from '@kit.ArkUI'

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
import UnifiedPreferences from '../utils/UnifyPreference'
import scheduleManager from '../utils/TimeTable'
import examManager, { examAttribute } from '../utils/ExamManager'
import { fileIo } from '@kit.CoreFileKit'

// 指定日历账户信息
const calendarAccount: calendarManager.CalendarAccount = {
  name: 'YourUSTC.class_notification',
  type: calendarManager.CalendarType.LOCAL,
  // 日历账户显示名称，该字段如果不填，创建的日历账户在界面显示为空字符串。
  displayName: "你的科大上课提醒"
};
const calendarAccount_exam: calendarManager.CalendarAccount = {
  name: 'YourUSTC.exam_notification',
  type: calendarManager.CalendarType.LOCAL,
  // 日历账户显示名称，该字段如果不填，创建的日历账户在界面显示为空字符串。
  displayName: "你的科大考试提醒"
};

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
        .width(28)
        .height(28)
        .objectFit(ImageFit.Contain)
        .draggable(false)
      // 按钮文字
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? $r('app.color.active_text') : $r('app.color.normal_text'))
    }
    .justifyContent(FlexAlign.Center)
    .height(52)
    .width('100%')
    .onClick(() => {
      this.currentIndex = index
      this.tabsController.changeIndex(this.currentIndex);
      if (this.currentIndex === 1) {
        FunctionOrder.refreshFunc(this.context); // 刷新点击次数显示
        this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
      }
    })
  }

  /**
   * 全局资源: 首页
   */
  @State checkInTotal: number = 0;
  @State checkInConsecutive: number = 0;
  @State checkedInToday: boolean = false;
  @State checkInContent: string = ''; // 签到后展示的随机内容

  @State todayCourse: classAttribute[] = [];
  @State tomorrowCourse: classAttribute[] = [];
  @State exams: examAttribute[] = [];

  @State showCheckIn: boolean = UnifiedPreferences.getBoolSync('showCheckIn', true);
  @State showRecentCourse: boolean = UnifiedPreferences.getBoolSync('showRecentCourse', true);
  @State showExamDetail: boolean = UnifiedPreferences.getBoolSync('showExamDetail', true);
  @State webAutoDarkMode: boolean = UnifiedPreferences.getBoolSync('webAutoDarkMode', true);
  @State webBackPress: boolean = UnifiedPreferences.getBoolSync('webBackPress', true);

  private context: Context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State currentTime: Date = new Date();
  @State isTodayCourseEnd: boolean = true;

  aboutToAppear(): void {
    Schedule.initSchedulePre(this.context);
    const GeneratedDestructArray_1 = CheckInTools.loadCheckInOnStartup();
    this.checkInTotal = GeneratedDestructArray_1[0];
    this.checkInConsecutive = GeneratedDestructArray_1[1];
    this.checkedInToday = GeneratedDestructArray_1[2];
    this.checkInContent = this.checkedInToday ? GeneratedDestructArray_1[3] : '';
    scheduleManager.getFormattedSchedule(); // 初始化首页课表
    if (scheduleManager.isTermEnd) {
      this.todayCourse = [];
      this.tomorrowCourse = [];
    } else {
      this.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
      this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed + (scheduleManager.today == 5 ? 1 : 0)][(scheduleManager.today + 1) % 7];
    }
    for (let todaySingleCourse of this.todayCourse)
      if (this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
        + Schedule.commonClassStamp[todaySingleCourse.timeSpan[todaySingleCourse.timeSpan.length - 1]][1]) {
        this.isTodayCourseEnd = false;
        break;
      }
    examManager.readStoredExam();
    this.exams = examManager.allExamInfo;
    for (let i = this.exams.length - 1; i >= 0; i--)
      if (this.currentTime.getTime() > this.exams[i].endTimeStamp)
        this.exams.splice(i, 1);
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
    FunctionOrder.refreshFunc(this.context); // 刷新点击次数显示
    this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
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
          .margin({ left: '16vp', right: '12vp' })
          .draggable(false)
        Text(item.title)
          .fontSize('16fp')
          .fontColor($r('app.color.normal_text'))
      }

      if (item.others === undefined) {
        Image($r('app.media.right_arrow'))
          .width('12vp')
          .height('12vp')
          .draggable(false)
      } else if (item.id == 0) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showCheckIn })
          .onClick(() => {
            this.showCheckIn = !this.showCheckIn;
            UnifiedPreferences.putSync('showCheckIn', this.showCheckIn);
          });
      } else if (item.id == 1) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showRecentCourse })
          .onClick(() => {
            this.showRecentCourse = !this.showRecentCourse;
            UnifiedPreferences.putSync('showRecentCourse', this.showRecentCourse);
          });
      } else if (item.id == 2){
        Toggle({ type: ToggleType.Switch, isOn: $$this.showExamDetail })
          .onClick(() => {
            this.showExamDetail = !this.showExamDetail;
            UnifiedPreferences.putSync('showExamDetail', this.showExamDetail);
          });
      } else if (item.id == 5) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.webAutoDarkMode })
          .onClick(() => {
            this.webAutoDarkMode = !this.webAutoDarkMode;
            UnifiedPreferences.putSync('webAutoDarkMode', this.webAutoDarkMode);
          });
      } else { // item.id == 6
        Toggle({ type: ToggleType.Switch, isOn: $$this.webBackPress })
          .onClick(() => {
            this.webBackPress = !this.webBackPress;
            UnifiedPreferences.putSync('webBackPress', this.webBackPress);
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
                .textShadow({ radius: 1 })
                .lineSpacing({ value: 10, unit: LengthUnit.FP })
            }
            .width('80%')
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
              Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                Image($r('app.media.refresh'))
                  .height(20)
                  .width(20)
                  .draggable(false)
              }
              .height(36)
              .width(36)
              .onClick(() => {
                scheduleManager.getFormattedSchedule(); // 初始化首页课表
                this.currentTime = new Date();
                if (scheduleManager.isTermEnd) {
                  this.todayCourse = [];
                  this.tomorrowCourse = [];
                } else {
                  this.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
                  this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed + (scheduleManager.today == 5 ? 1 : 0)][(scheduleManager.today + 1) % 7];
                }
                this.isTodayCourseEnd = true;
                for (let todaySingleCourse of this.todayCourse) {
                  if (this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                    + Schedule.commonClassStamp[todaySingleCourse.timeSpan[todaySingleCourse.timeSpan.length - 1]][1]) {
                    this.isTodayCourseEnd = false;
                    break;
                  }
                }
              })
            } else {
              Blank().width(36);
            }

            Blank()

            Text($r('app.string.your_schedule'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.normal_text'))

            Blank()

            Image($r('app.media.right_arrow'))
              .height(28)
              .width(28)
              .margin({ left: 8 })
              .objectFit(ImageFit.Contain)
              .draggable(false)
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Schedule' })
              .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) })
          })

          if (this.showRecentCourse) {
            Divider();
            if (this.todayCourse.length === 0) {
              Column() {
                Image($r('app.media.no_course_today'))
                  .height(75)
                  .draggable(false)
                Text(scheduleManager.isTermEnd ? $r('app.string.no_class_term_end') : $r('app.string.no_class_today'));
              }
              .margin({ top: 12, bottom: 12 });
            } else {
              ForEach(this.todayCourse, (course: classAttribute, index: number) => {
                if (this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                  + Schedule.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1] + 1800000) {
                  Row() {
                    Column() {
                      Text(course.name)
                        .textAlign(TextAlign.Start)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis });

                      if (this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + Schedule.commonClassStamp[course.timeSpan[0]][0] &&
                        this.currentTime.getTime() > scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + Schedule.commonClassStamp[course.timeSpan[0]][0] - 1800000) {
                        Text($r('app.string.class_soon'))
                          .fontColor($r('app.color.green'));
                      } else if (this.currentTime.getTime() >
                        scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + Schedule.commonClassStamp[course.timeSpan[0]][0] &&
                        this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + Schedule.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]) {
                        Text($r('app.string.class_in_session'))
                          .fontColor($r('app.color.bright_blue'));
                      } else if (this.currentTime.getTime() >
                        scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
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
                      Text(`\udb81\uddf3 ${course.teacher}`)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .visibility(course.teacher == '' ? Visibility.None : Visibility.Visible);

                      Text(`\udb80\uddb8 ${course.location}`)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .visibility(course.location == '' ? Visibility.None : Visibility.Visible);

                      Text(`\udb80\udfdc ${Schedule.commonClassTime[course.timeSpan[0]][0]}~${Schedule.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width('50%')
                    .alignItems(HorizontalAlign.Start);
                  }
                  .width('90%')
                  .margin({ top: 7, bottom: 7 });

                  if (index < this.todayCourse.length - 1) {
                    Divider()
                      .width('90%');
                  }
                }
              });
              if (this.isTodayCourseEnd) {
                Column() {
                  Image($r('app.media.course_finish_today'))
                    .height(50)
                    .draggable(false)
                  Text($r('app.string.class_finish_today'));
                }
                .margin({ top: 12, bottom: 12 });
              }
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
                    .width('90%');
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
                    Text(`\udb81\uddf3 ${course.teacher}`)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .visibility(course.teacher == '' ? Visibility.None : Visibility.Visible);

                    Text(`\udb80\uddb8 ${course.location}`)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .visibility(course.location == '' ? Visibility.None : Visibility.Visible);

                    Text(`\udb80\udfdc ${Schedule.commonClassTime[course.timeSpan[0]][0]}~${Schedule.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
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
              Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                Image($r('app.media.refresh'))
                  .height(20)
                  .width(20)
                  .draggable(false)
              }
              .height(36)
              .width(36)
              .onClick(() => {
                examManager.readStoredExam();
                this.exams = examManager.allExamInfo;
                for (let i = this.exams.length - 1; i >= 0; i--)
                  if (this.currentTime.getTime() > this.exams[i].endTimeStamp)
                    this.exams.splice(i, 1);
              });
            } else {
              Blank().width(36);
            }
            
            Blank()

            Text($r('app.string.exam_detail'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.normal_text'))

            Blank()

            Image($r('app.media.right_arrow'))
              .height(28)
              .width(28)
              .margin({ left: 8 })
              .objectFit(ImageFit.Contain)
              .draggable(false)
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/ExamDetail' })
              .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) })
          })

          if (this.showExamDetail) {
            Divider();
            if (this.exams.length === 0) {
              Column() {
                Image($r('app.media.no_exam1'))
                  .height(75)
                  .draggable(false)
                Text($r('app.string.no_exam_info1'));
              }
              .margin({ top: 12, bottom: 12 });
            } else {
              ForEach(this.exams, (singleExam: examAttribute, index: number) => {
                Row() {
                  if (this.currentTime.getTime() < singleExam.beginTimeStamp) {
                    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.End }) {
                      Row() {
                        Text(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 0).toString())
                          .fontSize(36)
                          .fontWeight(FontWeight.Bold)
                          .fontColor($r('app.color.green'))
                        Text($r('app.string.day'))
                          .fontColor($r('app.color.green'))
                          .lineSpacing({ value: 5, unit: LengthUnit.FP })
                          .maxFontSize(18)
                          .fontWeight(FontWeight.Bold)
                          .padding({ bottom: 6 })
                      }
                      .alignItems(VerticalAlign.Bottom)

                      Row() {
                        Text(Number((tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 1)
                          + tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 2) / 60).toExponential(1)).toString())
                          .fontSize(28)
                          .fontWeight(FontWeight.Bold)
                          .fontColor($r('app.color.hour'))
                        Text($r('app.string.hour'))
                          .fontColor($r('app.color.hour'))
                          .fontSize(14)
                          .fontWeight(FontWeight.Bold)
                          .padding({ bottom: 5 })
                      }
                      .margin({ bottom: 2 })
                      .alignItems(VerticalAlign.Bottom)
                    }
                    .width('30%');
                  } else {
                    Text($r('app.string.exam_processing'))
                      .fontSize(20)
                      .fontColor($r('app.color.transparent_text'))
                      .width('30%')
                      .textAlign(TextAlign.Start);
                  }

                  Column() {
                    Row() {
                      Text(singleExam.name + '  ')
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .margin({ bottom: 5 })
                      Text(singleExam.type)
                        .fontSize(18)
                        .margin({ bottom: 5 })
                    }

                    Text(`\udb80\uddb8 ${singleExam.campus} ${singleExam.building} ${singleExam.classroom}`)
                      .visibility(singleExam.campus + singleExam.building + singleExam.classroom == '' ? Visibility.None : Visibility.Visible);
                    Text(`\udb80\udfdc ${singleExam.date}`)
                      .visibility(singleExam.date == '' ? Visibility.None : Visibility.Visible);
                  }
                  .width('70%')
                  .alignItems(HorizontalAlign.Start);
                }
                .width('90%')
                .margin({ top: 7, bottom: 7 })
                .borderRadius(20);

                if (index < this.exams.length - 1) {
                  Divider().width('90%');
                }
              })
            }
          }
        }
      }
      .width('100%')
      .borderRadius(20)
      .margin({ top: 5, bottom: 12 })
      .backgroundColor($r('app.color.grid_background'));
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
    .padding({ top: 12, left: 12, right: 12 })
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
            .edgeEffect(EdgeEffect.Spring)
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
                  // 显示签到
                  this.showCheckIn = !this.showCheckIn;
                  UnifiedPreferences.putSync('showCheckIn', this.showCheckIn);
                  break;

                case 1:
                  // 显示课表
                  this.showRecentCourse = !this.showRecentCourse;
                  UnifiedPreferences.putSync('showRecentCourse', this.showRecentCourse);
                  break;

                case 2:
                  // 显示考试
                  this.showExamDetail = !this.showExamDetail;
                  UnifiedPreferences.putSync('showExamDetail', this.showExamDetail);
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
                      FunctionOrder.refreshFunc(this.context); // 刷新点击次数显示
                      this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
                    }
                  })
                  break;

                case 4:
                  // 重置最近使用
                  FunctionOrder.resetFunc(this.context);
                  FunctionOrder.refreshFunc(this.context); // 刷新点击次数显示
                  this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
                  try {
                    this.showMessage($r('app.string.have_cleared'), 500);
                  } catch (error) {
                    console.error(`ShowToast ERROR: [${error.name}] ${error.message}`);
                  }
                  break;

                case 5:
                  this.webAutoDarkMode = !this.webAutoDarkMode;
                  UnifiedPreferences.putSync('webAutoDarkMode', this.webAutoDarkMode);
                  break;

                case 6:
                  this.webBackPress = !this.webBackPress;
                  UnifiedPreferences.putSync('webBackPress', this.webBackPress);
                  break;

                case 7:
                  // 清除日历中的所有提醒信息
                  let getPermission: boolean = true;
                  calendarMgr?.getCalendar(calendarAccount).then((data: calendarManager.Calendar) => {
                    let calendar: calendarManager.Calendar | undefined = data;
                    if (calendar == undefined){
                      this.showMessage($r('app.string.calendar_null'), 500);
                    } else {
                      calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
                        getPermission = false;
                        this.calendar_permission_denied(error);
                      });
                      this.showMessage($r('app.string.clear_success'), 500);
                      calendar = undefined;
                    }
                  }).catch((err: BusinessError) => {
                    if (err.message == 'GetCalendar failed!')
                      this.showMessage($r('app.string.clear_success'), 500);
                    else {
                      getPermission = false;
                      this.calendar_permission_denied(err);
                    }
                  });
                  setTimeout(() => {
                    if (getPermission) {
                      calendarMgr?.getCalendar(calendarAccount_exam).then((data: calendarManager.Calendar) => {
                        let calendar: calendarManager.Calendar | undefined = data;
                        if (calendar != undefined) {
                          calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
                            this.calendar_permission_denied(error);
                          });
                          calendar = undefined;
                        }
                      }).catch((err: BusinessError) => {
                        if (err.message == 'GetCalendar failed!') {
                          this.showMessage($r('app.string.clear_success'), 500);
                        } else {
                          this.calendar_permission_denied(err);
                        }
                      });
                    }
                  }, 500);
                  break;

                case 8:
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
                      let getPermission: boolean = true;
                      // 删除日程
                      calendarMgr?.getCalendar(calendarAccount).then((data: calendarManager.Calendar) => {
                        getPermission = true;
                        let calendar: calendarManager.Calendar | undefined = data;
                        if (calendar != undefined) {
                          calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
                            getPermission = false;
                            this.calendar_permission_denied(error);
                          });
                          calendar = undefined;
                        }
                      }).catch((err: BusinessError) => {
                        if (err.message == 'GetCalendar error!') {
                          getPermission = false;
                          this.calendar_permission_denied(err);
                        }
                      });

                      //创建日程
                      setTimeout(() => {
                        if (getPermission)
                          calendarMgr?.createCalendar(calendarAccount).then((data: calendarManager.Calendar) => {
                            let calendar: calendarManager.Calendar | undefined = data;
                            // 确保日历账户创建成功后，再进行后续相关操作
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
                                    Schedule.setRemindBefore(valueData[Number(value.index)]);
                                    if (value.index == 0) {
                                      this.showMessage('已更改为 不提醒', 500);
                                    } else {
                                      this.showMessage(`已更改为 在${value.value}提醒`, 500);
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
                                                for (let j = layer3.weekOfTerm[i - 1] + 1; j < layer3.weekOfTerm[i];
                                                  j++) {
                                                  excludeDates.push(tools.getClassTimestamp(scheduleManager.termStart, j,
                                                    layer3.dayOfWeek, Schedule.commonClassStamp[layer3.timeSpan[0]][0]));
                                                }
                                              }
                                              // 设置日程
                                              const event: calendarManager.Event = {
                                                title: layer3.name, // 日程标题
                                                location: { location: layer3.location },
                                                type: calendarManager.EventType.NORMAL, // 日程类型
                                                startTime: tools.getClassTimestamp(scheduleManager.termStart,
                                                  layer3.weekOfTerm[0],
                                                  (layer3.dayOfWeek + 1) % 7,
                                                  Schedule.commonClassStamp[layer3.timeSpan[0]][0]), // 日程开始时间
                                                endTime: tools.getClassTimestamp(scheduleManager.termStart,
                                                  layer3.weekOfTerm[0],
                                                  (layer3.dayOfWeek + 1) % 7,
                                                  Schedule.commonClassStamp[layer3.timeSpan[1]][1]), // 日程结束时间
                                                reminderTime: Schedule.remindBefore, // 距开始时间提前remindBefore分钟提醒
                                                recurrenceRule: {
                                                  // 日程重复规则
                                                  recurrenceFrequency: calendarManager.RecurrenceFrequency.WEEKLY, // 日程重复规则类型
                                                  count: layer3.weekOfTerm.length, // 日程重复次数，该字段和expire属性只需要填写一个，如果两个都填写按照count属性计算。
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
                                  }).catch((err: BusinessError) => { this.calendar_permission_denied(err); });
                                }
                              });
                            }
                          }).catch((error: BusinessError) => {
                            this.calendar_permission_denied(error);
                          });
                      }, 500);
                    }
                  })
                  break;

                case 9:
                  let selected4: number = 0;
                  switch (Schedule.examRemindBefore[0]) {
                    case 30: selected4 = 1; break;
                    case 60: selected4 = 2; break;
                    case 120: selected4 = 3; break;
                    case 1440: selected4 = 4; break;
                    case 2880: selected4 = 5; break;
                    case 10080: selected4 = 6; break;
                  }
                  // 在上课几分钟前提醒
                  this.getUIContext().showTextPickerDialog({
                    selected: selected4,
                    range: ['不提醒', "考试前 30 分钟", "考试前 1 小时", "考试前 2 小时", "考试前 1 天", "考试前 2 天", "考试前 1 周"],
                    defaultPickerItemHeight: 36,
                    canLoop: false,
                    onAccept: (value: TextPickerResult) => {
                      // 删除原日程
                      let getPermission: boolean = true;
                      calendarMgr?.getCalendar(calendarAccount_exam).then((data: calendarManager.Calendar) => {
                        let calendar: calendarManager.Calendar | undefined = data;
                        if (calendar != undefined) {
                          calendarMgr?.deleteCalendar(calendar).catch((error: BusinessError) => {
                            getPermission = false;
                            this.calendar_permission_denied(error);
                          });
                          calendar = undefined;
                        }
                      }).catch((err: BusinessError) => {
                        if (err.message == 'GetCalendar error!') {
                          getPermission = false;
                          this.calendar_permission_denied(err);
                        }
                      });

                      // 创建日程
                      setTimeout(() => {
                        if (getPermission)
                          calendarMgr?.createCalendar(calendarAccount_exam).then((data: calendarManager.Calendar) => {
                            let calendar: calendarManager.Calendar | undefined = data;
                            // 确保日历账户创建成功后，再进行后续相关操作
                            // 将课程写入日历
                            if (calendar != undefined) {
                              //获取日历账户
                              calendarMgr?.getCalendar(calendarAccount_exam, (err, data) => {
                                if (err) {
                                  this.calendar_permission_denied(err);
                                } else {
                                  const config: calendarManager.CalendarConfig = {
                                    enableReminder: true, // 打开日程提醒
                                    color: '#FFCECB' // 设置日历账户颜色
                                  };
                                  data.setConfig(config).then(() => { // 设置日历配置信息
                                    const valueData: number[] = [-1, 30, 60, 120, 1440, 2880, 10080];
                                    Schedule.setExamRemindBefore(valueData[Number(value.index)]);
                                    if (value.index == 0) {
                                      this.showMessage('已更改为 不提醒', 500);
                                    } else {
                                      this.showMessage(`已更改为 在${value.value}提醒`, 500);
                                    }
                                    let eventId: number | undefined = undefined;
                                    for (let layer1 of this.exams) {
                                      // 设置日程
                                      const event: calendarManager.Event = {
                                        title: layer1.name, // 日程标题
                                        location: { location: layer1.building + layer1.classroom },
                                        type: calendarManager.EventType.NORMAL, // 日程类型
                                        startTime: new Date(layer1.date.slice(0, 16)).getTime(), // 日程开始时间
                                        endTime: new Date(layer1.date.slice(0, 11) +
                                        layer1.date.slice(17, 22)).getTime(), // 日程结束时间
                                        reminderTime: Schedule.examRemindBefore, // 距开始时间提前remindBefore分钟提醒
                                      };
                                      if (calendar != undefined) {
                                        calendar.addEvent(event).then((data: number) => {
                                          eventId = data;
                                        });
                                      }
                                    }
                                  }).catch((err: BusinessError) => {
                                    this.calendar_permission_denied(err);
                                  });
                                }
                              });
                            }
                          }).catch((error: BusinessError) => {
                            this.calendar_permission_denied(error);
                          });
                      }, 500);
                    }
                  })
                  break;

                case 10:
                  let cacheDir = this.getUIContext().getHostContext()!.cacheDir;
                  console.info(cacheDir);
                  fileIo.listFile(cacheDir).then((filenames) => {
                    for (let i = 0; i < filenames.length; i++) {
                      let dirPath = cacheDir + '/' + filenames[i];
                      console.log(dirPath);
                      // Determine whether it is a folder
                      let isDirectory: boolean = false;
                      try {
                        isDirectory = fileIo.statSync(dirPath).isDirectory();
                      } catch (e) {
                        console.error(JSON.stringify(e));
                      }
                      if (isDirectory) {
                        fileIo.rmdirSync(dirPath);
                      } else {
                        fileIo.unlink(dirPath).then(() => {
                          console.info('remove file succeed');
                        }).catch((err: Error) => {
                          console.error('remove file failed with error message: ' + err.message);
                        });
                      }
                    }
                  })
                  this.showMessage($r('app.string.wipe_cache_success'), 500);
                  break;

                case 11:
                  // 帮助
                  this.getUIContext().getRouter().pushUrl({ url: 'pages/Help' })
                    .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
                  break;
                case 12:
                  // 关于
                  this.getUIContext().getRouter().pushUrl({ url: 'pages/About' })
                    .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
                  break;
                case 13:
                  // 退出到恢复模式
                  UnifiedPreferences.putSync('RecoveryMode', true)
                  const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                  context.terminateSelf((err) => {
                    if (!err) {
                      context.getApplicationContext().killAllProcesses().catch((error: Error) => {
                        console.error(`Quitting ERROR: [${error.name}] ${error.message}`);
                      })
                    }
                  })
                  break;
                default:
                 this.showMessage($r('app.string.under_construction'), 500);
              }
            })
          })
        }
        .divider({
          strokeWidth: '0.6vp',
          color: $r('app.color.grid_border'),
          startMargin: '12vp',
          endMargin: '12vp'
        })
        .backgroundColor($r('app.color.grid_background'))
        .borderRadius(20)

      }, (item: ItemData) => JSON.stringify(item))

      ListItem()
        .visibility(Visibility.Hidden)
        .height('50vp')
    }
    .height('100%')
    .width('100%')
    .padding({ top: 20, left: 12, right: 12 })
    .scrollBar(BarState.Auto)
    .overlay(this.settingExitButton(), { align: Alignment.Bottom })
  }

  @Builder
  settingExitButton(){
    Column() {
      Button($r('app.string.exit_app'), { type: ButtonType.Capsule })
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontColor(Color.Red)
        .backgroundColor($r('app.color.normal_background_transparent'))
        .backgroundBlurStyle(BlurStyle.BACKGROUND_REGULAR, {
          colorMode: ThemeColorMode.LIGHT,
          adaptiveColor: AdaptiveColor.DEFAULT,
          scale: 0.1
        })
        .width('100%')
        .margin({ bottom: 15 })
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          context.terminateSelf((err) => {
            if (!err) {
              context.getApplicationContext().killAllProcesses().catch((error: Error) => {
                console.error(`Quitting ERROR: [${error.name}] ${error.message}`);
              })
            }
          })
        })
    }
    .width('80%')
    .justifyContent(FlexAlign.End)
    .hitTestBehavior(HitTestMode.Transparent)
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
      .padding({ left: 7, right: 7 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_start'), 0, $r('app.media.tab0_selected'), $r('app.media.tab0_unselected')))

      /**
       * Tab: 功能
       */
      TabContent() { this.pageFunction() }
      .padding({ left: 7, right: 7 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_function'), 1, $r('app.media.tab1_selected'), $r('app.media.tab1_unselected')))

      /**
       * Tab: 设置
       */
      TabContent() { this.pageSettings() }
      .padding({ left: 7, right: 7 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_settings'), 2, $r('app.media.tab2_selected'), $r('app.media.tab2_unselected')))

    }
    .width('100%')
    .backgroundColor($r('app.color.shaded_background'))
    .barHeight(52)
    .barMode(BarMode.Fixed)
    .onAnimationStart((index: number, targetIndex: number) => {
      this.currentIndex = targetIndex;
      if (this.currentIndex === 1) {
        FunctionOrder.refreshFunc(this.context); // 刷新点击次数显示
        this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
      }
    })
  }
}
