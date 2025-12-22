
import BackgroundImage from './BgImageManager';
import { common, Want } from '@kit.AbilityKit';
import UnifiedPreferences from '../utils/UnifyPreference';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';

@CustomDialog
export default struct BgImageDialog {
  controller: CustomDialogController; // 弹窗控制器
  private sliderNum: number = this.BlurStyleToNum(BackgroundImage.blurLevel); // 模糊程度滑动条参数
  @State opacityNum: number = UnifiedPreferences.getNumberSync('OpacityLevel', 100); // 不透明度
  @State isShown: boolean = BackgroundImage.showImage; // 显示预览图片
  @State imgPreview: ResourceStr = (BackgroundImage.imgPath == '') ? $r('app.media.confused') : fileUri.getUriFromPath(BackgroundImage.imgPath); //预览图片
  @State blurNum: BlurStyle = UnifiedPreferences.getNumberSync('BlurLevel', BlurStyle.Regular); // 模糊程度常数
  private selectResult: string | undefined = undefined; // 选择图片的结果
  private oriImgPath: string = ''; // 原始图片路径
  private imageSize: number = 0; // 图片文件大小

  @State showBlurSlider: boolean = BackgroundImage.backgroundBlur;

  windowWidth: number = 1840;
  windowHeight: number = 2800;
  @State showWarning: boolean = false;

