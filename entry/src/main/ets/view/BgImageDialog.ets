
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
  private transparency: number = 50;
  private isShown: boolean = BackgroundImage.showImage;

  build() {
    Column({ space: 5 }) {
      Row() {
        Text($r('app.string.custom_background'))
          .layoutWeight(1)
        Toggle({ isOn: BackgroundImage.showImage, type: ToggleType.Switch })
          .onChange((status: boolean) => {
            this.isShown = status;
          })
        Button($r('app.string.pick_image'))
          .buttonStyle(ButtonStyleMode.NORMAL)
          .onClick(() => {
            try {
              const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
              photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
              photoSelectOptions.maxSelectNumber = 1;
              const photoPicker = new photoAccessHelper.PhotoViewPicker();
              photoPicker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
                const oriImgPath: string = new fileUri.FileUri(photoSelectResult.photoUris[0]).path;
                const newImgPath: string = BackgroundImage.basicDir + '/backgroundImage'
                  + copyFileExtension(photoSelectResult.photoUris[0]);

                fileIo.copyFile(oriImgPath, newImgPath)
                  .catch((error: BusinessError) => console.error('Copy image failed:',JSON.stringify(error)));
                UnifiedPreferences.putSync('ImagePath', newImgPath);
              }).catch((err: BusinessError) => {
                console.error(`PhotoViewPicker failed: ${JSON.stringify(err)}`)
              })
            } catch (error) {
              console.error(`PhotoViewPicker failed: ${JSON.stringify(error)}`);
            }
          })
      }
      Row() {
        Text($r('app.string.transparency'))
        Slider({
          value: this.transparency,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.transparency = value;
          })
      }
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
            BackgroundImage.changeShowStatus(this.isShown);
            // 此处需要应用更改
            UnifiedPreferences.putSync('FaultOccurred', false);
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
    }
    .padding(16)
  }
}