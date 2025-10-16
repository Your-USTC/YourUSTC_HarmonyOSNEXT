@Entry
@Component
struct Webview {
  @State url: string = this.getUIContext().getRouter().getParams() as string

  build() {
    RelativeContainer() {
      Text(this.url)
        .id('WebviewHelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.url = 'Welcome'
        })
    }
    .height('100%')
    .width('100%')
  }
}