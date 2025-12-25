
/**
 * 卡片主程序
 */

import * as ScheduleSources from '../../constants/ScheduleSources';
import scheduleManager from '../../utils/TimeTable';
import { CardListComponent } from '../view/CardListComponent';
import { CardListParameter } from '../viewmodel/CardListParameter';

let localStorage = new LocalStorage();

@Entry(localStorage)
@Component
struct Class_schedule_dailyCard {

  // 内部变量
  @LocalStorageProp('todayCourse') todayCourse: ScheduleSources.classAttribute[] = [];
  @LocalStorageProp('tomorrowCourse') tomorrowCourse: ScheduleSources.classAttribute[] = [];

  @LocalStorageProp('cardListParameter') cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* isMask                   */ true,
    /* maskColor                */ $r('app.color.pure_white_or_black'),
    /* isItemCount              */ true,
    /* itemCount                */ this.todayCourse.length,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  );

  // 课程列表模块
  @Builder
  cardListBuilder() {

    if (this.todayCourse.length == 0) {
      // 今天没有课程
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
      // 今天有课程
      ForEach(this.todayCourse, (course: ScheduleSources.classAttribute, index: number) => {
        // 课程信息
        Row() {
          Column() {
            Line()
              .stroke((course.color.length === 9) ? `#${course.color.slice(3)}` : ((course.color.length === 5) ? `#${course.color.slice(2)}` : course.color))
              .width(6)
              .height(20)
              .strokeLineCap(LineCapStyle.Round)
              .strokeWidth(6)
              .startPoint([3, 0])
              .endPoint([3, 20])
              .margin({ right: 4 });
          }
          .alignItems(HorizontalAlign.End)
          .width('5%')

          Column() {
            Text(course.name)
              .textAlign(TextAlign.Start)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('45%')
          .alignItems(HorizontalAlign.Start)
          .padding({ right: 10 })

          Column() {
            Text(`\udb81\uddf3 ${course.teacher}`)
              .maxLines(1)
              .fontSize(13)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .visibility(course.teacher == '' ? Visibility.None : Visibility.Visible)

            Text(`\udb80\uddb8 ${course.location}`)
              .maxLines(1)
              .fontSize(13)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .visibility(course.location == '' ? Visibility.None : Visibility.Visible)

            Text(`\udb80\udfdc ${ScheduleSources.commonClassTime[course.timeSpan[0]][0]}~${ScheduleSources.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
              .maxLines(1)
              .fontSize(13)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('50%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({ top: 7, bottom: 7 })

        if (index < this.todayCourse.length - 1) {
          Divider()
            .width('90%')
        }
      })
    }

    if (this.tomorrowCourse.length > 0) {
      // 明天有课程

      // 小标题
      ListItem() {
        Row() {
          Text($r('app.string.tomorrow_class'))
            .fontSize(12)
            .margin({ right: 5 })
            .fontColor($r('app.color.pink'))

          Divider()
        }
      }
      .width('100%')
      .margin({ left: 5 })

      ForEach(this.tomorrowCourse, (course: ScheduleSources.classAttribute, index) => {
        if (index > 0) {
          Divider()
            .width('90%')
        }

        // 课程信息
        Row() {
          Column() {
            Text(course.name)
              .textAlign(TextAlign.Start)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('50%')
          .alignItems(HorizontalAlign.Start)
          .padding({ right: 10 });

          Column() {
            Text(`\udb81\uddf3 ${course.teacher}`)
              .maxLines(1)
              .fontSize(13)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .visibility(course.teacher == '' ? Visibility.None : Visibility.Visible)

            Text(`\udb80\uddb8 ${course.location}`)
              .maxLines(1)
              .fontSize(13)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .visibility(course.location == '' ? Visibility.None : Visibility.Visible)

            Text(`\udb80\udfdc ${ScheduleSources.commonClassTime[course.timeSpan[0]][0]}~${ScheduleSources.commonClassTime[course.timeSpan[course.timeSpan.length - 1]][1]}`)
              .maxLines(1)
              .fontSize(13)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('50%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('90%')
        .margin({ top: 7, bottom: 7 })
      })
    }
  }

  // 卡片主程序
  build() {
    Column() {
      // 卡片框架
      CardListComponent({ cardListParameter: this.cardListParameter }) {
        // 课程列表模块
        this.cardListBuilder();
      }
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      // 点击时进入课表页面
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { message: 'add detail', router: 'pages/Schedule'}
      });
    })
  }
}
