
import BackgroundImage from './BgImageManager';
import { common, Want } from '@kit.AbilityKit';
import UnifiedPreferences from '../utils/UnifyPreference';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { copyFileExtension } from '../utils/tools';

@CustomDialog
export default struct BgImageDialog {
  controller: CustomDialogController;
  private sliderNum: number = this.BlurStyleToNum(BackgroundImage.blurLevel);
  @State isShown: boolean = BackgroundImage.showImage;
  @State imgPreview: ResourceStr = (BackgroundImage.imgPath == '') ? $r('app.media.theHerta') : fileUri.getUriFromPath(BackgroundImage.imgPath);
  @State blurNum: BlurStyle = (BackgroundImage.blurLevel == undefined) ? BlurStyle.COMPONENT_REGULAR : BackgroundImage.blurLevel;
  private selectResult: string | undefined = undefined;

  build() {
    Column() {
      Row() {
        Text($r('app.string.custom_background'))
          .fontSize(24)
          .fontWeight("bold")
          .layoutWeight(1);
        Toggle({ isOn: $$this.isShown, type: ToggleType.Switch })
          .onClick(() => {
            this.isShown = !this.isShown;
          })
      }

      Stack() {
        Image(this.isShown ? this.imgPreview : $r('app.media.theHerta'))
          .width('100%')
          .alt($r('app.media.theHerta'))
          .constraintSize({ minHeight: 80, maxHeight: 200 })
          .borderRadius(16)
          .objectFit(ImageFit.Contain)
          .margin({ top: 5, bottom: 5 });

        Button($r('app.string.pick_image'))
          .buttonStyle(ButtonStyleMode.NORMAL)
          .backgroundBlurStyle(this.blurNum)
          .onClick(() => {
            try {
              const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
              photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
              photoSelectOptions.maxSelectNumber = 1;
              const photoPicker = new photoAccessHelper.PhotoViewPicker();
              photoPicker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
                if (photoSelectResult.photoUris[0] !== undefined) {
                  this.imgPreview = photoSelectResult.photoUris[0];
                  this.selectResult = photoSelectResult.photoUris[0];
                  this.isShown = true;
                }
              }).catch((err: BusinessError) => {
                console.error(`PhotoViewPicker failed: ${JSON.stringify(err)}`)
              })
            } catch (error) {
              console.error(`PhotoViewPicker failed: ${JSON.stringify(error)}`);
            }
          })
      }

      Row() {
        Text($r('app.string.grid_background_transparency'))
        Slider({
          value: this.sliderNum,
          min: 0,
          max: 5,
          step: 1,
          style: SliderStyle.InSet
        })
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
      }
      .width('90%');

      Row() {
        Image($r('app.media.lightbulb'))
          .height(18)
        Text($r('app.string.custom_background_hint'))
          .fontSize(12)
          .margin({ left: 3, right: 16 })
      }
      .width('90%')

      Row() {
        Button($r('app.string.cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {
            this.controller.close();
          })
          .layoutWeight(1)
        Button($r('app.string.ok_and_restart'))
          .layoutWeight(1)
          .onClick(() => {
            if (this.selectResult !== undefined) {
              const oriImgPath: string = new fileUri.FileUri(this.selectResult).path;
              const newImgPath: string = BackgroundImage.basicDir + '/backgroundImage'
                + copyFileExtension(this.selectResult);

              fileIo.copyFile(oriImgPath, newImgPath)
                .catch((error: BusinessError) => console.error('Copy image failed:', JSON.stringify(error)));
              UnifiedPreferences.putSync('ImagePath', newImgPath);
            }

            UnifiedPreferences.putSync('ShowImage', this.isShown);
            UnifiedPreferences.putSync('BlurLevel', this.blurNum);
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
}