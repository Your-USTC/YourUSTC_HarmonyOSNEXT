import { ComposeTitleBar, Prompt, ComposeTitleBarMenuItem } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Index {
  webviewController: webview.WebviewController = new webview.WebviewController()

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close')).width(24).height(24);
        }
        .height(42)
        .width(42)
        .margin({ left: 3 });
        Blank();
        Text($r('app.string.help'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))
        Blank()
          .margin({ right: 45 });
      }
      .id('header')
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.shaded_background'))
      Web({ src: $rawfile('help.html'), controller: this.webviewController })
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .width('100%')
        .layoutWeight(1)
        .darkMode(WebDarkMode.Auto)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
    }
  }
}