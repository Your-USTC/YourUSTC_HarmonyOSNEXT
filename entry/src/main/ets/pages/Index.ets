
import { fileIo } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { LengthUnit, mediaquery, window } from '@kit.ArkUI'
import { application, common, contextConstant } from '@kit.AbilityKit'

import * as tools from '../utils/tools'
import { CheckInTools } from '../utils/CheckIn'
import scheduleManager from '../utils/TimeTable'
import ItemData from '../view/SettingsComponent'
import GridComponent from '../view/GridComponent'
import BgImageDialog from '../view/BgImageDialog'
import WriteCalendar from '../utils/WriteCalendar'
import PasswordDialog from '../view/PasswordDialog'
import BackgroundImage from '../view/BgImageManager'
import * as FunctionOrder from '../utils/FunctionOrder'
import SettingsData from '../constants/SettingsSources'
import UnifiedPreferences from '../utils/UnifyPreference'
import * as ScheduleSources from '../constants/ScheduleSources'
import examManager, { examAttribute } from '../utils/ExamManager'
import { ListDataConstants } from '../constants/ListDataConstants'
import { GridData, otherGridDataList } from '../constants/GridListDataSources'


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
  /*
   * 以下是监听屏幕旋转
   */
  @State tabWidth: string = '100%';
  @State tabHeight: string = 'auto';
  @State tabHorizontal: boolean = false;
  portraitListener: mediaquery.MediaQueryListener = this.getUIContext().getMediaQuery().matchMediaSync('(orientation: landscape)');
  onPortrait(mediaQueryResult: mediaquery.MediaQueryResult) {
    let windowClass: window.Window | undefined = undefined;
    try {
      let promise = window.getLastWindow(this.context);
      promise.then((data)=> {
        //Get window object
        windowClass = data;
        try {
          //Get window properties
          let properties = windowClass.getWindowProperties();
          let rect = properties.windowRect;
          if (rect.width > rect.height) { // 横屏
            this.tabWidth = '52vp';
            this.tabHeight = '100%';
            this.tabHorizontal = true;
          } else { // 竖屏
            this.tabWidth = '100%';
            this.tabHeight = 'auto';
            this.tabHorizontal = false;
          }
        } catch (exception) {
          console.error('Failed to obtain the window properties. Cause: ' + JSON.stringify(exception));
        }
        console.info('Succeeded in obtaining the top window. Data: ' + JSON.stringify(data));
      }).catch((err: BusinessError)=>{
        console.error('Failed to obtain the top window. Cause: ' + JSON.stringify(err));
      });} catch (exception) {
      console.error('Failed to obtain the top window. Cause: ' + JSON.stringify(exception));
    }
  }
  /*
   * 以上是监听屏幕旋转
   */

  @State currentIndex: number = 0; // 当前标签索引 (从0开始), 初始值即为默认标签索引
  private tabsController: TabsController = new TabsController();

  dialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      isFromSetting: true
    }),
    autoCancel: true,
    gridCount: 4
  })

  dialogController2: CustomDialogController = new CustomDialogController({
    builder: BgImageDialog(),
    autoCancel: true,
    gridCount: 4
  })

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
    .height('52vp')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .onClick(() => {
      this.currentIndex = index
      this.tabsController.changeIndex(this.currentIndex);
      if (this.currentIndex === 1) {
        FunctionOrder.refreshFunc(); // 刷新点击次数显示
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

  @State todayCourse: ScheduleSources.classAttribute[] = [];
  @State tomorrowCourse: ScheduleSources.classAttribute[] = [];
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
    // 获取课表
    ScheduleSources.initSchedulePre();
    const GeneratedDestructArray_1 = CheckInTools.loadCheckInOnStartup();
    this.checkInTotal = GeneratedDestructArray_1[0];
    this.checkInConsecutive = GeneratedDestructArray_1[1];
    this.checkedInToday = GeneratedDestructArray_1[2];
    this.checkInContent = this.checkedInToday ? GeneratedDestructArray_1[3] : '';
    this.refreshInfo();
    // 初始化日历
    WriteCalendar.initializeCalendar(this.getUIContext());
    //初始化背景
    BackgroundImage.init(this.context);
    // 开启监听屏幕旋转
    this.portraitListener.on('change', (mediaQueryResult: mediaquery.MediaQueryResult) => {
      this.onPortrait(mediaQueryResult)
    });
    // 首次使用声明
    if (UnifiedPreferences.getBoolSync('FirstlyHint', true)) {
      UnifiedPreferences.putSync('FirstlyHint', false);
      this.getUIContext().getRouter().pushUrl({ url: 'pages/About' })
        .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) })
    }
  }

  aboutToDisappear(): void {
    this.portraitListener.off('change'); // 关闭监听屏幕旋转，防止内存泄露
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
    FunctionOrder.refreshFunc(); // 刷新点击次数显示
    this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
  }

  /**
   * 全局资源: 设置
   */
  clearCache = async () => {
    let paths: Array<string> = [];
    let moduleContext: common.Context;
    moduleContext = await application.createModuleContext(this.context, 'entry');
    // 缓存路径/data/storage/el2/base/cache
    paths.push(moduleContext.cacheDir);
    // 缓存路径/data/storage/el2/base/cache/web
    paths.push(moduleContext.cacheDir + '/web');
    // 缓存路径/data/storage/el2/base/haps/entry/cache
    paths.push(this.context.cacheDir);
    // 缓存路径/data/storage/el1/base/cache
    moduleContext.area = contextConstant.AreaMode.EL1;
    paths.push(moduleContext.cacheDir);
    // 缓存路径/data/storage/el1/base/haps/entry/cache
    this.context.area = contextConstant.AreaMode.EL1;
    paths.push(this.context.cacheDir);

    // 遍历paths数组，彻底删除每个文件夹下的缓存数据
    for (let i = 0; i < paths.length; i++) {
      let path = paths[i];
      fileIo.listFile(path).then((filenames) => {
        for (let i = 0; i < filenames.length; i++) {
          let dirPath = path + '/' + filenames[i];
          if (dirPath === '/data/storage/el2/base/cache/web' || dirPath === '/data/storage/el2/base/cache/web/Cookies')
            continue;
          // 判断是否为文件夹
          let isDirectory: boolean = false;
          try {
            isDirectory = fileIo.statSync(dirPath).isDirectory();
          } catch (err) {
            console.error(`remove file failed with error message: ${err.message}`);
          }
          if (isDirectory) {
            fileIo.rmdirSync(dirPath);
          } else {
            fileIo.unlink(dirPath).catch((err: Error) => {
              console.error(`remove file failed with error message: ${err.message}`);
            });
          }
        }
      });
    }
  }

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
      } else if (item.id == 1) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showCheckIn })
          .onClick(() => {
            this.showCheckIn = !this.showCheckIn;
            UnifiedPreferences.putSync('showCheckIn', this.showCheckIn);
          });
      } else if (item.id == 2) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.showRecentCourse })
          .onClick(() => {
            this.showRecentCourse = !this.showRecentCourse;
            UnifiedPreferences.putSync('showRecentCourse', this.showRecentCourse);
          });
      } else if (item.id == 3){
        Toggle({ type: ToggleType.Switch, isOn: $$this.showExamDetail })
          .onClick(() => {
            this.showExamDetail = !this.showExamDetail;
            UnifiedPreferences.putSync('showExamDetail', this.showExamDetail);
          });
      } else if (item.id == 7) {
        Toggle({ type: ToggleType.Switch, isOn: $$this.webAutoDarkMode })
          .onClick(() => {
            this.webAutoDarkMode = !this.webAutoDarkMode;
            UnifiedPreferences.putSync('webAutoDarkMode', this.webAutoDarkMode);
          });
      } else { // item.id == 8
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

  /*
   * 常用功能
   */
  refreshInfo() {
    this.currentTime = new Date();
    scheduleManager.getFormattedSchedule(); // 初始化首页课表
    if (scheduleManager.isTermEnd) {
      this.todayCourse = [];
      this.tomorrowCourse = [];
    } else {
      this.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
      this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed + (scheduleManager.today == 5 ? 1 : 0)][(scheduleManager.today + 1) % 7];
    }
    this.isTodayCourseEnd = true;
    for (let todaySingleCourse of this.todayCourse)
      if (this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
        + ScheduleSources.commonClassStamp[todaySingleCourse.timeSpan[todaySingleCourse.timeSpan.length - 1]][1]) {
        this.isTodayCourseEnd = false;
        break;
      }
    examManager.readStoredExam();
    this.exams = examManager.allExamInfo;
    for (let i = this.exams.length - 1; i >= 0; i--)
      if (this.currentTime.getTime() > this.exams[i].endTimeStamp)
        this.exams.splice(i, 1);
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
  @Builder
  pageStart() {
    List({ space: 10 }) {

      ListItem()
        .visibility(Visibility.Hidden)
        .height(15)

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
        .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.grid_background'))
        .backgroundBlurStyle(BackgroundImage.showImage ? BlurStyle.Regular : undefined);
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
                this.refreshInfo();
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
                  .interpolation(ImageInterpolation.Medium)
                  .draggable(false)
                Text(scheduleManager.isTermEnd ? $r('app.string.no_class_term_end') : $r('app.string.no_class_today'));
              }
              .margin({ top: 12, bottom: 12 });
            } else {
              ForEach(this.todayCourse, (course: ScheduleSources.classAttribute, index: number) => {
                if (this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                  + ScheduleSources.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1] + 1800000) {
                  Row() {
                    Column() {
                      Text(course.name)
                        .textAlign(TextAlign.Start)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis });

                      if (this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + ScheduleSources.commonClassStamp[course.timeSpan[0]][0] &&
                        this.currentTime.getTime() > scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + ScheduleSources.commonClassStamp[course.timeSpan[0]][0] - 1800000) {
                        Text($r('app.string.class_soon'))
                          .fontColor($r('app.color.green'));
                      } else if (this.currentTime.getTime() >
                        scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + ScheduleSources.commonClassStamp[course.timeSpan[0]][0] &&
                        this.currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + ScheduleSources.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]) {
                        Text($r('app.string.class_in_session'))
                          .fontColor($r('app.color.bright_blue'));
                      } else if (this.currentTime.getTime() >
                        scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
                          + ScheduleSources.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]) {
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

                      Text(`\udb80\udfdc ${ScheduleSources.commonClassTime[course.timeSpan[0]][0]}~${ScheduleSources.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
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
                    .height(75)
                    .interpolation(ImageInterpolation.Medium)
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
                      .visibility(course.teacher == '' ? Visibility.None : Visibility.Visible);

                    Text(`\udb80\uddb8 ${course.location}`)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .visibility(course.location == '' ? Visibility.None : Visibility.Visible);

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
      .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.grid_background'))
      .backgroundBlurStyle(BackgroundImage.showImage ? BlurStyle.Regular : undefined);

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
                this.refreshInfo();
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
                  .interpolation(ImageInterpolation.Medium)
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
      .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.grid_background'))
      .backgroundBlurStyle(BackgroundImage.showImage ? BlurStyle.Regular : undefined);
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
    .padding({ left: 12, right: 12 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  /**
   * 页面: 功能
   */
  @Builder
  pageFunction() {
    Column() {
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  /**
   * 页面: 设置
   */
  @Builder
  pageSettings() {
    List({ space: 12 }) {

      ListItem()
        .visibility(Visibility.Hidden)
        .height(5)

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
                  this.dialogController.open();
                  break;
                case 1:
                  // 显示签到
                  this.showCheckIn = !this.showCheckIn;
                  UnifiedPreferences.putSync('showCheckIn', this.showCheckIn);
                  break;

                case 2:
                  // 显示课表
                  this.showRecentCourse = !this.showRecentCourse;
                  UnifiedPreferences.putSync('showRecentCourse', this.showRecentCourse);
                  break;

                case 3:
                  // 显示考试
                  this.showExamDetail = !this.showExamDetail;
                  UnifiedPreferences.putSync('showExamDetail', this.showExamDetail);
                  break;

                case 4:
                  // 自定义背景!
                  this.dialogController2.open();
                  break;

                case 5:
                  // 选择最近使用
                  this.getUIContext().showTextPickerDialog({
                    selected: FunctionOrder.maxRecord - 1,
                    range: tools.getContArray([[1, 20]], true) as string[], // 在此处修改允许用户选择的最大显示数量上限！！（现在是20）
                    defaultPickerItemHeight: 36,
                    canLoop: false,
                    onAccept: (value: TextPickerResult) => {
                      FunctionOrder.setMaxRecord(Number(value.value));
                      this.showMessage(`已更改为 ${value.value}`);
                      FunctionOrder.refreshFunc(); // 刷新点击次数显示
                      this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
                    }
                  })
                  break;

                case 6:
                  // 重置最近使用
                  FunctionOrder.resetFunc();
                  FunctionOrder.refreshFunc(); // 刷新点击次数显示
                  this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
                  this.showMessage($r('app.string.have_cleared'));
                  break;

                case 7:
                  this.webAutoDarkMode = !this.webAutoDarkMode;
                  UnifiedPreferences.putSync('webAutoDarkMode', this.webAutoDarkMode);
                  break;

                case 8:
                  this.webBackPress = !this.webBackPress;
                  UnifiedPreferences.putSync('webBackPress', this.webBackPress);
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
                  this.clearCache();
                  this.showMessage($r('app.string.wipe_cache_success'));
                  break;

                case 13:
                  // 帮助
                  this.getUIContext().getRouter().pushUrl({ url: 'pages/Help' })
                    .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
                  break;
                case 14:
                  // 关于
                  this.getUIContext().getRouter().pushUrl({ url: 'pages/About' })
                    .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
                  break;
                case 15:
                  // 退出到恢复模式
                  UnifiedPreferences.putSync('RecoveryMode', true);
                  (this.context as common.UIAbilityContext).terminateSelf((err) => {
                    if (!err) {
                      this.context.getApplicationContext().killAllProcesses().catch((error: Error) => {
                        console.error(`Quitting ERROR: [${error.name}] ${error.message}`);
                      })
                    }
                  })
                  break;
                default:
                 this.showMessage($r('app.string.under_construction'));
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
        .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.grid_background'))
        .backgroundBlurStyle(BackgroundImage.showImage ? BlurStyle.Regular : undefined)
        .borderRadius(20)

      }, (item: ItemData) => JSON.stringify(item))

      ListItem()
        .visibility(Visibility.Hidden)
        .height(this.tabHorizontal ? 60 : 80)
    }
    .height('100%')
    .width('100%')
    .padding({ left: 12, right: 12 })
    .scrollBar(BarState.Auto)
    .overlay(this.settingExitButton(), {
      align: Alignment.Bottom,
      offset: { x: 0, y: (this.tabHorizontal ? 20 : 40) }
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
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
    .hitTestBehavior(HitTestMode.Transparent);
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
      .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_start'), 0, $r('app.media.tab0_selected'), $r('app.media.tab0_unselected')))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      /**
       * Tab: 功能
       */
      TabContent() { this.pageFunction() }
      .padding({ left: 7, right: 7 })
      .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_function'), 1, $r('app.media.tab1_selected'), $r('app.media.tab1_unselected')))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      /**
       * Tab: 设置
       */
      TabContent() { this.pageSettings() }
      .padding({ left: 7, right: 7 })
      .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_settings'), 2, $r('app.media.tab2_selected'), $r('app.media.tab2_unselected')))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

    }
    .backgroundColor($r('app.color.shaded_background'))
    .barBackgroundColor(BackgroundImage.showImage ? '#00d00721' : $r('app.color.shaded_background'))
    .barBackgroundBlurStyle(BackgroundImage.showImage ? BlurStyle.Regular : undefined)
    .backgroundImage(BackgroundImage.pic)
    .backgroundImageSize(ImageSize.Cover)
    .backgroundImagePosition(Alignment.Center)
    .barHeight(this.tabHeight)
    .barWidth(this.tabWidth)
    .vertical(this.tabHorizontal)
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onAnimationStart((index: number, targetIndex: number) => {
      this.currentIndex = targetIndex;
      if (this.currentIndex === 1) {
        FunctionOrder.refreshFunc(); // 刷新点击次数显示
        this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
      }
    })
  }
}
