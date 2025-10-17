import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Webview {
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State title: string = '';
  @State url: string = '';

  aboutToAppear() { // Receive parameters before loading the page
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    if (params) {
      this.title = params.title ?? '';
      this.url = params.url ?? '';
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({left: 12})
          .height(20)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })
        Blank()
        Text(this.title)
          .fontSize(18)
          .fontColor($r('app.color.complementary_normal_text'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Image($r('app.media.refresh'))
          .padding({right: 12})
          .height(20)
          .onClick(() => {
            this.webviewController.loadUrl(this.url);
          })
      }
      .id('header')
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.shaded_background'))
      /*.alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start },
        right: { anchor: '__container__', align: HorizontalAlign.End }
      })*/
      Web({
        src: this.url,
        controller: this.webviewController
      })
        .javaScriptAccess(true)
        .width('100%')
        .height('100%')
        // .alignRules({
        //   top: { anchor: '__container__', align: VerticalAlign.Top },
        //   left: { anchor: '__container__', align: HorizontalAlign.Start },
        //   right: { anchor: '__container__', align: HorizontalAlign.End }
        // })
    }
    .height('100%')
    .width('100%')
  }
}