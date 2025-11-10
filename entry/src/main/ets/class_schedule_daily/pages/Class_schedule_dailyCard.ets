
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
  @State todayCourse: classAttribute[] = [];
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

    if (this.todayCourse.length !== 0) {
      Column() {
        Image($r('app.media.no_course_today'))
          .height(50);
        Text(scheduleManager.isTermEnd ? $r('app.string.no_class_term_end') : $r('app.string.no_class_today'));
      }
      .justifyContent(FlexAlign.Center)
    } else {
      Column() {
        Image($r('app.media.default_function_icon'))
          .height(50);
      }
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
