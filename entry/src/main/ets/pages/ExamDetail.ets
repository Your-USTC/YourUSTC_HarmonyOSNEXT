
import { preferences } from '@kit.ArkData'
import { LengthUnit } from '@kit.ArkUI'
import * as tools from '../utils/tools'
import { obtainedData } from '../pages/Schedule'

@Entry
@Component
struct ExamDetail {

  @State context: UIContext = this.getUIContext()

  onPageShow(): void {
    const routerParams = this.getUIContext().getRouter().getParams() as obtainedData;
    try {
      console.log(`获取了考试信息: ${routerParams.timeTable}`)
    } catch (error) {}
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

        Blank()

        Text($r('app.string.exam_detail'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))

        Blank()

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

        // TODO: 删除示例考试 👇👇
        ListItem() {
          Row() {
            Column() {
              Row() {
                Text('14')
                  .fontColor($r('app.color.green'))    // TODO: 可以根据时间调整颜色
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                  .margin({ right: 8 })

                Text($r('app.string.days_before'))
                  .fontColor($r('app.color.green'))    // TODO: 可以根据时间调整颜色
                  .maxLines(2)
                  .lineSpacing({ value: 5, unit: LengthUnit.FP })
                  .maxFontSize(18)
                  .minFontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .padding({ bottom: 5 })
                  .layoutWeight(1)
              }
              .alignItems(VerticalAlign.Bottom)
            }
            .width('30%')
            .padding({ left: 5 })

            Column() {
              Text('数学分析(B1)')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 5 })

              Text(`\udb80\uddb8 西区 第三教学楼 3C103`)
              // 3段字符串拼接

              Text(`\udb80\udfdc 2025-11-23 14:30~16:30`)
              // 可以直接用网页上的字符串
            }
            .width('70%')
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 10 })
          }
        }
        .width('90%')
        .padding({ top: 10, bottom: 10, left: 16, right: 16 })
        .margin({ top: 7, bottom: 7 })
        .backgroundColor($r('app.color.grid_background'))
        .borderRadius(20)
        // TODO: 删除示例考试 👆👆

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