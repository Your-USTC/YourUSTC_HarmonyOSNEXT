
/**
 * 浏览器页面
 */

import { common } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { picker, fileUri } from  '@kit.CoreFileKit';
import { call } from '@kit.TelephonyKit';

import { DESKTOP_MODE, MOBILE_MODE, TABLET_MODE, DESKTOP_UA, MOBILE_UA, TABLET_UA } from '../constants/UserAgent';

import accountInfoProvider from '../utils/Encryption';
import { fillInformationJS } from '../utils/TimeTable';
import UnifiedPreferences, { PASSWORD_KEY, REMIND_KEY, UID_KEY} from '../utils/UnifyPreference';

import BackgroundImage from '../view/BgImageManager';
import PasswordDialog from '../view/PasswordDialog';

// 全局变量
const desktopUrl: string[] = ['https://young.ustc.edu.cn/login'] // 需要默认访问桌面版站点时使用
const autoJumpUrl: string[] = ['https://jw.ustc.edu.cn/for-std/course-table', 'https://jw.ustc.edu.cn/for-std/exam-arrange', 'https://jw.ustc.edu.cn/for-std/grade/sheet'];
let eachDownloadPercent = new Map<string, number>();

@Entry
@Component
struct Webview {

  // 内部变量
  webviewController: webview.WebviewController = new webview.WebviewController();
  downloadDelegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate();
  @State uaMode: number = MOBILE_MODE;
  title: string = '';
  url: string = '';
  webAutoDarkMode: boolean = UnifiedPreferences.getBoolSync('webAutoDarkMode', true);
  webBackPress: boolean = UnifiedPreferences.getBoolSync('webBackPress', true);
  @State loadingProgress: number = 0;
  @State downloadPercent: number = 100;
  @State downloadItemNum: number = 0;
  @State downloadItemTotal: number = 0;
  // 自动填充
  haveJumped: boolean = true;
  // @State infoProvider: accountInfoProvider = new accountInfoProvider();
  haveTriedLogin: boolean = false;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      isFromSetting: false,
      onConfirm: () => { this.webviewController.runJavaScript(fillInformationJS, (error, result) => {}); }
    }),
    autoCancel: true
  });

  /**
   * Toast 弹窗
   */
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

  /**
   * 系统导航：返回键（滑动）改为“后退”
   */
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

  /**
   * 组件：“更多”菜单
   */
  @Builder
  WebviewMenu() {
    Menu() {
      // 前进
      MenuItem({ content: $r('app.string.page_forward'), startIcon: $r('app.media.forth')})
        .parallelGesture(GestureGroup(
          GestureMode.Exclusive,
          // 点击
          TapGesture({ count: 1 })
            .onAction(() => {
              if (this.webviewController.accessForward()) {
                this.webviewController.forward();
              } else {
                this.showMessage($r('app.string.already_last_page'), 500);
              }
            }),
          // 长按
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
        ))

      // 清除 Cookies
      MenuItem({ content: $r('app.string.wipe_cookie'), startIcon: $r('app.media.remove_cookie') })
        .onClick(() => {
          try {
            // this.webviewController.removeCache(true);
            // fileIo.rmdirSync('/data/storage/el2/base/cache/web/Cookies');
            webview.WebCookieManager.clearAllCookiesSync();
            // webview.WebCookieManager.clearSessionCookieSync();
            this.showMessage($r('app.string.wipe_cache_success'), 500);
          } catch (error) {
            console.error(`rmdirSync ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        })

      // 释放内存
      MenuItem({ content: $r('app.string.trim_memory'), startIcon: $r('app.media.arrowshape_3_triangle_path') })
        .onClick(() => {
          try {
            // 设置当前内存压力等级为适中，释放少量内存
            webview.WebviewController.trimMemoryByPressureLevel(webview.PressureLevel.MEMORY_PRESSURE_LEVEL_MODERATE);
            this.showMessage($r('app.string.wipe_cache_success'), 500);
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        })

      // UA 切换
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

      // 在系统浏览器中打开
      MenuItem({
        content: $r('app.string.open_in_browser'),
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

      // 帮助
      MenuItem({ content: $r('app.string.help'), startIcon: $r('app.media.questionmark_circle')})
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/Help' })
            .catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            });
        })
    }
  }

  /**
   * 初始化：教务系统相关网站（白名单）登录后自动跳转
   */
  aboutToAppear() {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    if (params) {
      this.title = params.title ?? '';
      this.url = params.url ?? '';
    }
    if (autoJumpUrl.includes(this.url))
      this.haveJumped = false;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(22)
          .draggable(false)
          .onClick(() => {
            this.webviewController.terminateRenderProcess();
            this.getUIContext().getRouter().back();
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
                    this.getUIContext().getRouter().back();
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
          .height(22)
          .draggable(false)
          .onClick(() => this.webviewController.refresh())
        Image($r('app.media.more_opinion'))
          .padding({ right: 12 })
          .height(22)
          .draggable(false)
          .bindMenu(this.WebviewMenu())
      }
      .id('header')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background') : undefined)
      .opacity(BackgroundImage.opacityLevel)

      // 网页浏览器
      Stack({ alignContent: Alignment.TopStart}) {
        Web({ src: this.url, controller: this.webviewController })
          .backgroundColor('#00d00721')
          .opacity(BackgroundImage.opacityLevel)
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .width('100%')
          .height('100%')
          .darkMode(this.webAutoDarkMode ? WebDarkMode.Auto : WebDarkMode.Off)
          .forceDarkAccess(this.webAutoDarkMode)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .onProgressChange((event) => {    // 加载/下载进度条
            this.loadingProgress = event.newProgress;
          })
          .javaScriptProxy({                // 自动填充 JS
            object: accountInfoProvider,
            name: "infoProvider",
            methodList: ["getUID", "getPassword"],
            controller: this.webviewController,
            asyncMethodList: []
          })
          // 开始加载（自动跳转）
          .onPageBegin(() => {
            if (!this.haveJumped) { // 不在白名单中的网站已在 aboutToAppear 中设置不跳转
              if (this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/home')) {
                let i: number = -1;
                while (this.webviewController.accessStep(i))
                  i--;
                this.webviewController.backOrForward(i + 1);
                this.webviewController.loadUrl(this.url);
                this.haveJumped = true;
              }
            }
          })
          // 加载结束
          .onPageEnd(() => {
            if (!this.haveTriedLogin && this.webviewController.getUrl().startsWith('https://id.ustc.edu.cn/cas/login')) {
              this.haveTriedLogin = true;
              if (!(UnifiedPreferences.hasSync(UID_KEY) && UnifiedPreferences.hasSync(PASSWORD_KEY))
                && UnifiedPreferences.getBoolSync(REMIND_KEY, true)) {
                this.dialogController.open();
              } else {
                this.webviewController.runJavaScript(fillInformationJS, (error, result) => {});
              }
            }
          })
          // 特殊 URL 处理
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
                  this.getUIContext().getRouter().back();
                }
                return true;
              }
            }
            return false;
          })
          // 网络错误处理
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
          // 文件下载
          .onControllerAttached(() => {
            if (desktopUrl.includes(this.url)) {
              this.webviewController.setCustomUserAgent(DESKTOP_UA);
              this.uaMode = DESKTOP_MODE;
            } else {
              this.webviewController.setCustomUserAgent(MOBILE_UA);
              this.uaMode = MOBILE_MODE;
            }
            try {
              this.downloadDelegate.onBeforeDownload((webDownloadItem: webview.WebDownloadItem) => {
                this.downloadItemNum++;
                this.downloadItemTotal++;
                getDownloadPathFromPicker().then((downloadPath) => {
                  webDownloadItem.start(downloadPath + '/' + webDownloadItem.getSuggestedFileName());
                });
              })
              this.downloadDelegate.onDownloadUpdated((webDownloadItem: webview.WebDownloadItem) => {
                eachDownloadPercent.set(webDownloadItem.getGuid(), webDownloadItem.getPercentComplete());
                this.downloadPercent = 0;
                if (this.downloadItemTotal !== 0)
                  for (const value of eachDownloadPercent.values())
                    this.downloadPercent += value / this.downloadItemTotal;
                // 下载速度：console.info("download update speed: " + webDownloadItem.getCurrentSpeed())
              })
              this.downloadDelegate.onDownloadFailed((webDownloadItem: webview.WebDownloadItem) => {
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.download_failed_s', webDownloadItem.getLastErrorCode()) })
              })
              this.downloadDelegate.onDownloadFinish((webDownloadItem: webview.WebDownloadItem) => {
                this.downloadItemNum--;
                if (this.downloadItemNum === 0) {
                  this.getUIContext().showAlertDialog(
                    {
                      title: $r('app.string.download_finish'),
                      message: $r('app.string.whether_open_file_manager'),
                      autoCancel: true,
                      alignment: DialogAlignment.Center,
                      gridCount: 4,
                      primaryButton: {
                        value: $r('app.string.cancel'),
                        action: () => {
                          eachDownloadPercent.clear();
                          this.downloadItemTotal = 0;
                        }
                      },
                      secondaryButton: {
                        enabled: true,
                        defaultFocus: true,
                        style: DialogButtonStyle.HIGHLIGHT,
                        value: $r('app.string.ok'),
                        action: () => {
                          eachDownloadPercent.clear();
                          this.downloadItemTotal = 0;
                          try {
                            (this.getUIContext().getHostContext() as common.UIAbilityContext).openLink('filemanager://openDirectory', { parameters: { 'fileUri': '' } });
                          } catch (paramError) {
                            console.error(`Failed to start link. Code is ${paramError.code}, message is ${paramError.message}`);
                          }
                        }
                      },
                      cancel: () => {
                        eachDownloadPercent.clear();
                        this.downloadItemTotal = 0;
                      },
                      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                        eachDownloadPercent.clear();
                        this.downloadItemTotal = 0;
                        if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
                          dismissDialogAction.dismiss();
                        }
                        if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
                          dismissDialogAction.dismiss();
                        }
                      }
                    }
                  );
                }
              })
              this.webviewController.setDownloadDelegate(this.downloadDelegate);
            } catch (error) {
              console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
            }
          })
          // 网页消息（警告）
          .onAlert((event) => {
            if (event) {
              this.getUIContext().showAlertDialog({
                title: "来自 " + event.url + " 的警告",
                message: event.message,
                confirm:{
                  value: "确认",
                  action: () => { event.result.handleConfirm(); }
                },
                cancel: () => { event.result.handleCancel(); }
              });
            }
            return true;
          })
          // 网页消息（一般）
          .onConfirm((event) => {
            if (event) {
              this.getUIContext().showAlertDialog({
                title: "来自 " + event.url + " 的消息",
                message: event.message,
                primaryButton: {
                  value: 'cancel',
                  action: () => { event.result.handleCancel(); }
                },
                secondaryButton: {
                  value: 'ok',
                  action: () => { event.result.handleConfirm(); }
                },
                cancel: () => { event.result.handleCancel(); }
              })
            }
            return true;
          })
          // 网页消息（带输入框）
          .onPrompt((event) => {
            if (event) {
              this.getUIContext().showAlertDialog({
                title: "来自 " + event.url + " 的消息",
                message: event.message + "\n󰊗此处应有输入框，但是我们没有在学校网站碰到过需要输入框的消息，因此没做（滑稽）。如果你不幸遇到了，在󰁡菜单中选择「在系统浏览器中打开」，并稍后在 GitHub 上向我们反馈。",
                confirm:{
                  value: "好吧",
                  action: () => { event.result.handleCancel(); }
                },
                cancel: () => { event.result.handleCancel(); }
              })
            }
            return true;
          })

        // 加载/下载进度条
        Line()
          .visibility(this.loadingProgress == 100 ? Visibility.None : Visibility.Visible)
          .width(`${this.loadingProgress}%`)
          .height(5)
          .startPoint([0, 0])
          .backgroundColor($r('app.color.pink'))

        Row() {
          Row({ space: 5 }) {
            LoadingProgress()
              .width(45)
              .height(45)
              .color($r('app.color.pink'))
            Text($r('app.string.loading'))
              .fontColor($r('app.color.pink'))
          }
          .visibility(this.loadingProgress === 100 ? Visibility.Hidden : Visibility.Visible)

          Row({ space: 5 }) {
            Text($r('app.string.downloading_d', this.downloadItemNum))
              .fontColor($r('app.color.pink'))
            Progress({ value: this.downloadPercent, total: 100, type: ProgressType.Ring })
              .color($r('app.color.pink'))
              .style({ strokeWidth: 4, enableScanEffect: true, shadow: true })
              .height(30)
          }
          .backgroundColor($r('app.color.grid_background'))
          .borderRadius(20)
          .padding({ left: 13, top: 5, right: 5, bottom: 5})
          .visibility(this.downloadItemTotal === 0 ? Visibility.Hidden : Visibility.Visible)
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Top)
        .width('100%')
        .padding({ left: 5, top: 5, right: 5 })
        .hitTestBehavior(HitTestMode.Transparent)
      }
      .layoutWeight(1)
    }
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundImage(BackgroundImage.pic)
    .backgroundImageSize(ImageSize.Cover)
    .backgroundImagePosition(Alignment.Center)
  }
}

/**
 * 获取下载路径
 */
function getDownloadPathFromPicker(): Promise<string> {
  return new Promise<string>(resolve => {
    try {
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
      const documentPicker = new picker.DocumentViewPicker();
      documentPicker.save(documentSaveOptions).then(async (documentSaveResult: Array<string>) => {
        if (documentSaveResult.length <= 0) {
          resolve('');
          return;
        }
        const uriString = documentSaveResult[0];
        // console.log(uriString);
        if (!uriString) {
          resolve('');
          return;
        }
        const uri = new fileUri.FileUri(uriString);
        resolve(uri.path);
      }).catch((err: BusinessError) => {
        console.error(`ErrorCode: ${err.code},  Message: ${err.message}`);
        resolve('');
      });
    } catch (error) {
      resolve('');
    }
  });
}
