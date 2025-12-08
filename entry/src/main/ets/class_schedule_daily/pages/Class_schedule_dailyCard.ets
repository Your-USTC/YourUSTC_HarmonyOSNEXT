import scheduleManager from '../../utils/TimeTable';
import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';
import * as ScheduleSources from '../../constants/ScheduleSources'

let localStorage = new LocalStorage();

@Entry(localStorage)
@Component
struct Class_schedule_dailyCard {
  @LocalStorageProp('todayCourse') todayCourse: ScheduleSources.classAttribute[] = [];
  @LocalStorageProp('tomorrowCourse') tomorrowCourse: ScheduleSources.classAttribute[] = [];

  @LocalStorageProp('cardListParameter') cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
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
    if (this.todayCourse.length == 0) {
      ListItem() {
        Column() {
          Image($r('app.media.no_course_today'))
            .height(50)
          Text(scheduleManager.isTermEnd ? $r('app.string.no_class_term_end') : $r('app.string.no_class_today'))
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height(scheduleManager.isTermEnd ? '100%' : undefined)
      .padding({ top: 12, bottom: 12 })
    } else {
      ForEach(this.todayCourse, (course: ScheduleSources.classAttribute, index: number) => {
        Row() {
          Column() {
            Text(course.name)
              .textAlign(TextAlign.Start)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .width('50%')
          .alignItems(HorizontalAlign.Start)
          .padding({ right: 10 });

          Column() {
            Text(`\udb81\uddf3 ${course.teacher}`)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .visibility(course.teacher == '' ? Visibility.None : Visibility.Visible);

            Text(`\udb80\uddb8 ${course.location}`)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .visibility(course.location == '' ? Visibility.None : Visibility.Visible);

            Text(`\udb80\udfdc ${ScheduleSources.commonClassTime[course.timeSpan[0]][0]}~${ScheduleSources.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('50%')
          .alignItems(HorizontalAlign.Start);
        }
        .width('90%')
        .margin({ top: 7, bottom: 7 });

        if (index < this.todayCourse.length - 1) {
          Divider()
            .width('90%');
        }
      });
    }

    if (this.tomorrowCourse.length > 0) {

      ListItem() {
        Row() {
          Text($r('app.string.tomorrow_class'))
            .fontSize(15)
            .margin({ right: 10 })
            .fontColor($r('app.color.pink'))

          Divider()
        }
      }
      .width('100%')
      .margin({ left: 5 })

      ForEach(this.tomorrowCourse, (course: ScheduleSources.classAttribute, index) => {
        if (index > 0) {
          Divider()
            .width('90%');
        }
        Row() {
          Column() {
            Text(course.name)
              .textAlign(TextAlign.Start)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .width('50%')
          .alignItems(HorizontalAlign.Start)
          .padding({ right: 10 });

          Column() {
            Text(`\udb81\uddf3 ${course.teacher}`)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .visibility(course.teacher == '' ? Visibility.None : Visibility.Visible);

            Text(`\udb80\uddb8 ${course.location}`)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .visibility(course.location == '' ? Visibility.None : Visibility.Visible);

            Text(`\udb80\udfdc ${ScheduleSources.commonClassTime[course.timeSpan[0]][0]}~${ScheduleSources.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('50%')
          .alignItems(HorizontalAlign.Start);
        }
        .width('90%')
        .margin({ top: 7, bottom: 7 })
      });
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
        params: { message: 'add detail', router: 'pages/Schedule'}
      });
    })
  }
}
