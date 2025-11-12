
@Entry
@Component
struct Index {

  build() {

    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(20)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

        Blank()

        Text($r('app.string.help'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()
          .margin({ right: 32 })
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.shaded_background'))


    }
  }
}