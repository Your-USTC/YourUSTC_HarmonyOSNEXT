
/* 写完后删除此注释
 * 存在preference里面的信息
 * step 0: 导入库
 import { preferences } from '@kit.ArkData';

 * step 1: 初始化 preferences
 let schedulePre: preferences.Preferences | null = null;
 schedulePre = preferences.getPreferencesSync(curContext, { name: 'ScheduleInfo' });

 * step 2: 删除原有的信息
 preferences.deletePreferences(curContext, { name: 'ScheduleInfo' })

 * step 3: 写入数据
 schedulePre.putSync(名称，日程详情);

 * step 4: 保存数据
 schedulePre.flush();

 * step 5: 读取数据
 let data: 类型 = schedulePre.getSync(名称, 默认值) as 类型;
 * */

// 课程信息类型
export interface classAttribute {
  name: string,
  teacher: string,
  weekOfTerm: number[], // 以枚举形式写出哪几周
  timeSpan: number[], // 应当仅包含开始和结束是第几节课
  dayOfWeek: number,
  location: string,
  id: string
}

export interface obtainedData {
  timeTable: string;
  startTime: number;
}
// 第几节课 -> 上课时间
export const commonClassTime: string[][] = [ ['07:21', '11:45'],                                      // 排除[0]
  ['07:50', '08:35'], ['08:40', '09:25'], ['09:45', '10:30'], ['10:35', '11:20'], ['11:25', '12:05'], // 上午
  ['14:00', '14:45'], ['14:50', '15:35'], ['15:55', '16:40'], ['16:45', '17:30'], ['17:35', '18:20'], // 下午
  ['19:30', '20:15'], ['20:20', '21:05'], ['21:10', '21:55']                                          // 晚上
];
export const commonClassStamp: number[][]= [
  [26460000, 42300000],
  [28200000, 30900000], [31200000, 33900000], [35100000, 37800000], [38100000, 40800000], [41000000, 43500000],
  [50400000, 53100000], [53400000, 56100000], [57300000, 60000000], [60300000, 63000000], [63300000, 66000000],
  [70200000, 72900000], [73200000, 75900000], [76200000, 78900000]
]

@Entry
@Component
struct Schedule {
  @State timeTable: string = '';
  @State termStart: number = 0;
  onPageShow(): void {
    try {
      const routerParams = this.getUIContext().getRouter().getParams() as obtainedData;
      this.timeTable = routerParams.timeTable;
      this.termStart = routerParams.startTime;
      console.info(`从页面路由获取了课表：${this.timeTable}`);
      console.info(`从页面路由获取了开学时间：${this.termStart}`);
    } catch (err) {
      console.info("没有从页面路由获取课表和开学时间，需要从首选项读取")
      /* 从首选项中获取timeTable和termStart */
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
      .id('header')
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.shaded_background'))

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

        ForEach([1,2,3,4,5,6,7,8,9,10,11,12,13], (item: number) => {
          GridItem({ style: GridItemStyle.NONE }) {
            Text(item.toString())
              .fontWeight(FontWeight.Bold)
              .fontSize(12)
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
         * 课程示例
         */
        GridItem({ style: GridItemStyle.PLAIN }) {
          Column() {
            Text('习近平新时代中国特色社会主义思想概论')
              .fontWeight(FontWeight.Bold)
              .fontSize(12)
              .fontColor($r('app.color.normal_text'))
              .maxLines(5)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('3C302')
              .fontSize(9)

            Text('赵立璐')
              .fontSize(9)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .rowStart(1)
        .rowEnd(2)
        .columnStart(2)
        .columnEnd(2)
        .padding(2)
        .backgroundColor($r('app.color.shaded_background'))
        .border({
          width: 1,
          color: $r('app.color.grid_border')
        })
      }
      .columnsTemplate('1fr 1fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr')    // 8 列
      .rowsTemplate('1fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr')    // 14 行
      .margin({ bottom: 30 })
      .padding(5)
    }
    .height('100%')
    .width('100%')
  }
}
