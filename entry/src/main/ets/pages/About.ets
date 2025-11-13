
import { LengthUnit } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'

@Entry
@Component
struct About {

  private context = this.getUIContext()
  private iconClickTime: number = 0
  @State isShowEggImage: boolean = false

  build() {

    Stack({ alignContent: Alignment.Top}) {
      Column() {

        Image($r('app.media.ciallo'))
          .width('90%')
          .draggable(false)
          .constraintSize({ maxWidth: 300 })
          .onClick(() => {
            this.iconClickTime++
            if (this.iconClickTime >= 6) {
              this.isShowEggImage = true
            }
          })
          .bindContentCover(this.isShowEggImage, this.EggImage(), ModalTransition.DEFAULT)

        Text($r('app.string.welcome_to_your_ustc'))
          .fontSize(24)
          .fontColor($r('app.color.normal_text'))
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })

        Text($r('app.string.github'))
          .margin({ top: 20 })
          .fontColor($r('app.color.active_text'))
          .decoration({
            type: TextDecorationType.Underline,
            color: $r('app.color.active_text')
          })
          .onClick(() => {
            this.context.getRouter().pushUrl({
              url: 'pages/Webview',
              params: {
                title: $r('app.string.github'),
                url: 'https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT'
              }
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })

        Row() {
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
        .margin({ top: 5 })

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

      Row() {
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(30)
            .width(30)
            .draggable(false)
        }
        .height(48)
        .width(48)
        .margin({ left: 10 })
        .onClick(() => {
          this.getUIContext().getRouter().back();
        });
        Blank();
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.share'))
            .height(30)
            .width(30)
            .draggable(false)
        }
        .height(48)
        .width(48)
        .margin({ right: 10 })
        .onClick(() => {
          const uiContext: UIContext | undefined = AppStorage.get('context');
          const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, '还在为找校园服务入口发愁？试试我正在使用的「你的科大」鸿蒙版！一站式导航+课表/考试管理，适配HarmonyOS NEXT，科大师生必备～你可以直接在App Gallery搜索，或者去github.com/Your-USTC/YourUSTC_HarmonyOSNEXT/找到它');
          const systemPasteboard = pasteboard.getSystemPasteboard();
          systemPasteboard.setData(pasteboardData);
          systemPasteboard.getData().then((data) => {
            if (data) {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_success'), duration: 1000 });
            } else {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_failed'), duration: 1000 });
            }
          })
        });
      }
      .width('100%')
      .padding({ top: 10 })
    }
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
