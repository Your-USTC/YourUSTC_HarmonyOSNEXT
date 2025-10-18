
import { hilog } from '@kit.PerformanceAnalysisKit';
import * as Links from '../constants/Links';
import { CheckInTools } from '../utils/CheckIn';
import { preferences } from '@kit.ArkData';

@Entry
@Component
struct Index {

  @State currentIndex: number = 0; // 当前标签索引 (从0开始), 初始值即为默认标签索引
  private tabsController: TabsController = new TabsController();

  @State checkInTotal: number = 0;
  @State checkedInToday: boolean = false;
  @State checkInContent: string = ''; // 签到后展示的随机内容
  private pref: preferences.Preferences | null = null;

  aboutToAppear(): void {
    this.pref = preferences.getPreferencesSync(
      this.getUIContext().getHostContext(),
      {name: CheckInTools.PREF_NAME}
    );
    this.checkInTotal = this.pref.getSync(CheckInTools.TOTAL_DAYS_KEY, 0) as number;
    this.checkedInToday = this.pref.getSync(CheckInTools.LAST_DAY_KEY, '') as string === CheckInTools.getTodayDate();
  }

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
    })
  }

  /**
   * 页面: 首页
   */
  @Builder
  pageStart() {
    Column() {
      Text('Start')
        .height(300)
        .fontSize(30)

      // TODO: Design check in UI

      Text(`check in count：${this.checkInTotal}`)
      Button(this.checkedInToday ? 'checked in' : 'check in')
        .enabled(!this.checkedInToday)
        .onClick(() => {
          const GeneratedDestructArray_1 = CheckInTools.doCheckIn(this.pref);
          this.checkInTotal = GeneratedDestructArray_1[0];
          this.checkedInToday = true;
          this.checkInContent = GeneratedDestructArray_1[1];
        })
      Text(this.checkInContent)
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 页面: 功能
   */
  @Builder
  pageFunction() {
    Column() {
      Text('Function')
        .height(300)
        .fontSize(30)
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 页面: 你的
   */
  @Builder
  pageYours() {
    Column() {
      Button(Links.STUDY_LINK[1].title, { type: ButtonType.Capsule })
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .controlSize(ControlSize.NORMAL)
        .fontColor($r('app.color.normal_background'))
        .backgroundColor($r('app.color.active_text'))
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/Webview',
            params: Links.STUDY_LINK[1]
          }).catch((err: Error) => {
            console.error(`Router ERROR: [${err.name}] ${err.message}`)
          })
        })
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 主程序
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
      .tabBar(this.tabBuilder($r('app.string.page_start'), 0, $r('app.media.tab_function_selected'), $r('app.media.tab_function_unselected')))

      /**
       * Tab: 功能
       */
      TabContent() { this.pageFunction() }
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_function'), 1, $r('app.media.tab_function_selected'), $r('app.media.tab_function_unselected')))

      /**
       * Tab: 你的
       */
      TabContent() { this.pageYours() }
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_yours'), 2, $r('app.media.tab_function_selected'), $r('app.media.tab_function_unselected')))

    }
    .width('100%')
    .backgroundColor($r('app.color.shaded_background'))
    .barHeight(52)
    .barMode(BarMode.Fixed)
    .onAnimationStart((index: number, targetIndex: number) => {
      hilog.info(0x0000, 'index', index.toString())
      this.currentIndex = targetIndex
    })
  }
}
