
import { CounterComponent, CounterType, LengthUnit } from '@kit.ArkUI'
import * as tools from '../utils/tools'
import { obtainedData } from '../pages/Schedule'
import examManager, { examAttribute } from '../utils/ExamManager';

@Entry
@Component
struct ExamDetail {

  context: UIContext = this.getUIContext();
  @State examInfo: examAttribute[] = [];
  @State currentTime: Date = new Date();
  showExamDetail: CustomDialogController | null = null;
  aboutToDisappear(): void {
    this.showExamDetail = null;  // 在自定义组件即将析构销毁时将showExamDetail置空
  }

  onPageShow(): void {
    try {
      const routerParams = this.getUIContext().getRouter().getParams() as obtainedData;
      if (routerParams != undefined && routerParams.timeTable != '') {
        examManager.storeExam(JSON.parse(routerParams.timeTable));
      }
      examManager.readStoredExam();
      this.examInfo = examManager.allExamInfo;
    } catch (error) {
      examManager.readStoredExam();
      this.currentTime = new Date();
      this.examInfo = examManager.allExamInfo;
      console.error(`onPageShow ERROR: [${error.name}] ${error.message}`);
    }
  }

  build() {

    Column() {
      Row() {
        Image($r('app.media.close'))
          .padding({ left: 12 })
          .height(20)
          .draggable(false)
          .onClick(() => {
            this.context.getRouter().back();
          })
        Image($r('app.media.refresh'))
          .padding({ left: 12 })
          .height(20)
          .draggable(false)
          .onClick(() => {
            examManager.readStoredExam();
            this.currentTime = new Date();
            this.examInfo = examManager.allExamInfo;
          })

        Blank()

        Text($r('app.string.exam_detail'))
          .fontSize(18)
          .fontColor($r('app.color.normal_text'))
          .height(48)

        Blank()
        Image($r('app.media.plus_square'))
          .padding({right: 12})
          .height(20)
          .draggable(false)
          .onClick(() => {
            let editExam: examAttribute = {
              id: '',
              type: '',
              name: '',
              date: `${this.currentTime.getFullYear()}-${(this.currentTime.getMonth() + 1).toString().padStart(2, '0')}-${this.currentTime.getDate().toString().padStart(2, '0')} ${this.currentTime.getHours().toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}~${(this.currentTime.getHours() + 2).toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}`,
              classroom: '',
              building: '',
              campus: '',
              info: '',
              beginTimeStamp: this.currentTime.getTime(),
              endTimeStamp: this.currentTime.getTime() + 7200000
            };
            this.showExamDetail = null;
            this.showExamDetail = new CustomDialogController({
              builder: ClassDetailDialog({
                toChange: this.examInfo,
                oriExamInfo: editExam,
                examInfo: editExam,
                isChangeSchedule: false,
                date: editExam.date.slice(0, 10),
                startHour: this.currentTime.getHours(),
                startMinute: this.currentTime.getMinutes(),
                endHour: this.currentTime.getHours() + 2,
                endMinute: this.currentTime.getMinutes()
              }),
              autoCancel: true,
              gridCount: 4,
              onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
                if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
                  dismissDialogAction.dismiss();
                }
                if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
                  dismissDialogAction.dismiss();
                }
              }
            })
            if (this.showExamDetail != null) {
              this.showExamDetail.open();
            }
          })
        Image($r('app.media.get'))
          .padding({ right: 12 })
          .height(20)
          .draggable(false)
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
      .backgroundColor($r('app.color.shaded_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      if (this.examInfo.length === 0) {
        Column() {
          Image($r('app.media.no_exam2'))
            .width(100)
            .interpolation(ImageInterpolation.Medium)
            .draggable(false)
          Text($r('app.string.no_exam_info2')).fontSize(18);
        }
        .height('80%')
        .justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(this.examInfo, (singleExam: examAttribute) => {
            ListItem() {
              Row() {
                if (this.currentTime.getTime() < singleExam.beginTimeStamp) {
                  Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.End }) {
                    Row() {
                      Text(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 0).toString())
                        .fontSize(36)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.green'))
                      Text($r('app.string.day'))
                        .fontColor($r('app.color.green'))
                        .lineSpacing({ value: 5, unit: LengthUnit.FP })
                        .maxFontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .padding({ bottom: 6 })
                    }
                    .alignItems(VerticalAlign.Bottom)

                    Row() {
                      Text(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 1).toString())
                        .fontSize(28)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.hour'))
                      Text($r('app.string.hour'))
                        .fontColor($r('app.color.hour'))
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .padding({ bottom: 5 })
                    }
                    .margin({ bottom: 2 })
                    .alignItems(VerticalAlign.Bottom)

                    Row() {
                      Text(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 2).toString())
                        .fontSize(28)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.minute'))
                      Text($r('app.string.minute'))
                        .fontColor($r('app.color.minute'))
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .padding({ bottom: 5 })
                    }
                    .margin({ bottom: 2 })
                    .alignItems(VerticalAlign.Bottom)
                  }
                  .width('30%');
                } else if (this.currentTime.getTime() < singleExam.endTimeStamp) {
                  Text($r('app.string.exam_processing'))
                    .fontSize(20)
                    .fontColor($r('app.color.transparent_text'))
                    .width('30%')
                    .textAlign(TextAlign.Start);
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

                  Text(`\udb80\uddb8 ${singleExam.campus} ${singleExam.building} ${singleExam.classroom}`)
                    .visibility(singleExam.campus + singleExam.building + singleExam.classroom == '' ? Visibility.None :
                      Visibility.Visible);
                  Text(`\udb80\udfdc ${singleExam.date}`)
                    .visibility(singleExam.date == '' ? Visibility.None : Visibility.Visible);
                  Text(`\udb80\ude95 ${singleExam.id} ${singleExam.info}`)
                    .visibility(singleExam.id + singleExam.info == '' ? Visibility.None : Visibility.Visible);
                }
                .width('70%')
                .alignItems(HorizontalAlign.Start)
                .padding({ left: 10 })
              }
              .backgroundColor($r('app.color.grid_background'))
              .borderRadius(20);
            }
            .width('100%')
            .padding({ top: 10, bottom: 10, left: 16, right: 16 })
            .margin({ top: 7, bottom: 7 })
            .backgroundColor($r('app.color.grid_background'))
            .borderRadius(20)
            .onClick(() => {
              let oriExam: examAttribute = {
                id: singleExam.id,
                type: singleExam.type,
                name: singleExam.name,
                date: singleExam.date,
                classroom: singleExam.classroom,
                building: singleExam.building,
                campus: singleExam.campus,
                info: singleExam.info,
                beginTimeStamp: singleExam.beginTimeStamp,
                endTimeStamp: singleExam.endTimeStamp
              };
              let editExam: examAttribute = {
                id: singleExam.id,
                type: singleExam.type,
                name: singleExam.name,
                date: singleExam.date,
                classroom: singleExam.classroom,
                building: singleExam.building,
                campus: singleExam.campus,
                info: singleExam.info,
                beginTimeStamp: singleExam.beginTimeStamp,
                endTimeStamp: singleExam.endTimeStamp
              };
              this.showExamDetail = null;
              this.showExamDetail = new CustomDialogController({
                builder: ClassDetailDialog({
                  toChange: this.examInfo,
                  oriExamInfo: oriExam,
                  examInfo: editExam,
                  isChangeSchedule: true,
                  date: oriExam.date.slice(0, 10),
                  startHour: Number(oriExam.date.slice(11, 13)),
                  startMinute: Number(oriExam.date.slice(14, 16)),
                  endHour: Number(oriExam.date.slice(17, 19)),
                  endMinute: Number(oriExam.date.slice(20, 22))
                }),
                autoCancel: true,
                gridCount: 4,
                onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                  if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
                    dismissDialogAction.dismiss();
                  }
                  if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
                    dismissDialogAction.dismiss();
                  }
                }
              })
              if (this.showExamDetail != null) {
                this.showExamDetail.open();
              }
            });
          });

        }
        .width('100%')
        .height('100%')
        .alignListItem(ListItemAlign.Center)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.normal_background'))
      }
    }
    .height('100%')
    .width('100%')

  }
}

