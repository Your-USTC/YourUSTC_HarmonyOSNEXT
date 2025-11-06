// .onBackPressed()在5.0.0上不起作用！

import { webview } from '@kit.ArkWeb'
import { DESKTOP_MODE, MOBILE_MODE, TABLET_MODE, DESKTOP_UA, MOBILE_UA, TABLET_UA } from '../constants/UserAgent'
import { startTimeQueryJS, timeTableQueryJS, timeTableQueryJSShort } from '../utils/TimeTable'
import { obtainedData } from '../pages/Schedule'
import { IconStyle } from '@kit.ArkUI'

const desktopUrl: string[] = [] // 需要默认访问桌面版站点时使用

@Entry
@Component
struct Webview {
  webviewController: webview.WebviewController = new webview.WebviewController()
  @State uaMode: number = MOBILE_MODE;
  title: string = '';
  url: string = '';
  @State isTimeTablePage: boolean = false;
  @State gotTimeTable: boolean = false;
  obtainedData: obtainedData = {timeTable: '', startTime: '0'};


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

  @Builder
  WebviewMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.page_forward'), startIcon: $r('app.media.forth')})
        .parallelGesture(
          GestureGroup(
            GestureMode.Exclusive,
            TapGesture({ count: 1 })
              .onAction(() => {
                if (this.webviewController.accessBackward()) {
                  this.webviewController.backward();
                } else {
                  this.showMessage($r('app.string.already_last_page'), 500);
                }
              }),
            LongPressGesture()
              .onAction(() => {
                if (this.webviewController.accessForward()) {
                  let i: number = 1;
                  while (this.webviewController.accessStep(i))
                    i++;
                  this.webviewController.backOrForward(i - 1);
                } else {
                  this.showMessage($r('app.string.already_last_page'), 500);
                }
              })
          )
        )

      MenuItemGroup({ header: $r('app.string.switch_ua') }) {
        MenuItem({ content: $r('app.string.visit_desktop_ua'),
          startIcon: $r('app.media.desktop'),
          endIcon: (this.uaMode == DESKTOP_MODE ? $r('app.media.checkmark') : undefined) })
          .onClick(() => {
            this.webviewController.setCustomUserAgent(DESKTOP_UA);
            this.webviewController.refresh();
            this.uaMode = DESKTOP_MODE;
          })
        MenuItem({ content: $r('app.string.visit_mobile_ua'),
          startIcon: $r('app.media.mobile'),
          endIcon: (this.uaMode == MOBILE_MODE ? $r('app.media.checkmark') : undefined) })
          .onClick(() => {
            this.webviewController.setCustomUserAgent(MOBILE_UA);
            this.webviewController.refresh();
            this.uaMode = MOBILE_MODE;
          })
        MenuItem({ content: $r('app.string.visit_tablet_ua'),
          startIcon: $r('app.media.tablet'),
          endIcon: (this.uaMode == TABLET_MODE ? $r('app.media.checkmark') : undefined) })
          .onClick(() => {
            this.webviewController.setCustomUserAgent(TABLET_UA);
            this.webviewController.refresh();
            this.uaMode = TABLET_MODE;
          })
      }

