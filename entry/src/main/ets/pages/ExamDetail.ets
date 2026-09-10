
import { CounterComponent, CounterType } from '@kit.ArkUI'
import * as tools from '../utils/tools'
import examManager, { areExamAttributesEqual } from '../utils/ExamManager';
import { examAttribute } from '../utils/ExamStorage';
import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import { FULL_TIME_FORMAT } from '../constants/BasicConstants';
import MessageDialog from '../view/MessageDialog';

@Builder
export function ExamBuilder(name: string, param?: Object) {
  ExamDetail();
}

@Entry
@Component
struct ExamDetail {

  context: UIContext = this.getUIContext();
  @State examInfo: examAttribute[] = [];
  @State currentTime: Date = new Date();

  msgDialogController?: CustomDialogController;
  /**
   * 详情弹窗部分
   */
  @State showSheet: boolean = false;
  private isChangeSchedule: boolean = true;

  private newExamInfo: examAttribute = { id: '', type: '', name: '', date: '', classroom: '', building: '', campus: '', info: '', beginTimeStamp: 0, endTimeStamp: 0, importance: 5};
  private oriExamInfo: examAttribute = { id: '', type: '', name: '', date: '', classroom: '', building: '', campus: '', info: '', beginTimeStamp: 0, endTimeStamp: 0, importance: 5};
  private date: string = '2025-07-21';
  private startHour: number = 0;
  private startMinute: number = 0;
  private endHour: number = 0;
  private endMinute: number = 0;

