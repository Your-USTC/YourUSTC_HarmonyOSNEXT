
/**
 * 同步在线课表、考试页面
 */

import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

import { obtainedData } from '../constants/ScheduleSources';
import accountInfoProvider from '../utils/Encryption';
import PasswordDialog from '../view/PasswordDialog';
import { examInfoQueryJS, fillInformationJS, startTimeQueryJS, timeTableQueryJS, pollUntilLoad } from '../utils/TimeTable';
import UnifiedPreferences, { PASSWORD_KEY, REMIND_KEY, UID_KEY} from '../utils/UnifyPreference';

@Entry
@Component
struct Webview {

  // 内部变量
  webviewController: webview.WebviewController = new webview.WebviewController();
  title: string = '';
  url: string = '';
  isTimeTablePage: boolean = false;
  gotTimeTable: boolean = false;
  isExamInfoPage: boolean = false;
  gotExamInfo: boolean = false;
  obtainedData: obtainedData = {timeTable: '', startTime: '0'};
  webAutoDarkMode: boolean = UnifiedPreferences.getBoolSync('webAutoDarkMode', true);
  @State loadingProgress: number = 0;
  haveTriedLogin: boolean = false;
  autoGetFailed: boolean = false;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      isFromSetting: false,
      onConfirm: () => {
        this.webviewController.runJavaScript(fillInformationJS, (error, result) => {});
      }
    }),
    autoCancel: true
  });

  // Toast 消息
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

  // 初始化（传入参数）
  aboutToAppear() {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    if (params) {
      this.title = params.title ?? '';
      this.url = params.url ?? '';
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        // 退出
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(22)
          .draggable(false)
          .onClick(() => {
            console.info(`课表页面路由path：${this.getUIContext().getRouter().getLength()}`);
            if (this.obtainedData.startTime !== '0') {
              this.getUIContext().getRouter().back();
              return;
            }
            this.getUIContext().getRouter().back();
          })

        // 返回上一页
        Image($r('app.media.back'))
          .padding(({ left: 12, right: 4 }))
          .height(16)
          .draggable(false)
          .parallelGesture(GestureGroup(
            GestureMode.Exclusive,
            // 单击
            TapGesture({ count: 1 })
              .onAction(() => {
                if (this.webviewController.accessBackward()) {
                  this.webviewController.backward();
                } else {
                  this.getUIContext().getRouter().back();
                }
              }),
            // 长按
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
          ))

        Blank()

        // 标题
        Text(this.title)
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .height(48)

        Blank()

        // 刷新
        Image($r('app.media.refresh'))
          .padding({ right: 12 })
          .height(22)
          .draggable(false)
          .onClick(() => this.webviewController.refresh())

        // 手动同步
        Image($r('app.media.get'))
          .padding({ right: 12 })
          .height(22)
          .draggable(false)
          .onClick(() => {
            if (this.autoGetFailed) {
              if (this.isTimeTablePage && !this.gotTimeTable) {
                this.webviewController.runJavaScript(startTimeQueryJS, (error, result) => {
                  if (error) { /* 理论上这里不会出什么错误 */ return; }
                  this.obtainedData.startTime = result;
                });
                this.webviewController.runJavaScript(timeTableQueryJS, (error, result) => {
                  if (error) {
                    this.showMessage($r('app.string.get_timetable_err_msg'), 2000);
                    return;
                  }
                  if (result === 'null') {
                    this.showMessage($r('app.string.auto_get_timetable_fail_msg'), 2000);
                    return;
                  }
                  this.gotTimeTable = true;
                  this.obtainedData.timeTable = result;
                  this.getUIContext().getRouter().back({
                    params: this.obtainedData,
                    url: 'pages/Schedule'
                  });
                });
              }
              if (this.isExamInfoPage && !this.gotExamInfo) {
                this.webviewController.runJavaScript(examInfoQueryJS, (error, result) => {
                  if (error) {
                    this.showMessage($r('app.string.get_exam_info_err_msg'), 2000);
                    return;
                  }
                  if (result === 'null') {
                    this.showMessage($r('app.string.auto_get_exam_info_fail_msg'), 2000);
                    return;
                  }
                  this.gotExamInfo = true;
                  this.showMessage($r('app.string.get_exam_info_succ_msg'), 2000);
                  this.obtainedData.timeTable = result;
                  this.getUIContext().getRouter().back({
                    params: this.obtainedData,
                    url: 'pages/ExamDetail'
                  });
                })
              }
            } else {
              this.showMessage($r('app.string.auto_get_info'), 2000);
            }
          })
      }
      .id('header')
      .width('100%')
      .backgroundColor($r('app.color.shaded_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 网页浏览器（获取课标/考试信息）
      Stack({ alignContent: Alignment.TopStart}) {
        Web({
          src: 'https://id.ustc.edu.cn/cas/login?service=https://jw.ustc.edu.cn/ucas-sso/login',
          controller: this.webviewController
        })
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
          .darkMode(this.webAutoDarkMode ? WebDarkMode.Auto : WebDarkMode.Off)
          .forceDarkAccess(this.webAutoDarkMode)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .onLoadIntercept((event) => {
            if (event) {
              let url: string = event.data.getRequestUrl();
              if (url.indexOf('native://webview_error_backward') === 0) {
                if (this.webviewController.accessBackward()) {
                  this.webviewController.backward();
                } else {
                  this.getUIContext().getRouter().back();
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
          .onPageBegin(() => {
            this.isTimeTablePage = this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/for-std/course-table');
            this.isExamInfoPage = this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/for-std/exam-arrange');
            if (/*!this.isTimeTablePage &&*/ this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/home')) {
              this.webviewController.loadUrl(this.url);
              console.info(`${this.url}|xxx`);
            }
          })
          .onPageEnd(() => {
            if (!this.haveTriedLogin && this.webviewController.getUrl().startsWith('https://id.ustc.edu.cn/cas/login')) {
              this.haveTriedLogin = true;
              if (!(UnifiedPreferences.hasSync(UID_KEY) && UnifiedPreferences.hasSync(PASSWORD_KEY))) {
                if (UnifiedPreferences.getBoolSync(REMIND_KEY, true))
                 this.dialogController.open();
              } else {
                this.webviewController.runJavaScript(fillInformationJS, (error, result) => {
                  console.info(`自动填写uid：${UnifiedPreferences.getSync(UID_KEY)}`);
                });
              }
            }
            if (this.isTimeTablePage && !this.gotTimeTable) {
              this.webviewController.runJavaScript(startTimeQueryJS, (error, result) => {
                if (error) { /* 理论上这里不会出什么错误 */ return;}
                console.info(`学期开始的UNIX时间戳是${result}mm`); /* TODO: 保存开学时间到本地（需JSON.parse） */
                this.obtainedData.startTime = result;
                console.info(`转换后的时间戳是${this.obtainedData.startTime}`);
              });
              pollUntilLoad(() => this.webviewController.runJavaScript(timeTableQueryJS)).then((result) => {
                this.gotTimeTable = true;
                this.showMessage($r('app.string.get_timetable_succ_msg'), 2000);
                console.info(`课表是：${result}`);
                this.obtainedData.timeTable = result;
                this.getUIContext().getRouter().back({
                  params: this.obtainedData,
                  url: 'pages/Schedule'
                });
              });
            }
            if (this.isExamInfoPage && !this.gotExamInfo) {
              this.webviewController.runJavaScript(examInfoQueryJS, (error, result) => {
                if (error) {
                  this.showMessage($r('app.string.get_exam_info_err_msg'), 2000);
                  return;
                }
                if (result === 'null') {
                  this.showMessage($r('app.string.auto_get_exam_info_fail_msg'), 2000);
                  return;
                }
                this.gotExamInfo = true;
                this.showMessage($r('app.string.get_exam_info_succ_msg'), 2000);
                this.obtainedData.timeTable = result;
                this.getUIContext().getRouter().back({
                  params: this.obtainedData,
                  url: 'pages/ExamDetail'
                });
              })
            }
          })

        // 加载进度条
        Line()
          .visibility(this.loadingProgress == 100 ? Visibility.None : Visibility.Visible)
          .width(`${this.loadingProgress}%`)
          .height(5)
          .startPoint([0, 0])
          .backgroundColor($r('app.color.pink'))

        Row({ space: 5 }) {
          LoadingProgress()
            .width(45)
            .height(45)
            .color($r('app.color.pink'))
          Text($r('app.string.loading'))
            .fontColor($r('app.color.pink'))
        }
        .padding({ left: 5, top: 5 })
        .visibility(this.loadingProgress === 100 ? Visibility.None : Visibility.Visible);
      }
      .layoutWeight(1)
    }
  }
}
