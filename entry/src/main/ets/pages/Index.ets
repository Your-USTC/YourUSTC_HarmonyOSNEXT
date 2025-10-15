
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {

  @State currentIndex: number = 0;    // 当前标签索引 (从0开始), 初始值即为默认标签索引
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
      this.currentIndex = index;
      this.tabsController.changeIndex(this.currentIndex);
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
      Button('测试', { type: ButtonType.Capsule })
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .controlSize(ControlSize.NORMAL)
        .fontColor($r('app.color.normal_background'))
        .backgroundColor($r('app.color.active_text'))
        .onClick((event: ClickEvent) => {
          // 按钮被点击后

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
      .tabBar(this.tabBuilder($r('app.string.page_start'), 0, $r('app.media.startIcon'), $r('app.media.foreground')))

      /**
       * Tab: 功能
       */
      TabContent() { this.pageFunction() }
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_function'), 1, $r('app.media.startIcon'), $r('app.media.foreground')))

      /**
       * Tab: 你的
       */
      TabContent() { this.pageYours() }
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.normal_background'))
      .tabBar(this.tabBuilder($r('app.string.page_yours'), 2, $r('app.media.startIcon'), $r('app.media.foreground')))

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
