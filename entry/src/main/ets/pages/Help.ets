
import { ItemRestriction, LengthUnit, SegmentButton, SegmentButtonOptions, SegmentButtonTextItem } from '@kit.ArkUI';
import { getContArray } from '../utils/tools';
import BackgroundImage from '../view/BgImageManager';
import UnifiedPreferences from '../utils/UnifyPreference';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State isContentShow: boolean[] = new Array(15).fill(false);
  context: UIContext = this.getUIContext();
  @State rotateAngle: number[] = new Array(15).fill(0);

  @State tabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: $r('app.string.online_help') }, { text: $r('app.string.help') }] as ItemRestriction<SegmentButtonTextItem>,
    backgroundBlurStyle: BackgroundImage.blurLevel
  });

  @State @Watch('onSegmentButtonChange') tabSelectedIndexes: number[] = [0];
  private tabsController: TabsController = new TabsController();
  onSegmentButtonChange() {
    this.tabsController.changeIndex(this.tabSelectedIndexes[0]);
  }

  webviewController: webview.WebviewController = new webview.WebviewController();
  webAutoDarkMode: boolean = UnifiedPreferences.getBoolSync('webAutoDarkMode', true);

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Tabs({ controller: this.tabsController }) {
        TabContent() {
          this.OnlineHelp();
        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

        TabContent() {
          this.LocalHelp();
        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .barHeight(0)
      .onAnimationStart((index: number, targetIndex: number, event: TabsAnimationEvent) => {
        if (index === targetIndex) {
          return;
        }
        // selectedIndex控制自定义TabBar内Image和Text颜色切换
        this.tabSelectedIndexes[0] = targetIndex;
      })

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
          this.getUIContext().getRouter().back();
        })

        Blank()

        SegmentButton({
          options: this.tabOptions,
          selectedIndexes: $tabSelectedIndexes,
        })
          .width('50%')
          .constraintSize({ maxWidth: 500 })

        Blank().margin({ right: 32 })
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .width('100%')
      // .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background') : undefined)
      .opacity(BackgroundImage.opacityLevel)
      .padding({ top: 10, left: 10, right: 10 })
    }
    .backgroundImage(BackgroundImage.pic)
    .backgroundImageSize(ImageSize.Cover)
    .backgroundImagePosition(Alignment.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.normal_background'));
  }


  @Builder
  OnlineHelp() {
    Web({ src: 'https://ustc.edu.cn', controller: this.webviewController })
      .domStorageAccess(true)
      .javaScriptAccess(true)
      .width('100%')
      .height('100%')
      .darkMode(this.webAutoDarkMode ? WebDarkMode.Auto : WebDarkMode.Off)
      .forceDarkAccess(this.webAutoDarkMode)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .onErrorReceive((event) => {
        // Only handle loading errors of the main framework to avoid duplicate processing of errors in sub-resources
        if (event && event.request.isMainFrame()) {
          this.tabSelectedIndexes = [1];
          try {
            this.webviewController.loadUrl($rawfile('WebError.html')); // 加载自定义错误页面
          } catch (error) {
            console.error(`ErrorCode: ${(error as BusinessError).code}, Message: ${(error as BusinessError).message}`);
          }
        }
      })
  }


  @Builder
  LocalHelp() {
    List({ initialIndex: 0 }) {
      ListItem().height(52)

      ForEach(getContArray([[0, 8]]), (index: number) => {
        ListItem() {
          Column() {
            Row() {
              Text($r(`app.string.help${index}_title`))
                .margin({ right: 15 })
                .fontWeight(FontWeight.Bold);
              Image($r('app.media.chevron_right'))
                .height(20)
                .rotate({ angle: this.rotateAngle[index] })
                .animation({
                  duration: 300,
                  curve: Curve.Friction,
                  playMode: PlayMode.Alternate,
                  expectedFrameRateRange: {
                    min: 20,
                    max: 120,
                    expected: 90,
                  }
                });
            }
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .onClick(() => {
              this.context.animateTo({
                // 设置按钮收起展开动画效果
                duration: 300,
                onFinish: () => {
                  console.info('animation end');
                }
              }, () => {
                this.isContentShow[index] = !this.isContentShow[index];
              });
              if (this.rotateAngle[index] === 0)
                this.rotateAngle[index] = 90;
              else
                this.rotateAngle[index] = 0;
            });

            if (this.isContentShow[index]) { // 判断当前按钮为“收起”显示内容区域
              Divider()
                .color($r('app.color.grid_border'));

              Text($r(`app.string.help${index}_content`))
                .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.help_context'))
                .borderRadius({ bottomLeft: 20, bottomRight: 20 })
                .textAlign(TextAlign.Start)
                .lineSpacing({ value: 5, unit: LengthUnit.FP })
                .width('100%')
                .padding({ top: 10, bottom: 10, left: 20, right: 20 })
            }
          }
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
          .opacity(BackgroundImage.opacityLevel)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .width('100%')
          .margin({ top: 10 })
          .borderRadius(20);
        }
      }, (item: string) => item.toString());

      ListItem().height('50vp')
    }
    .padding({ left: 15, right: 15 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .scrollBar(BarState.Auto)
    .height('100%')
    .width('100%');
  }
}