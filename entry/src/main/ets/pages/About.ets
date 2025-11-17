
import { LengthUnit } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'
import { image } from '@kit.ImageKit'
import { common } from '@kit.AbilityKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo } from '@kit.CoreFileKit'
import { http } from '@kit.NetworkKit'

@Entry
@Component
struct About {

  private context = this.getUIContext()
  private iconClickTime: number = 0
  @State isShowEggImage: boolean = false
  @State imagePixelMap?: image.PixelMap = undefined

  async aboutToAppear() {
    console.log('aboutToAppear!!')
    this.imagePixelMap = await this.getPixmapFromMedia($r('app.media.nic'))
  }

  aboutToDisappear(): void {
    console.log('aboutToAppear!!!')
    this.imagePixelMap?.release();
  }

  build() {

    Stack({ alignContent: Alignment.Top}) {
      Column() {

        Image($r('app.media.ciallo'))
          .width('90%')
          .draggable(false)
          .constraintSize({ maxWidth: 300 })
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.under_construction') });
            this.iconClickTime++;
            if (this.iconClickTime >= 7) {
              this.isShowEggImage = true
            }
          })
          .bindContentCover(this.isShowEggImage, this.EggImage(), ModalTransition.DEFAULT)

        Text($r('app.string.welcome_to_your_ustc'))
          .fontSize(24)
          .fontColor($r('app.color.normal_text'))
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })

        Text($r('app.string.github'))
          .margin({ top: 20 })
          .fontColor($r('app.color.active_text'))
          .decoration({
            type: TextDecorationType.Underline,
            color: $r('app.color.active_text')
          })
          .onClick(() => {
            this.context.getRouter().pushUrl({
              url: 'pages/Webview',
              params: {
                title: $r('app.string.github'),
                url: 'https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT'
              }
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })

        Row() {
          Text($r('app.string.terms_of_use'))
            .fontColor($r('app.color.active_text'))
            .decoration({
              type: TextDecorationType.Underline,
              color: $r('app.color.active_text')
            })
            .onClick(() => {
              this.context.getRouter().pushUrl({
                url: 'pages/Webview',
                params: {
                  title: $r('app.string.terms_of_use'),
                  url: $rawfile('TermsOfUse.html')
                }
              }).catch((err: Error) => {
                console.error(`Router ERROR: [${err.name}] ${err.message}`)
              })
            })

          Text('  |  ')

          Text($r('app.string.privacy_policy'))
            .fontColor($r('app.color.active_text'))
            .decoration({
              type: TextDecorationType.Underline,
              color: $r('app.color.active_text')
            })
            .onClick(() => {
              this.context.getRouter().pushUrl({
                url: 'pages/Webview',
                params: {
                  title: $r('app.string.privacy_policy'),
                  url: $rawfile('PrivacyPolicy.html')
                }
              }).catch((err: Error) => {
                console.error(`Router ERROR: [${err.name}] ${err.message}`)
              })
            })
        }
        .margin({ top: 5 })

        Text($r('app.string.credits'))
          .textAlign(TextAlign.Center)
          .lineSpacing({ value: 5, unit: LengthUnit.FP })
          .margin({ top: 20 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.normal_background'))
      .padding({ bottom: 40 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      Row() {
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .height(42)
        .width(42)
        .margin({ left: 10 })
        .onClick(() => {
          this.getUIContext().getRouter().back();
        });
        Blank();
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.share'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .height(42)
        .width(42)
        .margin({ right: 10 })
        .onClick(() => {
          const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, '还在为找校园服务入口发愁？试试我正在使用的「你的科大」鸿蒙版！一站式导航+课表/考试管理，适配HarmonyOS NEXT，科大师生必备～你可以直接在App Gallery搜索，或者去github.com/Your-USTC/YourUSTC_HarmonyOSNEXT/找到它');
          const systemPasteboard = pasteboard.getSystemPasteboard();
          systemPasteboard.setData(pasteboardData);
          systemPasteboard.getData().then((data) => {
            if (data) {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_success') });
            } else {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_failed') });
            }
          });
        });
      }
      .width('100%')
      .padding({ top: 10 })
    }
  }

  @Builder
  EggImage() {
    Image(this.imagePixelMap ?? $r('app.media.nic'))
      .width('100%')
      .height('100%')
      .background($r('app.color.normal_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .objectFit(ImageFit.Contain)
      .draggable(false)
      .overlay(this.ExitAndSave(), { align: Alignment.Top })
      .onDisAppear(() => {
        this.iconClickTime = 0;
        this.isShowEggImage = false;
      });
  }

  @Builder
  ExitAndSave() {
    Row() {
      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.close'))
          .height(24)
          .width(24)
          .draggable(false)
      }
      .height(42)
      .width(42)
      .margin({ left: 10 })
      .onClick(() => { this.isShowEggImage = false; })
      Blank();
      SaveButton({ icon: SaveIconStyle.FULL_FILLED })
        .width(42)
        .height(42)
        .iconSize(24)
        .offset({ x: -10 })
        .onClick(async (event: ClickEvent, result: SaveButtonOnClickResult, error?) => {
          if (result === SaveButtonOnClickResult.SUCCESS) {
            try {
              let helper = photoAccessHelper.getPhotoAccessHelper(this.getUIContext().getHostContext());
              let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
              let file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
              let imagePackerApi = image.createImagePacker();
              let packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
              imagePackerApi.packToFile(this.imagePixelMap, file.fd, packOpts, (err) => {
                if (err) {
                  console.error(`Failed to pack the image to file.code ${err.code},message is ${err.message}`);
                } else {
                  console.info('Succeeded in packing the image to file.');
                  imagePackerApi.release((err) => {
                    if (err) {
                      console.error(`Failed to release the image source instance.code ${err.code},message is ${err.message}`);
                    } else {
                      console.info('Succeeded in releasing the image source instance.');
                      fileIo.close(file.fd);
                    }
                  })
                  this.getUIContext().getPromptAction().showToast({ message: $r('app.string.save_image_success') });
                }
              });
            } catch (error) {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.save_image_fail') });
            }
          } else {
            this.getUIContext().getPromptAction().showToast({ message: $r('app.string.save_image_fail') });
          }
        });
    }
    // .alignItems(VerticalAlign.Top)
    .width('100%');
  }

  private async getPixmapFromMedia(resource: Resource) {

    let createPixelMap: image.PixelMap
    try {

      const unit8Array = await this.getUIContext().getHostContext()!.resourceManager?.getMediaContent(resource.id)
      const imageSource = image.createImageSource(unit8Array.buffer.slice(0, unit8Array.buffer.byteLength))
      createPixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      })
      await imageSource.release()
      this.imagePixelMap?.release()

    } catch (error) {

      console.error(`getPixmapFromMedia ERROR: [${error.code}] ${error.message}`)
      return
    }
    return createPixelMap
  }
}
