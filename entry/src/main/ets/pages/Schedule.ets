
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
  id: string
}

export interface obtainedData {
  timeTable: string;
  startTime: string;
}

let schedulePre: preferences.Preferences | null = null;
export let remindBefore: number[] = [];

export function initSchedulePre(curContext: Context | undefined) {
  try {
    schedulePre = preferences.getPreferencesSync(curContext, { name: 'ScheduleInfo' });
    remindBefore[0] = schedulePre.getSync('remindBefore', 0) as number;
    if (remindBefore[0] == -1)
      remindBefore = [];
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

// 第几节课 -> 上课时间
export const commonClassTime: string[][] = [
  ['07:21', '11:45'],    // 排除[0]
  ['07:50', '08:35'], ['08:40', '09:25'], ['09:45', '10:30'], ['10:35', '11:20'], ['11:25', '12:05'],    // 上午
  ['14:00', '14:45'], ['14:50', '15:35'], ['15:55', '16:40'], ['16:45', '17:30'], ['17:35', '18:20'],    // 下午
  ['19:30', '20:15'], ['20:20', '21:05'], ['21:10', '21:55']    // 晚上
];

export const commonClassStamp: number[][]= [
  [26460000, 42300000],
  [28200000, 30900000], [31200000, 33900000], [35100000, 37800000], [38100000, 40800000], [41000000, 43500000],
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
          .padding({left: 12})
          .height(20)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

        Image($r('app.media.empty')) // 让标题居中
          .padding({left: 12})
          .height(20)

        Blank()

        Text($r('app.string.local_schedule'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))

        Blank()

        Image($r('app.media.plus_square'))
          .padding({right: 12})
          .height(20)
          .onClick(() => {
            let lesson: classAttribute = {teacher:'暂无', name:"暂无",location:"暂无",id:"暂无",weekOfTerm: [9], dayOfWeek: 6,timeSpan:[1,2]};
            this.ShowClassDetail = new CustomDialogController({
              builder: ClassDetailDialog({
                toChange: this.thisWeekSchedule,
                classInfo: lesson,
                oriClassInfo: lesson,
                weekDisplayed: this.weekDisplayed
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
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/Webview',
              params: { title: $r('app.string.online_schedule'), url: 'https://jw.ustc.edu.cn/for-std/course-table'}
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.shaded_background'))

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
          Text($r('app.string.monday'))
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
          Text($r('app.string.tuesday'))
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
          Text($r('app.string.wednesday'))
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
          Text($r('app.string.thursday'))
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
          Text($r('app.string.friday'))
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
          Text($r('app.string.saturday'))
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
          Text($r('app.string.sunday'))
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
                .fontSize(7)

              Blank()

              Text(item.toString())
                .fontWeight(FontWeight.Bold)
                .fontSize(14)

              Blank()

              Text(commonClassTime[item][1])
                .fontSize(7)
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
                .height(100).width(100);
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
                this.ShowClassDetail = new CustomDialogController({
                  builder: ClassDetailDialog({
                    toChange: this.thisWeekSchedule,
                    classInfo: lesson,
                    oriClassInfo: lesson,
                    weekDisplayed: this.weekDisplayed
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
              .columnStart(indexDay + 2)
              .columnEnd(indexDay + 2)
              .padding(2)
              .backgroundColor($r('app.color.shaded_background'))
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
  classInfo: classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2', weekOfTerm: tools.getContArray([[2, 10], [13, 16]]) as number[], timeSpan: [6, 7], dayOfWeek: 1 };
  oriClassInfo: classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2', weekOfTerm: tools.getContArray([[2, 10], [13, 16]]) as number[], timeSpan: [6, 7], dayOfWeek: 1 };
  controller?: CustomDialogController;
  weekDisplayed: number = 1;


  build() {
    Column() {
      Text($r('app.string.class_detail'))
        .fontSize(24)
        .fontWeight("bold")
        .textAlign(TextAlign.Center)
        .width('90%');
      Blank('16');

      Row() {
        Text($r('app.string.class_detail_name'));
        TextInput({ text: (this.classInfo.name == '' ? $r('app.string.temporary_null') : this.classInfo.name) })
          .layoutWeight(1)
          .textOverflow(TextOverflow.Ellipsis)
          .onChange((input: string) => this.classInfo.name = input );
      }
      .margin({ top: 5, bottom: 5})
      .width('80%');

      Row() {
        Text($r('app.string.class_detail_teacher'));
        TextInput({ text: (this.classInfo.teacher == '' ? $r('app.string.temporary_null') : this.classInfo.teacher) })
          .layoutWeight(1)
          .textOverflow(TextOverflow.Ellipsis)
          .onChange((input: string) => this.classInfo.teacher = input );
      }
      .margin({ top: 5, bottom: 5})
      .width('80%');

      Row() {
        Text($r('app.string.class_detail_location'));
        TextInput({ text: (this.classInfo.location == '' ? $r('app.string.temporary_null') : this.classInfo.location) })
          .layoutWeight(1)
          .textOverflow(TextOverflow.Ellipsis)
          .onChange((input: string) => this.classInfo.location = input );
      }
      .margin({ top: 5, bottom: 5})
      .width('80%');

      Row() {
        Text($r('app.string.class_detail_id'));
        TextInput({ text: (this.classInfo.id == '' ? $r('app.string.temporary_null') : this.classInfo.id) })
          .layoutWeight(1)
          .textOverflow(TextOverflow.Ellipsis)
          .onChange((input: string) => this.classInfo.id = input );
      }
      .margin({ top: 5, bottom: 5})
      .width('80%');

      Text($r('app.string.class_detail_time', (this.classInfo.timeSpan.toString() == '' ? $r('app.string.temporary_null') : this.classInfo.timeSpan.toString())))
        .textAlign(TextAlign.Start)
        .width('80%');
      Text($r('app.string.class_detail_weeks', (this.classInfo.weekOfTerm.toString() == '' ? $r('app.string.temporary_null') : tools.shrinkContArrayToString(this.classInfo.weekOfTerm))))
        .textAlign(TextAlign.Start)
        .width('80%');
      Text($r('app.string.class_detail_day_of_week', this.classInfo.dayOfWeek + 1))
        .textAlign(TextAlign.Start)
        .width('80%');

      Blank('16');
      Row() {
        Button($r('app.string.delete'))
          .onClick(() => {
            scheduleManager.deleteSchedule(this.oriClassInfo);
            this.toChange = scheduleManager.formattedSchedule[this.weekDisplayed];
            if (this.controller != undefined)
              this.controller.close();
          })
          .width('50%')
          .fontColor($r('app.color.red'))
          .buttonStyle(ButtonStyleMode.TEXTUAL);
        Button($r('app.string.ok'))
          .onClick(() => {
            scheduleManager.changeSchedule(this.oriClassInfo, this.classInfo);
            this.toChange = scheduleManager.formattedSchedule[this.weekDisplayed];
            if (this.controller != undefined)
              this.controller.close();
          })
          .width('50%')
          .buttonStyle(ButtonStyleMode.EMPHASIZED);
      };

      Button($r('app.string.cancel'))
        .onClick(() => {
          console.log(`123${this.classInfo.dayOfWeek}`)
          if (this.controller != undefined)
            this.controller.close();
        })
        .width('100%')
        .buttonStyle(ButtonStyleMode.TEXTUAL);
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.grid_background'))
  }
}