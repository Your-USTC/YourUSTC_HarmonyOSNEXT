
import UnifiedPreferences, { UID_KEY, PASSWORD_KEY, REMIND_KEY } from '../utils/UnifyPreference';
import accountInfoProvider from '../utils/Encryption';

@CustomDialog
export default struct PasswordDialog {
  controller: CustomDialogController;
  inputUID: string = UnifiedPreferences.getSync(UID_KEY, '');
  inputPassword: string = UnifiedPreferences.getSync(PASSWORD_KEY, '');
  isFromSetting: boolean= true;

  oriInputUID: string = '';
  oriInputPassword: string = '';

  aboutToAppear(): void {
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
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.incomplete'), duration: 1500 });
              }
            }

            if (this.inputPassword === '')
              UnifiedPreferences.deleteSync(PASSWORD_KEY);
            else {
              if (!/\s/.test(this.inputPassword) && /[a-z]/.test(this.inputPassword) && /[A-Z]/.test(this.inputPassword) && /\d/.test(this.inputPassword))
                UnifiedPreferences.putSync(PASSWORD_KEY, accountInfoProvider.encryptPassword(this.inputPassword));
              else {
                if (correctInput) {
                  this.getUIContext().getPromptAction().showToast({ message: $r('app.string.incomplete'), duration: 1500 });
                  correctInput = false;
                }
              }
            }
            
            if (correctInput) {
              if (this.inputUID !== '' && this.inputPassword !== '')
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.fill_next_time'), duration: 1500 });
              else
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.cannot_fill'), duration: 1500 });
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