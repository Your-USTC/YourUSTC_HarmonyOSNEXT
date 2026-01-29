import { webview } from '@kit.ArkWeb';
import UnifiedPreferences from '../utils/UnifyPreference';
import { setUSTCLink, setHUSTLink } from '../constants/Links';

@Entry
@Component
struct Declaration {
  @State agreePolitic: boolean = false;
  @State chooseSchool: number = -1;
  @State showSheet: boolean = false;
  private webController: webview.WebviewController = new webview.WebviewController();

  onBackPress(): boolean {
    return true;
  }

  build() {
    Stepper() {
      StepperItem() {
        Column() {
          Column({ space: 7 }) {
            Image($r('app.media.icon_round'))
              .height(80)
              .width(80)
            Text($r('app.string.welcome_to_your_ustc'))
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 10 })
          }

          Row() {
            Checkbox()
              .onChange((value: boolean) => {
                this.agreePolitic = value;
              })
            Text() {
              Span($r('app.string.read_privacy_policy'))
              Span($r('app.string.terms_of_use_and_privacy_policy'))
                .fontColor($r('app.color.active_text'))
                .onClick(() => {
                  this.showSheet = true;
                })
                .decoration({
                  type: TextDecorationType.Underline,
                  color: $r('app.color.active_text')
                })
            }
          }
        }
        .justifyContent(FlexAlign.SpaceAround)
        .padding(15)
        .height('90%')
        .width('90%')
        .bindSheet($$this.showSheet, this.agreementSheet(), {
          detents: [SheetSize.LARGE],
          preferType: SheetType.CENTER
        })
      }
      .status(this.agreePolitic ? ItemState.Normal: ItemState.Disabled)

      StepperItem() {
        Column({ space: 7 }) {
          Text($r('app.string.choose_school'))
            .fontSize(24)
            .fontWeight(FontWeight.Bolder)
          Select([{ value: '华中科技大学' }, { value: '中国科学技术大学' }])
            .onSelect((index: number) => {
              this.chooseSchool = index;
            })
          Text($r('app.string.will_support_school'))
            .fontSize(12)
            .fontColor($r('app.color.transparent_text'))
        }
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .padding(15)
        .height('90%')
        .width('90%')
      }
      .nextLabel('妮可，启动！')
      .status(this.chooseSchool === -1 ? ItemState.Disabled : ItemState.Normal)
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onFinish(() => {
      switch (this.chooseSchool) {
        case 1:
          UnifiedPreferences.putSync('school', 'USTC');
          setUSTCLink();
          break;
        case 0:
          UnifiedPreferences.putSync('school', 'HUST');
          setHUSTLink();
          break;
      }
      UnifiedPreferences.putSync('InitialLaunch', false);
      this.getUIContext().getRouter().back();
    })
  }

  @Builder
  agreementSheet() {
    Web({ src: $rawfile('TermsOfUse.html'), controller: this.webController })
      .height('100%')
      .width('100%')
      .darkMode(WebDarkMode.Auto)
      .backgroundColor($r('app.color.normal_background'))
  }
}