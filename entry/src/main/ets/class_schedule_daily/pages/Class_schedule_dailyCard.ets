
import * as tools from '../../utils/tools';
import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';

interface CardListItemData {
  title: ResourceStr;
  content: ResourceStr;
  icon?: Resource;
}

@Entry
@Component
struct Class_schedule_dailyCard {
  readonly cardList: number[] = tools.getContArray([[0,9]]) as number[];
  @State cardListParameter: CardListParameter = new CardListParameter($r('sys.color.ohos_id_color_background'),
    $r('app.string.card_list_title'), '', ImageSize.Auto, $r('app.media.icon_round'), true,
    $r('app.color.fade'), true, this.cardList.length, $r('sys.color.ohos_id_color_emphasize'),    // TODO: 浅色模式显示有问题，深色没事
    $r('app.color.list_item_count_background'), '', true, $r('app.media.bottom_icon'));

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
        .width('100%')
      }
      .width('100%')
      .height(44)
    }, (item: number, index) => index + JSON.stringify(item))
  }

  build() {
    Row() {
      CardListComponent({ cardListParameter: this.cardListParameter }) {
        this.cardListBuilder();
      }
    }
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { message: 'add detail' }
      });
    })
  }
}
