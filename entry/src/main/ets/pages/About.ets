
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
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      Row() {
        Text($r('app.string.homepage'))
          .fontColor($r('app.color.active_text'))
          .decoration({
            type: TextDecorationType.Underline,
            color: $r('app.color.active_text')
          })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/Webview',
              params: { title: $r('app.string.homepage'), url: 'https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT'}
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })

        Text('  |  ')

        Text($r('app.string.terms_of_use'))
          .fontColor($r('app.color.active_text'))
          .decoration({
            type: TextDecorationType.Underline,
            color: $r('app.color.active_text')
          })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/Webview',
              params: { title: $r('app.string.terms_of_use'), url: 'https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT/blob/main/LICENSE'}
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })

        Text('  |  ')

        Text($r('app.string.privacy_policy'))
          .fontColor($r('app.color.active_text'))
          .decoration({
            type: TextDecorationType.Underline,
            color: $r('app.color.active_text')
          })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/Webview',
              params: { title: $r('app.string.privacy_policy'), url: 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1802923490693635520'}
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })
      }
      .margin({ top: 20 })

      Text($r('app.string.credits'))
        .textAlign(TextAlign.Center)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.grid_background'))
    .padding({ bottom: 40 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
