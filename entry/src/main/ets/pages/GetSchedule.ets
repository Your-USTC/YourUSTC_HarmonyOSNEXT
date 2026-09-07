
import { webview } from '@kit.ArkWeb';
import ScheduleManager from '../utils/Classes/ScheduleManager';
import PasswordDialog from '../view/PasswordDialog';
import accountInfoProvider from '../utils/Encryption';
import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import { fillInformationJS, truncateString } from '../utils/tools';
import UnifiedPreferences, { PASSWORD_KEY, REMIND_KEY, UID_KEY}  from '../utils/UnifyPreference';
import { classAttribute, COVER_MODE, semesterAttribute } from '../constants/ScheduleSources';
import { ExceptionPrompt, MarginType } from '@kit.ArkUI';

@Builder
export function GetBuilder(name: string, param?: string[]) {
  if (param)
    Webview({ title: param[0], url: param[1] });
  else
    Webview();
}

const delay = (ms: number) => new Promise<void>(resolve => setTimeout(resolve, ms));
async function pollUntilLoad(callback: () => Promise<string>, intervalMs: number = 1000, maxAttempts: number = 30): Promise<string> {
  let result: string = 'null';
  while (result === 'null' && maxAttempts > 0) {
    result = await callback();
    maxAttempts--;
    if (result === 'null' && maxAttempts > 0) {
      await delay(intervalMs);
    }
  }
  return result;
}

const timeTableQueryJS = `
function getWeekNumber(str) {
    const parts = str.replace(/[^0-9,-]/g, '').split(',');
    const result = [];
    for (const part of parts) {
        if (part.includes('-')) {
            const [start, end] = part.split('-').map(Number);
            for (let i = start; i <= end; i++) {
                result.push(i);
            }
        } else {
            result.push(Number(part));
        }
    }
    return result;
}

function getTimeTable() {
    const timeTable = document.evaluate(
        "/html/body/div[2]/div[3]/div/div/table",
        document,
        null,
        XPathResult.FIRST_ORDERED_NODE_TYPE,
        null).singleNodeValue;
    const rows = timeTable.getElementsByTagName("tr");
    const getClassesOfDay = dayNumber => {
        let classesOfDay = [];
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].hasAttribute("class")) {
                const classesOfWeek = rows[i].getElementsByTagName("td");
                let count = 0;
                const target = Array.from(classesOfWeek).find(elem => {
                    if (!elem.hasAttribute("style")) { return ++count > dayNumber; }
                    return false;
                })
                const classList = Array.from(target.querySelectorAll(".c")).map(element => ({
                    name: element.querySelector(".title").innerText,
                    teacher: Array.from(element.querySelectorAll(".teacher .name")).map(elem => elem.innerText).join(", "),
                    weekOfTerm: getWeekNumber(element.querySelector(".time .week").innerText),
                    timeSpan: getWeekNumber(element.querySelector(".timespan").innerText),
                    dayOfWeek: dayNumber,
                    location: element.querySelector(".classroom .name").innerText.trim(),
                    id: element.querySelector(".number").innerText
                }));
                classesOfDay.push(classList);
            }
        }
        return classesOfDay;
    };
    return ([0, 1, 2, 3, 4, 5, 6].map(i => getClassesOfDay(i)));
}

JSON.stringify(getTimeTable());
`

const startTimeQueryJS = `
(() => {
  const startTime = new Date(document.getElementById('startDate').innerText);
  return startTime.setHours(0, 0, 0, 0);
})();
`

const getSemesterNameJS = `
function getSemesterText() {
    const targetElement = document.querySelector('.selectize-input.items.full.has-options.has-items .item');
    // 检查元素是否存在
    if (targetElement) {
        // 获取元素内的文本内容
        const semesterText = targetElement.textContent.trim();
        return semesterText;
    } else {
        // 未找到目标元素
        return '自定义名称';
    }
}

// 调用函数执行获取操作
getSemesterText();
`

