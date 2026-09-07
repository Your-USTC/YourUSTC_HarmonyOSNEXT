
import { LengthUnit } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { getRandomInt } from '../utils/tools'
import BackgroundImage from '../utils/BgImageManager'
import { common } from '@kit.AbilityKit'
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import UpdateInfo from '../view/UpdateInfo';
import { WantAbility } from '../utils/WantAbility'
import { currentAppVersion } from '../constants/BasicConstants'
import { SimpleLink } from '../constants/Links'

@Builder
export function AboutBuilder(name: string, param?: Object) {
  About();
}

@Entry
@Component
struct About {

  private context = this.getUIContext();
  private iconClickTime: number = 0;
  @State isShowEggImage: boolean = false;
  @State imagePixelMap?: image.PixelMap = undefined;
  @State showUpdateLog: boolean = false;

  private shareController: systemShare.ShareController | undefined = undefined;
  private iconThumbnail: Uint8Array | undefined = undefined;

  async getImage() {
    this.imagePixelMap = await this.getPixmapFromMedia($r('app.media.nic'))
  }

  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        Scroll() {
          Column() {
            Column() {
              Image($r('app.media.ciallo'))
                .width('90%')
                .draggable(false)
                .constraintSize({ maxWidth: 300 })
                .onClick(() => {
                  this.context.getPromptAction()
                    .showToast({ message: $r('app.string.egg_hint' + getRandomInt(1, 2).toString()) });
                  this.iconClickTime++;
                  if (this.iconClickTime >= 7) {
                    this.isShowEggImage = true;
                  }
                })
                .bindContentCover(this.isShowEggImage, this.EggImage(), ModalTransition.DEFAULT)

              Text($r('app.string.welcome_to_your_ustc'))
                .fontSize(22)
                .fontColor($r('app.color.normal_text'))
                .fontWeight(FontWeight.Bold)

              Text() {
                Span($r('app.string.version', currentAppVersion))
                  .onClick(() => {
                    this.showUpdateLog = true;
                  })
                Span('  |  ')
                  .decoration(undefined)
                  .fontColor(undefined)
                Span($r('app.string.homepage_website'))
                  .onClick(() => {
                    this.pathStack.pushPath({ name: 'Webview', param: {
                      title: $r('app.string.homepage_website'),
                      url: 'https://dailynic.feixu.site/'
                    } as SimpleLink});
                  })
                Span('  |  ')
                  .decoration(undefined)
                  .fontColor(undefined)
                Span($r('app.string.join_qq_group'))
                  .onClick(() => {
                    WantAbility.StartQQ(this.getUIContext().getHostContext() as common.UIAbilityContext);
                  })
              }
              .margin({ top: 10, bottom: 10 })
              .fontColor($r('app.color.active_text'))
              .decoration({
                type: TextDecorationType.Underline,
                color: $r('app.color.active_text')
              })
              .bindSheet($$this.showUpdateLog, this.UpdateLog(), {
                detents: [SheetSize.LARGE],
                preferType: SheetType.CENTER,
                title: { subtitle: $r('app.string.version', currentAppVersion), title: $r('app.string.update_log') },
                backgroundColor: '#0000',
                blurStyle: BlurStyle.Regular
              })

              Text() {
                Span($r('app.string.github'))
                  .fontColor($r('app.color.active_text'))
                  .decoration({
                    type: TextDecorationType.Underline,
                    color: $r('app.color.active_text')
                  })
                  .onClick(() => {
                    this.context.showAlertDialog({
                      title: $r('app.string.about_to_open_github'),
                      message: $r('app.string.about_to_open_github_failed'),
                      confirm: {
                        value: $r('app.string.ok'),
                        action: () => {
                          WantAbility.openGitHub(this.getUIContext().getHostContext() as common.UIAbilityContext);
                        }
                      }
                    });
                  })

                ImageSpan($r('app.media.GPLv3'))
                  .height(20)
                  .margin({ left: 10 })
                  .objectFit(ImageFit.Fill)
                  .verticalAlign(ImageSpanAlignment.BOTTOM)
                  .onClick(() => {
                    this.pathStack.pushPath({ name: 'Webview', param: {
                      title: $r('app.string.open_source_license'),
                      url: $rawfile('OpenSourceLicense.html')
                    } as SimpleLink});
                  })
              }

              Row({ space: 15 }) {
                Text($r('app.string.developer_list'))
                  .textAlign(TextAlign.Center)
                Text($r('app.string.special_thanks'))
                  .textAlign(TextAlign.Center)
              }
              .alignItems(VerticalAlign.Top)
              .margin({ top: 15 })

              Text($r('app.string.credits'))
                .textAlign(TextAlign.Center)
                .lineSpacing({ value: 5, unit: LengthUnit.FP })
                .margin({ top: 15, bottom: 15 })

              Text() {
                Span($r('app.string.terms_of_use_and_privacy_policy'))
                  .onClick(() => {
                    this.pathStack.pushPath({ name: 'Webview', param: {
                      title: $r('app.string.terms_of_use_and_privacy_policy'),
                      url: $rawfile('TermsOfUse.html')
                    } as SimpleLink});
                  })

                Span('  |  ')
                  .decoration(undefined)
                  .fontColor(undefined)

                Span($r('app.string.beian_info'))
                  .onClick(() => {
                    this.pathStack.pushPath({ name: 'Webview', param: {
                      title: $r('app.string.beian_query'),
                      url: 'https://beian.miit.gov.cn/'
                    } as SimpleLink});
                  })
              }
              .fontSize(12)
              .fontColor($r('app.color.active_text'))
              .decoration({
                type: TextDecorationType.Underline,
                color: $r('app.color.active_text')
              })
            }
            .margin({ top: 20 })
            .padding(10)
            .borderRadius(12)
            .backgroundBlurStyle(BackgroundImage.blurLevel)
            .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
        .padding({ bottom: 20 })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

        Row() {
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.close'))
              .height(24)
              .width(24)
              .draggable(false)
          }
          .height(42)
          .width(42)
          .backgroundColor($r('app.color.grid_background'))
          .onClick(() => {
            this.pathStack.pop();
          });

          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.share'))
              .height(24)
              .width(24)
              .draggable(false)
          }
          .height(42)
          .width(42)
          .backgroundColor($r('app.color.grid_background'))
          .onClick(() => {
            if (this.iconThumbnail === undefined) {
              // 获取资源文件内容，返回Uint8Array。
              this.iconThumbnail = ((this.context.getHostContext() as common.UIAbilityContext).resourceManager).getRawFileContentSync('IconThumbnail.png');
            }

            if (this.shareController === undefined) {
              // 构造ShareData，需配置一条有效数据信息
              const shareData = new systemShare.SharedData({
                utd: uniformTypeDescriptor.UniformDataType.TEXT,
                content: '还在为找校园服务入口发愁？试试我正在使用的「妮可之记」鸿蒙版！一站式导航+课表/考试管理，适配HarmonyOS NEXT，科大师生必备～你可以直接在华为应用市场搜索，或者去https://github.com/Your-USTC/DailyNic_HMOS找到它！',
                title: '妮可之记 for HarmonyOS NEXT',
                thumbnail: this.iconThumbnail,
                description: '专为HarmonyOS NEXT开发，轻松查询课表、考试安排，支持校园服务网页一键访问，开源免费且无任何广告，深度适配鸿蒙系统特性，让你的校园生活更高效。'
              });
              shareData.addRecord({
                utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
                content: 'https://dailynic.feixu.site',
                title: '妮可之记 for HarmonyOS NEXT',
                thumbnail: this.iconThumbnail,
                description: '专为HarmonyOS NEXT开发，轻松查询课表、考试安排，支持校园服务网页一键访问，开源免费且无任何广告，深度适配鸿蒙系统特性，让你的校园生活更高效。'
              });
              this.shareController = new systemShare.ShareController(shareData);
            }
            this.shareController.show(this.context.getHostContext() as common.UIAbilityContext, {
              selectionMode: systemShare.SelectionMode.SINGLE,
              previewMode: systemShare.SharePreviewMode.DETAIL,
            }).then(() => {
              console.info('ShareController show success.');
            }).catch((error: BusinessError) => {
              console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
            });
          });
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding({ top: 8, left: 12, right: 12 })
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.getImage();
    })
    .onDisAppear(() => {
      this.imagePixelMap?.release();
    })
  }

  @Builder
  UpdateLog() {
    UpdateInfo()
      .padding({ bottom: 12 })
  }

  @Builder
  EggImage() {
    WithTheme({ colorMode: ThemeColorMode.LIGHT }) {
      Row() {
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .height(42)
        .width(42)
        .onClick(() => {
          this.isShowEggImage = false;
          this.iconClickTime = 0;
        })
        Blank();
        SaveButton({ icon: SaveIconStyle.FULL_FILLED })
          .width(42)
          .height(42)
          .iconSize(24)
          .onClick(async (event: ClickEvent, result: SaveButtonOnClickResult, error?) => {
            if (result === SaveButtonOnClickResult.SUCCESS) {
              try {
                let helper = photoAccessHelper.getPhotoAccessHelper(this.context.getHostContext());
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
                    this.context.getPromptAction().showToast({ message: $r('app.string.save_image_success') });
                  }
                });
              } catch (error) {
                this.context.getPromptAction().showToast({ message: $r('app.string.save_image_fail') });
              }
            } else {
              this.context.getPromptAction().showToast({ message: $r('app.string.save_image_fail') });
            }
          });
      }
      .linearGradient({
        angle: 45,
        colors: [[0xb1b2cd, 0.0], [0xf9f9fb, 0.75], [0xffffff, 1.0]]
      })
      .width('100%')
      .height('100%')
      .backgroundImage($r('app.media.nic'))
      .backgroundImageSize(ImageSize.Contain)
      .backgroundImagePosition(Alignment.Center)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .alignItems(VerticalAlign.Top)
      .padding({ top: 45, left: 10, right: 10 })
    }
  }

  private async getPixmapFromMedia(resource: Resource) {

    let createPixelMap: image.PixelMap
    try {

      const unit8Array = await this.context.getHostContext()!.resourceManager?.getMediaContent(resource.id)
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