      MenuItem({ content: $r('app.string.help'), startIcon: $r('app.media.questionmark_circle')})
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/Help' })
            .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
        })
    }
  }

  aboutToAppear() { // Receive parameters before loading the page
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    if (params) {
      this.title = params.title ?? '';
      this.url = params.url ?? '';
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r('app.media.close'))
            .padding({ left: 12 })
            .height(20)
            .onClick(() => {
              console.info(`课表页面路由path：${this.getUIContext().getRouter().getLength()}`);
              this.getUIContext().getRouter().back({
                params: this.obtainedData,
                url: this.getUIContext().getRouter().getLength() === '3' ? 'pages/Schedule' : 'pages/Index'
              })
            })
          Image($r('app.media.back'))
            .padding(({ left: 12, right: 16 }))
            .height(16)
            .draggable(false)
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
                    if (this.webviewController.accessBackward()) {
                      let i: number = -1;
                      while (this.webviewController.accessStep(i))
                        i--;
                      this.webviewController.backOrForward(i + 1);
                    } else {
                      this.showMessage($r('app.string.already_first_page'), 500);
                    }
                  })
              )
            )
          Blank()
          Text(this.title)
            .fontSize(18)
            .fontColor($r('app.color.normal_text'))
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
          Image($r('app.media.get'))
            .padding({ right: 12 })
            .height(this.isTimeTablePage && !this.gotTimeTable ? 20 : 0)
            .enabled(this.isTimeTablePage && !this.gotTimeTable)
            .onClick(() => {
              this.webviewController.runJavaScript(timeTableQueryJSShort, (error, result) => {
                if (error) {
                  this.showMessage($r('app.string.get_timetable_err_msg'), 2000);
                  return;
                }
                if (result === 'null') {
                  this.showMessage($r('app.string.auto_get_timetable_fail_msg'), 3500 );
                  return;
                }
                this.gotTimeTable = true;
                console.info(`课表是：${result}`); /* TODO: 保存课程表到本地（需JSON.parse） */
                this.obtainedData.timeTable = result;
                this.webviewController.runJavaScript(startTimeQueryJS, (error, result) => {
                  if (error) { /* 理论上这里不会出什么错误（doge） */
                    return;
                  }
                  console.info(`学期开始的UNIX时间戳是${result}mm`); /* TODO: 保存开学时间到本地（需JSON.parse） */
                  this.obtainedData.startTime = result;
                  console.info(`转换后的时间戳是${this.obtainedData.startTime}`);
                  if (this.getUIContext().getRouter().getLength() === '3') {
                    this.getUIContext().getRouter().back({
                      params: this.obtainedData,
                      url: 'pages/Schedule'
                    });
                  }
                });
              });
            })
          Image($r('app.media.refresh'))
            .padding({ right: 12 })
            .height(20)
            .onClick(() => this.webviewController.refresh())
          Image($r('app.media.more_opinion'))
            .padding({ right: 12 })
            .height(20)
            .bindMenu(this.WebviewMenu())
        }
        .id('header')
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.shaded_background'))

        Web({ src: this.url, controller: this.webviewController })
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .width('100%')
          .layoutWeight(1)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .onControllerAttached(() => {
            if (desktopUrl.includes(this.url)) {
              this.webviewController.setCustomUserAgent(DESKTOP_UA);
              this.uaMode = DESKTOP_MODE;
            } else {
              this.webviewController.setCustomUserAgent(MOBILE_UA);
              this.uaMode = MOBILE_MODE;
            }
          })
          .onPageBegin(() => {
            this.isTimeTablePage =
              this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/for-std/course-t');
          })
          .onPageEnd(() => {
            if (this.isTimeTablePage && !this.gotTimeTable) {
              const uiContext: UIContext = this.getUIContext();
              setTimeout(() => {
                this.webviewController.runJavaScript(timeTableQueryJS, (error, result) => {
                  if (error) {
                    uiContext.getPromptAction()
                      .showToast({ message: $r('app.string.get_timetable_err_msg'), duration: 2000 });
                    return;
                  }
                  if (result === 'null') {
                    uiContext.getPromptAction()
                      .showToast({ message: $r('app.string.auto_get_timetable_fail_msg'), duration: 3500 });
                    return;
                  }
                  this.gotTimeTable = true;
                  console.info(`课表是：${result}`); /* TODO: 保存课程表到本地（需JSON.parse） */
                  this.obtainedData.timeTable = result;
                  this.webviewController.runJavaScript(startTimeQueryJS, (error, result) => {
                    if (error) { /* 理论上这里不会出什么错误（doge） */
                      return;
                    }
                    console.info(`学期开始的UNIX时间戳是${result}mm`);
                    this.obtainedData.startTime = result;
                    console.info(`转换后的时间戳是${this.obtainedData.startTime}`);
                    if (this.getUIContext().getRouter().getLength() === '3') {
                      this.getUIContext().getRouter().back({
                        params: this.obtainedData,
                        url: 'pages/Schedule'
                      });
                    }
                  });
                });
              }, 1000);
            }
          })
      }
      .height('100%')
      .width('100%')
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      if (this.webviewController.accessStep(-1)) {
        console.error('aaa true');
        this.webviewController.backward()           // 返回上一页
        return true;
      } else {
        console.error('aaa false');
        return false;
      }
    })
  }
}