const examInfoQueryJS = `
(() => {
    const examInfoTable = document.querySelector('#table-content');
    if (examInfoTable == null) {return null;}
    return Array.from(document.querySelectorAll('#exams tbody tr')).map(
        tr => {
            const trCells = tr.cells;
            return ({
                id: trCells[0].innerText,
                type: trCells[1].innerText,
                name: trCells[2].innerText,
                date: trCells[3].innerText,
                classroom: trCells[4].innerText,
                building: trCells[5].innerText,
                campus: trCells[6].innerText,
                info: trCells[7].innerText
            })
        }
    )
})()
`

@Entry
@Component
struct Webview {
  webviewController: webview.WebviewController = new webview.WebviewController();
  title: string = '';
  url: string = '';
  webBackPress: boolean = UnifiedPreferences.getBoolSync('webBackPress', true);
  isTimetablePage: boolean = false;
  isExamInfoPage: boolean = false;
  allowGet: boolean = false;
  timetable: string = '[[[]]]';
  startTime: number = 0;
  webAutoDarkMode: boolean = UnifiedPreferences.getBoolSync('webAutoDarkMode', true);
  @State loadingProgress: number = 0;
  haveTriedLogin: boolean = false;
  autoGetFailed: boolean = false;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      isFromSetting: false,
      onConfirm: () => {
        this.haveTriedLogin = true;
        this.webviewController.runJavaScript(fillInformationJS);
      }
    }),
    autoCancel: false
  })


  pathStack: NavPathStack = new NavPathStack();
  @State loadError: string = '';
  @State showGetHint: boolean = true;
  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Web({ src: 'https://id.ustc.edu.cn/cas/login?service=https://jw.ustc.edu.cn/ucas-sso/login', controller: this.webviewController })
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
          .backgroundColor(BackgroundImage.blurLevel === undefined ? undefined : '#0000')
          .onErrorReceive((event) => {
            // Only handle loading errors of the main framework to avoid duplicate processing of errors in sub-resources
            this.loadError = event.error.getErrorInfo();
          })
          .onProgressChange((event) => {
            this.loadingProgress = event.newProgress;
          })
          .onPageBegin(() => {
            this.loadError = '';
            this.isTimetablePage = this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/for-std/course-table');
            this.isExamInfoPage = this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/for-std/exam-arrange');
            if ( /*!this.isTimetablePage &&*/ this.webviewController.getUrl().startsWith('https://jw.ustc.edu.cn/home')) {
              this.webviewController.loadUrl(this.url);
              console.info(`${this.url}|xxx`);
            }
          })
          .onPageEnd(() => {
            if (!this.haveTriedLogin && this.webviewController.getUrl().startsWith('https://id.ustc.edu.cn/cas/login')) {
              if (!(UnifiedPreferences.hasSync(UID_KEY) && UnifiedPreferences.hasSync(PASSWORD_KEY))) {
                if (UnifiedPreferences.getBoolSync(REMIND_KEY, true))
                  this.dialogController.open();
              } else {
                this.haveTriedLogin = true;
                this.webviewController.runJavaScript(fillInformationJS, (error, result) => {
                  console.info(`自动填写uid：${UnifiedPreferences.getSync(UID_KEY)}`);
                });
              }
            }

            if (this.isTimetablePage) {
              pollUntilLoad(() => this.webviewController.runJavaScript(timeTableQueryJS))
                .then((result: string) => {
                  if (result !== 'null') {
                    this.allowGet = true;
                    this.timetable = result;
                    return;
                  }
                });
            }

            if (this.isExamInfoPage) {
              this.webviewController.runJavaScript(examInfoQueryJS, (error, result) => {
                if (error) {
                  this.allowGet = true;
                  this.getUIContext().getPromptAction().showToast({ message: $r('app.string.get_exam_info_err_msg'), duration: 2000 });
                  return;
                }
                if (result === 'null') {
                  this.allowGet = true;
                  this.getUIContext().getPromptAction().showToast({ message: $r('app.string.auto_get_exam_info_fail_msg'), duration: 2000 });
                  return;
                }
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.get_exam_info_succ_msg'), duration: 2000 });
                this.pathStack.pop(result);
              })
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
                .fontSize(30)
                .fontColor($r('app.color.red'))
              Text($r('app.string.network_error_explain', this.loadError))
                .textAlign(TextAlign.Center)
                .margin({ top: 6, bottom: 10 })
                .fontColor(this.webAutoDarkMode ? $r('app.color.normal_text') : '#000000')
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
        }

        if (this.url.startsWith('https://jw.ustc.edu.cn/for-std/course-table')) {
          ExceptionPrompt({
            options: {
              tip: $r('app.string.get_schedule_hint'),
              marginType: MarginType.DEFAULT_MARGIN,
              marginTop: 7,
              isShown: this.showGetHint,
              icon: $r('app.media.lightbulb')
            },
            onTipClick: () => this.showGetHint = false
          })
        }

        Line()
          .visibility(this.loadingProgress == 100 ? Visibility.None : Visibility.Visible)
          .width(`${this.loadingProgress}%`)
          .height(5)
          .startPoint([0, 0])
          .backgroundColor($r('app.color.pink'));
        Row({ space: 5 }) {
          LoadingProgress()
            .width(45)
            .height(45)
            .color($r('app.color.pink'));
          Text($r('app.string.loading'))
            .fontColor($r('app.color.pink'));
        }
        .padding({ left: 5, top: 5 })
        .visibility(this.loadingProgress === 100 ? Visibility.None : Visibility.Visible);
      }
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title(this.customTitle(), {
      backgroundColor: (BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : '#0000')
    })
    .hideBackButton(true)
    .backgroundColor('#0000')
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .onBackPressed(() => {
      this.webviewController.terminateRenderProcess();
      if (this.isTimetablePage) {
        this.pathStack.pop(this.selectIndex);
        return true;
      } else
        return false;
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
        this.webviewController.terminateRenderProcess();
        this.pathStack.pop(this.selectIndex);
      })

      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.refresh'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .onClick(() => this.webviewController.refresh())

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.get'))
          .height(22)
          .draggable(false)
      }
      .height(40)
      .width(40)
      .onClick(() => {
        if (!this.allowGet) {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.do_not_worry'), duration: 1500 });
        } else if (this.isTimetablePage) {
          // 异步执行回调，所以要嵌套执行
          this.webviewController.runJavaScript(startTimeQueryJS, (error, result) => { // 此处返回值没有双引号
            if (error) { /* 理论上这里不会出什么错误 */
              return;
            }
            this.startTime = Number(result);
            this.webviewController.runJavaScript(getSemesterNameJS, (error, result) => {
              if (error) {
                this.semesterName = '自定义名称';
                return;
              }
              this.semesterName = result.replace(/^["']|["']$/g, '').replace(/\\/g, '');
              this.webviewController.runJavaScript(timeTableQueryJS, (error, result) => {
                if (!error && result)
                  this.timetable = result.replace(/^["']|["']$/g, '').replace(/\\/g, '');
                else
                  this.timetable = '[[[]]]';
                this.showSelectTerm = true;
              });
            });
          });
        } else if (this.isExamInfoPage) {
          this.webviewController.runJavaScript(examInfoQueryJS, (error, result) => {
            if (error) {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.get_exam_info_err_msg'), duration: 2000 });
              return;
            }
            if (result === 'null') {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.auto_get_exam_info_fail_msg'), duration: 2000 });
              return;
            }
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.get_exam_info_succ_msg'), duration: 2000 });
            this.pathStack.pop(result);
          });
        } else {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.do_not_worry'), duration: 1500 });
        }
      })
      .bindSheet($$this.showSelectTerm, this.selectTerm(), {
        detents: [SheetSize.LARGE],
        preferType: SheetType.CENTER,
        backgroundColor: '#0000',
        blurStyle: BlurStyle.Regular,
        enableOutsideInteractive: false,
        enableFloatingDragBar: true,
        title: { title: '嘿咻——拿到啦！', subtitle: '新建或选择已有学期以保存课表' }
      })
    }
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .height(56)
    .width('100%')
  }

  @State showSelectTerm: boolean = false;
  @State semesterName: string = '自定义名称';
  @State selectIndex: number = ScheduleManager.displaySemester;
  @State semesters: semesterAttribute[] = ScheduleManager.semesters;

  @Builder selectTerm() {
    Column() {
      Row() {
        Text('名称')
          .margin({ left: 40 })
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
        Text('学期开始日期')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 6 })
      .width('100%')

      Scroll() {
        Column() {
          Row({ space: 5 }) {
            Image($r('app.media.add'))
              .width(25)
              .height(25)
            Text($r('app.string.new_semester', this.semesterName))
              .layoutWeight(1)
            Text(new Date(this.startTime).toLocaleString('zh-cn', { year: 'numeric', month: '2-digit', day: '2-digit'}))
          }
          .height(50)
          .width('100%')
          .onClick(() => {
            ScheduleManager.newSemester(this.semesterName, '从教务系统导入', this.startTime, Date.now(), undefined, ScheduleManager.parseOnlineSchedule(JSON.parse(this.timetable) as classAttribute[][][], true));
            this.semesters = ScheduleManager.semesters;
            this.selectIndex = this.semesters.length - 1;
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.have_saved', truncateString(this.semesterName, 10)) })
          })

          ForEach(this.semesters, (singleTerm: semesterAttribute, index: number) => {
            Divider();

            Row({ space: 5 }) {
              Image($r('app.media.selected'))
                .width(25)
                .height(25)
                .visibility(index === this.selectIndex ? Visibility.Visible : Visibility.Hidden);
              Text(singleTerm.name)
                .layoutWeight(1)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(new Date(singleTerm.beginTime).toLocaleString('zh-cn', { year: 'numeric', month: '2-digit', day: '2-digit'}))
            }
            .alignItems(VerticalAlign.Center)
            .height(50)
            .width('100%')
            .onClick(() => {
              this.selectIndex = index;
            })
          })
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
      }
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .width('100%')
      .align(Alignment.Top)
      .layoutWeight(1)

      Text($r('app.string.retain_color_priority'))
        .margin({ top: 5, bottom: 5 })

      Row() {
        Button($r('app.string.append'))
          .buttonStyle(ButtonStyleMode.NORMAL)
          .fontColor(presetColor[BackgroundImage.themeColor][2])
          .width('25%')
          .onClick(() => {
            ScheduleManager.coverExistSemester(this.selectIndex, ScheduleManager.parseOnlineSchedule(JSON.parse(this.timetable) as classAttribute[][][]), COVER_MODE.APPEND, true);
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.have_appended', truncateString(this.semesters[this.selectIndex].name, 10)) });
          })

        Button($r('app.string.cover'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor(presetColor[BackgroundImage.themeColor][2])
          .width('25%')
          .onClick(() => {
            ScheduleManager.coverExistSemester(this.selectIndex, ScheduleManager.parseOnlineSchedule(JSON.parse(this.timetable) as classAttribute[][][]), COVER_MODE.COVER, true);
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.have_covered', truncateString(this.semesters[this.selectIndex].name, 10)) });
          })

        Button($r('app.string.cover_duplicate'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .backgroundColor(presetColor[BackgroundImage.themeColor][2])
          .width('50%')
          .onClick(() => {
            ScheduleManager.coverExistSemester(this.selectIndex, ScheduleManager.parseOnlineSchedule(JSON.parse(this.timetable) as classAttribute[][][]), COVER_MODE.COVER_DUPLICATE, true);
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.have_covered', truncateString(this.semesters[this.selectIndex].name, 10)) });
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
  }
}