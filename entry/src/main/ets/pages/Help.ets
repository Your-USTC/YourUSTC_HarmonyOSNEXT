import { curves } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
  @State isContentShow: boolean[] = new Array(15).fill(false);
  context: UIContext = this.getUIContext();
  @State rotateAngle: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  build() {

    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(20)
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
      .backgroundColor($r('app.color.shaded_background'))


      List({ initialIndex: 0 }) {
        ForEach(this.arr, (item: number, index: number) => {
          ListItem() {
            Column() {
              Row() {
                Text(item.toString());
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
                Text('这是内容区域')
                  .backgroundColor($r('app.color.transparent_text'))
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .height(100);
              }
            }
            .backgroundColor($r('app.color.grid_background'))
            .width('100%')
            .margin({ top: 10 })
            .borderRadius(20);
          };
        }, (item: string) => item.toString());
      }
      .padding({ left: 15, right: 15 })
      .margin({ left: 12, right: 12})
      .scrollBar(BarState.Auto)
      .height('100%')
      .width('100%');
    }
    .backgroundColor($r('app.color.normal_background'));
  }
}