
import { LengthUnit } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo } from '@kit.CoreFileKit'
import { getRandomInt } from '../utils/tools';

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
    console.log('aboutToDisappear!!!')
    this.imagePixelMap?.release();
  }

  build() {

    Stack({ alignContent: Alignment.Top}) {
      Scroll() {
        Column() {
          Image($r('app.media.ciallo'))
            .width('90%')
            .margin({ top: 40 })
            .draggable(false)
            .constraintSize({ maxWidth: 300 })
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.egg_hint' + getRandomInt(1, 2).toString()) });
              this.iconClickTime++;
              if (this.iconClickTime >= 7) {
                this.isShowEggImage = true;
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
            Text($r('app.string.terms_of_use_and_privacy_policy'))
              .fontColor($r('app.color.active_text'))
              .decoration({
                type: TextDecorationType.Underline,
                color: $r('app.color.active_text')
              })
              .onClick(() => {
                this.context.getRouter().pushUrl({
                  url: 'pages/Webview',
                  params: {
                    title: $r('app.string.terms_of_use_and_privacy_policy'),
                    url: $rawfile('TermsOfUse.html')
                  }
                }).catch((err: Error) => {
                  console.error(`Router ERROR: [${err.name}] ${err.message}`)
                })
              })

            Text('  |  ')

            Text($r('app.string.open_source_license'))
              .fontColor($r('app.color.active_text'))
              .decoration({
                type: TextDecorationType.Underline,
                color: $r('app.color.active_text')
              })
              .onClick(() => {
                this.context.getRouter().pushUrl({
                  url: 'pages/Webview',
                  params: {
                    title: $r('app.string.open_source_license'),
                    url: $rawfile('OpenSourceLicense.html')
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
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
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
          const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, '还在为找校园服务入口发愁？试试我正在使用的「你的科大」鸿蒙版！一站式导航+课表/考试管理，适配HarmonyOS NEXT，科大师生必备～你可以直接在华为应用市场搜索，或者去https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT找到它！');
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
    WithTheme({ colorMode: ThemeColorMode.LIGHT }) {
      Column() {
        Image(this.imagePixelMap ?? $r('app.media.nic'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .onDisAppear(() => {
            this.iconClickTime = 0;
            this.isShowEggImage = false;
          });
      }
      .linearGradient({
        angle: 45,
        colors: [[0xb1b2cd, 0.0], [0xf9f9fb, 0.75], [0xffffff, 1.0]]
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .overlay(this.ExitAndSave(), { align: Alignment.Top, offset: { x: 0, y: 45 } });
    }
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
    .width('100%')
    .height(42)
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
