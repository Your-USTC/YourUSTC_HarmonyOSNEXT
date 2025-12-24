
/**
 * 卡片框架
 */

import { CardListParameter } from '../viewmodel/CardListParameter';

@Component
export struct CardListComponent {

  // 外部参数
  @Link cardListParameter: CardListParameter | undefined;

  // 内部变量
  @BuilderParam customBuilderParam: () => void = this.customBuilder;
  @LocalStorageProp('lastRefresh') lastRefresh: string = '点击右侧按钮刷新';

  @Builder
  customBuilder() {
    // custom builder
  }

  build() {
    if (this.cardListParameter !== undefined) {
      Stack({ alignContent: Alignment.Bottom }) {
        // 卡片主体区域
        Column({ space: FlexAlign.Start }) {
          // 标题区域
          Row() {
            Row() {
              Text(this.cardListParameter.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .height(24)
                .fontColor(this.cardListParameter.titleColor)
                .padding({ right: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              if (this.cardListParameter.isItemCount === true && this.cardListParameter.itemCount !== undefined) {
                Text(this.cardListParameter.itemCount > 99 ? '99+' :
                  this.cardListParameter.itemCount + '')
                  .textAlign(TextAlign.Center)
                  .fontSize(10)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.cardListParameter.itemCountColor)
                  .backgroundColor(this.cardListParameter.itemCountBackgroundColor)
                  .width(24)
                  .height(16)
                  .borderRadius(8)
              }
            }
            .layoutWeight(1)

            Text(this.lastRefresh)
              .opacity(0.8)
              .fontSize(14)
              .margin({ right: 4 })

            Image($r('app.media.refresh'))
              .width(24)
              .height(24)
              .onClick(() => {
                postCardAction(this, {
                  action: 'message',
                  params: { msgTest: 'messageEvent' }
                });
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ bottom: 4 })

          // 课程列表模块
          List() {
            this.customBuilderParam()
          }
          .width('100%')
          .height('100%')
          .alignListItem(ListItemAlign.Center)
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
        }
        .pixelRound({ bottom: PixelRoundCalcPolicy.FORCE_CEIL })

        // 卡片底部区域
        Stack({ alignContent: Alignment.BottomEnd }) {
          // 底部渐变遮罩
          if (this.cardListParameter.isMask !== undefined) {
            Row()
              .width('100%')
              .height(24)
              .linearGradient({
                direction: GradientDirection.Top,
                repeating: false,
                colors: [[this.cardListParameter.maskColor, 0.0], [$r('app.color.transparent'), 1.0]]
              })
              .pixelRound({ bottom: PixelRoundCalcPolicy.FORCE_CEIL })
              .hitTestBehavior(HitTestMode.None)
          }

          // 右下角图标
          if (this.cardListParameter.isBottomIcon !== undefined) {
            Image(this.cardListParameter.bottomIcon)
              .width(32)
              .height(32)
          }
        }
        .width('100%')
      }
      .backgroundImage(this.cardListParameter.backgroundImage)
      .backgroundImageSize(this.cardListParameter.backgroundImageSize)
      .backgroundColor(this.cardListParameter.backgroundColor)
      .padding(12)
    }
  }
}
