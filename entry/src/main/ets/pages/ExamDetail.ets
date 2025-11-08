import { obtainedData } from '../pages/Schedule';

@Entry
@Component
struct ExamDetail {
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
          .padding({left: 12/*, right: 32*/})
          .height(20)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })

        Blank()

        Text($r('app.string.exam_detail'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))

        Blank()

        Image($r('app.media.get'))
          .padding({right: 12})
          .height(20)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
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
    }
  }
}