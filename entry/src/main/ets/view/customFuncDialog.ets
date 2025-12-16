import { BusinessError, pasteboard } from "@kit.BasicServicesKit";
import UnifiedPreferences from '../utils/UnifyPreference';
import { setInsiderLink, LINK } from '../constants/Links';

const CERTAIN_KEY: string = "The world will not open itself before those with ignoble hearts."
interface num_to_key {
  num: string,
  title: string,
  url: string
}

@CustomDialog
export default struct customFuncDialog {
  controller: CustomDialogController;
  @State showError: boolean = false;
  @State showSuccess: boolean = false;
  @State insiderUser: boolean = false;
  private userInput: num_to_key[] = [];

  build() {
    Column({ space: 5 }) {
      Text($r('app.string.custom_function'))
        .visibility(this.showSuccess ? Visibility.None : Visibility.Visible)

      Text($r('app.string.insiders_from_clipboard_failed'))
        .fontColor($r('app.color.red'))
        .visibility(this.showError ? Visibility.Visible : Visibility.None)
        .textAlign(TextAlign.Center)

      Text(this.insiderUser ? $r('app.string.insiders') : $r('app.string.insiders_from_clipboard_success', this.userInput.length))
        .fontColor($r('app.color.green'))
        .visibility(this.showSuccess ? Visibility.Visible : Visibility.None)
        .textAlign(TextAlign.Center)

      Text($r('app.string.show_how_to_custom'))
        .decoration({
          type: TextDecorationType.Underline,
          color: $r('app.color.active_text')
        })
        .fontColor($r('app.color.active_text'))
        .fontSize(22)
        .onClick(() => {
          this.controller.close();
          this.getUIContext().getRouter().pushUrl({ url: 'pages/Help' })
            .catch((err: Error) => { console.error(`Router ERROR: [${err.name}] ${err.message}`) });
        })

      Row() {
        PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.Circle })
          .size({ width: 30, height: 30 })
          .onClick((event: ClickEvent, result: PasteButtonOnClickResult, error?: BusinessError<void>) => {
            if (result === PasteButtonOnClickResult.SUCCESS) {
              pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                if (err) {
                  this.showError = true;
                  return;
                }
                const pasteText: string = pasteData.getPrimaryText();
                try {
                  if (pasteText.includes(CERTAIN_KEY.slice(0, 10) + CERTAIN_KEY.slice(19, 49) + CERTAIN_KEY.slice(51, 64))) {
                    UnifiedPreferences.putSync('insider', true);
                    setInsiderLink();
                    this.insiderUser = true;
                  } else {
                    this.userInput = JSON.parse(pasteText);
                    for (let i of this.userInput) {
                      if (i == undefined || i.num == undefined || i.title == undefined || i.url == undefined)
                        throw new Error();
                      if (i.num.includes('.') && /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w.-]*)*\/?$/i.test(i.url)) {
                        LINK.set(i.num, { title: i.title, url: i.url });
                      } else {
                        throw new Error();
                      }
                    }
                  }
                  this.showSuccess = true;
                } catch (error) {
                  this.showError = true;
                }
              });
            } else {
              this.showError = true;
            }
          });

        Text($r('app.string.insiders_from_clipboard'))
      }
    }
    .padding(16)
  }
}