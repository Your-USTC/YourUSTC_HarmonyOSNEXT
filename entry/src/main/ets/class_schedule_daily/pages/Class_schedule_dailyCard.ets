import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';

const MAX_LINES = 1;

const STROKE_WIDTH = 0.38;

const LAYOUT_WEIGHT = 1;

const CARD_LENGTH = 10;

function getCardList(): number[] {
  const arr: number[] = [];
  for (let index = 0; index < CARD_LENGTH; index++) {
    arr.push(index);
  }
  return arr;
}

@Entry
@Component
struct Class_schedule_dailyCard {
  readonly cardList: number[] = getCardList();
  @State cardListParameter: CardListParameter = new CardListParameter($r('sys.color.ohos_id_color_background'),
    $r('app.string.card_list_title'), '', ImageSize.Auto, $r('app.media.startIcon'), true,
    $r('sys.color.ohos_id_color_background'), true, this.cardList.length, $r('sys.color.ohos_id_color_emphasize'),
    $r('app.color.list_item_count_background'), '', true, $r('app.media.bottom_icon'));
  /*
   * The action type.
   */
  readonly actionType = 'router';
  /*
   * The ability name.
   */
  readonly abilityName = 'EntryAbility';
  /*
   * The message.
   */
  readonly message = 'add detail';
  /*
   * The width percentage setting.
   */
  readonly fullWidthPercent = '100%';
  /*
   * The height percentage setting.
   */
  readonly fullHeightPercent = '100%';
  readonly cardListData: CardListItemData = {
    title: $r('app.string.card_list_title'),
    content: $r('app.string.card_list_content'),
    icon: $r('app.media.list_item')
  };

  @Builder
  cardListBuilder() {
    ForEach(this.cardList, () => {
      ListItem() {
        Row() {
          Column() {
            Text(this.cardListData.title)
              .maxLines(MAX_LINES)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize($r('app.float.item_content_font_size'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.black'))
              .height($r('app.float.item_text_height'))
              .margin({ top: $r('app.float.item_text_margin') })
            Text(this.cardListData.content)
              .maxLines(MAX_LINES)
              .fontSize($r('app.float.item_content_font_size'))
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontWeight(FontWeight.Regular)
              .height($r('app.float.item_text_height'))

            Divider()
              .strokeWidth(STROKE_WIDTH)
              .lineCap(LineCapStyle.Square)
              .margin({ top: $r('app.float.list_divider_margin') })
          }
          .margin({ right: $r('app.float.list_row_margin') })
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(LAYOUT_WEIGHT)

          Image(this.cardListData.icon)
            .width($r('app.float.item_image_size'))
            .height($r('app.float.item_image_size'))
        }
        .alignItems(VerticalAlign.Center)
        .width(this.fullWidthPercent)
      }
      .width(this.fullWidthPercent)
      .height($r('app.float.item_height'))
    }, (item: number, index) => index + JSON.stringify(item))
  }

  build() {
    Row() {
      CardListComponent({ cardListParameter: this.cardListParameter }) {
        this.cardListBuilder();
      }
    }
    .height(this.fullHeightPercent)
    .onClick(() => {
      postCardAction(this, {
        action: this.actionType,
        abilityName: this.abilityName,
        params: {
          message: this.message
        }
      });
    })
  }
}

interface CardListItemData {
  title: ResourceStr;
  content: ResourceStr;
  icon?: Resource;
}