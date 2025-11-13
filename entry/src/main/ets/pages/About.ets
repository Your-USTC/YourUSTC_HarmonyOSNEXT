
import { LengthUnit } from '@kit.ArkUI'

@Entry
@Component
struct About {

  private context = this.getUIContext()
  private iconClickTime: number = 0
  @State isShowEggImage: boolean = false

  build() {

    Column() {

      Image($r('app.media.icon_round'))
        .height(100)
        .width(100)
        .draggable(false)
        .onClick(() => {
          this.iconClickTime++
          if (this.iconClickTime >= 6) {
            this.isShowEggImage = true
          }
        })
        .bindContentCover(this.isShowEggImage, this.EggImage(), ModalTransition.DEFAULT)

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
            this.context.getRouter().pushUrl({
              url: 'pages/Webview',
              params: {
                title: $r('app.string.homepage'),
                url: 'https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT'
              }
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
            this.context.getRouter().pushUrl({
              url: 'pages/Webview',
              params: {
                title: $r('app.string.terms_of_use'),
                url: $rawfile('TermsOfUse.html')
              }
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
            this.context.getRouter().pushUrl({
              url: 'pages/Webview',
              params: {
                title: $r('app.string.privacy_policy'),
                url: $rawfile('PrivacyPolicy.html')
              }
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })
      }
      .margin({ top: 20 })

      Text($r('app.string.credits'))
        .textAlign(TextAlign.Center)
        .lineSpacing({ value: 5, unit: LengthUnit.FP })
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.normal_background'))
    .padding({ bottom: 40 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  EggImage() {
    Image($rawfile('nic.png'))
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .objectFit(ImageFit.Contain)
      .backgroundColor($r('app.color.shaded_background'))
      .draggable(false)
      .onDisAppear(() => {
        this.iconClickTime = 0
        this.isShowEggImage = false
      })
  }
}
