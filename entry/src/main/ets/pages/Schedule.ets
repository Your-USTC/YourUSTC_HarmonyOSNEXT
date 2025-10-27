
export interface classAttribute {
  name: string,
  teacher: string,
  location: string,
  id: string
}

// TODO: 接受课程信息

@Entry
@Component
struct Schedule {

  build() {

    Column() {
        // Header
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

        // 课表
        Grid() {
          /**
           * 行: 表头
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
            width: {left: 1},
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
            width: {left: 1},
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
            width: {left: 1},
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
            width: {left: 1},
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
            width: {left: 1},
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
            width: {left: 1},
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
            width: {left: 1},
            color: $r('app.color.grid_border')
          })

          /**
           * 行: 第一节
           */
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
            width: { top: 1 },
            color: $r('app.color.grid_border')
          })

          GridItem({ style: GridItemStyle.NONE }) {
            Text('1')
              .fontWeight(FontWeight.Bold)
              .fontSize(12)
          }
          .rowStart(1)
          .rowEnd(1)
          .columnStart(1)
          .columnEnd(1)
          .padding(1)
          .border({
            width: { top: 1, left: 1 },
            color: $r('app.color.grid_border')
          })

          GridItem({ style: GridItemStyle.PLAIN }) {
            Text('1')
              .fontWeight(FontWeight.Bold)
              .fontSize(12)
          }
          .rowStart(1)
          .rowEnd(2)
          .columnStart(2)
          .columnEnd(2)
          .padding(1)
          .backgroundColor($r('app.color.shaded_background'))
          .border({
            width: { top: 1, left: 1 },
            color: $r('app.color.grid_border')
          })
        }
        .columnsTemplate('1fr 1fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr')    // 8 列
        .rowsTemplate('1fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr 2fr')    // 14 行
        .margin({ bottom: 20 })
        .padding(5)
    }
    .height('100%')
    .width('100%')
  }
}
