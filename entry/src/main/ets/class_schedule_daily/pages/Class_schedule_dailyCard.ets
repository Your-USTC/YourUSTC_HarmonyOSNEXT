
import * as tools from '../../utils/tools';
import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';
import { classAttribute } from '../../pages/Schedule';
import UnifiedPreference from '../../utils/UnifyPreference';
import scheduleManager from '../../utils/TimeTable';

interface CardListItemData {
  title: ResourceStr;
  content: ResourceStr;
  icon?: Resource;
}

@Entry
@Component
struct Class_schedule_dailyCard {

  @State cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* logo                     */ $r('app.media.icon_round'),
    /* isMask                   */ true,
    /* maskColor                */ $r('app.color.fade'),
    /* isItemCount              */ false,
    /* itemCount                */ undefined,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  );

  private currentTime: Date = new Date();
  @State todayCourse: classAttribute[] = [];
  @State tomorrowCourse: classAttribute[] = [];

  aboutToAppear(): void {    // TODO: 获取课程数据 (与应用中不一样)
    //scheduleManager.getFormattedSchedule();
    //this.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
    //this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed + Math.floor((scheduleManager.today + 1) / 7)][(scheduleManager.today + 1) % 7];
  }

  @Builder
  cardListBuilder() {
    if (this.todayCourse.length == 0) {
      ListItem() {
        Column() {
          Image($r('app.media.no_course_today'))
            .height(50);
          Text($r('app.string.no_class_today'));
        }
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .height('100%')
    } else {

    }
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
