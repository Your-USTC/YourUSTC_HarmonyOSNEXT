
import * as Links from '../constants/Links';
import { CheckInTools } from '../utils/CheckIn';
import { preferences } from '@kit.ArkData';
import { ScrollPosition } from '../constants/CommonConstants';
import { ListDataConstants } from '../constants/ListDataConstants';
import GridComponent from '../view/GridComponent';
import { emptyGridData, GridData, otherGridDataList } from '../constants/GridListDataSources';
import * as FunctionOrder from '../utils/FunctionOrder'

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
    this.pref = preferences.getPreferencesSync(
      this.getUIContext().getHostContext(),
      {name: CheckInTools.PREF_NAME}
    ); // 载入包含签到信息的首选项
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

  /**
   * 全局资源: 你的
   */


  /**
   * 页面: 首页
   */
  @Builder
  pageStart() {
    List({ space: 10 }) {
      ListItem() {
        Column() {
          Row() {
            Text($r('app.string.daily_checkin'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 15, bottom: 10 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Row() {
            Text(this.checkInContent)
              .fontColor($r('app.color.active_text'))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .textShadow({ radius: 1 })
              .margin({ bottom: 10 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Row() {
            Text($r('app.string.checkin_count', this.checkInTotal))
              .fontSize(12)
              .align(Alignment.Start)
              .margin({ right: 30 })

            Text($r('app.string.checkin_consecutive', this.checkInConsecutive))
              .fontSize(12)
              .align(Alignment.End)
              .margin({ left: 30 })
          }
          .width('90%')
          .margin({ bottom: 10 })
          .justifyContent(FlexAlign.Center)
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .borderRadius(20)
      .backgroundColor($r('app.color.grid_background'))
    }
    .width('100%')
    .height('100%')
    .padding({ top: 20, left: 20, right: 20 })

    Column() {
      Button(this.checkedInToday ? 'checked in' : 'check in')
        .enabled(!this.checkedInToday)
        .onClick(() => {
          const GeneratedDestructArray_1 = CheckInTools.doCheckIn(this.pref);
          this.checkInTotal = GeneratedDestructArray_1[0];
          this.checkedInToday = true;
          this.checkInConsecutive = GeneratedDestructArray_1[1];
          this.checkInContent = GeneratedDestructArray_1[2];
        })
    }
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 页面: 功能
   */
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
   * 页面: 你的
   */
  @Builder
  pageYours() {
    Column() {
      Button($r("app.string.KeChengBiao"), { type: ButtonType.Capsule })
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .controlSize(ControlSize.NORMAL)
        .fontColor($r('app.color.normal_background'))
        .backgroundColor($r('app.color.active_text'))
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/Webview',
            params: Links.LINK.get("0.1")
          }).catch((err: Error) => {
            console.error(`Router ERROR: [${err.name}] ${err.message}`)
          })
        })
      Button($r("app.string.ClearFunctionHistory"), { type: ButtonType.Normal })
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .controlSize(ControlSize.NORMAL)
        .fontColor($r('app.color.normal_background'))
        .backgroundColor($r('app.color.active_text'))
        .onClick(() => {
          FunctionOrder.resetFunc(this.getUIContext().getHostContext());
          this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
          this.getUIContext().getPromptAction().showToast({
            message: $r('app.string.apply_on_restart'),
            duration: 500
          })
        })
    }
    .height('100%')
    .width('100%')
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
       * Tab: 你的
       */
      TabContent() { this.pageYours() }
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_yours'), 2, $r('app.media.tab2_selected'), $r('app.media.tab2_unselected')))

    }
    .width('100%')
    .backgroundColor($r('app.color.shaded_background'))
    .barHeight(52)
    .barMode(BarMode.Fixed)
    .onAnimationStart((index: number, targetIndex: number) => {
      this.currentIndex = targetIndex
    })
  }
}
