
@Entry
@Component
struct Index {

  build() {

    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(20)
          .draggable(false)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Blank()

        Text($r('app.string.help'))
          .fontSize(18)
          .height(48)
          .fontColor($r('app.color.normal_text'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()
          .margin({ right: 32 })
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .width('100%')
      .id('header')
      .backgroundColor($r('app.color.shaded_background'))
    }
  }
}