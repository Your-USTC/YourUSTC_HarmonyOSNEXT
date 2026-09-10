
import UnifiedPreferences, { UID_KEY, PASSWORD_KEY, REMIND_KEY } from '../utils/UnifyPreference';
import accountInfoProvider from '../utils/Encryption';
import { userAuth } from '@kit.UserAuthenticationKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { BusinessError } from '@kit.BasicServicesKit';
import BackgroundImage, { presetColor } from '../utils/BgImageManager';

/**
 * authResult 认证结果
 * 0: 未认证
 * 1: 认证成功
 * 2: 认证失败
 */
let authResult: number = 0;

@CustomDialog
export default struct PasswordDialog {
  controller: CustomDialogController;
  private inputUID: string = accountInfoProvider.getUID();
  private inputPassword: string = accountInfoProvider.getPassword();
  private showDelButton: boolean = false;
  isFromSetting: boolean= true;

  @Consume displayUsername: string;
  onConfirm: () => void = () => {};

  @State passwordState: boolean = false;

  aboutToAppear(): void {
    if (this.inputUID === null)
      this.inputUID = '';
    if (this.inputPassword === null)
      this.inputPassword = '';
    this.showDelButton = (this.inputUID + this.inputPassword === '') ? false : true;
    authResult = 0;
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.key_shield'))
          .height(30)
          .margin({ right: 5, left: 6 });
        Text($r('app.string.set_account_info'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1);
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.trash_red'))
            .width(20)
            .height(20)
        }
        .visibility(this.showDelButton ? Visibility.Visible : Visibility.Hidden)
        .height(36)
        .width(36)
        .onClick(() => {
          this.getUIContext().showAlertDialog({
            message: $r('app.string.delete_account_or_not'),
            autoCancel: true, alignment: DialogAlignment.Center, gridCount: 4, cancel: () => {},
            primaryButton: { value: $r('app.string.cancel'), action: () => {} },
            secondaryButton: {
              enabled: true, defaultFocus: true, style: DialogButtonStyle.HIGHLIGHT, value: $r('app.string.ok'),
              action: () => {
                UnifiedPreferences.deleteSync(UID_KEY);
                UnifiedPreferences.deleteSync(PASSWORD_KEY);
                this.controller.close();
              }
            },
            onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
              if (dismissDialogAction.reason === DismissReason.PRESS_BACK)
                dismissDialogAction.dismiss();
              if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE)
                dismissDialogAction.dismiss();
            }
          });
        })
      }

      Text($r('app.string.input_account_info'))
        .margin({ bottom: 10 })
        .width('90%')

      Column() {
        Row() {
          Text($r('app.string.student_id'))
          TextInput({ text: this.inputUID })
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

          TextInput({ text: this.inputPassword })
            .type(InputType.Password)
            .showPasswordIcon(false)
            .showPassword(this.passwordState)
            .enableAutoFill(false)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.inputPassword = value;
            })

          Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
            Image(this.passwordState ? $r('app.media.eye') : $r('app.media.eye_slash'))
              .height(27)
          }
          .height(40)
          .width(40)
          .margin({ left: 3 })
          .onClick(() => {
            if (this.passwordState) {
              this.passwordState = false;
            } else if (authResult === 1) {
              this.passwordState = true;
            } else {
              try {
                authResult = 0;
                const rand = cryptoFramework.createRandom();
                let randData: Uint8Array | null = null;
                let retryCount = 0;
                while(retryCount < 3){
                  randData = rand?.generateRandomSync(16)?.data;
                  if(randData){
                    break;
                  }
                  retryCount++;
                }
                if(!randData){
                  return;
                }
                // 设置认证参数。
                const authParam: userAuth.AuthParam = {
                  challenge: randData,
                  authType: [userAuth.UserAuthType.PIN, userAuth.UserAuthType.FACE],
                  authTrustLevel: userAuth.AuthTrustLevel.ATL3,
                };
                // 配置认证界面。
                const widgetParam: userAuth.WidgetParam = {
                  title: "输入锁屏密码以查看统一身份认证密码"
                };
                // 获取认证对象。
                const userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
                console.info('get userAuth instance success');
                // 订阅认证结果。
                userAuthInstance.on('result', {
                  onResult(result) {
                    if (result.result === 12500003) { // 失败
                      authResult = 2;
                    } else { // 成功
                      authResult = 1;
                    }
                    // 可在认证结束或其他业务需要场景，取消订阅认证结果。
                    userAuthInstance.off('result');
                  }
                });
                console.info('auth on success');
                userAuthInstance.start();
                console.info('auth start success');
                const intervalId = setInterval(() => {
                  if (authResult !== 0) {
                    if (authResult === 1)
                      this.passwordState = true;
                    clearInterval(intervalId); // 清除定时器
                  }
                }, 500);
              } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`auth catch error. Code is ${err?.code}, message is ${err?.message}`);
              }
            }
          })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('80%')

      Row() {
        if (!this.isFromSetting) {
          Button($r('app.string.no_reminding'))
            .buttonStyle(ButtonStyleMode.NORMAL)
            .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
            .onClick(() => {
              UnifiedPreferences.putSync(REMIND_KEY, false);
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.input_later'), duration: 2000 });
              this.controller.close();
            })
            .layoutWeight(1)
        }
        Button($r('app.string.cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
          .onClick(() => {
            this.controller.close();
          })
          .layoutWeight(1)
        Button($r('app.string.ok'))
          .backgroundColor(presetColor[BackgroundImage.themeColor].accentColor)
          .onClick(() => {
            if (this.inputUID === '')
              UnifiedPreferences.deleteSync(UID_KEY);
            else
              UnifiedPreferences.putSync(UID_KEY, this.inputUID);
            if (this.inputPassword === '')
              UnifiedPreferences.deleteSync(PASSWORD_KEY);
            else
              UnifiedPreferences.putSync(PASSWORD_KEY, accountInfoProvider.encryptPassword(this.inputPassword));
            this.displayUsername = this.inputUID;

            if (this.inputUID === '' || this.inputPassword === '') {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.cannot_fill') });
              this.controller.close();
            } else {
              if (!/^[A-Z]{2}\d{8}$/.test(this.inputUID) ||
                !(!/\s/.test(this.inputPassword) && /[a-z]/.test(this.inputPassword) &&
                  this.inputPassword.length >= 8 &&
                /[A-Z]/.test(this.inputPassword) && /\d/.test(this.inputPassword) && this.inputPassword.length <= 32)
              ) {
                this.getUIContext().showAlertDialog({
                  title: '╮(๑•́ ₃•̀๑)╭',
                  message: $r('app.string.password_incomplete'),
                  autoCancel: true, gridCount: 4, alignment: DialogAlignment.Center, cancel: () => {},
                  primaryButton: { value: $r('app.string.back'), action: () => {}, fontColor: presetColor[BackgroundImage.themeColor].accentColor },
                  secondaryButton: {
                    enabled: true,
                    defaultFocus: true,
                    style: DialogButtonStyle.HIGHLIGHT,
                    backgroundColor: presetColor[BackgroundImage.themeColor].accentColor,
                    value: $r('app.string.ok'),
                    action: () => {
                      this.onConfirm();
                      this.controller.close();
                    }
                  },
                  onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                    if (dismissDialogAction.reason === DismissReason.PRESS_BACK)
                      dismissDialogAction.dismiss();
                    if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE)
                      dismissDialogAction.dismiss();
                  }
                });
              }
              else {
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.fill_next_time'), duration: 3000 });
                this.onConfirm();
                this.controller.close();
              }
            }
          })
          .layoutWeight(1)
      }
      .margin({ top: 15 })
    }
    .padding(16)
    .width('100%')
  }
}