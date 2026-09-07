
import { webview } from '@kit.ArkWeb';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { picker, fileUri } from  '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { WantAbility } from '../utils/WantAbility';
import PasswordDialog from '../view/PasswordDialog';
import accountInfoProvider from '../utils/Encryption';
import BackgroundImage from '../utils/BgImageManager';
import { MultiPageMenu, webName } from '../view/MultiPageMenu';
import { fillInformationJS, deleteAIHelper } from '../utils/tools';
import UnifiedPreferences, { PASSWORD_KEY, REMIND_KEY, UID_KEY} from '../utils/UnifyPreference';
import { DESKTOP_MODE, MOBILE_MODE, TABLET_MODE, DESKTOP_UA, MOBILE_UA, TABLET_UA } from '../constants/UserAgent';
import { deviceType, hostContext } from '../constants/BasicConstants';
import { openPermissionSetting, regainPermission, PermissionRequestState } from '../utils/PermissionManager';
import { SimpleLink } from '../constants/Links';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';

const desktopUrl: string[] = ['https://young.ustc.edu.cn/login'] // 需要默认访问桌面版站点时使用
const autoJumpUrl: string[] = ['https://jw.ustc.edu.cn/for-std/course-table', 'https://jw.ustc.edu.cn/for-std/exam-arrange', 'https://jw.ustc.edu.cn/for-std/grade/sheet'];

let eachDownloadPercent = new Map<string, number>();

@Builder
export function WebBuilder(name: string, param?: SimpleLink) {
  if (param)
    Webview({ title: param.title as string, url: param.url as string });
  else
    Webview();
}