  @Builder examDetailDialog() {
    Column() {
      Row({ space: 5 }) {
        Text(this.isChangeSchedule ? $r('app.string.exam_detail') : $r('app.string.exam_detail_new'))
          .fontSize(24)
          .fontWeight("bold")
          .layoutWeight(1)
          .margin({ left: 8 });

        if (this.isChangeSchedule) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.trash_red'))
              .width(24)
              .height(24)
          }
          .height(42)
          .width(42)
          .onClick(() => {
            this.msgDialogController = new CustomDialogController({
              builder: MessageDialog({
                message: $r('app.string.delete_exam_or_not'),
                onConfirm: () => {
                  examManager.deleteExam(this.oriExamInfo);
                  this.examInfo = examManager.allExamInfo;
                  this.showSheet = false;
                }
              }),
              autoCancel: true,
              gridCount: 4
            });
            this.msgDialogController.open();
          });

          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.copy'))
              .width(24)
              .height(24)
              .draggable(false)
          }
          .height(42)
          .width(42)
          .onClick(() => {
            if (this.startHour * 60 + this.startMinute > this.endHour * 60 + this.endMinute){
              let temp: number = this.startHour;
              this.startHour = this.endHour;
              this.endHour = temp;
              temp = this.startMinute;
              this.startMinute = this.endMinute;
              this.endMinute = temp;
            }
            this.newExamInfo.date = `${this.date} ${this.startHour.toString().padStart(2, '0')}:${this.startMinute.toString().padStart(2, '0')}~${this.endHour.toString().padStart(2, '0')}:${this.endMinute.toString().padStart(2, '0')}`;
            examManager.addExam(this.newExamInfo);
            this.examInfo = examManager.allExamInfo;
            this.showSheet = false;
          });
        }

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .width(24)
            .height(24)
        }
        .width(42)
        .height(42)
        .onClick(() => {
          if (this.startHour * 60 + this.startMinute > this.endHour * 60 + this.endMinute){
            let temp: number = this.startHour;
            this.startHour = this.endHour;
            this.endHour = temp;
            temp = this.startMinute;
            this.startMinute = this.endMinute;
            this.endMinute = temp;
          }
          this.newExamInfo.date = `${this.date} ${this.startHour.toString().padStart(2, '0')}:${this.startMinute.toString().padStart(2, '0')}~${this.endHour.toString().padStart(2, '0')}:${this.endMinute.toString().padStart(2, '0')}`;
          if (!areExamAttributesEqual(this.newExamInfo, this.oriExamInfo)) {
            this.msgDialogController = new CustomDialogController({
              builder: MessageDialog({
                mainTitle: $r('app.string.unsaved_change'),
                message: $r('app.string.back_to_examinfo_or_not'),
                onConfirm: () => {
                  this.showSheet = false;
                }
              }),
              autoCancel: true,
              gridCount: 4
            });
            this.msgDialogController.open();
          } else {
            this.showSheet = false;
          }
        });

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image(this.isChangeSchedule ? $r('app.media.save') : $r('app.media.checkmark'))
            .width(24)
            .height(24)
        }
        .width(42)
        .height(42)
        .onClick(() => {
          if (this.startHour * 60 + this.startMinute > this.endHour * 60 + this.endMinute){
            let temp: number = this.startHour;
            this.startHour = this.endHour;
            this.endHour = temp;
            temp = this.startMinute;
            this.startMinute = this.endMinute;
            this.endMinute = temp;
          }
          this.newExamInfo.date = `${this.date} ${this.startHour.toString().padStart(2, '0')}:${this.startMinute.toString().padStart(2, '0')}~${this.endHour.toString().padStart(2, '0')}:${this.endMinute.toString().padStart(2, '0')}`;
          if (this.isChangeSchedule) {
            if (!areExamAttributesEqual(this.newExamInfo, this.oriExamInfo)) {
              examManager.deleteExam(this.oriExamInfo);
              examManager.addExam(this.newExamInfo);
              this.examInfo = examManager.allExamInfo;
            }
          } else {
            examManager.addExam(this.newExamInfo);
            this.examInfo = examManager.allExamInfo;
          }
          this.showSheet = false;
        });
      }
      .margin({ bottom: 10 })
      .width('100%');

      Column() {
        Row() {
          Text($r('app.string.exam_detail_object'));
          TextInput({ text: this.oriExamInfo.name })
            .layoutWeight(1)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.newExamInfo.name = input)
            .selectAll(true);
        }
        .margin({ bottom: 5 });

        Row() {
          Text($r('app.string.exam_detail_type'));
          TextInput({ text: this.oriExamInfo.type })
            .layoutWeight(1)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.newExamInfo.type = input)
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
            .onChange((input: string) => this.newExamInfo.campus = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
          TextInput({ text: this.oriExamInfo.building, placeholder: $r('app.string.building') })
            .layoutWeight(5)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.newExamInfo.building = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
          TextInput({ text: this.oriExamInfo.classroom, placeholder: $r('app.string.classroom') })
            .layoutWeight(3)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.newExamInfo.classroom = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
        }

        Row() {
          Text($r('app.string.exam_detail_other'));
          TextInput({ text: this.oriExamInfo.id, placeholder: $r('app.string.id') })
            .layoutWeight(1)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.newExamInfo.id = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
          TextInput({ text: this.oriExamInfo.info, placeholder: $r('app.string.note') })
            .layoutWeight(1)
            .textOverflow(TextOverflow.Ellipsis)
            .onChange((input: string) => this.newExamInfo.info = input)
            .textAlign(TextAlign.Center)
            .selectAll(true)
            .showUnderline(true);
        }

        Row() {
          Text($r('app.string.class_detail_priority'));
          Slider({ min: 0, max: 10, value: this.oriExamInfo.importance, step: 1, style: SliderStyle.InSet })
            .showSteps(true)
            .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
            .layoutWeight(1)
            .onChange((value: number) => {
              this.newExamInfo.importance = value;
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('90%');
    }
    .width('100%')
    .padding({ top: 16, right: 16, left: 16});
  }

  menuItems: Array<NavigationMenuItem> = [
    {
      value: $r('app.string.refresh'),
      icon: $r('app.media.refresh'),
      action: () => {
        examManager.readStoredExam();
        this.examInfo = examManager.allExamInfo;
        this.currentTime = new Date();
      }
    },
    {
      value: $r('app.string.new'),
      icon: $r('app.media.plus_square'),
      action: () => {
        this.oriExamInfo = {
          id: '',
          type: '',
          name: '',
          importance: 5,
          date: `${this.currentTime.getFullYear()}-${(this.currentTime.getMonth() + 1).toString().padStart(2, '0')}-${this.currentTime.getDate().toString().padStart(2, '0')} ${this.currentTime.getHours().toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}~${(this.currentTime.getHours() + 2).toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}`,
          classroom: '',
          building: '',
          campus: '',
          info: '',
          beginTimeStamp: this.currentTime.getTime(),
          endTimeStamp: this.currentTime.getTime() + 7200000
        };
        this.newExamInfo = {
          id: '',
          type: '',
          name: '',
          importance: 5,
          date: `${this.currentTime.getFullYear()}-${(this.currentTime.getMonth() + 1).toString().padStart(2, '0')}-${this.currentTime.getDate().toString().padStart(2, '0')} ${this.currentTime.getHours().toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}~${(this.currentTime.getHours() + 2).toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}`,
          classroom: '',
          building: '',
          campus: '',
          info: '',
          beginTimeStamp: this.currentTime.getTime(),
          endTimeStamp: this.currentTime.getTime() + 7200000
        };
        this.isChangeSchedule = false;
        this.date = this.newExamInfo.date.slice(0, 10);
        this.startHour = this.currentTime.getHours();
        this.startMinute = this.currentTime.getMinutes();
        this.endHour = this.currentTime.getHours() + 2;
        this.endMinute = this.currentTime.getMinutes();
        this.showSheet = true;
      }
    },
    {
      value: $r('app.string.online_exam_info'),
      icon: $r('app.media.get'),
      action: () => {
        this.pathStack.pushPath({
          name: "GetSchedule",
          param: [$r('app.string.online_exam_info'), 'https://jw.ustc.edu.cn/for-std/exam-arrange'],
          onPop: (popInfo: PopInfo) => {
            if (typeof popInfo.result === "string") {
              const routerParams: string = popInfo.result;
              if (routerParams != '') {
                examManager.storeExam(JSON.parse(routerParams));
                examManager.readStoredExam();
                this.currentTime = new Date();
                this.examInfo = examManager.allExamInfo;
              }
            }
          }
        });
      }
    }
  ]

  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      Column() {
        if (this.examInfo.length === 0) {
          Column() {
            Column() {
              Image($r('app.media.no_exam2'))
                .width(100)
                .interpolation(ImageInterpolation.Medium)
                .draggable(false)
              Text($r('app.string.no_exam_info2')).fontSize(18).textAlign(TextAlign.Center);
            }
            .backgroundBlurStyle(BackgroundImage.blurLevel)
            .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
            .padding({
              top: 5,
              left: 10,
              right: 10,
              bottom: 10
            })
            .borderRadius(12);
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
                      Text() {
                        Span(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 0).toString())
                          .fontSize(36)
                        Span($r('app.string.day'))
                          .fontSize(18)
                      }
                      .fontColor($r('app.color.green'))
                      .fontWeight(FontWeight.Bold)

                      Text() {
                        Span(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 1).toString())
                          .fontSize(28)
                        Span($r('app.string.hour'))
                          .fontSize(14)
                      }
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.hour'))

                      Text() {
                        Span(tools.formatTimeDiff(this.currentTime.getTime(), singleExam.beginTimeStamp, 2).toString())
                          .fontSize(28)
                        Span($r('app.string.minute'))
                          .fontSize(14)
                      }
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.minute'))
                    }
                    .width('30%');
                  } else if (this.currentTime.getTime() < singleExam.endTimeStamp) {
                    Text($r('app.string.exam_processing'))
                      .fontSize(20)
                      .fontColor($r('app.color.transparent_text'))
                      .width('30%')
                      .textAlign(TextAlign.Start);
                  } else {
                    Text($r('app.string.ended'))
                      .fontSize(20)
                      .fontColor($r('app.color.transparent_text'))
                      .width('30%')
                      .textAlign(TextAlign.Start);
                  }

                  Column() {
                    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.End }) {
                      Text(singleExam.name + '  ')
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .margin({ right: 5 })
                      Text(singleExam.type)
                        .fontSize(16)
                    }
                    .margin({ bottom: 5 })

                    Text('\udb80\uddb8 ' + singleExam.campus + singleExam.building + singleExam.classroom)
                      .visibility(singleExam.campus + singleExam.building + singleExam.classroom == '' ?
                        Visibility.None :
                        Visibility.Visible);
                    Text('\udb80\udfdc ' + singleExam.date)
                      .visibility(singleExam.date == '' ? Visibility.None : Visibility.Visible);
                    Text(`\udb80\ude95 ${singleExam.id} ${singleExam.info}`)
                      .visibility(singleExam.id + singleExam.info == '' ? Visibility.None : Visibility.Visible);
                  }
                  .width('70%')
                  .alignItems(HorizontalAlign.Start)
                  .padding({ left: 10 })
                }
              }
              .width('100%')
              .padding({ top: 10, bottom: 10, left: 16, right: 16 })
              .margin({ top: 8, bottom: 6 })
              .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
              .backgroundBlurStyle(BackgroundImage.blurLevel)
              .borderRadius(20)
              .onClick(() => {
                this.oriExamInfo = {
                  id: singleExam.id,
                  type: singleExam.type,
                  name: singleExam.name,
                  date: singleExam.date,
                  classroom: singleExam.classroom,
                  building: singleExam.building,
                  campus: singleExam.campus,
                  info: singleExam.info,
                  beginTimeStamp: singleExam.beginTimeStamp,
                  endTimeStamp: singleExam.endTimeStamp,
                  importance: singleExam.importance
                };
                this.newExamInfo = {
                  id: singleExam.id,
                  type: singleExam.type,
                  name: singleExam.name,
                  date: singleExam.date,
                  classroom: singleExam.classroom,
                  building: singleExam.building,
                  campus: singleExam.campus,
                  info: singleExam.info,
                  beginTimeStamp: singleExam.beginTimeStamp,
                  endTimeStamp: singleExam.endTimeStamp,
                  importance: singleExam.importance
                };
                this.isChangeSchedule = true;
                this.date = this.oriExamInfo.date.slice(0, 10);
                this.startHour = Number(this.oriExamInfo.date.slice(11, 13));
                this.startMinute = Number(this.oriExamInfo.date.slice(14, 16));
                this.endHour = Number(this.oriExamInfo.date.slice(17, 19));
                this.endMinute = Number(this.oriExamInfo.date.slice(20, 22));
                this.showSheet = true;
              });
            })
          }
          .width('100%')
          .height('100%')
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .padding({ left: 12, right: 12 })
          .contentStartOffset(4)
          .contentEndOffset(12)
        }
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .height('100%')
      .width('100%')
      .bindSheet($$this.showSheet, this.examDetailDialog(), {
        // 如果与 gridItem 绑定，会弹出很多个！
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        preferType: SheetType.CENTER,
        showClose: false,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS,
        backgroundColor: '#0000',
        blurStyle: BlurStyle.Regular,
        onWillDismiss: ((DismissSheetAction: DismissSheetAction) => {
          if (this.startHour * 60 + this.startMinute > this.endHour * 60 + this.endMinute) {
            let temp: number = this.startHour;
            this.startHour = this.endHour;
            this.endHour = temp;
            temp = this.startMinute;
            this.startMinute = this.endMinute;
            this.endMinute = temp;
          }
          this.newExamInfo.date =
            `${this.date} ${this.startHour.toString().padStart(2, '0')}:${this.startMinute.toString()
              .padStart(2, '0')}~${this.endHour.toString().padStart(2, '0')}:${this.endMinute.toString()
              .padStart(2, '0')}`;
          if (!areExamAttributesEqual(this.oriExamInfo, this.newExamInfo)) {
            this.msgDialogController = new CustomDialogController({
              builder: MessageDialog({
                mainTitle: $r('app.string.unsaved_change'),
                message: $r('app.string.back_to_examinfo_or_not'),
                onConfirm: () => {
                  DismissSheetAction.dismiss();
                }
              }),
              autoCancel: true,
              gridCount: 4
            });
            this.msgDialogController.open();
          } else {
            DismissSheetAction.dismiss();
          }
        })
      })
    }
    .title({ main: $r('app.string.exam_detail'), sub: '\udb80\udfd5 '+ this.currentTime.toLocaleString('zh-cn', FULL_TIME_FORMAT)}, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : undefined
    })
    .backButtonIcon($r('app.media.close'))
    .menus(this.menuItems)
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;

      examManager.readStoredExam();
      this.examInfo = examManager.allExamInfo;
      this.currentTime = new Date();
    })
  }
}
