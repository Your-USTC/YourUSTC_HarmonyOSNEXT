
export interface classAttribute {
  name: string,
  teacher: string,
  weekOfTerm: number[],
  timeSpan: number[],
  location: string,
  id: string,
}

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
          GridItem()
            .margin(2)
            .backgroundColor($r('app.color.grid_background'))

        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr 2fr 2fr 1fr 2fr 3fr 3fr')
        .margin({ bottom: 20 })
        .padding(5)
    }
    .height('100%')
    .width('100%')
  }
}
