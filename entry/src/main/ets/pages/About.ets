
@Entry
@Component
struct About {
  build() {
    Column() {
      Text($r('app.string.about')).fontSize(36)
      Text('开发者（按拼音排序） 25-少-dsc 25-信-lmc 25-微-zym')
    }
  }
}