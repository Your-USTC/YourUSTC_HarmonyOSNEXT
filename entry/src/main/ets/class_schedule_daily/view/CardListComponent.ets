
import { CardListParameter } from '../viewmodel/CardListParameter';

@Component
export struct CardListComponent {
  @BuilderParam customBuilderParam: () => void = this.customBuilder;
  @Link cardListParameter: CardListParameter | undefined;
  @LocalStorageProp('lastRefresh') lastRefresh: string = '点击右上角按钮刷新';

  @Builder
  customBuilder() {
    // custom builder
  }

  build() {
    if (this.cardListParameter !== undefined) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column({ space: FlexAlign.Start }) {
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
            }.layoutWeight(1)

            Image($r('app.media.refresh'))
              .width(24)
              .height(24)
              .margin({ right: 10 })
              .onClick(() => {
                postCardAction(this, {
                  action: 'message',
                  params: { msgTest: 'messageEvent' }
                });
              })

            Image(this.cardListParameter.logo)
              .width(24)
              .height(24)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ bottom: 4 })
          Row() {
            Text(this.lastRefresh)
              .opacity(0.6)
              .fontSize(16)
              .margin({ left: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .justifyContent(FlexAlign.Start)
          .padding({ bottom: 4 })

          List() {
            this.customBuilderParam();
          }
          .width('100%')
          .height('100%')
          .alignListItem(ListItemAlign.Center)
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
        }
        .pixelRound({ bottom: PixelRoundCalcPolicy.FORCE_CEIL })

        Stack({ alignContent: Alignment.BottomEnd }) {
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
