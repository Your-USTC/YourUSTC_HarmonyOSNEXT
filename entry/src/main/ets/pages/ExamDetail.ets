
import { preferences } from '@kit.ArkData'
import { LengthUnit } from '@kit.ArkUI'
import * as tools from '../utils/tools'
import { obtainedData } from '../pages/Schedule'
import examManager, { examAttribute } from '../utils/ExamManager';

@Entry
@Component
struct ExamDetail {

  context: UIContext = this.getUIContext();
  @State examInfo: examAttribute[] = [];
  @State currentTime: Date = new Date();

  onPageShow(): void {
    const routerParams = this.getUIContext().getRouter().getParams() as obtainedData;
    if (routerParams != undefined) {
      examManager.storeExam(routerParams.timeTable);
    }
    examManager.readStoredExam();
    this.examInfo = examManager.allExamInfo;
  }

  build() {

    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(20)
          .onClick(() => {
            this.context.getRouter().back()
          })
        Image($r('app.media.refresh'))
          .padding({ left: 12 })
          .height(20)
          .onClick(() => {
            examManager.readStoredExam();
            this.currentTime = new Date();
            this.examInfo = examManager.allExamInfo;
          })

        Blank()

        Text($r('app.string.exam_detail'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))

        Blank()
        Image($r('app.media.plus_square'))
          .padding({right: 12})
          .height(20)
          // .onClick(() => {
          //   this.ShowClassDetail = null;
          //   this.ShowClassDetail = new CustomDialogController({
          //     builder: ClassDetailDialog({
          //       toChange: this.thisWeekSchedule,
          //       weekDisplayed: this.weekDisplayed,
          //       isChangeSchedule: false
          //     }),
          //     autoCancel: true,
          //     gridCount: 4,
          //     onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
          //       if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
          //         dismissDialogAction.dismiss();
          //       }
          //       if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
          //         dismissDialogAction.dismiss();
          //       }
          //     }
          //   })
          //   if (this.ShowClassDetail != null) {
          //     this.ShowClassDetail.open();
          //   }
          // })
        Image($r('app.media.get'))
          .padding({ right: 12 })
          .height(20)
          .onClick(() => {
            this.context.getRouter().pushUrl({
              url: 'pages/GetSchedule',
              params: { title: $r('app.string.online_exam_info'), url: 'https://jw.ustc.edu.cn/for-std/exam-arrange'}
            }).catch((err: Error) => {
              console.error(`Router ERROR: [${err.name}] ${err.message}`)
            })
          })
      }
      .width('100%')
      .height(48)
      .backgroundColor($r('app.color.shaded_background'))

      List() {
        ListItem() {
          Column() {
            Image($r('app.media.course_finish_today')).width(100);
            Text($r('app.string.no_exam_info')).fontSize(18).padding({ top: 10 });
          }
        }
        .visibility(this.examInfo.length == 0 ? Visibility.Visible : Visibility.None)

        ForEach(this.examInfo, (singleExam: examAttribute) => {
          ListItem() {
            Row() {
              if (this.currentTime.getTime() < new Date(singleExam.date.slice(0, 16)).getTime()) {
                Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.End }) {
                  Row() {
                    Text(tools.formatTimeDiff(this.currentTime.getTime(),
                      new Date(singleExam.date.slice(0, 16)).getTime(), 0).toString())
                      .fontSize(36)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.green'))
                    Text($r('app.string.day'))
                      .fontColor($r('app.color.green'))
                      .lineSpacing({ value: 5, unit: LengthUnit.FP })
                      .maxFontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .padding({ bottom: 5 })
                  }
                  .alignItems(VerticalAlign.Bottom)

                  Row() {
                    Text(tools.formatTimeDiff(this.currentTime.getTime(),
                      new Date(singleExam.date.slice(0, 16)).getTime(), 1).toString())
                      .fontSize(28)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.hour'))
                    Text($r('app.string.hour'))
                      .fontColor($r('app.color.hour'))
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .padding({ bottom: 5 })
                  }
                  .alignItems(VerticalAlign.Bottom)

                  Row() {
                    Text(tools.formatTimeDiff(this.currentTime.getTime(),
                      new Date(singleExam.date.slice(0, 16)).getTime(),
                      2).toString())
                      .fontSize(28)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.minute'))
                    Text($r('app.string.minute'))
                      .fontColor($r('app.color.minute'))
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .padding({ bottom: 5 })
                  }
                  .alignItems(VerticalAlign.Bottom)
                }
                .width('30%');
              } else {
                Text($r('app.string.exam_ended'))
                  .fontSize(20)
                  .fontColor($r('app.color.transparent_text'))
                  .width('30%')
                  .textAlign(TextAlign.Start);
              }

              Column() {
                Row() {
                  Text(singleExam.name + '  ')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 5 })
                  Text(singleExam.type)
                    .fontSize(18)
                    .margin({ bottom: 5 })
                }
                Text(`\udb80\uddb8 ${singleExam.campus} ${singleExam.building} ${singleExam.classroom}`);
                Text(`\udb80\udfdc ${singleExam.date}`);
                Text(`\udb80\ude95 ${singleExam.id} ${singleExam.info}`);
              }
              .width('70%')
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 10 })
            }
            .backgroundColor($r('app.color.grid_background'))
            .borderRadius(20);
          }
          .width('90%')
          .padding({ top: 10, bottom: 10, left: 16, right: 16 })
          .margin({ top: 7, bottom: 7 })
          .backgroundColor($r('app.color.grid_background'))
          .borderRadius(20)
        });

      }
      .width('100%')
      .height('100%')
      .alignListItem(ListItemAlign.Center)
      .scrollBar(BarState.Auto)
      .padding({ top: 7, bottom: 48 })
      .backgroundColor($r('app.color.normal_background'))
    }
    .height('100%')
    .width('100%')

  }
}