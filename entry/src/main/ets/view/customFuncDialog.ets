import { BusinessError, pasteboard } from "@kit.BasicServicesKit";
import UnifiedPreferences from '../utils/UnifyPreference';
import { setInsiderLink, LINK } from '../constants/Links';

const CERTAIN_KEY: string = "The world will not open itself before those with ignoble hearts"
interface num_to_key {
  num: string,
  title: string,
  url: string
}

let change_func_num: string = '0.0';
export function set_func_num(toChange: string) {
  change_func_num = toChange;
}

@CustomDialog
export default struct customFuncDialog {
  controller: CustomDialogController;
  @State showError: boolean = false;
  @State showSuccess: boolean = false;
  @State insiderUser: boolean = false;
  private userInput: num_to_key[] = [];
  private singleURL: string = '';
  private singleTitle: string = '';

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

      if (change_func_num !== 'all') {
        Row() {
          TextInput({ placeholder: $r('app.string.fill_single_title') })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.singleTitle = value;
            })

          TextInput({ placeholder: $r('app.string.fill_single_url') })
            .layoutWeight(1)
            .type(InputType.URL)
            .onChange((value: string) => {
              this.singleURL = value;
            })

          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.checkmark'))
              .height(24).width(24)
          }
          .height(36)
          .width(36)
          .onClick(() => {
            if (/^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w.-]*)*\/?$/i.test(this.singleURL)) {
              this.userInput = [{ num: '', title: '', url: '' }];
              LINK.set(change_func_num, { title: this.singleTitle, url: this.singleURL });
              this.showError = false;
              this.showSuccess = true;
            } else {
              this.showSuccess = false;
              this.showError = true;
            }
          })
        }

        Row({ space: 3 }) {
          Divider()
            .layoutWeight(1)
          Text($r('app.string.or_you_can'))
            .fontSize(12)
          Divider()
            .layoutWeight(1)
        }
      }

      Row() {
        PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.Circle })
          .size({ width: 30, height: 30 })
          .onClick((event: ClickEvent, result: PasteButtonOnClickResult, error?: BusinessError<void>) => {
            if (result === PasteButtonOnClickResult.SUCCESS) {
              pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                if (err) {
                  this.showError = true;
                  this.showSuccess = false;
                  return;
                }
                const pasteText: string = pasteData.getPrimaryText();
                try {
                  if (pasteText.includes(CERTAIN_KEY.slice(0, 10) + CERTAIN_KEY.slice(19, 49) + CERTAIN_KEY.slice(51, 63))) {
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
                  this.showError = false;
                  this.showSuccess = true;
                } catch (error) {
                  this.showSuccess = false;
                  this.showError = true;
                }
              });
            } else {
              this.showError = true;
              this.showSuccess = false;
            }
          });

        Text($r('app.string.insiders_from_clipboard'))
      }
    }
    .padding(16)
  }
}