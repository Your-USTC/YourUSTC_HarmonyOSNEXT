
import { common } from '@kit.AbilityKit'
import { LengthUnit } from '@kit.ArkUI'

import * as ScheduleSources from '../constants/ScheduleSources'
import SettingsData from '../constants/SettingsSources'

import { CheckInTools } from '../utils/CheckIn'
import { examAttribute } from '../utils/ExamStorage';
import examManager from '../utils/ExamManager'
import * as FunctionOrder from '../utils/FunctionOrder'
import ScheduleManager from '../utils/Classes/ScheduleManager'
import * as tools from '../utils/tools'
import UnifiedPreferences, { millisecondsPerWeek } from '../utils/UnifyPreference'
import WriteCalendar from '../utils/WriteCalendar'

import BackgroundImage, { presetColor } from '../utils/BgImageManager'
import { GridComponent, MostRecentComponent } from '../view/GridComponent'
import PasswordDialog from '../view/PasswordDialog'
import ItemData from '../view/SettingsComponent'

import display from '@ohos.display'
import { WantAbility } from '../utils/WantAbility'
import { currentAppVersion, initHostContext, deviceType, hostContext } from '../constants/BasicConstants'
import { hdsMaterial, HdsTabs, HdsTabsController } from '@kit.UIDesignKit'
import accountInfoProvider from '../utils/Encryption'
import { LinkSet, LINK, SimpleLink, MultiLink } from '../constants/Links'
// import { SplitPlaceholder } from '../view/SplitPlaceholder'

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
  private windowRect: display.Display = display.getDefaultDisplaySync();

  @State currentIndex: number = 0; // 当前标签索引 (从0开始), 初始值即为默认标签索引
  private tabsController: HdsTabsController = new HdsTabsController();

  @Provide displayUsername: string = accountInfoProvider.getUID();
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      isFromSetting: true,
    }),
    autoCancel: false,
    gridCount: 4
  });

  /**
   * 函数: 构建 Tab 按钮
   * @param title 按钮文字
   * @param index 标签索引 (从0开始)
   * @param selectedImg 按钮图片 (选中时)
   * @param normalImg 按钮图片 (未选中时)
   */
  @Builder tabBuilder(title: string | Resource, index: number, selectedImg: Resource, normalImg: Resource) {
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
    .height('52vp')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .onClick(() => {
      this.currentIndex = index
      this.tabsController.changeIndex(this.currentIndex);
    })
  }

  /**
   * 全局资源: 首页
   */
  @State checkInTotal: number = 0;
  @State checkInConsecutive: number = 0;
  @State checkedInToday: boolean = false;
  @State checkInContent: string = ''; // 签到后展示的随机内容

  @State todayCourse: ScheduleSources.classAttribute[] = [];
  @State tomorrowCourse: ScheduleSources.classAttribute[] = [];
  @State exams: examAttribute[] = [];

  @State showCheckIn: boolean = UnifiedPreferences.getBoolSync('showCheckIn', true);
  @State showRecentCourse: boolean = UnifiedPreferences.getBoolSync('showRecentCourse', true);
  @State showExamDetail: boolean = UnifiedPreferences.getBoolSync('showExamDetail', true);
  @State webAutoDarkMode: boolean = UnifiedPreferences.getBoolSync('webAutoDarkMode', true);
  @State webBackPress: boolean = UnifiedPreferences.getBoolSync('webBackPress', true);
  @State currentTime: Date = new Date();

  aboutToAppear(): void {
    // 保存 hostContext
    initHostContext(this.getUIContext().getHostContext() as common.UIAbilityContext);
    // 快捷方式跳转
    hostContext().eventHub.on('navigation', (path: string) => {
      let paths = this.pageInfo.getAllPathName();
      if (paths.slice().pop() === path) {
        return;
      }
      this.pageInfo.pushPath({ name: path }, false);
    });
    // 刷新点击次数显示
    FunctionOrder.refreshFunc();
    this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
    // 获取签到和课表
    ScheduleSources.initSchedulePre();
    const GeneratedDestructArray_1 = CheckInTools.loadCheckInOnStartup();
    this.checkInTotal = GeneratedDestructArray_1[0];
    this.checkInConsecutive = GeneratedDestructArray_1[1];
    this.checkedInToday = GeneratedDestructArray_1[2];
    this.checkInContent = this.checkedInToday ? GeneratedDestructArray_1[3] : '';
    this.refreshInfo();
    // 初始化导航模式偏好（热更新时经AppStorage('adaptSplit')同步到.mode()）
    this.adaptSplit = UnifiedPreferences.getNumberSync('AdaptSplit', NavigationMode.Auto);
    // 初始化背景
    BackgroundImage.init(hostContext());
    this.avatar = BackgroundImage.avatar;
    // 初始化日历
    WriteCalendar.initializeCalendar(this.getUIContext());
    // 首次启动提示
    if (UnifiedPreferences.getBoolSync('InitialLaunch', true)) {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/Declaration' })
        .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
    } else if (UnifiedPreferences.getSync('AppVersion') !== currentAppVersion) {
      UnifiedPreferences.putSync('ShowPinchHint', true); // Ver 2.2.1 新增了提示，因此重置提示
      this.getUIContext().getRouter().pushUrl({ url: 'pages/UpdateLog' })
        .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
    }
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

  @Builder listBuilder() {
    Row() {
      List({ space: 16, scroller: this.scrollerForTitle }) {
        ForEach(LINK, (item: LinkSet, index) => {
          ListItem() {
            Column() {
              Text(item.title)
                .fontColor(this.currentListIndex === index ? presetColor[BackgroundImage.themeColor][2] : $r('app.color.normal_text'))
                .fontSize('16fp')
                .fontWeight(this.currentListIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .margin({ top: '15vp' })

              Divider()
                .color(presetColor[BackgroundImage.themeColor][2])
                .strokeWidth(2)
                .width(this.getUIContext().getMeasureUtils().measureText({ textContent: item.title, fontSize: '16fp' }).toString() + 'px')
                .margin({ top: '4vp' })
                .visibility(this.currentListIndex === index ? Visibility.Visible : Visibility.Hidden)
            }
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.scrollerForList.scrollToIndex(index);
              this.scrollerForScroll.scrollEdge(Edge.Bottom);
              this.scrollerForTitle.scrollToIndex(index);
              this.currentListIndex = index;
            })
          }
        })//, (item: string, index: number) => index + JSON.stringify(item))
      }
      .width('100%')
      .height('51vp')
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .fadingEdge(true)
      .contentStartOffset(6)
      .contentEndOffset(6)
    }
    .margin({ bottom: '8vp' })
    .padding({ left: '10vp', right: '10vp' })
    .backgroundColor(BackgroundImage.showImage
      ? (BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
      : $r('app.color.normal_background'))
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .borderRadius(20)
  }

  @State copyMostUsedFunc: MultiLink[] = FunctionOrder.mostUsedFunc;

  /**
   * 全局资源: 设置
   */
  @Builder settingCell(item: ItemData) {
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
      } else if (item.id === 1) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showCheckIn })
          .selectedColor(presetColor[BackgroundImage.themeColor][2])
          .onChange((value: boolean) => {
            UnifiedPreferences.putSync('showCheckIn', value);
          });
      } else if (item.id === 2) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showRecentCourse })
          .selectedColor(presetColor[BackgroundImage.themeColor][2])
          .onChange((value: boolean) => {
            UnifiedPreferences.putSync('showRecentCourse', value);
          });
      } else if (item.id === 3){
        Toggle({ type: ToggleType.Switch, isOn: $$this.showExamDetail })
          .selectedColor(presetColor[BackgroundImage.themeColor][2])
          .onChange((value: boolean) => {
            UnifiedPreferences.putSync('showExamDetail', value);
          });
      } else if (item.id === 6) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.webAutoDarkMode })
          .selectedColor(presetColor[BackgroundImage.themeColor][2])
          .onChange((value: boolean) => {
            UnifiedPreferences.putSync('webAutoDarkMode', value);
          });
      } else { // item.id === 8
        Toggle({ type: ToggleType.Switch, isOn: $$this.webBackPress })
          .selectedColor(presetColor[BackgroundImage.themeColor][2])
          .onChange((value: boolean) => {
            UnifiedPreferences.putSync('webBackPress', value);
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

  /*
   * 常用功能
   */
  @State termState: number = 0; // 0：未开始，1：进行中，2: 进行中但今天无课程，3: 进行中但今天的课都上完了，4：已结束
  private currentWeek: number = 1;
  private todayBeginTime: number = 0;
  refreshInfo() {
    this.currentTime = new Date();
    const termStartTime: number = ScheduleManager.semesters[ScheduleManager.defaultSemester].beginTime;
    this.todayBeginTime = new Date(this.currentTime).setHours(0, 0, 0, 0);
    if (this.currentTime.getTime() < termStartTime) {
      this.termState = 0;
      this.currentWeek = 1;
      this.todayCourse = [];
      this.tomorrowCourse = [];
    } else if (this.currentTime.getTime() > termStartTime + ScheduleManager.semesters[ScheduleManager.defaultSemester].totalWeekNum * millisecondsPerWeek) {
      this.termState = 4;
      this.currentWeek = 1;
      this.todayCourse = [];
      this.tomorrowCourse = [];
    } else {
      this.currentWeek = Math.ceil((this.currentTime.getTime() - termStartTime) / millisecondsPerWeek);
      this.todayCourse = ScheduleManager.getDefaultClassByDay(this.currentWeek, this.currentTime.getDay(), true);
      this.tomorrowCourse = ScheduleManager.getDefaultClassByDay(this.currentWeek + (this.currentTime.getDay() === 6 ? 1 : 0), (this.currentTime.getDay() + 1) % 7, true);
      if (this.todayCourse.length === 0)
        this.termState = 2;
      else if (this.currentTime.getTime() > this.todayBeginTime + ScheduleSources.commonClassStamp[this.todayCourse[this.todayCourse.length - 1].timeSpan[this.todayCourse[this.todayCourse.length - 1].timeSpan.length - 1]][1])
        this.termState = 3;
      else
        this.termState = 1;
    }

    examManager.readStoredExam();
    this.exams = examManager.allExamInfo.filter(item => this.currentTime.getTime() <= item.endTimeStamp);
  }

  showMessage(message: string | ResourceStr, duration?: number) {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message,
        duration: duration
      });
    } catch (error) {
      console.error(`ShowToast ERROR: [${error.name}] ${error.message}`);
    }
  }

  /*
   * 日历权限相关
   */

  /**
   * 页面: 首页
   */
  @Builder pageStart() {
    List({ space: 10 }) {
      // 每日签到
      if (this.showCheckIn) {
        ListItem() {
          Column() {
            Row() {
              Text($r('app.string.archive'))
                .fontSize(13)
                .visibility(Visibility.Hidden)
                .margin({ left: 20 })

              Text($r('app.string.daily_checkin'))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.normal_text'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

              Text($r('app.string.archive'))
                .fontSize(13)

              Image($r('app.media.right_arrow'))
                .height(28)
                .width(20)
                .objectFit(ImageFit.Contain)
                .draggable(false)
            }
            .width('100%')
            .padding(8)
            .onClick(() => {
              if (this.pageInfo.popToName('CheckinCollection') === -1) {
                this.pageInfo.clear();
                this.pageInfo.pushPath({ name: 'CheckinCollection' });
              }
            })

            Row() {
              Text(this.checkInContent)
                .fontColor($r('app.color.active_text'))
                .fontSize(20)
                .textShadow({ radius: 1 })
                .lineSpacing({ value: 10, unit: LengthUnit.FP })
                .wordBreak(WordBreak.BREAK_ALL)
            }
            .width('80%')
            .margin({ bottom: 10 })
            .justifyContent(FlexAlign.Center)

            Row() {
              Button(this.checkedInToday ? $r('app.string.checked_in') : $r('app.string.check_in'))
                .buttonStyle(this.checkedInToday ? ButtonStyleMode.NORMAL : ButtonStyleMode.EMPHASIZED)
                .enabled(!this.checkedInToday)
                .onClick(() => {
                  const GeneratedDestructArray_1 = CheckInTools.doCheckIn();
                  this.checkInTotal = GeneratedDestructArray_1[0];
                  this.checkedInToday = true;
                  this.checkInConsecutive = GeneratedDestructArray_1[1];
                  this.checkInContent = GeneratedDestructArray_1[2];
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
        .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
        .backgroundBlurStyle(BackgroundImage.blurLevel);
      }

      // 你的课表
      ListItem() {
        Column() {
          Row() {
            Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
              Image($r('app.media.refresh'))
                .height(20)
                .width(20)
                .draggable(false)
            }
            .height(36)
            .width(36)
            .visibility(this.showRecentCourse ? Visibility.Visible : Visibility.Hidden)
            .onClick(() => {
              this.refreshInfo();
            })

            Text($r('app.string.local_schedule'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.normal_text'))

            Image($r('app.media.right_arrow'))
              .height(28)
              .width(28)
              .margin({ left: 8 })
              .objectFit(ImageFit.Contain)
              .draggable(false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding(8)
          .onClick(() => {
            if (this.pageInfo.popToName('Schedule') === -1) {
              this.pageInfo.clear();
              this.pageInfo.pushPath({ name: 'Schedule',
                param: UnifiedPreferences.getNumberSync('GridHeight', px2vp(this.windowRect.height) - 75) });
            }
            // this.getUIContext().getRouter().pushUrl({ url: 'pages/Schedule' })
            //   .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) })
          })

          if (this.showRecentCourse) {
            Divider();

            if (this.termState === 0) {
              Column() {
                Image($r('app.media.no_course_term_not_start'))
                  .height(100)
                  .draggable(false);
                Text($r('app.string.no_class_term_not_start'))
                  .textAlign(TextAlign.Center);
              }
              .margin({ top: 12, bottom: 12 });
            } else if (this.termState === 2) {
              Column() {
                Image($r('app.media.no_course_today'))
                  .height(100)
                  .draggable(false);
                Text($r('app.string.no_class_today'))
                  .textAlign(TextAlign.Center);
              }
              .margin({ top: 12, bottom: 12 });
            } else if (this.termState === 4) {
              Column() {
                Image($r('app.media.no_course_term_end'))
                  .height(100)
                  .draggable(false);
                Text($r('app.string.no_class_term_end'))
                  .textAlign(TextAlign.Center);
              }
              .margin({ top: 12, bottom: 12 });
            } else {
              ForEach(this.todayCourse, (course: ScheduleSources.classAttribute, index: number) => {
                if (this.currentTime.getTime() < this.todayBeginTime +
                ScheduleSources.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1] + 1800000) {
                  Row() {
                    Column() {
                      Line()
                        .stroke((course.color.length === 9) ? `#${course.color.slice(3)}` :
                          ((course.color.length === 5) ? `#${course.color.slice(2)}` : course.color))
                        .width(6)
                        .height(20)
                        .strokeLineCap(LineCapStyle.Round)
                        .strokeWidth(6)
                        .startPoint([3, 0])
                        .endPoint([3, 20])
                        .margin({ right: 4 });
                    }
                    .alignItems(HorizontalAlign.End)
                    .width('5%');

                    Column() {
                      Text(course.name)
                        .textAlign(TextAlign.Start)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis });

                      if (this.currentTime.getTime() <
                        this.todayBeginTime + ScheduleSources.commonClassStamp[course.timeSpan[0]][0] &&
                        this.currentTime.getTime() >
                          this.todayBeginTime + ScheduleSources.commonClassStamp[course.timeSpan[0]][0] - 1800000) {
                        Text($r('app.string.class_soon'))
                          .fontColor($r('app.color.green'));
                      } else if (this.currentTime.getTime() >
                        this.todayBeginTime + ScheduleSources.commonClassStamp[course.timeSpan[0]][0] &&
                        this.currentTime.getTime() < this.todayBeginTime +
                        ScheduleSources.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]) {
                        Text($r('app.string.class_in_session'))
                          .fontColor($r('app.color.bright_blue'));
                      } else if (this.currentTime.getTime() >
                        this.todayBeginTime + ScheduleSources.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]) {
                        Text($r('app.string.class_end'))
                          .fontColor($r('app.color.red'));
                      } else {
                        Text($r('app.string.class_not_start'))
                          .fontColor($r('app.color.green'));
                      }
                    }
                    .width('45%')
                    .alignItems(HorizontalAlign.Start)
                    .padding({ right: 10 });

                    Column() {
                      Text(`\udb81\uddf3 ${course.teacher}`)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .visibility(course.teacher === '' ? Visibility.None : Visibility.Visible);

                      Text(`\udb80\uddb8 ${course.location}`)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .visibility(course.location === '' ? Visibility.None : Visibility.Visible);

                      Text(`\udb80\udfdc ${ScheduleSources.commonClassTime[course.timeSpan[0]][0]}~${ScheduleSources.commonClassTime[course.timeSpan[course.timeSpan.length -
                        1]][1]}`)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis });
                    }
                    .width('48%')
                    .alignItems(HorizontalAlign.Start);
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Start)
                  .margin({ top: 7, bottom: 7 });

                  if (index < this.todayCourse.length - 1) {
                    Divider()
                      .width('90%');
                  }
                }
              });
              if (this.termState === 3) {
                Column() {
                  Image($r('app.media.course_finish_today'))
                    .height(100)
                    .draggable(false);
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

              ForEach(this.tomorrowCourse, (course: ScheduleSources.classAttribute, index) => {
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
                      .visibility(course.teacher === '' ? Visibility.None : Visibility.Visible);

                    Text(`\udb80\uddb8 ${course.location}`)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .visibility(course.location === '' ? Visibility.None : Visibility.Visible);

                    Text(`\udb80\udfdc ${ScheduleSources.commonClassTime[course.timeSpan[0]][0]}~${ScheduleSources.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
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
      .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
      .backgroundBlurStyle(BackgroundImage.blurLevel);

      // 考试信息
      ListItem() {
        Column() {
          Row() {
            Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
              Image($r('app.media.refresh'))
                .height(20)
                .width(20)
                .draggable(false)
            }
            .height(36)
            .width(36)
            .visibility(this.showExamDetail ? Visibility.Visible : Visibility.Hidden)
            .onClick(() => {
              this.refreshInfo();
            });

            Text($r('app.string.exam_detail'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.normal_text'))

            Image($r('app.media.right_arrow'))
              .height(28)
              .width(28)
              .margin({ left: 8 })
              .objectFit(ImageFit.Contain)
              .draggable(false)
          }
          .width('100%')
          .padding(8)
          .justifyContent(FlexAlign.SpaceBetween)
          .onClick(() => {
            if (this.pageInfo.popToName('ExamDetail') === -1) {
              this.pageInfo.clear();
              this.pageInfo.pushPath({ name: 'ExamDetail' });
            }
          })

          if (this.showExamDetail) {
            Divider();
            if (this.exams.length === 0) {
              Column() {
                Image($r('app.media.no_exam1'))
                  .height(100)
                  .draggable(false)
                Text($r('app.string.no_exam_info1'));
              }
              .margin({ top: 12, bottom: 12 });
            } else {
              ForEach(this.exams, (singleExam: examAttribute, index: number) => {
                Column() {
                  Row() {
                    Text(singleExam.name)
                      .layoutWeight(1)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ right: 5 })

                    if (this.currentTime.getTime() < singleExam.beginTimeStamp) {
                      Text() {
                        Span(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 0).toString())
                          .fontColor($r('app.color.green'))
                        Span(':')
                        Span(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 1).toString())
                          .fontColor($r('app.color.hour'))
                        Span(':')
                        Span(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 2).toString())
                          .fontColor($r('app.color.minute'))
                      }
                      .fontSize(22)
                      .fontColor($r('app.color.transparent_text'))
                    } else {
                      Text($r('app.string.exam_processing'))
                        .layoutWeight(1)
                        .fontSize(18)
                        .margin({ bottom: 4 })
                        .fontColor($r('app.color.transparent_text'))
                        .textAlign(TextAlign.End);
                    }
                  }
                  .alignItems(VerticalAlign.Top)
                  .width('100%')

                  Text('\udb81\ude5a ' + singleExam.type)
                    .fontSize(15)
                  Text('\udb80\udfdc ' + singleExam.date)
                    .fontSize(15)
                    .visibility(singleExam.date === '' ? Visibility.None : Visibility.Visible);
                  Text('\udb80\uddb8 ' + singleExam.campus + singleExam.building + singleExam.classroom)
                    .fontSize(15)
                    .visibility(singleExam.campus + singleExam.building + singleExam.classroom === '' ? Visibility.None : Visibility.Visible);
                }
                .padding({ left: 15, right: 15 })
                .margin({ top: 7, bottom: 7 })
                .alignItems(HorizontalAlign.Start)
                .borderRadius(20);

                if (index < this.exams.length - 1) {
                  Divider().padding({ left: 15, right: 15 });
                }
              })
            }
          }
        }
      }
      .width('100%')
      .borderRadius(20)
      .margin({ top: 5 })
      .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
      .backgroundBlurStyle(BackgroundImage.blurLevel);

      ListItem() {
        Text($r('app.string.not_newest'))
          .fontColor($r('app.color.transparent_text'))
          .fontSize(12)
      }
      .margin({ bottom: 87 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
    .padding({ left: 12, right: 12 })
    .margin({ top: 8 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  /**
   * 页面: 功能
   */
  @Builder pageFunction() {
    Column() {
      Scroll(this.scrollerForScroll) {
        Column() {
          // 常用区 Grid
          MostRecentComponent({ gridData: this.copyMostUsedFunc, pageInfo: this.pageInfo, copyMostUsedFunc: this.copyMostUsedFunc })
          // 常用区下面的所有功能区 GridComponent
          this.listBuilder();
          List({ scroller: this.scrollerForList }) {
            ForEach(LINK, (item: LinkSet, index: number) => {
              GridComponent({
                gridData: item,
                gridIndex: index,
                pageInfo: this.pageInfo,
                copyMostUsedFunc: this.copyMostUsedFunc
              })
            })//, (item: GridData,index:number) => index + JSON.stringify(item))

            ListItem().height('100%')
          }
          // .padding({ bottom: '40vp' })
          .borderRadius({ topLeft: 20, topRight: 20 })
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
            if (this.currentListIndex === LINK.length - 1 && offset > 0) {
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
          .height("calc(100% - 59vp)") // this.listBuilder的高度：51 + 8 = 59
        }
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.None)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .onWillScroll((yOffset: number) => {
        if (!((this.scrollPosition === ScrollPosition.start && yOffset < 0) || (this.scrollPosition === ScrollPosition.end && yOffset > 0))) {
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
    .margin({ top: 8 })
    .padding({ left: '12vp', right: '12vp' })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  /**
   * 页面: 设置
   */
  @State avatar: ResourceStr | undefined = undefined;
  @Builder pageSettings() {
    List({ space: 12 }) {
      ListItem() {
        // new ItemData(0, $r('app.string.set_account_info'), $r('app.media.key_horizontal'))
        Row({ space: 6 }) {
          Image(this.avatar)
            .width(60)
            .height(60)
            .borderRadius(30)
            .autoResize(true)
            .onClick(() => BackgroundImage.pickAvatar().then(() => {
              this.avatar = BackgroundImage.avatar;
            }))
          Text(this.displayUsername || $r('app.string.welcome_to_your_ustc'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .wordBreak(WordBreak.BREAK_ALL)
          Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
            Image($r('app.media.key_horizontal'))
              .height(20)
              .width(20)
          }
          .width(36)
          .height(36)
          .onClick(() => this.dialogController.open())

          Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
            Image($r('app.media.person'))
              .height(20)
              .width(20)
          }
          .width(36)
          .height(36)
          .onClick(() => {
            this.pageInfo.clear();
            this.pageInfo.pushPath({ name: "Webview", param: {
              title: $r('app.string.GeRenZhongXin'),
              url: 'https://id.ustc.edu.cn/gate/cas-success/personal-center-home-page' } as SimpleLink });
          })
        }
        .width('100%')
        .padding(12)
      }
      .width('100%')
      .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
      .backgroundBlurStyle(BackgroundImage.blurLevel)
      .borderRadius(20)

      ForEach(SettingsData.getSettingListData(), (item: ItemData[], _index: number) => {
        ListItemGroup() {
          ForEach(item, (cell: ItemData, _cellIndex) => {
            ListItem() {
              this.settingCell(cell)
            }
            .height('48vp')
            .onClick(() => this.settingAction(cell.id))
          })
        }
        .divider({
          strokeWidth: '0.6vp',
          color: $r('sys.color.comp_divider'),
          startMargin: '12vp',
          endMargin: '12vp'
        })
        .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .borderRadius(20)

      }/*, (item: ItemData) => JSON.stringify(item)*/)
    }
    .height('100%')
    .width('100%')
    .padding({ left: 12, right: 12 })
    .margin({ top: 8 })
    .scrollBar(BarState.Auto)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .contentEndOffset(80)
  }

  settingAction(cellID: number) {
    switch (cellID) { // 根据 cell.id 区分设置项
      case 1:
      case 2:
      case 3:
        break;

      case 4:
        if (this.pageInfo.popToName('ThemeSetting') === -1) {
          this.pageInfo.clear();
          this.pageInfo.pushPath({ name: 'ThemeSetting', param: [this.windowRect.width, this.windowRect.height] });
        }
        break;

      case 5:
        if (this.pageInfo.popToName('AddCard') === -1) {
          this.pageInfo.clear();
          this.pageInfo.pushPath({ name: 'AddCard' });
        }
        break;

      case 6:
      case 7:
        break;

      case 8:
        this.getUIContext().showTextPickerDialog({
          range: ['电脑端', '手机端', '平板端'],
          selected: UnifiedPreferences.getNumberSync('UAMode', deviceType === 'phone' ? 1 : (deviceType === 'tablet' ? 2 : 0)),
          canLoop: false,
          onAccept: (value: TextPickerResult) => {
            if (typeof value.index === "number")
              UnifiedPreferences.putSync('UAMode', value.index);
            else
              UnifiedPreferences.putSync('UAMode', value.index[0]);
            this.showMessage(`已更改为 ${value.value}`);
          }
        });
        break;

      case 9:
        if (WriteCalendar.askForCalendar(1)) {
          WriteCalendar.deleteCalendar();
        }
        break;

      case 10:
        if (WriteCalendar.askForCalendar(2)) {
          WriteCalendar.setClassCalendar();
        }
        break;

      case 11:
        if (WriteCalendar.askForCalendar(3)) {
          WriteCalendar.setExamCalendar();
        }
        break;

      case 12:
        if (this.pageInfo.popToName('CleanStorage') === -1) {
          this.pageInfo.clear();
          this.pageInfo.pushPath({ name: 'CleanStorage' });
        }
        break;

      case 13:
        // 帮助
        if (this.pageInfo.popToName('Help') === -1) {
          this.pageInfo.clear();
          this.pageInfo.pushPath({ name: 'Help' });
        }
        break;

      case 14:
        // 关于
        if (this.pageInfo.popToName('About') === -1) {
          this.pageInfo.clear();
          this.pageInfo.pushPath({ name: 'About' });
        }
        break;

      case 15: // 退出
        WantAbility.quit(hostContext());

      default:
        this.showMessage($r('app.string.under_construction'));
        break;
    }
  }

  /**
   * Tabs 主控程序
   */
  // defPlaceholder = new ComponentContent(this.getUIContext(), wrapBuilder(SplitPlaceholder));
  pageInfo: NavPathStack = new NavPathStack();
  // 分栏模式偏好（自适应/强制单栏），.mode()绑定此值才能保持自适应；
  // isSplit存onNavigationModeChange回报的实际模式，供Webview等页面判断
  @StorageLink('adaptSplit') adaptSplit: NavigationMode = NavigationMode.Auto;
  @StorageLink('isSplit') isSplit: NavigationMode = NavigationMode.Auto;

  build() {
    Stack() {
      if (BackgroundImage.showImage)
        Image(BackgroundImage.pic)
          .height('100%')
          .width('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .autoResize(true)
          .opacity(BackgroundImage.effectiveBrightness)

      Navigation(this.pageInfo) {
        HdsTabs({ controller: this.tabsController }) {
          /**
           * Tab: 首页
           */
          TabContent() {
            this.pageStart()
          }
          .padding({ left: 7, right: 7 })
          .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.normal_background'))
          .tabBar(this.tabBuilder($r('app.string.page_start'), 0, $r('app.media.tab0_selected'), $r('app.media.tab0_unselected')))
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

          /**
           * Tab: 功能
           */
          TabContent() {
            this.pageFunction()
          }
          .padding({ left: 7, right: 7 })
          .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.normal_background'))
          .tabBar(this.tabBuilder($r('app.string.page_function'), 1, $r('app.media.tab1_selected'), $r('app.media.tab1_unselected')))
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

          /**
           * Tab: 设置
           */
          TabContent() {
            this.pageSettings()
          }
          .padding({ left: 7, right: 7 })
          .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.normal_background'))
          .tabBar(this.tabBuilder($r('app.string.page_settings'), 2, $r('app.media.tab2_selected'),
            $r('app.media.tab2_unselected')))
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

        }
        .vertical(false)
        .barPosition(BarPosition.End)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .onAnimationStart((_index: number, targetIndex: number) => {
          this.currentIndex = targetIndex;
        })
        .barOverlap(true)
        .barFloatingStyle({
          barBottomMargin: 5,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
      }
      .enableDragBar(true)
      .navBarWidth('360vp')
      .navBarWidthRange(['336vp', '50%'])
      .hideTitleBar(true)
      .hideToolBar(true)
      .mode(this.adaptSplit)
      .onNavigationModeChange((mode: NavigationMode) => {
        this.isSplit = mode;
      })
      // .splitPlaceholder(this.defPlaceholder)

      if (BackgroundImage.opacityLevel !== 1)
        Image(BackgroundImage.pic)
          .height('100%')
          .width('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .autoResize(true)
          .opacity((1 - BackgroundImage.opacityLevel) * BackgroundImage.effectiveBrightness)
          .hitTestBehavior(HitTestMode.None)
    }
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor(BackgroundImage.showImage ? $r('app.color.pure_white_or_black') : $r('app.color.normal_background'))
  }
}
