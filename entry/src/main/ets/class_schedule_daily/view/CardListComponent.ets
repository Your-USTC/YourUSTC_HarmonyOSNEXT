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
                .fontSize($r('app.float.list_title_font_size'))
                .fontWeight(FontWeight.Bold)
                .height($r('app.float.list_title_height'))
                .fontColor(this.cardListParameter.titleColor)
                .padding({ right: $r('app.float.list_title_padding_right') })
                .maxLines(MAX_LINES)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              if (this.cardListParameter.isItemCount !== undefined && this.cardListParameter.itemCount !== undefined) {
                Text(this.cardListParameter.itemCount > this.maxQuantity ? '99+' :
                  this.cardListParameter.itemCount + '')
                  .textAlign(TextAlign.Center)
                  .fontSize($r('app.float.item_count_font_size'))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.cardListParameter.itemCountColor)
                  .backgroundColor(this.cardListParameter.itemCountBackgroundColor)
                  .width($r('app.float.item_count_width'))
                  .height($r('app.float.item_count_height'))
                  .borderRadius($r('app.float.item_count_radius'))
              }
            }.layoutWeight(LAYOUT_WEIGHT)

            Image(this.cardListParameter.logo)
              .width($r('app.float.list_logo_size'))
              .height($r('app.float.list_logo_size'))
              .margin({ left: $r('app.float.icon_margin') })
          }
          .width(this.fullWidthPercent)
          .alignItems(VerticalAlign.Top)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ bottom: $r('app.float.list_row_padding_bottom') })

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
              .height($r('app.float.list_mask_height'))
              .linearGradient({
                direction: GradientDirection.Top,
                repeating: false,
                colors: [[this.cardListParameter.maskColor, LINEAR_START_GRADIENT], ['#00ffffff', LINEAR_END_GRADIENT]]
              })
              .pixelRound({ bottom: PixelRoundCalcPolicy.FORCE_CEIL })
              .hitTestBehavior(HitTestMode.None)
          }

          if (this.cardListParameter.isBottomIcon !== undefined) {
            Image(this.cardListParameter.bottomIcon)
              .width($r('app.float.bottom_icon_size'))
              .height($r('app.float.bottom_icon_size'))
          }
        }
        .width(this.fullWidthPercent)
      }
      .backgroundImage(this.cardListParameter.backgroundImage)
      .backgroundImageSize(this.cardListParameter.backgroundImageSize)
      .backgroundColor(this.cardListParameter.backgroundColor)
      .padding({
        top: $r('app.float.list_side_padding'),
        bottom: $r('app.float.list_side_padding'),
        left: $r('app.float.list_side_padding'),
        right: $r('app.float.list_side_padding')
      })
    }
  }
}