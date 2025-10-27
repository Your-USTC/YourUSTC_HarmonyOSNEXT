
import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { calendarManager } from '@kit.CalendarKit'
import { BusinessError } from '@kit.BasicServicesKit';
import { classAttribute } from './Schedule'
import * as Links from '../constants/Links'
import { CheckInTools } from '../utils/CheckIn'
import ItemData from '../view/SettingsComponent'
import GridComponent from '../view/GridComponent'
import * as FunctionOrder from '../utils/FunctionOrder'
import SettingsData from '../constants/SettingsSources'
import { calendarMgr } from '../entryability/EntryAbility'
import { ScrollPosition } from '../constants/CommonConstants'
import { ListDataConstants } from '../constants/ListDataConstants'
import { GridData, otherGridDataList } from '../constants/GridListDataSources'

// 日历初始化
let calendar: calendarManager.Calendar | undefined = undefined;
// 指定日历账户信息
const calendarAccount: calendarManager.CalendarAccount = {
  name: 'YourUSTC.class_notification',
  type: calendarManager.CalendarType.LOCAL,
  // 日历账户显示名称，该字段如果不填，创建的日历账户在界面显示为空字符串。
  displayName: "你的科大上课提醒"
};
// 日历配置信息：是否提醒及颜色
const calendarConfig: calendarManager.CalendarConfig = { enableReminder: true, color: '#bcc7df' };
export let calendarAccess: boolean = false;
// 创建日历账户
calendarMgr?.createCalendar(calendarAccount).then((data: calendarManager.Calendar) => {
  console.info(`创建日历数据成功->${JSON.stringify(data)}`);
  calendar = data;
  calendarAccess = true; // 确保日历账户创建成功后，再进行相关日程的管理
  // 设置日历配置信息，打开日程提醒、设置日历账户颜色
  calendar.setConfig(calendarConfig).then(() => {
    console.info(`设置config成功->${JSON.stringify(calendarConfig)}`);
  }).catch((err: BusinessError) => {
    console.error(`设置config失败。Code: ${err.code}, message: ${err.message}`);
  });
  // ...
}).catch((error: BusinessError) => {
  console.error(`创建日历对象失败。Code: ${error.code}, message: ${error.message}`);
});


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
  private pref: preferences.Preferences | null = null;

  aboutToAppear(): void {
    try {
      this.pref = preferences.getPreferencesSync(
        this.getUIContext().getHostContext(),
        { name: CheckInTools.PREF_NAME }
      ); // 载入包含签到信息的首选项
    } catch (error) {
      console.error(`CheckIn load ERROR: [${error.name}] ${error.message}`);
    }
    const GeneratedDestructArray_1 = CheckInTools.loadCheckInOnStartup(this.pref);
    this.checkInTotal = GeneratedDestructArray_1[0];
    this.checkInConsecutive = GeneratedDestructArray_1[1];
    this.checkedInToday = GeneratedDestructArray_1[2];
    this.checkInContent = this.checkedInToday ? GeneratedDestructArray_1[3] : '';
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
                  .width('65vp')
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
        FunctionOrder.refreshFunc(this.getUIContext().getHostContext()); // 刷新点击次数显示
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
      }

      if (item.others === undefined) {
        Image($r('app.media.right_arrow'))
          .width('12vp')
          .height('24vp')
      } else {
        Toggle({ type: ToggleType.Switch, isOn: false })
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding({
      left: '8vp',
      right: '22vp'
    })
  }

  /**
   * 页面: 首页
   */
  @Builder
  pageStart() {
    List({ space: 10 }) {
      // 每日签到
      ListItem() {
        Column() {
          Row() {
            Text($r('app.string.daily_checkin'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
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
                const GeneratedDestructArray_1 = CheckInTools.doCheckIn(this.pref)
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

      // 你的课表
      ListItem() {
        Column() {
          Row() {
            Blank()

            Text($r('app.string.your_schedule'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Blank()

            Image($r('app.media.right_arrow'))
              .width('12vp')
              .height('24vp')
          }
          .width('100%')
          .margin({ top: 15, bottom: 10 })
          .padding({ left: 27, right: 15 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Schedule' })
              .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) })
          })

          // TODO: 今日课程 或 当前课程
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .borderRadius(20)
      .margin({ top: 5 })
      .backgroundColor($r('app.color.grid_background'))
    }
    .width('100%')
    .height('100%')
    .margin({ top: 20 })
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
        .edgeEffect(EdgeEffect.Spring)
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
  pageYours() {
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
                  case 1:
                    // 选择最近使用
                    let maxRecordList: string[] = [];
                    for (let i = 1; i <= 20; i++) // 在此处修改允许用户选择的最大显示数量上限！！（现在是20）
                      maxRecordList.push(i.toString());
                    this.getUIContext().showTextPickerDialog({
                      range: maxRecordList,
                      defaultPickerItemHeight: 36,
                      canLoop: false,
                      onAccept: (value: TextPickerResult) => {
                        try {
                          this.getUIContext().getPromptAction().showToast({
                            message: `已更改为 ${value.value}`,
                            duration: 200
                          });
                        } catch (error) {
                          console.error(`CheckIn load ERROR: [${error.name}] ${error.message}`);
                        }
                        let options: preferences.Options = { name: 'FunctionOrderNum' };
                        try {
                          let maxRecordPre: preferences.Preferences | null = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);
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
                  case 2:
                    // 重置最近使用
                    FunctionOrder.resetFunc(this.getUIContext().getHostContext());
                    this.refreshTabGrid(1);
                    try {
                      this.getUIContext()
                        .getPromptAction()
                        .showToast({ message: $r('app.string.have_cleared'), duration: 500 })
                    } catch (error) {
                      console.error(`ShowToast ERROR: [${error.name}] ${error.message}`);
                    }
                    break;
                  case 3:
                    // （调试）课程表
                    this.getUIContext().getRouter().pushUrl({
                      url: 'pages/Webview',
                      params: Links.LINK.get("0.1")
                    }).catch((err: Error) => {
                      console.error(`Router ERROR: [${err.name}] ${err.message}`)
                    })
                    break;
                  case 4:
                    let eventId : number | undefined = undefined;
                    let classInfo: classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2'};
                    // 获取课程详情
                    // .....待更新
                    // 获取课程详情
                    const date = new Date();
                    const event: calendarManager.Event = {
                      title: `${classInfo.name} ${classInfo.location}`, // 日程标题
                      type: calendarManager.EventType.NORMAL, // 日程类型
                      startTime: date.getTime(), // 日程开始时间
                      endTime: date.getTime() + 60 * 60 * 1000, // 日程结束时间
                      reminderTime: [10], // 距开始时间提前10分钟提醒
                      recurrenceRule: { // 日程重复规则
                        recurrenceFrequency: calendarManager.RecurrenceFrequency.WEEKLY, // 日程重复规则类型
                        count: 100, // 日程重复次数，该字段和expire属性只需要填写一个，如果两个都填写按照count属性计算。
                        interval: 1, // 重复日程间隔时间，以recurrenceFrequency为单位
                        expire: date.getTime() + 60 * 60 * 1000 * 3, // 日程过期时间，该字段和count属性只需要填写一个，如果两个都填写按照count属性计算。
                        excludedDates: [date.getTime() + 60 * 60 * 1000 * 2] // 日程排除日期，将该日期从重复日程中排除掉
                      }
                    };
                    if (calendar != undefined) {
                      calendar.addEvent(event).then((data: number) => {
                        console.info(`Succeeded in adding event, id -> ${data}`);
                        eventId = data;
                      });
                    }
                    break;
                }
              })
            })
          }
          .backgroundColor($r('app.color.grid_background'))
          .divider({
            strokeWidth: '1vp',
            color: '#0d000000',
            startMargin: '42vp',
            endMargin: '24vp'
          })
          .backgroundColor($r('app.color.normal_background'))
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
      TabContent() { this.pageYours() }
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
