
import { webview } from '@kit.ArkWeb'
import { DESKTOP_MODE, MOBILE_MODE, TABLET_MODE, DESKTOP_UA, MOBILE_UA, TABLET_UA } from '../constants/UserAgent'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import UnifiedPreference from '../utils/UnifyPreference'
import { call } from '@kit.TelephonyKit'

const desktopUrl: string[] = [] // 需要默认访问桌面版站点时使用

@Entry
@Component
struct Webview {
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State uaMode: number = MOBILE_MODE;
  title: string = '';
  url: string = '';
  webAutoDarkMode: boolean = UnifiedPreference.getBoolSync('webAutoDarkMode', true);
  webBackPress: boolean = UnifiedPreference.getBoolSync('webBackPress', true);
  @State loadingProgress: number = 0;

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

  onBackPress() {
    if (this.webBackPress)
      return false;
    if (this.webviewController.accessStep(-1)) {
      this.webviewController.backward();
      return true;
    } else {
      return false;
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
                if (this.webviewController.accessForward()) {
                  this.webviewController.forward();
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

      MenuItem({ content: $r('app.string.trim_memory'), startIcon: $r('app.media.arrowshape_3_triangle_path')})
        .onClick(() => {
          try {
            // 设置当前内存压力等级为适中，释放少量内存
            webview.WebviewController.trimMemoryByPressureLevel(webview.PressureLevel.MEMORY_PRESSURE_LEVEL_MODERATE);
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        })

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

      MenuItem({ content: $r('app.string.open_in_browser'),
        startIcon: $r('app.media.browser')
      })
        .onClick(() => {
          (this.getUIContext().getHostContext() as common.UIAbilityContext).startAbility({
            action: 'ohos.want.action.viewData',
            entities: ['entity.system.browsable'],
            uri: this.webviewController.getUrl()
          }).catch((err: BusinessError) => {
              console.error(`startAbility failed, code is ${err.code}, message is ${err.message}`);
            })
        })

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
    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(20)
          .onClick(() => {
            this.webviewController.terminateRenderProcess();
            console.info(`课表页面路由path：${this.getUIContext().getRouter().getLength()}`);
            this.webviewController.terminateRenderProcess();
            this.getUIContext().getRouter().back({
              url: 'pages/Index'
            })
          })
        Image($r('app.media.back'))
          .padding(({ left: 12, right: 4 }))
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
                    this.webviewController.terminateRenderProcess();
                    this.getUIContext().getRouter().back({
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
          .height(48)
        Blank()
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
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .backgroundColor($r('app.color.shaded_background'))

      Stack({ alignContent: Alignment.TopStart}) {
        Web({ src: this.url, controller: this.webviewController })
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .width('100%')
          .height('100%')
          .darkMode(this.webAutoDarkMode ? WebDarkMode.Auto : WebDarkMode.Off)
          .forceDarkAccess(this.webAutoDarkMode)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .onLoadIntercept((event) => {
            if (event) {
              let uri: string = event.data.getRequestUrl();
              if (uri.startsWith('mailto:')) {
                (this.getUIContext().getHostContext() as common.UIAbilityContext).startAbility({
                  action: 'ohos.want.action.sendToData',
                  uri: uri
                }).catch((err: BusinessError) => {
                    console.error(`startAbility failed, code is ${err.code}, message is ${err.message}`);
                  })
                return true;
              } else if (uri.indexOf('tel:') === 0) {
                call.makeCall(uri.substring(4), (err) => {
                  if (!err) {
                    console.info('make call succeeded.');
                  } else {
                    console.info('make call fail, err is:' + JSON.stringify(err));
                  }
                });
                return true;
              } else if (uri.indexOf('native://webview_error_backward') === 0) {
                if (this.webviewController.accessBackward()) {
                  this.webviewController.backward();
                } else {
                  this.webviewController.terminateRenderProcess();
                  this.getUIContext().getRouter().back({
                    url: this.getUIContext().getRouter().getLength() === '3' ? 'pages/Schedule' : 'pages/Index'
                  });
                }
                return true;
              }
            }
            return false;
          })
          .onErrorReceive((event) => {
            // Only handle loading errors of the main framework to avoid duplicate processing of errors in sub-resources
            if (event && event.request.isMainFrame()) {
              try {
                this.webviewController.loadUrl($rawfile('WebError.html')); // 加载自定义错误页面
              } catch (error) {
                console.error(`ErrorCode: ${(error as BusinessError).code}, Message: ${(error as BusinessError).message}`);
              }
            }
          })
          .onProgressChange((event) => {
            this.loadingProgress = event.newProgress;
          })
          .onControllerAttached(() => {
            if (desktopUrl.includes(this.url)) {
              this.webviewController.setCustomUserAgent(DESKTOP_UA);
              this.uaMode = DESKTOP_MODE;
            } else {
              this.webviewController.setCustomUserAgent(MOBILE_UA);
              this.uaMode = MOBILE_MODE;
            }
          })

        Line()
          .visibility(this.loadingProgress == 100 ? Visibility.None : Visibility.Visible)
          .width(`${this.loadingProgress}%`)
          .height(5)
          .startPoint([0, 0])
          .backgroundColor($r('app.color.pink'))
        LoadingProgress()
          .width(45)
          .height(45)
          .padding({ left: 5, top: 5})
          .color($r('app.color.pink'))
          .visibility(this.loadingProgress === 100 ? Visibility.None : Visibility.Visible)

      }
      .layoutWeight(1)
    }
  }
}
