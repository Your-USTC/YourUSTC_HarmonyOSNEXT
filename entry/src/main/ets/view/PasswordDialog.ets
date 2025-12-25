
/**
 * 自动填充对话框
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { userAuth } from '@kit.UserAuthenticationKit';

import accountInfoProvider from '../utils/Encryption';
import UnifiedPreferences, { UID_KEY, PASSWORD_KEY, REMIND_KEY } from '../utils/UnifyPreference';

/**
 * authResult 认证结果
 * 0: 未认证
 * 1: 认证成功
 * 2: 认证失败
 */
let authResult: number = 0;

@CustomDialog
export default struct PasswordDialog {

  // 内部变量
  private inputUID: string = accountInfoProvider.getUID();
  private inputPassword: string = accountInfoProvider.getPassword();
  @State passwordState: boolean = false;
  controller: CustomDialogController;
  isFromSetting: boolean= true;
  onConfirm: () => void = () => {};

  // 初始化
  aboutToAppear(): void {
    if (this.inputUID === null)
      this.inputUID = '';
    if (this.inputPassword === null)
      this.inputPassword = '';
    authResult = 0;
  }

  build() {
    Column() {
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

                // 接入系统安全能力

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
            .onClick(() => {
              UnifiedPreferences.putSync(REMIND_KEY, false);
              this.getUIContext().getPromptAction().showToast({
                message: $r('app.string.input_later'),
                duration: 2000
              });
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
                this.getUIContext().getPromptAction().showToast({
                  message: $r('app.string.incomplete')
                });
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
                  this.getUIContext().getPromptAction().showToast({
                    message: $r('app.string.incomplete')
                  });
                  correctInput = false;
                }
              }
            }
            
            if (correctInput) {
              if (this.inputUID !== '' && this.inputPassword !== '') {
                this.getUIContext().getPromptAction().showToast({
                  message: $r('app.string.fill_next_time')
                });
                this.onConfirm();
              }
              else
                this.getUIContext().getPromptAction().showToast({
                  message: $r('app.string.cannot_fill')
                });
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
