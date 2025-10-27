
import { webview } from '@kit.ArkWeb'
import { DESKTOP_UA, MOBILE_UA } from '../constants/UserAgent'
import { startTimeQueryJS, timeTableQueryJS, timeTableQueryJSShort } from '../utils/TimeTable'
import { obtainedData } from '../pages/Schedule'

const desktopUrl: string[] = [] // 需要默认访问桌面版站点时使用

@Entry
@Component
struct Webview {
  webviewController: webview.WebviewController = new webview.WebviewController()
  @State isDesktop: boolean = false;
  title: string = '';
  url: string = '';
  @State isTimeTablePage: boolean = false;
  @State gotTimeTable: boolean = false;
  obtainedData: obtainedData = {timeTable: '', startTime: 0};

  aboutToAppear() { // Receive parameters before loading the page
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    if (params) {
      this.title = params.title ?? '';
      this.url = params.url ?? '';
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({left: 12})
          .height(20)
          .onClick(() => {
            console.info(`课表页面路由path：${this.getUIContext().getRouter().getLength()}`);
            this.getUIContext().getRouter().back({
              params: this.obtainedData,
              url: this.getUIContext().getRouter().getLength() === '3' ? 'pages/Schedule' : 'pages/Index'
            })
          })
        Image($r('app.media.back'))
          .padding(({left: 12}))
          .height(16)
          .parallelGesture(
            GestureGroup(
              GestureMode.Exclusive,
              TapGesture({ count: 1 })
                .onAction(() => {
                  if (this.webviewController.accessBackward()) {
                    this.webviewController.backward();
                  } else {
                    this.getUIContext().getRouter().back({
                      params: this.obtainedData,
                      url: this.getUIContext().getRouter().getLength() === '3' ? 'pages/Schedule' : 'pages/Index'
                    });
                  }
                }),
              LongPressGesture()
                .onAction(() => {
                  this.webviewController.loadUrl(this.url)
                })
            )
          )
          .draggable(false)
        Blank()
        Text(this.title)
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Image($r('app.media.get'))
          .padding({right: 12})
          .height(this.isTimeTablePage && !this.gotTimeTable ? 20 : 0)
          .enabled(this.isTimeTablePage && !this.gotTimeTable)
          .onClick(() => {
            const uiContext: UIContext = this.getUIContext();
            this.webviewController.runJavaScript(timeTableQueryJSShort, (error, result) => {
              if (error) {
                uiContext.getPromptAction().showToast({ message: $r('app.string.get_timetable_err_msg'), duration: 2000 });
                return;
              }
              if (result === 'null') {
                uiContext.getPromptAction().showToast({ message: $r('app.string.auto_get_timetable_fail_msg'), duration: 3500 });
                return;
              }
              this.gotTimeTable = true;
              console.info(`课表是：${result}`); /* TODO: 保存课程表到本地（需JSON.parse） */
              this.obtainedData.timeTable = result;
            });
            this.webviewController.runJavaScript(startTimeQueryJS, (error, result) => {
              if (error) {/* 理论上这里不会出什么错误（doge） */ return;}
              console.info(`学期开始的UNIX时间戳是${result}mm`); /* TODO: 保存开学时间到本地（需JSON.parse） */
              this.obtainedData.startTime = Number(result);
            });
          })
        Image(this.isDesktop ? $r('app.media.mobile') : $r('app.media.desktop'))
          .padding({right: 12})
          .height(20)
          .onClick(() => {
            this.webviewController.setCustomUserAgent(this.isDesktop ? MOBILE_UA : DESKTOP_UA);
            this.webviewController.refresh();
            this.isDesktop = !this.isDesktop;
          })
        Image($r('app.media.refresh'))
          .padding({right: 12})
          .height(20)
          .onClick(() => this.webviewController.refresh())
      }
      .id('header')
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.shaded_background'))
      Web({ src: this.url, controller: this.webviewController })
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .width('100%')
        .height('100%')
        .onControllerAttached(() => {
          if (desktopUrl.includes(this.url))
            this.webviewController.setCustomUserAgent(DESKTOP_UA);
          else
            this.webviewController.setCustomUserAgent(MOBILE_UA);
        })
        .onPageBegin(() => {
          this.isTimeTablePage = this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/for-std/course-t');
        })
        .onPageEnd(() => {
          if (this.isTimeTablePage && !this.gotTimeTable) {
            const uiContext: UIContext = this.getUIContext();
            setTimeout(() => {
              this.webviewController.runJavaScript(timeTableQueryJS, (error, result) => {
                if (error) {
                  uiContext.getPromptAction().showToast({ message: $r('app.string.get_timetable_err_msg'), duration: 2000 });
                  return;
                }
                if (result === 'null') {
                  uiContext.getPromptAction().showToast({ message: $r('app.string.auto_get_timetable_fail_msg'), duration: 3500 });
                  return;
                }
                this.gotTimeTable = true;
                console.info(`课表是：${result}`); /* TODO: 保存课程表到本地（需JSON.parse） */
                this.obtainedData.timeTable = result;
              });
              this.webviewController.runJavaScript(startTimeQueryJS, (error, result) => {
                if (error) {/* 理论上这里不会出什么错误（doge） */ return;}
                console.info(`学期开始的UNIX时间戳是${result}mm`);
                this.obtainedData.startTime = Number(result);
              });
            }, 1000);
          }
        })
    }
    .height('100%')
    .width('100%')
  }
}
