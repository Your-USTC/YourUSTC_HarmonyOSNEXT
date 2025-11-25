
import { preferences } from '@kit.ArkData';
import * as tools from '../utils/tools';
import scheduleManager from '../utils/TimeTable';


// 课程信息类型
export interface classAttribute {
  name: string,
  teacher: string,
  weekOfTerm: number[],    // 以枚举形式写出哪几周
  timeSpan: number[],      // 应当仅包含开始和结束是第几节课
  dayOfWeek: number,
  location: string,
  id: string,
  color: string
}

export interface obtainedData {
  timeTable: string;
  startTime: string;
}

let schedulePre: preferences.Preferences | null = null;
export let remindBefore: number[] = [];
export let examRemindBefore: number[] = [];

export function initSchedulePre(curContext: Context | undefined) {
  try {
    schedulePre = preferences.getPreferencesSync(curContext, { name: 'ScheduleInfo' });
    remindBefore[0] = schedulePre.getSync('remindBefore', 0) as number;
    if (remindBefore[0] == -1)
      remindBefore = [];
    examRemindBefore[0] = schedulePre.getSync('examRemindBefore', 0) as number;
    if (examRemindBefore[0] == -1)
      examRemindBefore = [];
  } catch (error) {
    console.error(`Get preferences sync ERROR: [${error.name}] ${error.message}`)
  }
}

export function setRemindBefore(minute: number) {
  if (minute == -1)
    remindBefore = [];
  else
    remindBefore[0] = minute;
  try {
    schedulePre?.putSync('remindBefore', minute);
  } catch (error) {
    console.error(`put sync ERROR: [${error.name}] ${error.message}`)
  }
  schedulePre?.flush()
    .catch((error: Error) => {
      console.error(`flush ERROR: [${error.name}] ${error.message}`)
    })
}

export function setExamRemindBefore(minute: number) {
  if (minute == -1)
    examRemindBefore = [];
  else
    examRemindBefore[0] = minute;
  try {
    schedulePre?.putSync('examRemindBefore', minute);
  } catch (error) {
    console.error(`put sync ERROR: [${error.name}] ${error.message}`)
  }
  schedulePre?.flush()
    .catch((error: Error) => {
      console.error(`flush ERROR: [${error.name}] ${error.message}`)
    })
}

// 第几节课 -> 上课时间
export const commonClassTime: string[][] = [
  ['07:21', '11:45'],    // 排除[0]
  ['07:50', '08:35'], ['08:40', '09:25'], ['09:45', '10:30'], ['10:35', '11:20'], ['11:25', '12:10'],    // 上午
  ['14:00', '14:45'], ['14:50', '15:35'], ['15:55', '16:40'], ['16:45', '17:30'], ['17:35', '18:20'],    // 下午
  ['19:30', '20:15'], ['20:20', '21:05'], ['21:10', '21:55']    // 晚上
];

export const commonClassStamp: number[][]= [
  [26460000, 42300000],
  [28200000, 30900000], [31200000, 33900000], [35100000, 37800000], [38100000, 40800000], [41000000, 43800000],
  [50400000, 53100000], [53400000, 56100000], [57300000, 60000000], [60300000, 63000000], [63300000, 66000000],
  [70200000, 72900000], [73200000, 75900000], [76200000, 78900000]
];


@Entry
@Component
struct Schedule {
  @State weekDisplayed: number = 0;
  @State termStart: number = 0;
  @State weekStart: number = 0;
  @State weekEnd: number = 0;
  @State thisWeekSchedule: classAttribute[][] = []; // 第一层：星期几(0-6)；第三层：每天的所有课，不一定按顺序

