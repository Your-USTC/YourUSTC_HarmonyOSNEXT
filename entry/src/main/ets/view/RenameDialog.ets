import BackgroundImage, { presetColor } from "../utils/BgImageManager";

@CustomDialog
export default struct RenameDialog {
  controller: CustomDialogController;
  name: string = '';
  onConfirm: (newName: string) => void = () => {};
  message: ResourceStr = '';

  build() {
    Column() {
      Row() {
        Image($r('app.media.rename'))
          .height(30)
          .margin({ right: 5 });

        Text($r('app.string.rename'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .margin({ bottom: 5 })

      Text(this.message)
        .margin({ bottom: 5 })
        .width('90%')

      TextInput({ text: this.name })
        .selectAll(true)
        .onChange((value: string) => {
          this.name = value;
        })

      Row() {
        Button($r('app.string.cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor(presetColor[BackgroundImage.themeColor][2])
          .width('50%')
          .onClick(() => this.controller.close())

        Button($r('app.string.ok'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .backgroundColor(presetColor[BackgroundImage.themeColor][2])
          .width('50%')
          .onClick(() => {
            this.onConfirm(this.name);
            this.controller.close();
          })
      }
      .margin({ top: 16 })
    }
    .padding(16)
    .width('100%')
  }
}