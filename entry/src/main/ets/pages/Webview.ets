
import { webview } from '@kit.ArkWeb'
import { DESKTOP_UA, MOBILE_UA } from '../constants/UserAgent'

@Entry
@Component
struct Webview {
  webviewController: webview.WebviewController = new webview.WebviewController()
  @State isDesktop: boolean = false;
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
        Image($r('app.media.back'))
          .padding(({left: 12}))
          .height(16)
          .onClick(() => {
            if (this.webviewController.accessBackward()) {
              this.webviewController.backward();
            } else {
              console.log("Cannot go back!");
              this.getUIContext().getRouter().back();
            }
          })
        Blank()
        Text(this.title)
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Image(this.isDesktop ? $r('app.media.mobile') : $r('app.media.desktop'))
          .padding({right: 12})
          .height(20)
          .onClick(() => {
            this.webviewController.setCustomUserAgent(this.isDesktop ? MOBILE_UA : DESKTOP_UA);
            this.webviewController.refresh();
            this.isDesktop = !this.isDesktop;
          })
        Image($r('app.media.refresh'))
          .padding({right: 12})
          .height(20)
          .onClick(() => {
            this.webviewController.refresh();
          })
      }
      .id('header')
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.shaded_background'))
      Web({
        src: this.url,
        controller: this.webviewController
      })
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .width('100%')
        .height('100%')

    }
    .height('100%')
    .width('100%')
  }
}
