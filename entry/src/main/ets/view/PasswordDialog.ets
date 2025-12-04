
import UnifiedPreferences, { UID_KEY, PASSWORD_KEY, REMIND_KEY } from '../utils/UnifyPreference';
import accountInfoProvider from '../utils/Encryption';

@CustomDialog
export default struct PasswordDialog {
  controller: CustomDialogController;
  private inputUID: string = accountInfoProvider.getUID();
  private inputPassword: string = accountInfoProvider.getPassword();
  isFromSetting: boolean= true;

  onConfirm: () => void = () => {};

  private oriInputUID: string = '';
  private oriInputPassword: string = '';

  aboutToAppear(): void {
    if (this.inputUID === null)
      this.inputUID = '';
    if (this.inputPassword === null)
      this.inputPassword = '';
    this.oriInputUID = this.inputUID;
    this.oriInputPassword = this.inputPassword;
  }

  build() {
    Column() {
      Text($r('app.string.input_account_info'))
        .margin({ bottom: 10 })
        .width('90%')

      Column() {
        Row() {
          Text($r('app.string.student_id'))
          TextInput({ text: this.oriInputUID })
            .type(InputType.USER_NAME)
            .enableAutoFill(false)
            .layoutWeight(1)
            .margin({ bottom: 5 })
            .onChange((value: string) => {
              this.inputUID = value;
            })
        }

        Row() {
          Text($r('app.string.password'))
          TextInput({ text: this.oriInputPassword })
            .type(InputType.Password)
            .showPasswordIcon(true)
            .enableAutoFill(false)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.inputPassword = value;
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('80%')

      Row() {
        if (!this.isFromSetting) {
          Button($r('app.string.no_reminding'))
            .buttonStyle(ButtonStyleMode.NORMAL)
            .onClick(() => {
              UnifiedPreferences.putSync(REMIND_KEY, false);
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.input_later'), duration: 2000 });
              this.controller.close();
            })
            .layoutWeight(1)
        }
        Button($r('app.string.cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {
            this.controller.close();
          })
          .layoutWeight(1)
        Button($r('app.string.ok'))
          .onClick(() => {
            let correctInput: boolean = true;
            if (this.inputUID === '')
              UnifiedPreferences.deleteSync(UID_KEY);
            else {
              if (/^[A-Z]{2}\d{8}$/.test(this.inputUID)) {
                UnifiedPreferences.putSync(UID_KEY, this.inputUID);
              } else {
                correctInput = false;
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.incomplete') });
              }
            }

            if (this.inputPassword === '')
              UnifiedPreferences.deleteSync(PASSWORD_KEY);
            else {
              if (
                !/\s/.test(this.inputPassword) && /[a-z]/.test(this.inputPassword) && this.inputPassword.length >= 8 &&
                /[A-Z]/.test(this.inputPassword) && /\d/.test(this.inputPassword) && this.inputPassword.length <= 32
              )
                UnifiedPreferences.putSync(PASSWORD_KEY, accountInfoProvider.encryptPassword(this.inputPassword));
              else {
                if (correctInput) {
                  this.getUIContext().getPromptAction().showToast({ message: $r('app.string.incomplete') });
                  correctInput = false;
                }
              }
            }
            
            if (correctInput) {
              if (this.inputUID !== '' && this.inputPassword !== '') {
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.fill_next_time') });
                this.onConfirm();
              }
              else
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.cannot_fill') });
              this.controller.close();
            }
          })
          .layoutWeight(1)
      }
      .margin({ top: 20 })
    }
    .padding(16)
    .width('100%')
  }
}