  build() {
    Column() {
      Row() {
        Image($r('app.media.shutter_photo'))
          .height(30)
          .margin({ right: 5 });
        Text($r('app.string.custom_background'))
          .fontSize(20)
          .fontWeight("bold")
          .layoutWeight(1);
        Toggle({ isOn: $$this.isShown, type: ToggleType.Switch })
          .onChange((value: boolean) => {
            if (BackgroundImage.imgPath == '' && this.selectResult == undefined && value) {
              this.isShown = false;
              this.SelectImage();
            }
          })
      }

      Stack() {
        Image(this.isShown ? this.imgPreview : $r('app.media.confused'))
          .width('100%')
          .alt($r('app.media.confused'))
          .constraintSize({ minHeight: 80, maxHeight: 200 })
          .borderRadius(16)
          .objectFit(ImageFit.Contain)
          .onComplete((value) => {
            if (value !== undefined) {
              let swapTemp: number;
              if (value.width > value.height){
                swapTemp = value.width;
                value.width = value.height;
                value.height = swapTemp;
              }
              if (value.width > this.windowWidth * 3 || value.height > this.windowHeight * 3 || this.imageSize > 50000000) {
                this.showWarning = true;
              } else {
                this.showWarning = false;
              }
            } else {
              this.showWarning = false;
            }
          })

        Button($r('app.string.pick_image'))
          .buttonStyle(ButtonStyleMode.NORMAL)
          .backgroundBlurStyle(this.showBlurSlider ? this.blurNum : undefined)
          .opacity(this.showBlurSlider ? 1 : this.opacityNum / 100)
          .onClick(() => {
            this.SelectImage();
          })
      }
      .margin({ bottom: 5 })

      Row() {
        Text($r('app.string.background_opaque'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Toggle({ isOn: $$this.showBlurSlider, type: ToggleType.Switch })
          .switchStyle({ unselectedColor: $r('sys.color.ohos_id_color_component_activated') })
        Text($r('app.string.background_blur'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }

      Row() {
        if (this.showBlurSlider) {
          Text($r('app.string.grid_background_blur'))
          Slider({ value: this.sliderNum, min: 0, max: 5, step: 1, style: SliderStyle.InSet })
            .showSteps(true)
            .layoutWeight(1)
            .onChange((value: number) => {
              this.sliderNum = value;
              switch (value) {
                case 0:
                  this.blurNum = BlurStyle.NONE;
                  break;
                case 1:
                  this.blurNum = BlurStyle.COMPONENT_ULTRA_THIN;
                  break;
                case 2:
                  this.blurNum = BlurStyle.COMPONENT_THIN;
                  break;
                case 3:
                  this.blurNum = BlurStyle.COMPONENT_REGULAR;
                  break;
                case 4:
                  this.blurNum = BlurStyle.COMPONENT_THICK;
                  break;
                case 5:
                  this.blurNum = BlurStyle.COMPONENT_ULTRA_THICK;
                  break;
              }
            })
        } else {
          Text($r('app.string.grid_background_opacity'))
          Slider({ value: this.opacityNum, min: 25, max: 100, step: 1, style: SliderStyle.InSet })
            .showTips(true)
            .layoutWeight(1)
            .onChange((value: number) => {
              this.opacityNum = value;
            });
        }
      }
      .width('95%');

      Text($r('app.string.too_large_bg_image'))
        .width('95%')
        .fontColor($r('app.color.red'))
        .fontSize(15)
        .maxLines(1)
        .visibility(this.showWarning ? Visibility.Visible : Visibility.None);

      Text() {
        ImageSpan($r('app.media.lightbulb'))
          .height(18)
          .verticalAlign(ImageSpanAlignment.CENTER)
        Span($r('app.string.custom_background_hint'))
          .fontSize(12)
          .margin({ left: 3, right: 16 })
      }
      .width('95%')

      Row() {
        Button($r('app.string.cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {
            this.controller.close();
          })
          .layoutWeight(1)
        Button($r('app.string.ok_and_restart'))
          .layoutWeight(1)
          .enabled(!this.showWarning)
          .onClick(() => {
            if (this.selectResult !== undefined) {
              const newImgPath: string = BackgroundImage.basicDir + '/backgroundImage';

              fileIo.copyFile(this.oriImgPath, newImgPath)
                .catch((error: BusinessError) => console.error('Copy image failed:', JSON.stringify(error)));
              UnifiedPreferences.putSync('ImagePath', newImgPath);
            }

            UnifiedPreferences.putSync('ShowImage', this.isShown);
            UnifiedPreferences.putSync('BackgroundBlur', this.showBlurSlider);
            UnifiedPreferences.putSync('BlurLevel', this.blurNum);
            UnifiedPreferences.putSync('OpacityLevel', this.opacityNum);
            UnifiedPreferences.putSync('FaultOccurred', false);

            // 重启
            let applicationContext = (this.getUIContext().getHostContext() as common.UIAbilityContext).getApplicationContext();
            let want: Want = {
              bundleName: 'com.nic.yourustc',
              abilityName: 'EntryAbility'
            };
            try {
              applicationContext.restartApp(want);
            } catch (error) {
              console.error(`restartApp fail, error: ${JSON.stringify(error)}`);
              if (error.code === 16000064) {
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                context.terminateSelf((err) => {
                  if (!err) {
                    context.getApplicationContext().killAllProcesses().catch((error: Error) => {
                      console.error(`Quitting ERROR: [${error.name}] ${error.message}`);
                    })
                  }
                });
              }
            }
            this.controller.close();
          })
      }
      .margin({ top: 5 })
    }
    .padding(16)
  }

  BlurStyleToNum(ori: BlurStyle | undefined): number {
    switch (ori) {
      case BlurStyle.NONE:
        return 0;
      case BlurStyle.COMPONENT_ULTRA_THIN:
        return 1;
      case BlurStyle.COMPONENT_THIN:
        return 2;
      case BlurStyle.COMPONENT_REGULAR:
        return 3;
      case BlurStyle.COMPONENT_THICK:
        return 4;
      case BlurStyle.COMPONENT_ULTRA_THICK:
        return 5;
      default:
        return 3;
    }
  }

  SelectImage() {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
        if (photoSelectResult.photoUris[0] !== undefined) {
          this.selectResult = photoSelectResult.photoUris[0];
          this.oriImgPath = new fileUri.FileUri(this.selectResult).path;
          this.imageSize = fileIo.statSync(this.oriImgPath).size;
          this.imgPreview = photoSelectResult.photoUris[0];
          this.isShown = true;
        }
      }).catch((err: BusinessError) => {
        console.error(`PhotoViewPicker failed: ${JSON.stringify(err)}`)
      })
    } catch (error) {
      console.error(`PhotoViewPicker failed: ${JSON.stringify(error)}`);
    }
  }
}