@Entry
@Component
struct Webview {
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
  haveJumped: boolean = true;
  // @State infoProvider: accountInfoProvider = new accountInfoProvider();
  haveTriedLogin: boolean = false;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      isFromSetting: false,
      onConfirm: () => { this.webviewController.runJavaScript(fillInformationJS, (error, result) => {}); },
    }),
    autoCancel: true
  })
  tmpDialogController: undefined;

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

  @StorageLink('isSplit')isSplit: NavigationMode = NavigationMode.Auto;
  @State allowSysOpen: boolean = true;
  @Builder WebviewMenu() {
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

      MenuItem({ content: $r('app.string.switch_page'), builder: MultiPageMenu(this.pathStack),
        startIcon: $r('app.media.switch_page'), endIcon: $r('sys.media.ohos_ic_public_arrow_right') })

      MenuItem({ content: $r('app.string.switch_ua'), builder: this.changeUAMenu(),
        startIcon: this.uaMode === MOBILE_MODE ? $r('app.media.mobile') : (this.uaMode === TABLET_MODE ? $r('app.media.tablet') : $r('app.media.desktop')),
        endIcon: $r('sys.media.ohos_ic_public_arrow_right') })

      MenuItem({ content: $r('app.string.open_file_manager'), startIcon: $r('app.media.folder_badge_eye') })
        .onClick(() => {
          hostContext().openLink(
            'filemanager://openDirectory', {
              parameters: {
                'fileUri': 'file://docs/storage/Users/currentUser/Download/com.nic.dailynic'
              }
            }
          );
        })

      MenuItem({ content: $r('app.string.open_in_full_screen'), startIcon: $r('app.media.arrow_right_up_and_square') })
        .enabled(this.isSplit === NavigationMode.Split)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/Webview_legacy',
            params: { title: this.title, url: this.webviewController.getUrl() }
          }).catch((err: Error) => {
            console.error(`Router ERROR: [${err.name}] ${err.message}`)
          });
        })

      MenuItem({ content: $r('app.string.trim_memory'), startIcon: $r('app.media.storage') })
        .onClick(() => {
          try {
            // 设置当前内存压力等级为适中，释放少量内存
            webview.WebviewController.trimMemoryByPressureLevel(webview.PressureLevel.MEMORY_PRESSURE_LEVEL_MODERATE);
            this.showMessage($r('app.string.clear_success'), 500);
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        })

      MenuItem({ content: $r('app.string.share'), startIcon: $r('app.media.share') })
        .onClick(() => {
          const webTitle = this.webviewController.getTitle();
          const webUrl = this.webviewController.getUrl();
          const shareData = new systemShare.SharedData({
            utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
            content: webUrl,
            title: webTitle,
            description: '分享链接'
          });
          shareData.addRecord({
            utd: uniformTypeDescriptor.UniformDataType.TEXT,
            content: `我通过妮可之记向你分享了一个网址：[${webTitle}](${webUrl})`,
            title: webTitle,
            description: '分享链接'
          });
          const shareController = new systemShare.ShareController(shareData);
          shareController.show(hostContext(), {
            selectionMode: systemShare.SelectionMode.SINGLE,
            previewMode: systemShare.SharePreviewMode.DETAIL,
          }).then(() => {
            console.info('ShareController show success.');
          }).catch((error: BusinessError) => {
            console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
          });
        })

      MenuItem({ content: $r('app.string.help'), startIcon: $r('app.media.questionmark_circle')})
        .onClick(() => {
          this.pathStack.pushPath({ name: 'Help' });
        })
    }
    // .subMenuExpandingMode(SubMenuExpandingMode.STACK_EXPAND)
  }

  @Builder changeUAMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.visit_desktop_ua'), startIcon: $r('app.media.desktop'),
        endIcon: (this.uaMode == DESKTOP_MODE ? $r('app.media.checkmark') : undefined) })
        .onClick(() => {
          this.webviewController.setCustomUserAgent(DESKTOP_UA);
          this.webviewController.refresh();
          this.uaMode = DESKTOP_MODE;
        })
      MenuItem({ content: $r('app.string.visit_mobile_ua'), startIcon: $r('app.media.mobile'),
        endIcon: (this.uaMode == MOBILE_MODE ? $r('app.media.checkmark') : undefined) })
        .onClick(() => {
          this.webviewController.setCustomUserAgent(MOBILE_UA);
          this.webviewController.refresh();
          this.uaMode = MOBILE_MODE;
        })
      MenuItem({ content: $r('app.string.visit_tablet_ua'), startIcon: $r('app.media.tablet'),
        endIcon: (this.uaMode == TABLET_MODE ? $r('app.media.checkmark') : undefined) })
        .onClick(() => {
          this.webviewController.setCustomUserAgent(TABLET_UA);
          this.webviewController.refresh();
          this.uaMode = TABLET_MODE;
        })
    }
  }

  @State loadError: string = '';
  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Web({ src: this.url, controller: this.webviewController })
          .javaScriptProxy({
            object: accountInfoProvider,
            name: "infoProvider",
            methodList: ["getUID", "getPassword"],
            controller: this.webviewController,
            asyncMethodList: []
          })
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .width('100%')
          .height('100%')
          .backgroundColor(BackgroundImage.blurLevel === undefined ? undefined : '#0000')
          .darkMode(this.webAutoDarkMode ? WebDarkMode.Auto : WebDarkMode.Off)
          .forceDarkAccess(this.webAutoDarkMode)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .onPageBegin(() => {
            if (this.webviewController.getUrl().startsWith("resource://"))
              this.allowSysOpen = false;
            else
              this.allowSysOpen = true;
            this.loadError = '';
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
            if (this.webviewController.getUrl().includes('https://i.ustc.edu.cn'))
              this.webviewController.runJavaScript(deleteAIHelper, (error, result) => {});
          })
          .onLoadIntercept((event) => {
            if (event) {
              let uri: string = event.data.getRequestUrl();
              if (uri.startsWith('mailto:')) {
                WantAbility.SendEmail(hostContext(), uri);
                return true;
              } else if (uri.indexOf('tel:') === 0) {
                WantAbility.MakeCall(uri.substring(4));
                return true;
              }
            }
            return false;
          })
          .onErrorReceive((event) => {
            // Only handle loading errors of the main framework to avoid duplicate processing of errors in sub-resources
            if (event && event.request.isMainFrame()) {
              this.loadError = event.error.getErrorInfo();
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
              switch(UnifiedPreferences.getNumberSync('UAMode', deviceType === 'phone' ? 1 : (deviceType === 'tablet' ? 2 : 0))) {
                case 0:
                  this.webviewController.setCustomUserAgent(DESKTOP_UA);
                  this.uaMode = DESKTOP_MODE;
                  break;
                case 1:
                  this.webviewController.setCustomUserAgent(MOBILE_UA);
                  this.uaMode = MOBILE_MODE;
                  break;
                case 2:
                  this.webviewController.setCustomUserAgent(TABLET_UA);
                  this.uaMode = TABLET_MODE;
                  break;
              }
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
                            hostContext().openLink('filemanager://openDirectory', { parameters: { 'fileUri': 'file://docs' + webDownloadItem.getFullPath() } });
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
          .onAlert((event) => {
            if (event) {
              this.getUIContext().showAlertDialog({
                title: $r('app.string.web_dialog_alert_from', event.url),
                message: event.message,
                autoCancel: true,
                alignment: DialogAlignment.Center,
                gridCount: 4,
                primaryButton: {
                  value: $r('app.string.cancel'),
                  action: () => { event.result.handleCancel(); }
                },
                secondaryButton: {
                  enabled: true,
                  defaultFocus: true,
                  style: DialogButtonStyle.HIGHLIGHT,
                  value: $r('app.string.ok'),
                  action: () => { event.result.handleConfirm(); }
                },
                cancel: () => { event.result.handleCancel(); },
                onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                  if (dismissDialogAction.reason === DismissReason.PRESS_BACK || dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
                    dismissDialogAction.dismiss();
                    event.result.handleCancel();
                  }
                }
              });
            }
            return true;
          })
          .onConfirm((event) => {
            if (event) {
              this.getUIContext().showAlertDialog({
                title: $r('app.string.web_dialog_message_from', event.url),
                message: event.message,
                autoCancel: true,
                alignment: DialogAlignment.Center,
                gridCount: 4,
                primaryButton: {
                  value: $r('app.string.cancel'),
                  action: () => { event.result.handleCancel(); }
                },
                secondaryButton: {
                  enabled: true,
                  defaultFocus: true,
                  style: DialogButtonStyle.HIGHLIGHT,
                  value: $r('app.string.ok'),
                  action: () => { event.result.handleConfirm(); }
                },
                cancel: () => { event.result.handleCancel(); },
                onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                  if (dismissDialogAction.reason === DismissReason.PRESS_BACK || dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
                    dismissDialogAction.dismiss();
                    event.result.handleCancel();
                  }
                }
              })
            }
            return true;
          })
          .onPrompt((event) => {
            if (event) {
              this.getUIContext().showAlertDialog({
                title: $r('app.string.web_dialog_message_from', event.url),
                message: event.message + "\n󰊗此处应有输入框，但是我们没有在学校网站碰到过需要输入框的消息，因此没做（滑稽）。如果你不幸遇到了，在󰁡菜单中选择「在系统浏览器中打开」，并稍后通过「关于」页面的联系方式向我们反馈。",
                autoCancel: true,
                alignment: DialogAlignment.Center,
                gridCount: 4,
                primaryButton: {
                  value: $r('app.string.cancel'),
                  action: () => { event.result.handleCancel(); }
                },
                secondaryButton: {
                  enabled: true,
                  defaultFocus: true,
                  style: DialogButtonStyle.HIGHLIGHT,
                  value: $r('app.string.ok'),
                  action: () => { event.result.handleCancel(); }
                },
                cancel: () => { event.result.handleCancel(); },
                onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                  if (dismissDialogAction.reason === DismissReason.PRESS_BACK || dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
                    dismissDialogAction.dismiss();
                    event.result.handleCancel();
                  }
                }
              })
            }
            return true;
          })
          .onGeolocationShow(async (event) => {
            if (event) {
              // 应用级定位权限是Web定位的前提：未授权先拉起系统授权弹窗，被"禁止后不再询问"时提示用户前往设置
              const state = await regainPermission(hostContext(), ["ohos.permission.APPROXIMATELY_LOCATION"]);
              if (state === PermissionRequestState.GRANTED) {
                this.askLocation(event);
              } else if (state === PermissionRequestState.BLOCKED) {
                this.locationPermissionBlocked(event);
              } else {
                event.geolocation.invoke(event.origin, false, false);
              }
            }
          })

        if (this.loadError !== '') {
          Column() {
            Column() {
              Image($r('app.media.thinking'))
                .layoutWeight(1)
                .objectFit(ImageFit.Contain)
                .constraintSize({ maxWidth: '60%', maxHeight: 300 })
              Text($r('app.string.network_error'))
                .fontWeight(FontWeight.Bold)
                .fontSize(27)
                .fontColor($r('app.color.red'))
              Text($r('app.string.network_error_explain', this.loadError))
                .textAlign(TextAlign.Center)
                .margin({ top: 6, bottom: 10 })
              Row({ space: 6 }) {
                Button($r('app.string.back_to_last_page'))
                  .onClick(() => {
                    if (this.webviewController.accessBackward()) {
                      this.webviewController.backward();
                    } else {
                      this.webviewController.terminateRenderProcess();
                      this.pathStack.pop();
                    }
                  })
                Button($r('app.string.refresh'))
                  .onClick(() => {
                    this.webviewController.refresh();
                  })
                Button($r('app.string.close_this_hint'))
                  .onClick(() => {
                    this.loadError = '';
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.after_close') });
                  })
              }
            }
            .padding({ left: 12, right: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .hitTestBehavior(HitTestMode.Transparent);
        }

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
              .color($r('app.color.pink'));
            Text($r('app.string.loading'))
              .fontColor($r('app.color.pink'));
          }
          .visibility(this.loadingProgress === 100 ? Visibility.Hidden : Visibility.Visible);

          Row({ space: 5 }) {
            Text($r('app.string.downloading_d', this.downloadItemNum))
              .fontColor($r('app.color.pink'));
            Progress({ value: this.downloadPercent, total: 100, type: ProgressType.Ring })
              .color($r('app.color.pink'))
              .style({ strokeWidth: 4, enableScanEffect: true, shadow: true })
              .height(30);
          }
          .backgroundColor($r('app.color.grid_background'))
          .borderRadius(20)
          .padding({ left: 13, top: 5, right: 5, bottom: 5})
          .visibility(this.downloadItemTotal === 0 ? Visibility.Hidden : Visibility.Visible);
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Top)
        .width('100%')
        .padding({ left: 5, top: 5, right: 5 })
        .hitTestBehavior(HitTestMode.Transparent)
      }
      .layoutWeight(1)
    }
    .title(this.customTitle(), {
      backgroundColor: (BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : '#0000')
    })
    .hideBackButton(true)
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .backgroundColor(BackgroundImage.blurLevel === undefined ? undefined : '#0000')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;

      if (autoJumpUrl.includes(this.url))
        this.haveJumped = false;
    })
    .onBackPressed(() => {
      if (this.webviewController.accessStep(-1) && !this.webBackPress) {
        this.webviewController.backward();
        return true;
      } else {
        webName.pop();
        return false;
      }
    })
  }

  @Builder customTitle() {
    Row({ space: 6 }) {
      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.close'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .onClick(() => {
        webName.pop();
        this.webviewController.terminateRenderProcess();
        this.pathStack.pop();
      })

      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.back'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .parallelGesture(
        GestureGroup(
          GestureMode.Exclusive,
          TapGesture({ count: 1 })
            .onAction(() => {
              if (this.webviewController.accessBackward()) {
                this.webviewController.backward();
              } else {
                this.showMessage($r('app.string.already_first_page'), 500);
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

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.refresh'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .onClick(() => this.webviewController.refresh())

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.more_opinion'))
          .height(22)
          .draggable(false)
      }
      .bindMenu(this.WebviewMenu())
      .height(40)
      .width(40)
    }
    .padding({ left: 12, right: 12 })
    // .alignItems(VerticalAlign.Center)
    .height(56)
    .width('100%')
  }

  askLocation(event: OnGeolocationShowEvent) {
    let answered = false;
    const answer = (allow: boolean) => {
      if (answered)
        return;
      answered = true;
      // invoke的第三个参数表示是否记住当前弹窗的选择状态，如果传入true，则下次不再弹出对话框
      event.geolocation.invoke(event.origin, allow, false);
    };
    this.getUIContext().showAlertDialog({
      title: $r('app.string.location_permission_title'),
      message: $r('app.string.ask_location_permission', event.origin),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      primaryButton: {
        value: $r('app.string.no'),
        action: () => answer(false)
      },
      secondaryButton: {
        enabled: true,
        defaultFocus: true,
        style: DialogButtonStyle.HIGHLIGHT,
        value: $r('app.string.yes'),
        action: () => answer(true)
      },
      cancel: () => answer(false),
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason === DismissReason.PRESS_BACK || dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
          dismissDialogAction.dismiss();
          answer(false);
        }
      }
    });
  }

  locationPermissionBlocked(event: OnGeolocationShowEvent) {
    let denied = false;
    const deny = () => {
      if (denied)
        return;
      denied = true;
      event.geolocation.invoke(event.origin, false, false);
    };
    this.getUIContext().showAlertDialog({
      title: $r('app.string.location_permission_title'),
      message: $r('app.string.need_location_permission'),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => deny()
      },
      secondaryButton: {
        enabled: true,
        defaultFocus: true,
        style: DialogButtonStyle.HIGHLIGHT,
        value: $r('app.string.goto_system_settings'),
        action: () => {
          openPermissionSetting(hostContext(), ["ohos.permission.APPROXIMATELY_LOCATION"]).then((granted: boolean) => {
            if (granted)
              this.askLocation(event);
            else
              deny();
          });
        }
      },
      cancel: () => deny(),
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason === DismissReason.PRESS_BACK || dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
          dismissDialogAction.dismiss();
          deny();
        }
      }
    });
  }
}


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
  })
}