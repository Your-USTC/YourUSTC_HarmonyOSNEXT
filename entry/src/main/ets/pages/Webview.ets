import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Webview {
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State url: string = this.getUIContext().getRouter().getParams() as string

  build() {
    RelativeContainer() {
      Row() {
        Text('Title here')
          .fontSize(18)
          .fontColor($r('sys.color.black'))
          .padding({ left: 16 })
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
      }
      .id('header')
      .width('100%')
      .height(96)
      .backgroundColor($r('sys.color.brand'))
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start },
        right: { anchor: '__container__', align: HorizontalAlign.End }
      })
      Web({
        src: this.url,
        controller: this.webviewController
      })
        .javaScriptAccess(true)
        .width('100%')
        .height('100%')
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          left: { anchor: '__container__', align: HorizontalAlign.Start },
          right: { anchor: '__container__', align: HorizontalAlign.End }
        })
      /*Text(this.url)
        .id('WebviewHelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.url = 'Welcome'
        })*/
    }
    .height('100%')
    .width('100%')
  }
}