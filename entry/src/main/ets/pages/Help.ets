
import { LengthUnit } from '@kit.ArkUI';
import { getContArray } from '../utils/tools';
import BackgroundImage from '../view/BgImageManager';

@Entry
@Component
struct Index {
  @State isContentShow: boolean[] = new Array(15).fill(false);
  context: UIContext = this.getUIContext();
  @State rotateAngle: number[] = new Array(15).fill(0);

  build() {

    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(22)
          .draggable(false)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })

        Blank()

        Text($r('app.string.help'))
          .fontSize(18)
          .height(48)
          .fontColor($r('app.color.normal_text'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()
          .margin({ right: 32 })
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .width('100%')
      .id('header')
      .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background') : undefined)
      .opacity(BackgroundImage.opacityLevel)
      .backgroundBlurStyle(BackgroundImage.blurLevel)

      List({ initialIndex: 0 }) {
        ForEach(getContArray([[0, 9]]), (index: number) => {
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
          };
        }, (item: string) => item.toString());

        ListItem()
          .visibility(Visibility.Hidden)
          .height('50vp')
      }
      .padding({ left: 15, right: 15 })
      .margin({ left: 12, right: 12 })
      .scrollBar(BarState.Auto)
      .height('100%')
      .width('100%');
    }
    .backgroundImage(BackgroundImage.pic)
    .backgroundImageSize(ImageSize.Cover)
    .backgroundImagePosition(Alignment.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.normal_background'));
  }
}