import { webview } from '@kit.ArkWeb';
import UnifiedPreferences from '../utils/UnifyPreference';
import { font } from '@kit.ArkUI';

@Entry
@Component
struct Declaration {
  @State agreePolitic: boolean = false;
  @State knowIndependence: boolean = false;
  @State showSheet: boolean = false;
  private webController: webview.WebviewController = new webview.WebviewController();

  onBackPress(): boolean {
    return false;
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
        .borderRadius(20)
        .backgroundColor($r('app.color.grid_background'))
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
          Text($r('app.string.no_association1'))
            .fontSize(24)
            .fontWeight(FontWeight.Bolder)
          Text($r('app.string.no_association2'))
            .fontColor($r('app.color.red'))
          Text($r('app.string.no_association3'))
            .copyOption(CopyOptions.InApp)
          TextArea()
            .onChange((value: string) => {
              if (value === '我已知晓“你的科大”为中科大学生独立开发，与中国科学技术大学官方无任何关联')
                this.knowIndependence = true;
            })
          Text($r('app.string.no_association4'))
            .fontColor($r('app.color.green'))
            .visibility(this.knowIndependence ? Visibility.Visible: Visibility.Hidden)
        }
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .backgroundColor($r('app.color.grid_background'))
        .padding(15)
        .height('90%')
        .width('90%')
      }
      .nextLabel('妮可，启动！')
      .status(this.knowIndependence ? ItemState.Normal : ItemState.Disabled)
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.normal_background'))
    .onFinish(() => {
      UnifiedPreferences.putSync('InitialLaunch', false);
      this.getUIContext().getRouter().back();
    })
  }

  @Builder
  agreementSheet() {
    Web({ src: $rawfile('TermsOfUse.html'), controller: this.webController })
      .height('100%')
      .width('100%')
  }
}