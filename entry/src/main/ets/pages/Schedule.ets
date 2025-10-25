
@Entry
@Component
struct Schedule {

  build() {

    Column() {
      Text('本地课表\n(命名为Schedule.ets以与TimeTable区分)')
        .id('ScheduleHelloWorld')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
    }
    .height('100%')
    .width('100%')

  }
}
