
/* 写完后删除此注释
 * 存在preference里面的信息
 * step 0: 导入库
 import { preferences } from '@kit.ArkData';

 * step 1: 初始化 preferences

 * step 2: 删除原有的信息
 preferences.deletePreferences(curContext, { name: 'ScheduleInfo' })

 * step 3: 写入数据
 schedulePre.putSync(名称，日程详情);

 * step 4: TODO: 保存数据
 schedulePre.flush();

 * step 5: 读取数据
 let data: 类型 = schedulePre.getSync(名称, 默认值) as 类型;
 * */

import { preferences } from '@kit.ArkData';
import * as tools from '../utils/tools';
import UnifiedPreferences from '../utils/UnifyPreference';
import { SCHEDULE_KEY, START_TIME_KEY, millisecondsPerWeek } from '../utils/UnifyPreference';

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
  termStart: number = 0;
  @State parsedSchedule: classAttribute[][][] = [];
  @State weekDisplayed: number = 6;
  onPageShow(): void {
    const currentTime: Date = new Date();
    try {
      const routerParams = this.getUIContext().getRouter().getParams() as obtainedData;
      const timeTable = routerParams.timeTable.slice(1, -1).replace(/\\/g, '');
      this.termStart = Number(routerParams.startTime.replace(/[^0-9]/g, ''));
      this.parsedSchedule = JSON.parse(timeTable) as classAttribute[][][];
      UnifiedPreferences.putSync(SCHEDULE_KEY, timeTable);
      UnifiedPreferences.putSync(START_TIME_KEY, this.termStart);
      this.weekDisplayed = Math.ceil((currentTime.getTime() - this.termStart) / millisecondsPerWeek);
      console.info(`课表 weekdisplayed ${this.weekDisplayed}`)
      console.info(`课表 weekdisplayed ${currentTime.getTime()}`)
      console.info(`课表 weekdisplayed ${this.termStart}`)
    } catch (err) {
      this.parsedSchedule = JSON.parse(UnifiedPreferences.getSync(SCHEDULE_KEY, '[[[]]]'))
      this.weekDisplayed = UnifiedPreferences.hasSync(START_TIME_KEY)
        ? Math.ceil((currentTime.getTime() - Number(UnifiedPreferences.getSync(START_TIME_KEY))) / millisecondsPerWeek) : 1;
    }
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

        Blank()

        Text($r('app.string.local_schedule'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))

        Blank()

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
        Text('2025-09-07' + ' ~ ' + '2025-09-13')    // TODO: 获取一周首末日
          // 注意网页中周日的日期最早，周六最迟
          .id('week_of_term_span')
          .fontWeight(FontWeight.Bold)
          .fontSize(14)

        Blank()

        Image($r('app.media.last_page'))
          .height(18)
          .width(40)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            this.weekDisplayed--;
            // TODO: 上一周
            this.getUIContext().getPromptAction().showToast({
              message: '上一周',
              duration: 500
            })
          })

        Text($r('app.string.week_of_term_no_d', this.weekDisplayed))    // TODO: 获取当前周数
          .id('week_of_term_no')
          .fontWeight(FontWeight.Bold)
          .fontSize(14)

        Image($r('app.media.next_page'))
          .height(18)
          .width(40)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            this.weekDisplayed++;
            // TODO: 下一周
            this.getUIContext().getPromptAction().showToast({
              message: '下一周',
              duration: 500
            })
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
          })
        })

        /**
         * 课程内容
         */
        ForEach(this.parsedSchedule, (day: classAttribute[][], indexDay) => {
          ForEach(day, (course: classAttribute[]) => {
            ForEach(course, (lesson: classAttribute) => {
              if (lesson.weekOfTerm.includes(this.weekDisplayed)) {
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
                .rowStart(course[0].timeSpan[0])
                .rowEnd(course[0].timeSpan[course[0].timeSpan.length - 1])
                .columnStart(indexDay + 2)
                .columnEnd(indexDay + 2)
                .padding(2)
                .backgroundColor($r('app.color.shaded_background'))
                .border({
                  width: 1,
                  color: $r('app.color.grid_border')
                })
              }
            })
          })
        })
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
