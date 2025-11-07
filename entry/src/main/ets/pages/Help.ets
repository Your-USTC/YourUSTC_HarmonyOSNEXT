import { ComposeTitleBar, Prompt, ComposeTitleBarMenuItem } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Index {
  webviewController: webview.WebviewController = new webview.WebviewController()

  build() {
    Column() {
      ComposeTitleBar({
        title: $r('app.string.help'),
        menuItems: [{ value: $r('sys.media.ohos_save_button_filled'), isEnabled: true,
          action: () => Prompt.showToast({ message: 'icon 1' }),
        },]
      })
      Divider().height(2).color(0xCCCCCC)
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