@CustomDialog
@Component
struct ClassDetailDialog {
  @Link toChange: examAttribute[];
  isChangeSchedule: boolean = true;
  examInfo: examAttribute = { id: '', type: '', name: '', date: '', classroom: '', building: '', campus: '', info: '', beginTimeStamp: 0, endTimeStamp: 0};
  oriExamInfo: examAttribute = { id: '', type: '', name: '', date: '', classroom: '', building: '', campus: '', info: '', beginTimeStamp: 0, endTimeStamp: 0};
  controller?: CustomDialogController;
  date: string = '2025-07-21';
  startHour: number = 0;
  startMinute: number = 0;
  endHour: number = 0;
  endMinute: number = 0;

  build() {
    Column() {
      Row() {
        if (this.isChangeSchedule) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.trash_red'))
              .width(24)
              .height(24)
              .draggable(false)
          }
          .onClick(() => {
            examManager.deleteExam(this.oriExamInfo);
            this.toChange = examManager.allExamInfo;
            if (this.controller != undefined) {
              this.controller.close();
            }
          })
          .height(42)
          .width(42);
        }
        Blank();

        Text(this.isChangeSchedule ? $r('app.string.exam_detail') : $r('app.string.exam_detail_new'))
          .fontSize(24)
          .fontWeight("bold")
          .textAlign(TextAlign.Center)
          .height(42);

        Blank();
        if (this.isChangeSchedule) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.copy'))
              .width(24)
              .height(24)
              .draggable(false)
          }
          .onClick(() => {
            if (this.startHour * 60 + this.startMinute > this.endHour * 60 + this.endMinute){
              let temp: number = this.startHour;
              this.startHour = this.endHour;
              this.endHour = temp;
              temp = this.startMinute;
              this.startMinute = this.endMinute;
              this.endMinute = temp;
            }
            this.examInfo.date = `${this.date} ${this.startHour.toString().padStart(2, '0')}:${this.startMinute.toString().padStart(2, '0')}~${this.endHour.toString().padStart(2, '0')}:${this.endMinute.toString().padStart(2, '0')}`;
            examManager.addExam(this.examInfo);
            this.toChange = examManager.allExamInfo;
            if (this.controller != undefined) {
              this.controller.close();
            }
          })
          .height(42)
          .width(42);
        }
      }
      .margin({ bottom: 5 })
      .width('100%');

      Column() {
        Row() {
          Text($r('app.string.exam_detail_object'));
          TextInput({ text: this.oriExamInfo.name })
            .layoutWeight(1)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.examInfo.name = input)
            .selectAll(true);
        }
        .margin({ bottom: 5 });

        Row() {
          Text($r('app.string.exam_detail_type'));
          TextInput({ text: this.oriExamInfo.type })
            .layoutWeight(1)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.examInfo.type = input)
            .selectAll(true);
        }
        .margin({ bottom: 5 });

        Row() {
          Text($r('app.string.exam_detail_date'));
          CalendarPicker({ selected: new Date(this.oriExamInfo.date.slice(0, 10)) })
            .edgeAlign(CalendarAlign.CENTER)
            .onChange((value) => {
              this.date = `${value.getFullYear().toString().padStart(4, '0')}-${(value.getMonth() + 1).toString().padStart(2, '0')}-${value.getDate().toString().padStart(2, '0')}`;
            })
        }
        .margin({ bottom: 5 });

        Row() {
          Text($r('app.string.exam_detail_start_time'));
          CounterComponent({
            options: {
              type: CounterType.INLINE,
              inlineOptions: {
                value: this.startHour,
                min: 0,
                step: 1,
                max: 23,
                textWidth: 25,
                onChange: (value: number) => {
                  this.startHour = value;
                }
              }
            }
          })
          Text(' : ')
          CounterComponent({
            options: {
              type: CounterType.INLINE,
              inlineOptions: {
                value: this.startMinute,
                min: 0,
                step: 1,
                max: 59,
                textWidth: 25,
                onChange: (value: number) => {
                  this.startMinute = value;
                }
              }
            }
          })
        }
        .margin({ bottom: 5 });
        Row() {
          Text($r('app.string.exam_detail_end_time'));
          CounterComponent({
            options: {
              type: CounterType.INLINE,
              inlineOptions: {
                value: this.endHour,
                min: 0,
                step: 1,
                max: 23,
                textWidth: 25,
                onChange: (value: number) => {
                  this.endHour = value;
                }
              }
            }
          })
          Text(' : ')
          CounterComponent({
            options: {
              type: CounterType.INLINE,
              inlineOptions: {
                value: this.endMinute,
                min: 0,
                step: 1,
                max: 59,
                textWidth: 25,
                onChange: (value: number) => {
                  this.endMinute = value;
                }
              }
            }
          })
        }

        Row() {
          Text($r('app.string.class_detail_location'));
          TextInput({ text: this.oriExamInfo.campus, placeholder: $r('app.string.campus') })
            .layoutWeight(3)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.examInfo.campus = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
          TextInput({ text: this.oriExamInfo.building, placeholder: $r('app.string.building') })
            .layoutWeight(5)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.examInfo.building = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
          TextInput({ text: this.oriExamInfo.classroom, placeholder: $r('app.string.classroom') })
            .layoutWeight(3)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.examInfo.classroom = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
        }

        Row() {
          Text($r('app.string.exam_detail_other'));
          TextInput({ text: this.oriExamInfo.id, placeholder: $r('app.string.id') })
            .layoutWeight(1)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.examInfo.id = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
          TextInput({ text: this.oriExamInfo.info, placeholder: $r('app.string.note') })
            .layoutWeight(1)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.examInfo.info = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('85%');

      Row() {
        Button($r('app.string.cancel'))
          .onClick(() => {
            if (this.controller != undefined)
              this.controller.close();
          })
          .width('50%')
          .buttonStyle(ButtonStyleMode.TEXTUAL);

        Button($r('app.string.ok'))
          .onClick(() => {
            if (this.isChangeSchedule)
              examManager.deleteExam(this.oriExamInfo);
            if (this.startHour * 60 + this.startMinute > this.endHour * 60 + this.endMinute){
              let temp: number = this.startHour;
              this.startHour = this.endHour;
              this.endHour = temp;
              temp = this.startMinute;
              this.startMinute = this.endMinute;
              this.endMinute = temp;
            }
            this.examInfo.date = `${this.date} ${this.startHour.toString().padStart(2, '0')}:${this.startMinute.toString().padStart(2, '0')}~${this.endHour.toString().padStart(2, '0')}:${this.endMinute.toString().padStart(2, '0')}`;
            examManager.addExam(this.examInfo);
            this.toChange = examManager.allExamInfo;
            if (this.controller != undefined)
              this.controller.close();
          })
          .width('50%')
          .buttonStyle(ButtonStyleMode.EMPHASIZED);
      }
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.grid_background'));
  }
}