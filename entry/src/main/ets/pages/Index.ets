
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  @Builder
  tabBuilder(title: string | Resource, index: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === index ? selectedImg : normalImg)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)

      Text(title)
        .margin({ top: 4 })
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#3388ff' : $r('app.color.normal_text'))
    }
    .justifyContent(FlexAlign.Center)
    .height(52)
    .width('100%')
    .onClick(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(this.currentIndex);
    })
  }

  @Builder
  tabContentBuilder(text: string | Resource, index: number, selectedImg: Resource, normalImg: Resource) {
    TabContent() {
      Row() {
        Text(text)
          .height(300)
          .fontSize(30)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.normal_background'))
    .tabBar(this.tabBuilder(text, index, selectedImg, normalImg))
  }

  build() {
    Tabs({
      barPosition: BarPosition.End,
      controller: this.tabsController
    }) {
      this.tabContentBuilder('1',
        0, $r('app.media.startIcon'), $r('app.media.foreground'))
      this.tabContentBuilder('2',
        1, $r('app.media.startIcon'), $r('app.media.foreground'))
      this.tabContentBuilder('3',
        2, $r('app.media.startIcon'), $r('app.media.foreground'))
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