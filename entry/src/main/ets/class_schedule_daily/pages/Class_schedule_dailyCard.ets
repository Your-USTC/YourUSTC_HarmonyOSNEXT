
import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';

function getCardList(): number[] {
  const arr: number[] = [];
  for (let index = 0; index < 10; index++) {
    arr.push(index);
  }
  return arr;
}

@Entry
@Component
struct Class_schedule_dailyCard {
  readonly cardList: number[] = getCardList();
  @State cardListParameter: CardListParameter = new CardListParameter($r('sys.color.ohos_id_color_background'),
    $r('app.string.card_list_title'), '', ImageSize.Auto, $r('app.media.icon_round'), true,
    $r('app.color.fade'), true, this.cardList.length, $r('sys.color.ohos_id_color_emphasize'),    // TODO: 浅色模式显示有问题，深色没事
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
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.black'))
              .height(16)
              .margin({ top: 5 })
            Text(this.cardListData.content)
              .maxLines(1)
              .fontSize(12)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontWeight(FontWeight.Regular)
              .height(16)

            Divider()
              .strokeWidth(0.38)
              .lineCap(LineCapStyle.Square)
              .margin({ top: 6 })
          }
          .margin({ right: 4 })
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Image(this.cardListData.icon)
            .width(32)
            .height(32)
        }
        .alignItems(VerticalAlign.Center)
        .width(this.fullWidthPercent)
      }
      .width(this.fullWidthPercent)
      .height(44)
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
