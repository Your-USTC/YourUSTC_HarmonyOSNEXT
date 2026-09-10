
import { LengthUnit } from '@kit.ArkUI';
import { getContArray } from '../utils/tools';
import BackgroundImage from '../utils/BgImageManager';
import { common } from '@kit.AbilityKit';
import { WantAbility } from '../utils/WantAbility';

@Builder
export function HelpBuilder(name: string, param?: Object) {
  Help();
}

@Entry
@Component
struct Help {
  @State isContentShow: boolean[] = new Array(15).fill(false);
  context: UIContext = this.getUIContext();
  @State rotateAngle: number[] = new Array(15).fill(0);

  menuItems: Array<NavigationMenuItem> = [
    {
      value: $r('app.string.join_qq_group'),
      icon: $r('app.media.message_on_message'),
      action: () => {
        WantAbility.StartQQ(this.getUIContext().getHostContext() as common.UIAbilityContext);
      }
    }
  ];
  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      List() {
        ForEach(getContArray([[0, 11]]), (index: number) => {
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
            .backgroundBlurStyle(BackgroundImage.blurLevel)
            .width('100%')
            .margin({ top: 10 })
            .borderRadius(20);
          };
        });

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
    .title($r('app.string.help'), {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : undefined
    })
    .menus(this.menuItems)
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}