
@Entry
@Component
struct About {
  build() {
    Column() {
      Text($r('app.string.about')).fontSize(36)
    }
  }
}