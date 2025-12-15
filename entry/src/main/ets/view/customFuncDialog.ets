import { BusinessError, pasteboard } from "@kit.BasicServicesKit";
import UnifiedPreferences from '../utils/UnifyPreference';

const CERTAIN_KEY: string = 'The world open itself before those with noble hearts';

@CustomDialog
export default struct customFuncDialog {
  controller: CustomDialogController;

  build() {
    Column({ space: 5 }) {
      Text($r('app.string.custom_function'))
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
                  this.getUIContext()
                    .getPromptAction()
                    .showToast({ message: $r('app.string.insiders_from_clipboard_failed') });
                  return;
                }
                const pasteText: string = pasteData.getPrimaryText();
                try {
                  if (pasteText.includes(CERTAIN_KEY)) {
                    UnifiedPreferences.putSync('insider', true);
                    this.getUIContext().getPromptAction().showToast({ message: $r('app.string.insiders') });
                  } else {
                  }
                } catch (error) {
                  this.getUIContext().getPromptAction().showToast({ message: $r('app.string.insiders_from_clipboard_failed') });
                }
              });
            } else {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.insiders_from_clipboard_failed') });
            }
          });

        Text($r('app.string.insiders_from_clipboard'))
      }
    }
    .padding(16)
  }
}