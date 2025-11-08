
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

      ForEach(this.todayCourse, (course: classAttribute, index: number) => {
        if (
          this.currentTime.getTime() <
            scheduleManager.weekStart + 57600000
              + scheduleManager.today * 86400000
              + Schedule.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]
              + 1800000
        ) {
          ListItem() {
            Row() {
              Column() {
                Text(course.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Start)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (
                  this.currentTime.getTime() <
                    scheduleManager.weekStart + 57600000
                      + scheduleManager.today * 86400000
                      + Schedule.commonClassStamp[course.timeSpan[0]][0]
                  && this.currentTime.getTime() >
                    scheduleManager.weekStart + 57600000
                      + scheduleManager.today * 86400000
                      + Schedule.commonClassStamp[course.timeSpan[0]][0]
                      - 1800000
                ) {
                  Text($r('app.string.class_soon'))
                    .fontColor($r('app.color.green'))

                } else if (
                  this.currentTime.getTime() >
                    scheduleManager.weekStart + 57600000
                      + scheduleManager.today * 86400000
                      + Schedule.commonClassStamp[course.timeSpan[0]][0]
                  && this.currentTime.getTime() <
                    scheduleManager.weekStart + 57600000
                      + scheduleManager.today * 86400000
                      + Schedule.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]
                ) {
                  Text($r('app.string.class_in_session'))
                    .fontColor($r('app.color.bright_blue'))

                } else if (
                  this.currentTime.getTime() >
                    scheduleManager.weekStart + 57600000
                      + scheduleManager.today * 86400000
                      + Schedule.commonClassStamp[course.timeSpan[course.timeSpan.length - 1]][1]
                ) {
                  Text($r('app.string.class_end'))
                    .fontColor($r('app.color.red'))

                } else {
                  Text($r('app.string.class_not_start'))
                    .fontColor($r('app.color.green'))
                }
              }
              .width('50%')
              .alignItems(HorizontalAlign.Start)
              .padding({ right: 10 });

              Column() {
                Text(`\udb81\uddf3 ${course.teacher == '' ? '' : course.teacher}`)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(`\udb80\uddb8 ${course.location == '' ? '' : course.location}`)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(`\udb80\udfdc ${Schedule.commonClassTime[course.timeSpan[0]][0]} - ${Schedule.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('50%')
              .alignItems(HorizontalAlign.Start)
            }
          }
          .width('90%')
          .margin({ top: 7, bottom: 7 })

          if (index < this.todayCourse.length - 1) {
            Divider()
              .width('95%')
          }
        }
      })

      if (this.isTodayCourseEnd) {
        ListItem() {
          Column() {
            Image($r('app.media.course_finish_today'))
              .height(50)

            Text($r('app.string.class_finish_today'))
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .margin({ top: 12, bottom: 12 })
      }
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

      ForEach(this.tomorrowCourse, (course: classAttribute, index) => {
        if (index > 0) {
          Divider()
            .width('95%')
        }

        ListItem() {
          Row() {
            Column() {
              Text(course.name)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('50%')
            .alignItems(HorizontalAlign.Start)
            .padding({ right: 10 });

            Column() {
              Text(`\udb81\uddf3 ${course.teacher == '' ? '' : course.teacher}`)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(`\udb80\uddb8 ${course.location == '' ? '' : course.location}`)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(`\udb80\udfdc ${Schedule.commonClassTime[course.timeSpan[0]][0]} - ${Schedule.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('50%')
            .alignItems(HorizontalAlign.Start)
          }
        }
        .width('90%')
        .margin({ top: 7, bottom: 7 })
      })
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
