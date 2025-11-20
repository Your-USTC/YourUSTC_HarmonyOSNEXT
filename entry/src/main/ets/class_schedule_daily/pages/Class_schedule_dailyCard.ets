
import * as tools from '../../utils/tools';
import * as Schedule from '../../pages/Schedule'
import { classAttribute } from '../../pages/Schedule';
import scheduleManager from '../../utils/TimeTable';
import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';
import UnifiedPreference from '../../utils/UnifyPreference';

@Entry
@Component
struct Class_schedule_dailyCard {

  private currentTime: Date = new Date();
  @State todayCourse: classAttribute[] = [{ name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2', weekOfTerm: tools.getContArray([[2, 10], [13, 16]]) as number[], timeSpan: [6, 7], dayOfWeek: 0 }];
  @State isTodayCourseEnd: boolean = true;
  @State tomorrowCourse: classAttribute[] = [];

  aboutToAppear(): void {
    // TODO: 获取课程数据 (与应用中不一样)
  }

  @State cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* logo                     */ $r('app.media.icon_round'),
    /* isMask                   */ true,
    /* maskColor                */ $r('app.color.fade'),
    /* isItemCount              */ true,
    /* itemCount                */ this.todayCourse.length,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  )

  @Builder
  cardListBuilder() {

    // TODO: 删除示例课程 👇👇
    ListItem() {
      Row() {
        Column() {
          Text($r('app.string.under_construction'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Start)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text($r('app.string.class_in_session'))
            .fontColor($r('app.color.bright_blue'))
        }
        .width('50%')
        .alignItems(HorizontalAlign.Start)
        .padding({ right: 10 });

        Column() {
          Text(`\udb81\uddf3 ？？？`)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`\udb80\uddb8 ？？？`)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`\udb80\udfdc 07:21~11:45`)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('50%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('90%')
    .margin({ top: 7, bottom: 7 })

    Divider()
      .width('95%')
  }

  build() {
    Column() {
      CardListComponent({ cardListParameter: this.cardListParameter }) {
        this.cardListBuilder();
      }
    }
    .width('100%')
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
