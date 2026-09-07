
import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import { CheckInTools } from '../utils/CheckIn'
import { common } from '@kit.AbilityKit';
import { WantAbility } from '../utils/WantAbility';


@Builder
export function CheckinBuilder(name: string, param?: object) {
  CheckinGallery();
}

@Entry
@Component
struct CheckinGallery {

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
  @State LPercent: number = 0;
  @State RPercent: number = 0;
  build() {
    NavDestination() {
      List() {
        ForEach(CheckInTools.getCollectionStatus(), (item: boolean, index: number) => {
          ListItem() {
            if (item) {
              Row() {
                Text(CheckInTools.CHECK_IN_CONTENT_LIST[index])
                  .layoutWeight(1)
                  .wordBreak(WordBreak.BREAK_ALL)
              }
              .width('100%')
            } else {
              Row() {
                Image($r('app.media.lock'))
                  .width(24)
                  .height(24)
                  .draggable(false)
                  .margin({ right: 8 })
                Text('？？？')
                  .layoutWeight(1)
              }
              .width('100%')
            }
          }
          .margin({ top: 10 })
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
        })


        ListItem() { // 没什么用的小动画(doge)
          Stack({ alignContent: Alignment.Start }) {
            Text($r('app.string.require_more_sentences'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .fontSize(14)

            Row() {
              Row()
                .width(`${this.LPercent}%`)
                .height(70)
                .renderFit(RenderFit.RESIZE_COVER)
              Row()
                .width(`${this.RPercent}%`)
                .backgroundColor(presetColor[BackgroundImage.themeColor][2])
                .height(70)
                .renderFit(RenderFit.RESIZE_COVER)
            }
            .width('100%')
          }
          .height(70)
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .width('100%')
          .onClick(() => {
            this.LPercent = this.RPercent = 0;
            this.getUIContext().keyframeAnimateTo({ iterations: 1 },
              [{
                duration: 500,
                curve: Curve.Ease,
                event: () => {
                  this.RPercent = 100;
                }
              }, {
                duration: 500,
                curve: Curve.Ease,
                event: () => {
                  this.LPercent = 100;
                  this.RPercent = 0;
                }
              }]
            );
            WantAbility.StartQQ(this.getUIContext().getHostContext() as common.UIAbilityContext);
          })
        }
        .margin({ top: 10, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .alignListItem(ListItemAlign.Center)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .padding({ left: 12, right: 12 })
    }
    .title({ main: $r('app.string.archive'), sub: $r('app.string.unlock_item_num', CheckInTools.getCollectionNumber(), CheckInTools.CHECK_IN_CONTENT_LIST.length) }, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined
    })
    .menus(this.menuItems)
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}
