
@Entry
@Component
struct Schedule {

  build() {

    Column() {
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

        Grid() {
          GridItem() {
            Column() {
              Text('本地课表\n(命名为Schedule.ets以与TimeTable区分)')
                .fontSize(30)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Center)
            }
            .justifyContent(FlexAlign.Center)
          }
          .backgroundColor($r('app.color.grid_background'))
        }
        .columnsTemplate('1fr')
        .rowsTemplate('1fr')
        .padding({ top: 15, bottom: 35, left: 15, right: 15 })
    }
    .height('100%')
    .width('100%')
  }
}