  onPageShow(): void {
    const currentTime: Date = new Date();
    const routerParams = this.getUIContext().getRouter().getParams() as obtainedData;
    scheduleManager.refreshParsedSchedule(routerParams);
    scheduleManager.getFormattedSchedule();
    this.termStart = scheduleManager.termStart;
    this.weekDisplayed = scheduleManager.weekDisplayed;
    this.weekStart = scheduleManager.weekStart;
    this.weekEnd = scheduleManager.weekEnd;
    this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];

    // TODO: 将 weekStart 和 weekEnd 存入首选项
    console.info(`课表 weekDisplayed: ${this.weekDisplayed}`)
    console.info(`课表 currentTime: ${tools.timestampToDateTime(currentTime.getTime())}`)
    console.info(`课表 termStart: ${tools.timestampToDateTime(this.termStart)}`)
    console.info(`课表 weekStart: ${tools.timestampToDateTime(this.weekStart)}`)
    console.info(`课表 weekEnd: ${tools.timestampToDateTime(this.weekEnd)}`)
  }

  ShowClassDetail: CustomDialogController | null = null;
  aboutToDisappear(): void {
    this.ShowClassDetail = null;  // 在自定义组件即将析构销毁时将ShowClassDetail置空
  }

  build() {
    Column() {
      /**
       * Header
       */
      Row() {
        Image($r('app.media.close'))
          .padding({left: 12, right: 32})
          .height(20)
          .draggable(false)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

        Blank()

        Text($r('app.string.local_schedule'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))
          .height(48)

        Blank()

        Image($r('app.media.plus_square'))
          .padding({right: 12})
          .height(20)
          .draggable(false)
          .onClick(() => {
            this.ShowClassDetail = null;
            this.ShowClassDetail = new CustomDialogController({
              builder: ClassDetailDialog({
                toChange: this.thisWeekSchedule,
                weekDisplayed: this.weekDisplayed,
                isChangeSchedule: false
              }),
              autoCancel: true,
              gridCount: 4,
              onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
                if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
                  dismissDialogAction.dismiss();
                }
                if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
                  dismissDialogAction.dismiss();
                }
              }
            })
            if (this.ShowClassDetail != null) {
              this.ShowClassDetail.open();
            }
          })

        Image($r('app.media.get'))
          .padding({right: 12})
          .height(20)
          .draggable(false)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/GetSchedule',
              params: { title: $r('app.string.online_schedule'), url: 'https://jw.ustc.edu.cn/for-std/course-table'}
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.shaded_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      /**
       * 周数信息与翻页
       */
      Row() {
        Text(
          tools.timestampToDateTime(this.weekStart)
            + ' ~ '
            + tools.timestampToDateTime(this.weekEnd)
        )
          .id('week_of_term_span')
          .fontWeight(FontWeight.Bold)
          .fontSize(14)

        Blank()

        Image(this.weekDisplayed == 1 ? $r('app.media.arrow_left_circle_unavailable') : $r('app.media.arrow_left_circle'))
          .height(18)
          .width(40)
          .objectFit(ImageFit.Contain)
          .draggable(false)
          .onClick(() => {
            if (this.weekDisplayed > 1) {
              this.weekDisplayed--;
              this.weekStart -= 604800000;
              this.weekEnd -= 604800000;
              this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];
            }
          })

        Text($r('app.string.week_of_term_no_d', this.weekDisplayed))
          .id('week_of_term_no')
          .fontWeight(FontWeight.Bold)
          .fontSize(14)

        Image(this.weekDisplayed == 20 ? $r('app.media.arrow_right_circle_unavailable') : $r('app.media.arrow_right_circle'))
          .height(18)
          .width(40)
          .objectFit(ImageFit.Contain)
          .draggable(false)
          .onClick(() => {
            if (this.weekDisplayed < 20) {
              this.weekDisplayed++;
              this.weekStart += 604800000;
              this.weekEnd += 604800000;
              this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];
            }
          })
      }
      .width('100%')
      .height(30)
      .padding({ left: 20, right: 10 })
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.grid_background'))
      .border({
        width: { bottom: 1 },
        color: $r('app.color.grid_border')
      })

      /**
       * 课表
       */
      Grid() {
        /**
         * 表头
         */
        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.sunday'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(0)
        .rowEnd(0)
        .columnStart(2)
        .columnEnd(2)
        .padding(1)
        .border({
          width: { bottom: 1, left: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.monday'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(0)
        .rowEnd(0)
        .columnStart(3)
        .columnEnd(3)
        .padding(1)
        .border({
          width: { bottom: 1, left: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.tuesday'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(0)
        .rowEnd(0)
        .columnStart(4)
        .columnEnd(4)
        .padding(1)
        .border({
          width: { bottom: 1, left: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.wednesday'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(0)
        .rowEnd(0)
        .columnStart(5)
        .columnEnd(5)
        .padding(1)
        .border({
          width: { bottom: 1, left: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.thursday'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(0)
        .rowEnd(0)
        .columnStart(6)
        .columnEnd(6)
        .padding(1)
        .border({
          width: { bottom: 1, left: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.friday'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(0)
        .rowEnd(0)
        .columnStart(7)
        .columnEnd(7)
        .padding(1)
        .border({
          width: { bottom: 1, left: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.saturday'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(0)
        .rowEnd(0)
        .columnStart(8)
        .columnEnd(8)
        .padding(1)
        .border({
          width: { bottom: 1, left: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.morning'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(1)
        .rowEnd(5)
        .columnStart(0)
        .columnEnd(0)
        .padding(1)
        .backgroundColor($r('app.color.grid_background'))
        .border({
          width: { top: 1, right: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.afternoon'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(6)
        .rowEnd(10)
        .columnStart(0)
        .columnEnd(0)
        .padding(1)
        .backgroundColor($r('app.color.grid_background'))
        .border({
          width: { top: 1, right: 1 },
          color: $r('app.color.grid_border')
        })

        GridItem({ style: GridItemStyle.NONE }) {
          Text($r('app.string.evening'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
        }
        .rowStart(11)
        .rowEnd(13)
        .columnStart(0)
        .columnEnd(0)
        .padding(1)
        .backgroundColor($r('app.color.grid_background'))
        .border({
          width: { top: 1, right: 1 },
          color: $r('app.color.grid_border')
        })

        ForEach(tools.getContArray([[1, 13]]), (item: number) => {
          GridItem({ style: GridItemStyle.NONE }) {
            Column() {
              Text(commonClassTime[item][0])
                .fontSize('8fp')

              Blank()

              Text(item.toString())
                .fontWeight(FontWeight.Bold)
                .fontSize(14)

              Blank()

              Text(commonClassTime[item][1])
                .fontSize('8fp')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 2, bottom: 2 })
          }
          .rowStart(item)
          .rowEnd(item)
          .columnStart(1)
          .columnEnd(1)
          .padding(1)
          .border({
            width: { top: 1, right: 1 },
            color: $r('app.color.grid_border')
          });
        })

        /**
         * 课程内容
         */
        if (this.thisWeekSchedule.length === 0 || this.thisWeekSchedule.every(subArr => subArr.length === 0))
          GridItem({style:GridItemStyle.NONE}){
            Column() {
              Image($r('app.media.no_course_this_week'))
                .height(100)
                .width(100)
                .draggable(false)
              Text($r('app.string.no_class_this_week')).fontSize(18).textAlign(TextAlign.Center);
            }
          }
          .rowStart(1)
          .rowEnd(11)
          .columnStart(2)
          .columnEnd(8);
        else
          ForEach(this.thisWeekSchedule, (course: classAttribute[], indexDay) => {
            ForEach(course, (lesson: classAttribute) => {
              GridItem({ style: GridItemStyle.PLAIN }) {
                Column() {
                  Text(lesson.name)
                    .fontWeight(FontWeight.Bold)
                    .fontSize(13)
                    .fontColor($r('app.color.normal_text'))
                    .maxLines(4)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(lesson.location)
                    .fontSize(9)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.MARQUEE })

                  Text(lesson.teacher)
                    .fontSize(9)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.MARQUEE })
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
              }
              .onClick(() => {
                let oriLesson: classAttribute = {
                  name: lesson.name,
                  teacher: lesson.teacher,
                  weekOfTerm: [...lesson.weekOfTerm],    // 以枚举形式写出哪几周
                  timeSpan: [...lesson.timeSpan],      // 应当仅包含开始和结束是第几节课
                  dayOfWeek: lesson.dayOfWeek,
                  location: lesson.location,
                  id: lesson.id,
                  color: lesson.color
                };
                let editLesson: classAttribute = {
                  name: lesson.name,
                  teacher: lesson.teacher,
                  weekOfTerm: [...lesson.weekOfTerm],    // 以枚举形式写出哪几周
                  timeSpan: [...lesson.timeSpan],      // 应当仅包含开始和结束是第几节课
                  dayOfWeek: lesson.dayOfWeek,
                  location: lesson.location,
                  id: lesson.id,
                  color: lesson.color
                };
                let rectifyWeekOfTerm: boolean[] = [];
                for (let weekRepeat = 1; weekRepeat <= 20; weekRepeat++)
                  rectifyWeekOfTerm[weekRepeat] = false;
                for (let weekRepeat of lesson.weekOfTerm)
                  rectifyWeekOfTerm[weekRepeat] = true;
                this.ShowClassDetail = null;
                this.ShowClassDetail = new CustomDialogController({
                  builder: ClassDetailDialog({
                    toChange: this.thisWeekSchedule,
                    classInfo: editLesson,
                    oriClassInfo: oriLesson,
                    weekDisplayed: this.weekDisplayed,
                    rectifyTimeSpan: [oriLesson.timeSpan[0], oriLesson.timeSpan[oriLesson.timeSpan.length - 1]],
                    rectifyWeekOfTerm: rectifyWeekOfTerm,
                    weekOfTerm: [...editLesson.weekOfTerm]
                  }),
                  autoCancel: true,
                  gridCount: 4,
                  onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
                    if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
                      dismissDialogAction.dismiss();
                    }
                    if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
                      dismissDialogAction.dismiss();
                    }
                  }
                })
                if (this.ShowClassDetail != null) {
                  this.ShowClassDetail.open();
                }
              })
              .rowStart(lesson.timeSpan[0])
              .rowEnd(lesson.timeSpan[lesson.timeSpan.length - 1])
              .columnStart((indexDay + 1) % 7 + 2)
              .columnEnd((indexDay + 1) % 7 + 2)
              .padding(2)
              .backgroundColor(lesson.color)
              .border({
                width: 1,
                color: $r('app.color.grid_border')
              });
            });
          });
      }
      .id('schedule_grid')
      .columnsTemplate('1fr 1fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr')    // 8 列
      .rowsTemplate('1fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr')    // 14 行
      .margin({ bottom: 48 })
      .padding(0)

    }
    .height('100%')
    .width('100%')
  }
}

@CustomDialog
@Component
struct ClassDetailDialog {
  @Link toChange: classAttribute[][];
  classInfo: classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2',
    weekOfTerm: tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[], timeSpan: [6, 7], dayOfWeek: 0,
    color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)] };
  oriClassInfo: classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2',
    weekOfTerm: tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[], timeSpan: [6, 7], dayOfWeek: 0,
    color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)] };

  controller?: CustomDialogController;
  weekDisplayed: number = 1;
  isChangeSchedule: boolean = true;
  rectifyTimeSpan: number[] = [this.oriClassInfo.timeSpan[0], this.oriClassInfo.timeSpan[this.oriClassInfo.timeSpan.length - 1]];
  rectifyWeekOfTerm: boolean[] = [true, false, true, true, true, false, true, true, true, true, true,
    false, false, false, true, true, true, false, false, false, false];
  @State isOkButtonEnabled: boolean = true;
  @State weekOfTerm: number[] = tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[];
  @State isColorLegal: boolean = true;
  scroller: Scroller = new Scroller();

  private createArray = (start: number, end: number): Array<SelectOption> => {
    const arr: Array<SelectOption> = [];
    for (let i = start; i <= end; i++) {
      arr.push({ value: i.toString() });
    }
    return arr;
  };


  build() {
    Column() {
      Row() {
        if (this.isChangeSchedule) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.trash_red'))
              .width(24)
              .height(24)
              .draggable(false)
          }
          .onClick(() => {
            scheduleManager.deleteSchedule(this.oriClassInfo);
            this.toChange = scheduleManager.formattedSchedule[this.weekDisplayed];
            if (this.controller != undefined) {
              this.controller.close();
            }
          })
          .height(42)
          .width(42);
        }
        Blank();

        Text(this.isChangeSchedule ? $r('app.string.class_detail') : $r('app.string.class_detail_new'))
          .fontSize(24)
          .fontWeight("bold")
          .textAlign(TextAlign.Center)
          .height(42);

        Blank();
        if (this.isChangeSchedule) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.copy'))
              .width(24)
              .height(24)
              .draggable(false)
          }
          .onClick(() => {
            this.classInfo.weekOfTerm = [];
            for (let weekRepeat = 1; weekRepeat <= 20; weekRepeat++)
              if (this.rectifyWeekOfTerm[weekRepeat])
                this.classInfo.weekOfTerm.push(weekRepeat);
            if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
              let swapTemp = this.rectifyTimeSpan[0];
              this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
              this.rectifyTimeSpan[1] = swapTemp;
            }
            this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
            scheduleManager.addSchedule(this.classInfo);
            this.toChange = scheduleManager.formattedSchedule[this.weekDisplayed];
            if (this.controller != undefined) {
              this.controller.close();
            }
          })
          .height(42)
          .width(42)
          .enabled(this.isOkButtonEnabled);
        }
      }
      .width('100%');

      Scroll(this.scroller) {
        Column() {
          Row() {
            Text($r('app.string.class_detail_name'));
            TextInput({ text: this.classInfo.name })
              .layoutWeight(1)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.name = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_teacher'));
            TextInput({ text: this.classInfo.teacher })
              .layoutWeight(1)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.teacher = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_location'));
            TextInput({ text: this.classInfo.location })
              .layoutWeight(1)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.location = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_id'));
            TextInput({ text: this.classInfo.id })
              .layoutWeight(1)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.id = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_time'))
              .textAlign(TextAlign.Start);
            Select(this.createArray(1, 13))
              .value(this.rectifyTimeSpan[0].toString())
              .onSelect((index: number) => {
                this.rectifyTimeSpan[0] = index + 1;
              });
            Text(' ~ ');
            Select(this.createArray(1, 13))
              .value(this.rectifyTimeSpan[1].toString())
              .onSelect((index: number) => {
                this.rectifyTimeSpan[1] = index + 1;
              });
          }
          .margin({ bottom: 5 })

          Row() {
            Text($r('app.string.class_detail_day_of_week'))
              .textAlign(TextAlign.Start);
            Select([{ value: $r('app.string.monday') }, { value: $r('app.string.tuesday') },
              { value: $r('app.string.wednesday') },
              { value: $r('app.string.thursday') }, { value: $r('app.string.friday') },
              { value: $r('app.string.saturday') }, { value: $r('app.string.sunday') }])
              .value(`${this.classInfo.dayOfWeek + 1}`)
              .onSelect((index: number) => {
                this.classInfo.dayOfWeek = index;
              });
          }
          .margin({ bottom: 5 })

          Row() {
            Text($r('app.string.class_detail_color'))
              .textAlign(TextAlign.Start);
            Stack({ alignContent: Alignment.End }) {
              TextInput({ text: this.classInfo.color })
                .textOverflow(TextOverflow.Ellipsis)
                .onChange((input: string) => {
                  this.classInfo.color = input;
                  if (/^#([A-Fa-f0-9]{3}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(input)) {
                    this.isColorLegal = true;
                    this.isOkButtonEnabled = true;
                  } else {
                    this.isColorLegal = false;
                    this.isOkButtonEnabled = false;
                  }
                })
                .width('100%')
                .selectAll(true);
              Circle()
                .fill(this.isColorLegal ? this.classInfo.color : '#00000000')
                .width(25)
                .height(25)
                .margin({ right: 8 })
                .stroke(this.isColorLegal ? $r('app.color.grid_border') : $r('app.color.red'));
            }
            .layoutWeight(1)
          }
          .margin({ bottom: 5 })

          Row() {
            Text($r('app.string.class_detail_weeks', tools.shrinkContArrayToString(this.weekOfTerm)))
              .textAlign(TextAlign.Start)
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            CheckboxGroup({ group: 'checkboxGroup' })
              .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
              .onChange((itemName: CheckboxGroupResult) => {
                for (let checkboxRepeat = 1; checkboxRepeat <= 20; checkboxRepeat++) {
                  this.rectifyWeekOfTerm[checkboxRepeat] = false;
                }
                let selectAny: boolean = false;
                for (let checkboxRepeat of itemName.name) {
                  this.rectifyWeekOfTerm[Number(checkboxRepeat)] = true;
                  selectAny = true;
                }
                this.isOkButtonEnabled = selectAny;
                this.weekOfTerm = [];
                for (let weekRepeat = 1; weekRepeat <= 20; weekRepeat++) {
                  if (this.rectifyWeekOfTerm[weekRepeat]) {
                    this.weekOfTerm.push(weekRepeat);
                  }
                }
              });
            Text($r('app.string.select_all'));
          }
          .width('100%');

          ForEach(tools.getContArray([[0, 3]]), (checkboxId: number) => {
            Row() {
              ForEach(tools.getContArray([[1, 5]]), (checkboxId2: number) => {
                Checkbox({ name: (checkboxId * 5 + checkboxId2).toString(), group: 'checkboxGroup' })
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .select(this.rectifyWeekOfTerm[checkboxId * 5 + checkboxId2]);
                Text((checkboxId * 5 + checkboxId2).toString()).width('8%');
              })
            }
          });
        }
        .alignItems(HorizontalAlign.Start)
        .width('80%');
      }
      .width('100%')
      .layoutWeight(1)
      .constraintSize({ maxHeight: 480 })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring);

      Row() {
        Button($r('app.string.cancel'))
          .onClick(() => {
            if (this.controller != undefined)
              this.controller.close();
          })
          .width('50%')
          .buttonStyle(ButtonStyleMode.TEXTUAL);

        Button($r('app.string.ok'))
          .onClick(() => {
            this.classInfo.weekOfTerm = [];
            for (let weekRepeat = 1; weekRepeat <= 20; weekRepeat++)
              if (this.rectifyWeekOfTerm[weekRepeat])
                this.classInfo.weekOfTerm.push(weekRepeat);
            if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
              let swapTemp = this.rectifyTimeSpan[0];
              this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
              this.rectifyTimeSpan[1] = swapTemp;
            }
            this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
            if (this.isChangeSchedule)
              scheduleManager.deleteSchedule(this.oriClassInfo);
            scheduleManager.addSchedule(this.classInfo);
            this.toChange = scheduleManager.formattedSchedule[this.weekDisplayed];
            if (this.controller != undefined)
              this.controller.close();
          })
          .width('50%')
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .enabled(this.isOkButtonEnabled);
      }
      .margin({ top: 10 });

    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.grid_background'));
  }
}