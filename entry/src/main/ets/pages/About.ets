
@Entry
@Component
struct About {

  build() {
    Column() {
      Image($r('app.media.icon_round'))
        .height(100)
        .width(100)

      Text($r('app.string.app_name'))
        .fontSize(36)
        .fontColor($r('app.color.normal_text'))
        .fontWeight(FontWeight.Bolder)
        .margin({ top: 20 })

      Text('开发者（按拼音排序）：\n25-少-DSC\n25-计-LMC\n25-微-ZYM')
        .textAlign(TextAlign.Center)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.shaded_background'))
  }
}
