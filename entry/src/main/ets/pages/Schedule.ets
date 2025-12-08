
import * as tools from '../utils/tools';
import scheduleManager, { areClassAttributesEqual } from '../utils/TimeTable';
import { mediaquery, PopoverDialog, Popup, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import * as ScheduleSources from '../constants/ScheduleSources';
import BackgroundImage from '../view/BgImageManager';


@Entry
@Component
struct Schedule {

  private context: Context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  /*
   * 以下是监听屏幕旋转
   */
  readonly criticalHeight: number = 1500;    // 紧凑模式临界值
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  private portraitListener: mediaquery.MediaQueryListener = this.getUIContext().getMediaQuery().matchMediaSync('(orientation: landscape)');
  onPortrait(mediaQueryResult: mediaquery.MediaQueryResult) {
    let windowClass: window.Window | undefined = undefined;
    try {
      let promise = window.getLastWindow(this.context);
      promise.then((data)=> {
        //Get window object
        windowClass = data;
        try {
          //Get window properties
          let properties = windowClass.getWindowProperties();
          let rect = properties.windowRect;
          this.screenWidth = rect.width;
          this.screenHeight = rect.height;
          if (rect.width > rect.height) { // 横屏
            this.isLandscape = true;
          } else { // 竖屏
            this.isLandscape = false;
          }
          //rect.width: Window Width, rect.height: Window height
        } catch (exception) {
          console.error('Failed to obtain the window properties. Cause: ' + JSON.stringify(exception));
        }
        console.info('Succeeded in obtaining the top window. Data: ' + JSON.stringify(data));
      }).catch((err: Error)=>{
        console.error('Failed to obtain the top window. Cause: ' + JSON.stringify(err));
      });} catch (exception) {
      console.error('Failed to obtain the top window. Cause: ' + JSON.stringify(exception));
    }
  }
  /*
   * 以上是监听屏幕旋转
   */

  @State weekDisplayed: number = 0;
  @State termStart: number = 0;
  @State weekStart: number = 0;
  @State weekEnd: number = 0;
  @State thisWeekSchedule: ScheduleSources.classAttribute[][] = []; // 第一层：星期几(0-6)；第三层：每天的所有课，不一定按顺序

  @State showColorHint: boolean = false;
  @Builder
  colorHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.more_color_option') },
        showClose: false,
        buttons: [{
          text: $r('app.string.no_reminding'),
          action: () => {
            scheduleManager.hideColorHint();
            this.showColorHint = false;
          }
        }]
      })
    }
  }

  /**
   * 详情弹窗部分
   */
  @State showSheet: boolean = false;
  private classInfo: ScheduleSources.classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2',
    weekOfTerm: tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[], timeSpan: [6, 7], dayOfWeek: 0,
    color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)] };
  private oriClassInfo: ScheduleSources.classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2',
    weekOfTerm: [], timeSpan: [6, 7], dayOfWeek: 0,
    color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)] };

  private rectifyTimeSpan: number[] = [this.oriClassInfo.timeSpan[0], this.oriClassInfo.timeSpan[this.oriClassInfo.timeSpan.length - 1]];
  private rectifyWeekOfTerm: boolean[] = [true, false, true, true, true, false, true, true, true, true, true,
    false, false, false, true, true, true, false, false, false, false];
  @State isWeeksLegal: boolean = true;
  @State weekOfTerm: number[] = tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[];
  @State isColorLegal: boolean = true;
  private changeAllColor: boolean = true;

  private checkBoxGroup: number = 0;

  private isChangeSchedule: boolean = true;

  private createArray = (start: number, end: number): Array<SelectOption> => {
    const arr: Array<SelectOption> = [];
    for (let i = start; i <= end; i++) {
      arr.push({ value: i.toString() });
    }
    return arr;
  };

  private colorARGB: number[] = [255, 255, 199, 205];
  @State classColor: string = '#FFC7CD';
  @State showColorPicker: boolean = false;
  @State colorDialogText: string = '#FFC7CD';
  @Builder
  colorPicker() {
    Column() {
      Text(this.colorDialogText)
        .fontColor('#000000')
        .backgroundColor(this.colorDialogText)
        .textAlign(TextAlign.Center)
        .height(24)
        .width(110)
        .borderRadius(12)

      Row() {
        Text($r('app.string.transparent'))
        Slider({
          value: this.colorARGB[0],
          min: 0,
          max: 255,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.transparent'))
          .trackColor(new LinearGradient([
            { color: `#00${this.colorDialogText.slice(3, 9)}`, offset: 0 },
            { color: `#FF${this.colorDialogText.slice(3, 9)}`, offset: 1 }
          ]))
          .onChange((value: number) => {
            this.colorARGB[0] = value;
            this.colorDialogText = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          });
      }

      Row() {
        Text($r('app.string.red'))
        Slider({
          value: this.colorARGB[1],
          min: 0,
          max: 255,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.transparent'))
          .trackColor(new LinearGradient([
            { color: `#00${this.colorDialogText.slice(5, 9)}`, offset: 0 },
            { color: `#FF${this.colorDialogText.slice(5, 9)}`, offset: 1 }]))
          .onChange((value: number) => {
            this.colorARGB[1] = value;
            this.colorDialogText = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          });
      }

      Row() {
        Text($r('app.string.green'))
        Slider({
          value: this.colorARGB[2],
          min: 0,
          max: 255,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.transparent'))
          .trackColor(new LinearGradient([
            { color: `#${this.colorDialogText.slice(3, 5)}00${this.colorDialogText.slice(7, 9)}`, offset: 0 },
            { color: `#${this.colorDialogText.slice(3, 5)}FF${this.colorDialogText.slice(7, 9)}`, offset: 1 }]))
          .onChange((value: number) => {
            this.colorARGB[2] = value;
            this.colorDialogText = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          });
      }

      Row() {
        Text($r('app.string.blue'))
        Slider({
          value: this.colorARGB[3],
          min: 0,
          max: 255,
          style: SliderStyle.InSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.transparent'))
          .trackColor(new LinearGradient([
            { color: `#${this.colorDialogText.slice(3, 7)}00`, offset: 0 },
            { color: `#${this.colorDialogText.slice(3, 7)}FF`, offset: 1 }]))
          .onChange((value: number) => {
            this.colorARGB[3] = value;
            this.colorDialogText = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
              + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
          });
      }

      Row() {
        Toggle( { isOn: this.changeAllColor, type: ToggleType.Checkbox })
          .onChange((value: boolean) => {
            this.changeAllColor = value;
          });
        Text($r('app.string.change_all_color'))
      }
    }
    .padding(16)
    .width('100%')
    // .height(250)
    .justifyContent(FlexAlign.Center)
  }
  /*
   * 详情弹窗部分
   */
  @State showConflictClass: boolean = false;

  @Builder
  ConflictClass() {
    Column() {
      Row() {
        Text($r('app.string.conflict_class_detail'))
          .fontWeight(FontWeight.Bold)
          .fontSize(24)
          .layoutWeight(1)
          .margin({ left: 8 });
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
        }
        .width(42)
        .height(42)
        .onClick(() => {
          this.showConflictClass = false;
        })
      }
      .margin({ bottom: 10 })

      Text($r('app.string.conflict_class_intro'))
        .fontSize(12)
        .margin({ bottom: 5 })

      List({ space: 14 }) {
        ForEach([1, 2, 3, 4, 5, 6, 7], () => {
          ListItem() {
            Button('test')
              .onClick(() => {
                this.showSheet = true;
              })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10, left: 16, right: 16 })
          .backgroundColor($r('app.color.grid_background'))
          .borderRadius(20)
        })
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false });
    }
    .padding({ top: 16, left: 16, right: 16 })
  }
  /*
   * 叠课弹窗部分
   */
  /*
   * 叠课弹窗部分
   */

  onPageShow(): void {
    const currentTime: Date = new Date();
    const routerParams = this.getUIContext().getRouter().getParams() as ScheduleSources.obtainedData;
    if (routerParams != undefined)
      scheduleManager.refreshParsedSchedule(routerParams);
    scheduleManager.getFormattedSchedule();
    this.termStart = scheduleManager.termStart;
    this.weekDisplayed = scheduleManager.weekDisplayed;
    this.weekStart = scheduleManager.weekStart;
    this.weekEnd = scheduleManager.weekEnd;
    this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];

    // TODO: 将 weekStart 和 weekEnd 存入首选项
    console.info(`课表 weekDisplayed: ${this.weekDisplayed}`)
    console.info(`课表 currentTime: ${tools.timestampToDateTime(currentTime.getTime())}`)
    console.info(`课表 termStart: ${tools.timestampToDateTime(this.termStart)}`)
    console.info(`课表 weekStart: ${tools.timestampToDateTime(this.weekStart)}`)
    console.info(`课表 weekEnd: ${tools.timestampToDateTime(this.weekEnd)}`)
  }

  aboutToAppear(): void {
    this.portraitListener.on('change', (mediaQueryResult: mediaquery.MediaQueryResult) => {
      this.onPortrait(mediaQueryResult)
    }); // 开启监听屏幕旋转
  }

  aboutToDisappear(): void {
    this.portraitListener.off('change'); // 关闭监听屏幕旋转，防止内存泄露
  }

  build() {
    Column() {
      /**
       * Header
       */
      Column() {
        Row() {
          Image($r('app.media.close'))
            .padding({ left: 12 })
            .height(20)
            .draggable(false)
            .onClick(() => {
              this.getUIContext().getRouter().back();
            })

          Image($r('app.media.pile'))
            .padding({ left: 12 })
            .height(20)
            .draggable(false)
            .onClick(() => {
              this.showConflictClass = true;
            })
            .bindSheet($$this.showConflictClass, this.ConflictClass(), {
              detents: [SheetSize.LARGE, SheetSize.MEDIUM],
              preferType: SheetType.POPUP,
              backgroundColor: '#00d00721',
              blurStyle: BlurStyle.Regular,
              showClose: false,
              enableOutsideInteractive: false,
              enableFloatingDragBar: true,
              mode: SheetMode.OVERLAY
            })

          Blank()

          Text($r('app.string.local_schedule'))
            .fontSize(18)
            .fontColor($r('app.color.normal_text'))
            .height(48)
            .bindSheet($$this.showSheet, this.ClassDetailDialog(), {
              // 如果与 gridItem 绑定，会弹出很多个！
              detents: [SheetSize.MEDIUM, SheetSize.LARGE],
              preferType: SheetType.CENTER,
              showClose: false,
              scrollSizeMode: ScrollSizeMode.CONTINUOUS,
              backgroundColor: '#00d00721',
              blurStyle: BlurStyle.Regular,
              onAppear: () => {
                this.showColorHint = scheduleManager.showColorHint;
              },
              onWillDismiss: ((DismissSheetAction: DismissSheetAction) => {
                this.classInfo.weekOfTerm = [...this.weekOfTerm];
                if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
                  let swapTemp = this.rectifyTimeSpan[0];
                  this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
                  this.rectifyTimeSpan[1] = swapTemp;
                }
                this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
                if (!areClassAttributesEqual(this.oriClassInfo, this.classInfo)) {
                  this.getUIContext().showAlertDialog({
                    title: $r('app.string.unsaved_change'),
                    message: $r('app.string.back_to_schedule_or_not'),
                    autoCancel: true,
                    alignment: DialogAlignment.Center,
                    gridCount: 4,
                    primaryButton: {
                      value: $r('app.string.cancel'),
                      action: () => {
                      }
                    },
                    secondaryButton: {
                      enabled: true,
                      defaultFocus: true,
                      style: DialogButtonStyle.HIGHLIGHT,
                      value: $r('app.string.ok'),
                      action: () => {
                        DismissSheetAction.dismiss();
                      }
                    },
                    cancel: () => {
                    },
                    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                      if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
                        dismissDialogAction.dismiss();
                      }
                      if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
                        dismissDialogAction.dismiss();
                      }
                    }
                  });
                } else {
                  DismissSheetAction.dismiss();
                }
              })
            })

          Blank()

          Image($r('app.media.plus_square'))
            .padding({ right: 12 })
            .height(20)
            .draggable(false)
            .onClick(() => {
              this.checkBoxGroup = (this.checkBoxGroup + 1) % 2;
              this.isChangeSchedule = false;
              this.oriClassInfo = {
                name: '计算机程序设计',
                teacher: '李卫海',
                location: '3A212',
                id: 'CS1003.H2',
                weekOfTerm: tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[],
                timeSpan: [6, 7],
                dayOfWeek: 0,
                color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)]
              };
              this.classInfo = {
                name: '计算机程序设计',
                teacher: '李卫海',
                location: '3A212',
                id: 'CS1003.H2',
                weekOfTerm: tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[],
                timeSpan: [6, 7],
                dayOfWeek: 0,
                color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)]
              };
              this.classColor = this.oriClassInfo.color;
              this.rectifyWeekOfTerm = [true, false, true, true, true, false, true, true, true, true, true,
                false, false, false, true, true, true, false, false, false, false];
              this.rectifyTimeSpan = [6, 7];
              this.showSheet = true;
            })

          Image($r('app.media.get'))
            .padding({ right: 12 })
            .height(20)
            .draggable(false)
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/GetSchedule',
                params: { title: $r('app.string.online_schedule'), url: 'https://jw.ustc.edu.cn/for-std/course-table' }
              }).catch((err: Error) => {
                console.error(`Router ERROR: [${err.name}] ${err.message}`)
              })
            })
        }
        .width('100%')
        .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.shaded_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        /**
         * 周数信息与翻页
         */
        Row() {
          Text(tools.timestampToDateTime(this.weekStart) + ' ~ ' + tools.timestampToDateTime(this.weekEnd))
            .id('week_of_term_span')
            .fontWeight(FontWeight.Bold)
            .fontSize(14)

          Blank()

          Image(this.weekDisplayed == 1 ? $r('app.media.arrow_left_circle_unavailable') :
            $r('app.media.arrow_left_circle'))
            .height(18)
            .width(40)
            .objectFit(ImageFit.Contain)
            .draggable(false)
            .onClick(() => {
              if (this.weekDisplayed > 1) {
                this.weekDisplayed--;
                this.weekStart -= 604800000;
                this.weekEnd -= 604800000;
                this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];
              }
            })

          Text($r('app.string.week_of_term_no_d', this.weekDisplayed))
            .id('week_of_term_no')
            .fontWeight(FontWeight.Bold)
            .fontSize(14)

          Image(this.weekDisplayed == 20 ? $r('app.media.arrow_right_circle_unavailable') :
            $r('app.media.arrow_right_circle'))
            .height(18)
            .width(40)
            .objectFit(ImageFit.Contain)
            .draggable(false)
            .onClick(() => {
              if (this.weekDisplayed < 20) {
                this.weekDisplayed++;
                this.weekStart += 604800000;
                this.weekEnd += 604800000;
                this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];
              }
            })
        }
        .width('100%')
        .height(30)
        .padding({ left: 20, right: 10 })
        .justifyContent(FlexAlign.Center)
        .border({
          width: { bottom: 1 },
          color: $r('app.color.grid_border')
        })

        // 星期几
        Row() {
          Text($r('app.string.class_span'))
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
            .height('100%')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .border({
              width: { right: 1 },
              color: $r('app.color.grid_border')
            })
          Text(tools.weekTranslate[6])
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
            .textAlign(TextAlign.Center)
            .height('100%')
            .layoutWeight(1)
          ForEach(tools.getContArray([[3, 8]]), (item: number) => {
            Text(tools.weekTranslate[(item + 4) % 7])
              .fontWeight(FontWeight.Bold)
              .fontSize(12)
              .textAlign(TextAlign.Center)
              .height('100%')
              .layoutWeight(1)
              .border({
                width: { left: 1 },
                color: $r('app.color.grid_border')
              })
          })
        }
        .width('100%')
        .height(25)
        .border({
          width: { bottom: 1 },
          color: $r('app.color.grid_border')
        })
      }
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .backgroundBlurStyle(BackgroundImage.blurLevel)
      .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
      .opacity(BackgroundImage.opacityLevel)

      /**
       * 课表
       */
      Grid() {
        /**
         * 表头
         */
        GridItem({ style: GridItemStyle.NONE }) {
          Row() {
            // 上午、下午、晚上
            Column() {
              Text($r('app.string.morning'))
                .fontWeight(FontWeight.Bold)
                .fontSize(14)
                .layoutWeight(5)
                .width('100%')
                .textAlign(TextAlign.Center)
                .border({
                  width: { right: 1 },
                  color: $r('app.color.grid_border')
                })

              Text($r('app.string.afternoon'))
                .fontWeight(FontWeight.Bold)
                .fontSize(14)
                .layoutWeight(5)
                .width('100%')
                .textAlign(TextAlign.Center)
                .border({
                  width: { top: 1, right: 1 },
                  color: $r('app.color.grid_border')
                })

              Text($r('app.string.evening'))
                .fontWeight(FontWeight.Bold)
                .fontSize(14)
                .layoutWeight(3)
                .width('100%')
                .textAlign(TextAlign.Center)
                .border({
                  width: { top: 1, right: 1 },
                  color: $r('app.color.grid_border')
                })
            }
            .layoutWeight(1)

            // 13节课
            Column() {
              Column() {
                Text(ScheduleSources.commonClassTime[1][0])
                  .fontSize('8fp')
                  .visibility(this.screenHeight < this.criticalHeight ? Visibility.None : Visibility.Visible)

                Text('1')
                  .fontWeight(FontWeight.Bold)
                  .fontSize(14)
                  .align(Alignment.Center)

                Text(ScheduleSources.commonClassTime[1][1])
                  .fontSize('8fp')
                  .visibility(this.screenHeight < this.criticalHeight ? Visibility.None : Visibility.Visible)
              }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({ top: 2, bottom: 2 })
              .border({
                width: { right: 1 },
                color: $r('app.color.grid_border')
              });

              ForEach(tools.getContArray([[2, 13]]), (item: number) => {
                Column() {
                  Text(ScheduleSources.commonClassTime[item][0])
                    .fontSize('8fp')
                    .visibility(this.screenHeight < this.criticalHeight ? Visibility.None : Visibility.Visible)

                  Text(item.toString())
                    .fontWeight(FontWeight.Bold)
                    .fontSize(14)
                    .align(Alignment.Center)

                  Text(ScheduleSources.commonClassTime[item][1])
                    .fontSize('8fp')
                    .visibility(this.screenHeight < this.criticalHeight ? Visibility.None : Visibility.Visible)
                }
                .width('100%')
                .layoutWeight(1)
                .justifyContent(FlexAlign.SpaceBetween)
                .padding({ top: 2, bottom: 2 })
                .border({
                  width: { top: 1, right: 1 },
                  color: $r('app.color.grid_border')
                });
              })
            }
            .layoutWeight(1)
          }
        }
        .rowStart(0)
        .rowEnd(12)
        .columnStart(0)
        .columnEnd(0)
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
        .opacity(BackgroundImage.opacityLevel)

        /**
         * 课程内容
         */
        if (this.thisWeekSchedule.length === 0 || this.thisWeekSchedule.every(subArr => subArr.length === 0)) {
          GridItem({ style: GridItemStyle.NONE }) {
            Column() {
              Image($r('app.media.no_course_this_week'))
                .height(100)
                .width(100)
                .interpolation(ImageInterpolation.Medium)
                .draggable(false)
              Text($r('app.string.no_class_this_week')).fontSize(18).textAlign(TextAlign.Center)
            }
            .backgroundBlurStyle(BackgroundImage.blurLevel)
            .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
            .opacity(BackgroundImage.opacityLevel)
            .padding({
              top: 5,
              left: 10,
              right: 10,
              bottom: 10
            })
            .borderRadius(12);
          }
          .rowStart(0)
          .rowEnd(10)
          .columnStart(1)
          .columnEnd(7);
        } else {
          ForEach(this.thisWeekSchedule, (course: ScheduleSources.classAttribute[], indexDay) => {
            ForEach(course, (lesson: ScheduleSources.classAttribute) => {
              GridItem({ style: GridItemStyle.PLAIN }) {
                Column() {
                  Text(lesson.name)
                    .fontColor('#000000')
                    .fontWeight(FontWeight.Bold)
                    .fontSize(13)
                    .maxLines(this.screenHeight < this.criticalHeight ? 1 : 4)
                    .textOverflow({
                      overflow: (this.screenHeight < this.criticalHeight ? TextOverflow.MARQUEE : TextOverflow.Ellipsis)
                    })

                  Text(lesson.location)
                    .fontColor('#000000')
                    .fontSize(9)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.MARQUEE })

                  Text(lesson.teacher)
                    .fontColor('#000000')
                    .fontSize(9)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.MARQUEE })
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
              }
              .onClick(() => {
                this.checkBoxGroup = (this.checkBoxGroup + 1) % 2;
                this.isChangeSchedule = true;
                this.oriClassInfo = {
                  name: lesson.name,
                  teacher: lesson.teacher,
                  weekOfTerm: [...lesson.weekOfTerm], // 以枚举形式写出哪几周
                  timeSpan: [...lesson.timeSpan], // 应当仅包含开始和结束是第几节课
                  dayOfWeek: lesson.dayOfWeek,
                  location: lesson.location,
                  id: lesson.id,
                  color: lesson.color
                };
                this.classInfo = {
                  name: lesson.name,
                  teacher: lesson.teacher,
                  weekOfTerm: [...lesson.weekOfTerm], // 以枚举形式写出哪几周
                  timeSpan: [...lesson.timeSpan], // 应当仅包含开始和结束是第几节课
                  dayOfWeek: lesson.dayOfWeek,
                  location: lesson.location,
                  id: lesson.id,
                  color: lesson.color
                };
                this.classColor = this.oriClassInfo.color;
                this.rectifyWeekOfTerm = [];
                for (let weekRepeat = 1; weekRepeat <= 20; weekRepeat++) {
                  this.rectifyWeekOfTerm[weekRepeat] = false;
                }
                for (let weekRepeat of lesson.weekOfTerm) {
                  this.rectifyWeekOfTerm[weekRepeat] = true;
                }
                this.rectifyTimeSpan = [lesson.timeSpan[0], lesson.timeSpan[lesson.timeSpan.length - 1]];
                this.showSheet = true;
              })
              .rowStart(lesson.timeSpan[0] - 1)
              .rowEnd(lesson.timeSpan[lesson.timeSpan.length - 1] - 1)
              .columnStart((indexDay + 1) % 7 + 1)
              .columnEnd((indexDay + 1) % 7 + 1)
              .padding(2)
              .backgroundColor(lesson.color)
              .border({
                width: 1,
                color: $r('app.color.grid_border')
              });
            });
          });
        }
      }
      // .id('schedule_grid')
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')    // 8 列
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')    // 13 行
      .margin({ bottom: 75 })
      .padding(0)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(BackgroundImage.showImage ? undefined : $r('app.color.normal_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundImage(BackgroundImage.pic)
    .backgroundImageSize(ImageSize.Cover)
    .backgroundImagePosition(Alignment.Center)
  }

  @Builder
  ClassDetailDialog() {
    Column() {
      Row({ space: 8 }) {
        Text(this.isChangeSchedule ? $r('app.string.class_detail') : $r('app.string.class_detail_new'))
          .fontWeight(FontWeight.Bold)
          .fontSize(24)
          .layoutWeight(1)
          .margin({ left: 8 })

        if (this.isChangeSchedule) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.trash_red'))
              .height(24)
              .width(24)
          }
          .width(42)
          .height(42)
          .onClick(() => {
            this.getUIContext().showAlertDialog({
              message: $r('app.string.delete_class_or_not'),
              autoCancel: true,
              alignment: DialogAlignment.Center,
              gridCount: 4,
              primaryButton: {
                value: $r('app.string.cancel'),
                action: () => {}
              },
              secondaryButton: {
                enabled: true,
                defaultFocus: true,
                style: DialogButtonStyle.DEFAULT,
                fontColor: $r('app.color.red'),
                value: $r('app.string.ok'),
                action: () => {
                  scheduleManager.deleteSchedule(this.oriClassInfo);
                  this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];
                  this.showSheet = false;
                }
              },
              cancel: () => {
                console.info('Closed callbacks');
              },
              onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
                  dismissDialogAction.dismiss();
                }
                if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
                  dismissDialogAction.dismiss();
                }
              }
            });
          })

          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image($r('app.media.copy'))
              .height(24)
              .width(24)
          }
          .enabled(this.isWeeksLegal && this.isColorLegal)
          .width(42)
          .height(42)
          .onClick(() => {
            this.classInfo.weekOfTerm = [...this.weekOfTerm];
            if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
              let swapTemp = this.rectifyTimeSpan[0];
              this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
              this.rectifyTimeSpan[1] = swapTemp;
            }
            this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
            scheduleManager.addSchedule(this.classInfo, this.changeAllColor);
            this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];
            this.showSheet = false;
          })
        }

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
        }
        .width(42)
        .height(42)
        .onClick(() => {
          this.classInfo.weekOfTerm = [...this.weekOfTerm];
          if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
            let swapTemp = this.rectifyTimeSpan[0];
            this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
            this.rectifyTimeSpan[1] = swapTemp;
          }
          this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
          if (!areClassAttributesEqual(this.oriClassInfo, this.classInfo)) {
            this.getUIContext().showAlertDialog({
              title: $r('app.string.unsaved_change'),
              message: $r('app.string.back_to_schedule_or_not'),
              autoCancel: true,
              alignment: DialogAlignment.Center,
              gridCount: 4,
              primaryButton: {
                value: $r('app.string.cancel'),
                action: () => {}
              },
              secondaryButton: {
                enabled: true,
                defaultFocus: true,
                style: DialogButtonStyle.HIGHLIGHT,
                value: $r('app.string.ok'),
                action: () => {
                  this.showSheet = false;
                }
              },
              cancel: () => {},
              onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
                  dismissDialogAction.dismiss();
                }
                if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
                  dismissDialogAction.dismiss();
                }
              }
            });
          } else {
            this.showSheet = false;
          }
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image(this.isChangeSchedule ? $r('app.media.save') : $r('app.media.checkmark'))
            .height(24)
            .width(24)
        }
        .width(42)
        .height(42)
        .enabled(this.isWeeksLegal && this.isColorLegal)
        .onClick(() => {
          this.classInfo.weekOfTerm = [...this.weekOfTerm];
          if (this.rectifyTimeSpan[0] > this.rectifyTimeSpan[1]) {
            let swapTemp = this.rectifyTimeSpan[0];
            this.rectifyTimeSpan[0] = this.rectifyTimeSpan[1];
            this.rectifyTimeSpan[1] = swapTemp;
          }
          this.classInfo.timeSpan = tools.getContArray([this.rectifyTimeSpan]) as number[];
          if (this.isChangeSchedule) {
            if (!areClassAttributesEqual(this.oriClassInfo, this.classInfo)) {
              scheduleManager.deleteSchedule(this.oriClassInfo);
              scheduleManager.addSchedule(this.classInfo, this.changeAllColor);
              this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];
            }
          } else {
            scheduleManager.addSchedule(this.classInfo, this.changeAllColor);
            this.thisWeekSchedule = scheduleManager.formattedSchedule[this.weekDisplayed];
          }
          this.showSheet = false;
        });
      }
      .margin({ bottom: 10 })

      Scroll() {
        Column() {
          Row() {
            Text($r('app.string.class_detail_name'));
            TextInput({ text: this.classInfo.name })
              .layoutWeight(1)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.name = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_teacher'));
            TextInput({ text: this.classInfo.teacher })
              .layoutWeight(1)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.teacher = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_location'));
            TextInput({ text: this.classInfo.location })
              .layoutWeight(1)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.location = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_id'));
            TextInput({ text: this.classInfo.id })
              .layoutWeight(1)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.id = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 });

          Row() {
            Text($r('app.string.class_detail_time'))
              .textAlign(TextAlign.Start);
            Select(this.createArray(1, 13))
              .value(this.rectifyTimeSpan[0].toString())
              .onSelect((index: number) => {
                this.rectifyTimeSpan[0] = index + 1;
              });
            Text(' ~ ');
            Select(this.createArray(1, 13))
              .value(this.rectifyTimeSpan[1].toString())
              .onSelect((index: number) => {
                this.rectifyTimeSpan[1] = index + 1;
              });
          }
          .margin({ bottom: 5 })

          Row() {
            Text($r('app.string.class_detail_day_of_week'))
              .textAlign(TextAlign.Start);
            Select([{ value: $r('app.string.monday') }, { value: $r('app.string.tuesday') },
              { value: $r('app.string.wednesday') },
              { value: $r('app.string.thursday') }, { value: $r('app.string.friday') },
              { value: $r('app.string.saturday') }, { value: $r('app.string.sunday') }])
              .value(tools.weekTranslate[this.classInfo.dayOfWeek])
              .onSelect((index: number) => {
                this.classInfo.dayOfWeek = index;
              });
          }
          .margin({ bottom: 5 })

          Row() {
            Text($r('app.string.class_detail_color'))
              .textAlign(TextAlign.Start);
            Stack({ alignContent: Alignment.End }) {
              TextInput({ text: this.classColor })
                .textOverflow(TextOverflow.Ellipsis)
                .onChange((input: string) => {
                  // console.log('abcdefg'); 此处证明了this.classColor = input;不会导致死循环
                  if (/^#([A-Fa-f0-9]{3}|[A-Fa-f0-9]{4}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(input)) {
                    this.isColorLegal = true;
                    this.classInfo.color = input;
                    this.colorARGB = tools.stringToRgba(input);
                  } else {
                    this.isColorLegal = false;
                  }
                  this.classColor = input;
                })
                .width('100%')
                .selectAll(true);
              Circle()
                .fill(this.isColorLegal ? this.classColor : '#00d00721')
                .width(32)
                .height(32)
                .offset({ x: -4 })
                .stroke(this.isColorLegal ? $r('app.color.grid_border') : $r('app.color.red'))
                .bindPopup(this.showColorHint, {
                  builder: this.colorHintPopup(),
                  placement: Placement.Top,
                  width: 300,
                  onStateChange: (status) => {
                    if (!status.isVisible) {
                      this.showColorHint = false;
                    }
                  }
                });
              Image($r('app.media.paintpalette'))
                .height(25)
                .offset({ x: -7 })
                .onClick(() => {
                  if (this.classColor.length === 4) {
                    this.colorDialogText = this.classColor[0] + this.classColor[1] + this.classColor[1]
                      + this.classColor[2] + this.classColor[2] + this.classColor[3] + this.classColor[3];
                  } else if (this.classColor.length === 5) {
                    this.colorDialogText = this.classColor[0] + this.classColor[1] + this.classColor[1]
                      + this.classColor[2] + this.classColor[2] + this.classColor[3] + this.classColor[3]
                      + this.classColor[4] + this.classColor[4];
                  } else {
                    this.colorDialogText = this.classColor;
                  }
                  this.colorARGB = tools.stringToRgba(this.colorDialogText);
                  if (this.colorDialogText.length === 7)
                    this.colorDialogText = `#FF${this.colorDialogText.slice(1,7)}`;
                  this.showColorPicker = true;
                });
            }
            .layoutWeight(1);
            PopoverDialog({
              visible: this.showColorPicker,
              targetBuilder: () => {},
              popover: {
                width: 300,
                placement: Placement.Top,
                arrowPointPosition: ArrowPointPosition.END,
                builder: () => { this.colorPicker() },
                onStateChange: (popup) => {
                  if (!popup.isVisible) {
                    // 关闭弹窗后记录颜色值
                    this.showColorPicker = false;
                    if (this.colorARGB[0] === 255) {
                      this.classColor = '#' + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
                        + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
                        + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
                    } else {
                      this.classColor = '#' + this.colorARGB[0].toString(16).padStart(2, '0').toUpperCase()
                        + this.colorARGB[1].toString(16).padStart(2, '0').toUpperCase()
                        + this.colorARGB[2].toString(16).padStart(2, '0').toUpperCase()
                        + this.colorARGB[3].toString(16).padStart(2, '0').toUpperCase();
                    }
                    this.classInfo.color = this.classColor;
                  }
                }
              },
            })
          }
          .margin({ bottom: 5 })

          Row() {
            Text($r('app.string.class_detail_weeks', tools.shrinkContArrayToString(this.weekOfTerm)))
              .textAlign(TextAlign.Start)
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            CheckboxGroup({ group: `checkboxGroup${this.checkBoxGroup}` })
              .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
              .onChange((itemName: CheckboxGroupResult) => {
                let selectAny: boolean = false;
                this.weekOfTerm = [];
                for (let weekRepeat = 1; weekRepeat <= 20; weekRepeat++) {
                  if (this.rectifyWeekOfTerm[weekRepeat]) {
                    this.weekOfTerm.push(weekRepeat);
                    selectAny = true;
                  }
                }
                this.isWeeksLegal = selectAny;
              });
            Text($r('app.string.select_all'));
          }
          .width('100%');

          Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.SpaceAround }) {
            ForEach(tools.getContArray([[1, 20]]), (checkboxId: number) => {
              Row() {
                Checkbox({ name: checkboxId.toString(), group: `checkboxGroup${this.checkBoxGroup}` })
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
                  .select(this.rectifyWeekOfTerm[checkboxId])
                  .onChange((value: boolean) => {
                    this.rectifyWeekOfTerm[checkboxId] = value;
                  });
                Text((checkboxId).toString()).width(20);
              }
            });
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('90%');
      }
      .fadingEdge(true)
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false });
    }
    .padding({ top: 16, right: 16, left: 16})
    .width('100%')
    .height('100%')
  }
}
