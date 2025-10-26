import { CardListParameter } from '../viewmodel/CardListParameter';

const MAX_LINES = 1;

const LAYOUT_WEIGHT = 1;

const LINEAR_START_GRADIENT = 0.0;

const LINEAR_END_GRADIENT = 1.0;

@Component
export struct CardListComponent {
  @BuilderParam customBuilderParam: () => void = this.customBuilder;
  @Link cardListParameter: CardListParameter | undefined;
  /**
   * The max quantity of list items.
   */
  readonly maxQuantity = 99;
  /*
  * The width percentage setting.
  */
  readonly fullWidthPercent = '100%';
  /*
   * The height percentage setting.
   */
  readonly fullHeightPercent = '100%';

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
                .maxLines(MAX_LINES)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              if (this.cardListParameter.isItemCount !== undefined && this.cardListParameter.itemCount !== undefined) {
                Text(this.cardListParameter.itemCount > this.maxQuantity ? '99+' :
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
            }.layoutWeight(LAYOUT_WEIGHT)

            Image(this.cardListParameter.logo)
              .width(20)
              .height(20)
              .margin({ left: 28 })
          }
          .width(this.fullWidthPercent)
          .alignItems(VerticalAlign.Top)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ bottom: 4 })

          List() {
            this.customBuilderParam();
          }
          .width(this.fullWidthPercent)
          .height(this.fullHeightPercent)
          .layoutWeight(LAYOUT_WEIGHT)
          .scrollBar(BarState.Off)
        }
        .pixelRound({ bottom: PixelRoundCalcPolicy.FORCE_CEIL })

        Stack({ alignContent: Alignment.BottomEnd }) {
          if (this.cardListParameter.isMask !== undefined) {
            Row()
              .width(this.fullWidthPercent)
              .height(24)
              .linearGradient({
                direction: GradientDirection.Top,
                repeating: false,
                colors: [[this.cardListParameter.maskColor, LINEAR_START_GRADIENT], [$r('app.color.transparent'), 1.0]]
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
        .width(this.fullWidthPercent)
      }
      .backgroundImage(this.cardListParameter.backgroundImage)
      .backgroundImageSize(this.cardListParameter.backgroundImageSize)
      .backgroundColor(this.cardListParameter.backgroundColor)
      .padding(12)
    }
  }
}