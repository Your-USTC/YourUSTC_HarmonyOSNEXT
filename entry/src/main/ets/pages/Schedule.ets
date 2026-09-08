
import { PopoverDialog, Popup } from '@kit.ArkUI';
import * as ScheduleSources from '../constants/ScheduleSources';
import { classAttribute, semesterAttribute, exportSemester, exportedData } from '../constants/ScheduleSources';
import ScheduleManager, { areClassAttributesEqual } from '../utils/Classes/ScheduleManager';
import * as ScheduleStorage from '../utils/ScheduleStorage';
import * as tools from '../utils/tools';
import { weekTranslate } from '../utils/tools';
import UnifiedPreferences, { millisecondsPerWeek } from '../utils/UnifyPreference';
import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import RenameDialog from '../view/RenameDialog';
import { JSON } from '@kit.ArkTS';
import { currentScheduleVersion, FULL_TIME_FORMAT } from '../constants/BasicConstants';
import MessageDialog from '../view/MessageDialog';

interface PopupOnStateChangeInfo {
  isVisible: boolean;
}

const criticalHeight: number = 32; // 紧凑模式临界值(vp)
const classAndTeacher: number = 22; // 教室和教师占用高度
const font13fpHeight: number = 16; // 包括行间距

@Builder
export function ScheduleBuilder(name: string, param?: number) {
  if (param)
    Schedule({ gridHeight: param, maxLinesH: Math.max(1, (param / 13 - classAndTeacher) / font13fpHeight) });
  else
    Schedule({ gridHeight: UnifiedPreferences.getNumberSync('GridHeight', 500) })
}

@Entry
@Component
struct Schedule {

  initGridHeight: number = 0;
  @State gridHeight: number = 0; // 课表grid高度
  @State hideTime: boolean = false;
  gridMinHeight: number = 0;
  @State maxLinesH: number = 1; // H意为height

  @State currentWeek: number = 1;
  @State weekDisplayed: number = 1;
  @State weekStart: number = 0;
  private currentWeekStart: number = 0;
  @State displayTerm: number = 0;
  @State thisWeekSchedule: ScheduleSources.classAttribute[] = [];
  @State conflictSchedule: ScheduleSources.classAttribute[] = [];

  msgDialogController?: CustomDialogController;
  @State showXiuHint: boolean = false;
  @Builder xiuHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.back_to_current_week') },
        showClose: false,
        buttons: [{
          text: $r('app.string.next_hint'),
          action: () => {
            this.showXiuHint = false;
            this.showCalendarHint = true;
          }
        }]
      })}
  }
  @State showCalendarHint: boolean = false;
  @Builder calendarHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.quick_jump_tp') },
        showClose: false,
        buttons: [{
          text: $r('app.string.next_hint'),
          action: () => {
            this.showCalendarHint = false;
            this.showPinchHint = true;
          }
        }]
      })
    }
  }
  @State showPinchHint: boolean = false;
  @Builder pinchHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.pinch_to_scale') },
        showClose: false,
        buttons: [{
          text: $r('app.string.next_hint'),
          action: () => {
            this.showPinchHint = false;
            this.showSemHint = true;
          }
        }]
      })
    }
  }
  @State showSemHint: boolean = false;
  @Builder semHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.semester_dialog_hint') },
        showClose: false,
        buttons: [{
          text: $r('app.string.no_reminding'),
          action: () => {
            UnifiedPreferences.putSync('ShowPinchHint', false);
            this.showSemHint = false;
          }
        }]
      })
    }}
  @State showColorHint: boolean = false;
  @Builder colorHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.more_color_option') },
        showClose: false,
        buttons: [{
          text: $r('app.string.next_hint'),
          action: () => {
            this.showColorHint = false;
            this.showScrollHint = true;
          }
        }]
      })
    }
  }
  @State showScrollHint: boolean = false;
  @Builder scrollHintPopup() {
    Row() {
      Popup({
        icon: { image: $r('app.media.lightbulb') },
        message: { text: $r('app.string.change_detail_size') },
        showClose: false,
        buttons: [{
          text: $r('app.string.no_reminding'),
          action: () => {
            UnifiedPreferences.putSync('ShowColorHint', false);
            this.showScrollHint = false;
          }
        }]
      })
    }
  }


  /**
   * 详情弹窗部分
   */
  @State showSheet: boolean = false;
  private classInfo: ScheduleSources.classAttribute = {
    name: '计算机程序设计',
    teacher: '李卫海',
    location: '3A212',
    id: 'CS1003.H2',
    weekOfTerm: [2, 3, 4, 6, 7, 8, 9, 10, 14, 15, 16],
    timeSpan: [6, 7],
    dayOfWeek: 1,
    color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)],
    priority: 5,
    credits: '3'
  };
  private oriClassInfo: ScheduleSources.classAttribute = {
    name: '计算机程序设计',
    teacher: '李卫海',
    location: '3A212',
    id: 'CS1003.H2',
    weekOfTerm: [2, 3, 4, 6, 7, 8, 9, 10, 14, 15, 16],
    timeSpan: [6, 7],
    dayOfWeek: 1,
    color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)],
    priority: 5,
    credits: '3'
  };

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
  @Builder colorPicker() {
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


  /**
   * 菜单部分
   */
  @Builder editMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.class_detail_new'), startIcon: $r('app.media.plus_square') })
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
            dayOfWeek: 1,
            color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)],
            priority: 5,
            credits: '3'
          };
          this.classInfo = {
            name: '计算机程序设计',
            teacher: '李卫海',
            location: '3A212',
            id: 'CS1003.H2',
            weekOfTerm: tools.getContArray([[2, 4], [6, 10], [14, 16]]) as number[],
            timeSpan: [6, 7],
            dayOfWeek: 1,
            color: tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)],
            priority: 5,
            credits: '3'
          };
          this.classColor = this.oriClassInfo.color;
          this.rectifyWeekOfTerm = [true, false, true, true, true, false, true, true, true, true, true,
            false, false, false, true, true, true, false, false, false, false];
          this.rectifyTimeSpan = [6, 7];
          this.showSheet = true;
        });
      MenuItem({ content: $r('app.string.online_schedule'), startIcon: $r('app.media.cloud_download')})
        .onClick(() => {
          this.pathStack.pushPath({ name: "GetSchedule",
            param: [$r('app.string.online_schedule'), 'https://jw.ustc.edu.cn/for-std/course-table'],
            onPop: (popInfo: PopInfo) => {
              if (typeof popInfo.result === 'number' && popInfo.result < ScheduleManager.semesters.length) {
                ScheduleManager.switchTempSemester(popInfo.result);
                this.initSchedule();
                this.refreshGrid();
              }
            }
          });
        });
      MenuItem({ content: $r('app.string.search_in_all_courses'), startIcon: $r('app.media.search') })
        .onClick(() => {
          this.pathStack.pushPath({ name: 'GetClassByName' });
        });
      MenuItem({ startIcon: $r('app.media.archive'), content: "导入和导出", builder: this.archiveMenu() })
    }
    .subMenuExpandingMode(SubMenuExpandingMode.STACK_EXPAND)
  }
  @Builder archiveMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.import_schedule'), startIcon: $r('app.media.import') })
        .onClick(() => {
          tools.readStringFromFile(this.getUIContext(), '数据交换格式|.json').then(result => {
            if (result === 'null') {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.read_file_cancel') });
            } else {
              try {
                console.log('1!!!');
                console.log('!!!' + result);
                const rawImportedData = JSON.parse(result) as exportedData;
                const checkResult = ScheduleSources.validateExportedData(rawImportedData);
                if (checkResult === '') {
                  const oldNum: number = ScheduleManager.semesters.length;
                  let currentTime = Date.now();
                  rawImportedData.semesters.forEach(importSemester => {
                    ScheduleManager.newSemester(importSemester.attribute.name, importSemester.attribute.source, importSemester.attribute.beginTime, ++currentTime, importSemester.attribute.totalWeekNum, importSemester.courses);
                  })
                  if (rawImportedData.semesters.length > 0) {
                    ScheduleManager.switchTempSemester(oldNum + rawImportedData.defaultSemester);
                    this.initSchedule();
                    this.refreshGrid();
                  }
                  this.showSemesters = true;
                  this.getUIContext().getPromptAction().showToast({ message: '导入成功' });
                } else {
                  this.getUIContext().getPromptAction().showToast({ message: checkResult });
                }
              } catch(error) {
                console.log('!!!' + JSON.stringify(error));
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.read_file_format_error') });
              }
            }
          });
        });

      MenuItem({ content: $r('app.string.export_schedule'), startIcon: $r('app.media.export') })
        .onClick(() => {
          const saveTime: number = Math.trunc(Date.now() / 1000);
          let userContent: exportedData = {
            exportTime: saveTime,
            scheduleVersion: currentScheduleVersion,
            defaultSemester: ScheduleManager.defaultSemester,
            semesters: Array.from(ScheduleManager.semesters, (semester) => {
              return {
                attribute: semester,
                courses: ScheduleStorage.getCourses(semester.createTime)
              } as exportSemester;
            })
          };

          tools.saveStringToFile(this.getUIContext(), "DailyNicSchedule_" + String(saveTime) + ".json", '数据交换格式|.json', JSON.stringify(userContent));
        });
    }
  }

  /**
   * 叠课弹窗部分
   */
  @State showConflictClass: boolean = false;
  @Builder ConflictClass() {
    Column() {
      Row() {
        Column() {
          Text($r('app.string.conflict_class_detail_d', this.weekDisplayed))
            .fontWeight(FontWeight.Bold)
            .fontSize(20)
            .width('100%')
          Text($r('app.string.conflict_class_help'))
            .fontSize(12)
            .textOverflow({ overflow: TextOverflow.MARQUEE })
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 8 });

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .onClick(() => {
          this.showConflictClass = false;
        })
      }
      .margin({ bottom: 5 })

      List({ space: 14 }) {
        if (this.conflictSchedule.length === 0) {
          ListItem() {
            Column() {
              Image($r('app.media.no_conflict_class'))
                .height(120)
                .draggable(false)
              Text($r('app.string.no_conflict_class'))
                .fontSize(18)
            }
          }
          .width('100%')
          .margin({ top: 10 })
        }
        ForEach(this.conflictSchedule, (lesson: classAttribute) => {
          ListItem() {
            Row() {
              Text(lesson.name)
                .textAlign(TextAlign.Start)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .maxLines(2)
                .layoutWeight(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 5, bottom: 5 });

              Column() {
                Text(`\udb81\uddf3 ${lesson.teacher}`)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .visibility(lesson.teacher == '' ? Visibility.None : Visibility.Visible);

                Text(`\udb80\uddb8 ${lesson.location}`)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .visibility(lesson.location == '' ? Visibility.None : Visibility.Visible);

                Text() {
                  Span('\udb80\udfdc ');
                  Span(weekTranslate[lesson.dayOfWeek]);
                  Span(` ${ScheduleSources.commonClassTime[lesson.timeSpan[0]][0]}-${ScheduleSources.commonClassTime[lesson.timeSpan[lesson.timeSpan.length - 1]][1]}`);
                }
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width(162)
              .alignItems(HorizontalAlign.Start);
            }
          }
          .width('100%')
          .padding({ top: 10, bottom: 10, left: 13, right: 13 })
          .backgroundColor($r('app.color.grid_background'))
          .borderRadius(20)
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
              color: lesson.color,
              priority: lesson.priority,
              credits: lesson.credits
            };
            this.classInfo = {
              name: lesson.name,
              teacher: lesson.teacher,
              weekOfTerm: [...lesson.weekOfTerm], // 以枚举形式写出哪几周
              timeSpan: [...lesson.timeSpan], // 应当仅包含开始和结束是第几节课
              dayOfWeek: lesson.dayOfWeek,
              location: lesson.location,
              id: lesson.id,
              color: lesson.color,
              priority: lesson.priority,
              credits: lesson.credits
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
        })
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false });
    }
    .height('98%')
    .width('100%')
    .padding(16)
  }


  /**
   * 切换学期弹窗
   */
  @State showSemesters: boolean = false;
  @State semesters: semesterAttribute[] = [];
  @State defaultSemester: number = ScheduleManager.defaultSemester;
  @State displayName: string = ScheduleManager.semesters[ScheduleManager.defaultSemester].name;
  renameController: CustomDialogController | undefined;

  @Builder SemesterDetail() {
    Column() {
      Row() {
        Column() {
          Text($r('app.string.all_semesters'))
            .fontWeight(FontWeight.Bold)
            .fontSize(20)
            .width('100%')
          Text($r('app.string.all_semesters_intro'))
            .fontSize(12)
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 8 });

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.top'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .margin({ right: 8 })
        .onClick(() => {
          if (this.displayTerm > 0) {
            ScheduleManager.toppingSemester(this.displayTerm);
            this.defaultSemester = ScheduleManager.defaultSemester;
            this.initSchedule();
            this.refreshGrid();
          }
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.plus_square'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .margin({ right: 8 })
        .onClick(() => {
          const currentTime: Date = new Date();
          const currentTimestamp: number = currentTime.getTime();
          ScheduleManager.newSemester('自定义名称', '手动添加', currentTime.setHours(0, 0, 0, 0) - 86400000 * currentTime.getDay(), currentTimestamp);
          ScheduleManager.switchTempSemester(ScheduleManager.semesters.length - 1);
          this.initSchedule();
          this.refreshGrid();
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(24)
            .width(24)
            .draggable(false)
        }
        .width(42)
        .height(42)
        .onClick(() => {
          this.showSemesters = false;
        })
      }
      .margin({ bottom: 5 })

      List({ space: 14, initialIndex: this.displayTerm }) {
        ForEach(this.semesters, (semester: semesterAttribute, index: number) => {
          ListItem() {
            Column({ space: 4 }) {
              Row({ space: 5 }) {
                Text(semester.name)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .margin({ left: 10 })
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.MARQUEE })

                Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                  Image($r('app.media.default_semester'))
                    .height(22)
                    .width(22)
                    .fillColor(this.defaultSemester === index ? presetColor[BackgroundImage.themeColor][2] : undefined)
                }
                .height(40)
                .width(40)
                .onClick(() => {
                  this.getUIContext().getPromptAction().showToast({ message: $r('app.string.set_default_semester', ScheduleManager.semesters[index].name) });
                  ScheduleManager.setDefaultSemester(index);
                  this.defaultSemester = index;
                })

                Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                  Image($r('app.media.rename'))
                    .height(22)
                    .width(22)
                }
                .height(40)
                .width(40)
                .onClick(() => {
                  const semName = this.semesters[index].name;
                  this.renameController = new CustomDialogController({
                    builder: RenameDialog({
                      name: semName,
                      message: $r('app.string.rename_semester', semName),
                      onConfirm: (newName: string) => {
                        if (index === this.displayTerm) {
                          this.displayName = newName;
                        }
                        ScheduleManager.renameSemester(index, newName);
                        this.semesters = ScheduleManager.semesters;
                      }
                    }),
                    gridCount: 4,
                    autoCancel: false
                  });
                  this.renameController.open();
                })

                Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                  Image($r('app.media.copy'))
                    .height(22)
                    .width(22)
                }
                .height(40)
                .width(40)
                .onClick(() => {
                  const currentTime: Date = new Date();
                  const currentTimestamp: number = currentTime.getTime();
                  if (this.displayTerm === index)
                    ScheduleManager.newSemester(this.displayName + '_副本', '从「' + this.displayName + '」复制', currentTime.setHours(0, 0, 0, 0) - 86400000 * currentTime.getDay(), currentTimestamp, undefined, this.thisWeekSchedule);
                  else
                    ScheduleManager.newSemester(this.semesters[index].name + '_副本', '从「' + this.semesters[index].name + '」复制', currentTime.setHours(0, 0, 0, 0) - 86400000 * currentTime.getDay(), currentTimestamp, undefined, ScheduleStorage.getCourses(this.semesters[index].createTime));
                  ScheduleManager.switchTempSemester(ScheduleManager.semesters.length - 1);
                  this.initSchedule();
                  this.refreshGrid();
                })

                Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
                  Image($r('app.media.trash_red'))
                    .height(22)
                    .width(22)
                }
                .height(40)
                .width(40)
                .enabled(this.displayTerm !== index && this.defaultSemester !== index)
                .onClick(() => {
                  this.msgDialogController = new CustomDialogController({
                    builder: MessageDialog({
                      message: $r('app.string.delete_semester_or_not'),
                      onConfirm: () => {
                        ScheduleManager.deleteSemester(index);
                        this.displayTerm = ScheduleManager.displaySemester;
                        this.defaultSemester = ScheduleManager.defaultSemester;
                        this.semesters = ScheduleManager.semesters;
                      }
                    }),
                    autoCancel: true,
                    gridCount: 4
                  });
                  this.msgDialogController.open();
                })
              }

              Row() {
                Text($r('app.string.all_semesters_start_date'))
                Button(new Date(semester.beginTime).toLocaleDateString('zh-cn', { year: 'numeric', month: 'short', day: 'numeric' }))
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .height(30)
                  .borderRadius(15)
                  .fontColor(presetColor[BackgroundImage.themeColor][2])
                  .onClick(() => {
                    this.getUIContext().showDatePickerDialog({
                      start: new Date(0),
                      end: new Date(4133865600000),
                      selected: new Date(semester.beginTime),
                      showTime: false,
                      selectedTextStyle: { color: presetColor[BackgroundImage.themeColor][2] },
                      onDateAccept: (value: Date) => {
                        ScheduleManager.changeSemesterStartTime(index, value.setHours(0, 0, 0, 0) - 86400000 * value.getDay());
                        if (this.displayTerm === index) {
                          this.initSchedule();
                          this.refreshGrid();
                        }
                      }
                    })
                  })
              }
              .margin({ left: 15 })

              Text($r('app.string.all_semesters_total_week', semester.totalWeekNum))
                .margin({ left: 15 })

              Row() {
                Text($r('app.string.all_semesters_source'))
                  .margin({ left: 15 })
                Text(semester.source)
                  .layoutWeight(1)
              }
              .alignItems(VerticalAlign.Top)

              Text($r('app.string.all_semesters_create_time', new Date(semester.createTime).toLocaleString('zh-cn', FULL_TIME_FORMAT)))
                .margin({ left: 15 })
                .textAlign(TextAlign.Start)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(this.displayTerm === index ? 7 : 10)
            .borderRadius(20)
            .borderColor(this.displayTerm === index ? presetColor[BackgroundImage.themeColor][2] : undefined)
            .borderWidth(this.displayTerm === index ? 3 : undefined)
            .backgroundColor($r('app.color.grid_background'))
            .onClick(() => {
              ScheduleManager.switchTempSemester(index);
              this.initSchedule();
              this.refreshGrid();
            })
          }
          .width('100%')
          .transition(TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 600, delay: 60 * index, curve: Curve.Ease }))
        });
      }
      .width('100%')
      .layoutWeight(1)
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }

  refreshGrid() {
    const rawData: ScheduleSources.classAttribute[] = ScheduleManager.getDisplayClassesByWeek(this.weekDisplayed);
    this.thisWeekSchedule = [];
    this.conflictSchedule = [];
    rawData.sort((a, b) => {
      if (a.priority !== b.priority) {
        return a.priority - b.priority;
      }
      return b.timeSpan[0] - a.timeSpan[0];
    });

    const flag: boolean[][] = Array(7).fill(null).map(() => Array(14).fill(false));
    let noConflict: boolean;
    for (let i = rawData.length - 1; i >= 0; i--) {
      noConflict = true;
      for (let eachSpan of rawData[i].timeSpan) {
        if (flag[rawData[i].dayOfWeek][eachSpan]) {
          this.conflictSchedule.push(rawData[i]);
          noConflict = false;
          break;
        }
        flag[rawData[i].dayOfWeek][eachSpan] = true;
      }
      if (noConflict) {
        this.thisWeekSchedule.push(rawData[i]);
      }
    }
  }

  // 不含显示 Grid 课表！
  initSchedule() {
    const currentTime = new Date();
    this.displayTerm = ScheduleManager.displaySemester;
    this.semesters = ScheduleManager.semesters;
    const termStartTime: number = this.semesters[this.displayTerm].beginTime;
    if (currentTime.getTime() < termStartTime || currentTime.getTime() > termStartTime + this.semesters[this.displayTerm].totalWeekNum * millisecondsPerWeek) {
      this.currentWeek = this.weekDisplayed = 1;
      this.currentWeekStart = this.weekStart = termStartTime;
    } else {
      this.currentWeek = this.weekDisplayed = Math.ceil((currentTime.getTime() - termStartTime) / millisecondsPerWeek);
      this.currentWeekStart = this.weekStart = new Date(new Date(currentTime).setDate(currentTime.getDate() - currentTime.getDay())).setHours(0, 0, 0, 0);
    }
    this.displayName = this.semesters[this.displayTerm].name;
  }

  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      /**
       * 课表
       */
      Scroll() {
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
                    width: { right: 0.6 },
                    color: $r('app.color.grid_border')
                  })

                Text($r('app.string.afternoon'))
                  .fontWeight(FontWeight.Bold)
                  .fontSize(14)
                  .layoutWeight(5)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .border({
                    width: { top: 0.6, right: 0.6 },
                    color: $r('app.color.grid_border')
                  })

                Text($r('app.string.evening'))
                  .fontWeight(FontWeight.Bold)
                  .fontSize(14)
                  .layoutWeight(3)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .border({
                    width: { top: 0.6, right: 0.6 },
                    color: $r('app.color.grid_border')
                  })
              }
              .layoutWeight(1)

              // 13节课
              Column() {
                Column() {
                  Text(ScheduleSources.commonClassTime[1][0])
                    .fontSize('8fp')
                    .visibility(this.hideTime ? Visibility.None : Visibility.Visible)

                  Text('1')
                    .fontWeight(FontWeight.Bold)
                    .fontSize(14)
                    .align(Alignment.Center)

                  Text(ScheduleSources.commonClassTime[1][1])
                    .fontSize('8fp')
                    .visibility(this.hideTime ? Visibility.None : Visibility.Visible)
                }
                .clip(true)
                .width('100%')
                .layoutWeight(1)
                .justifyContent(FlexAlign.SpaceBetween)
                .padding({ top: 2, bottom: 2 })
                .border({
                  width: { right: 0.6 },
                  color: $r('app.color.grid_border')
                })
                .onSizeChange((_oldValue: SizeOptions, newValue: SizeOptions) => {
                  if (tools.LengthToNumber(newValue.height, 100) < criticalHeight + 6) // 加6是因为padding和border
                    this.hideTime = true;
                  else
                    this.hideTime = false;
                });

                ForEach(tools.getContArray([[2, 13]]), (item: number) => {
                  Column() {
                    Text(ScheduleSources.commonClassTime[item][0])
                      .fontSize('8fp')
                      .visibility(this.hideTime ? Visibility.None : Visibility.Visible)

                    Text(item.toString())
                      .fontWeight(FontWeight.Bold)
                      .fontSize(14)
                      .align(Alignment.Center)

                    Text(ScheduleSources.commonClassTime[item][1])
                      .fontSize('8fp')
                      .visibility(this.hideTime ? Visibility.None : Visibility.Visible)
                  }
                  .clip(true)
                  .width('100%')
                  .layoutWeight(1)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .padding({ top: 2, bottom: 2 })
                  .border({
                    width: { top: 0.6, right: 0.6 },
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
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)

          /**
           * 课程内容
           */
          if (this.thisWeekSchedule.length === 0) {
            GridItem({ style: GridItemStyle.NONE }) {
              Column() {
                Image($r('app.media.no_course_this_week'))
                  .height(128)
                  .width(128)
                  .draggable(false)
                Text($r('app.string.no_class_this_week')).fontSize(18).textAlign(TextAlign.Center)
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
            .rowStart(0)
            .rowEnd(10)
            .columnStart(1)
            .columnEnd(7);
          } else {
            ForEach(this.thisWeekSchedule, (lesson: ScheduleSources.classAttribute) => {
              GridItem({ style: GridItemStyle.PLAIN }) {
                Column() {
                  Text(lesson.name)
                    .fontColor('#000000')
                    .fontWeight(FontWeight.Bold)
                    .fontSize(13)
                    .maxLines(Math.floor(this.maxLinesH * lesson.timeSpan.length))
                    .textOverflow({
                      overflow: (Math.floor(this.maxLinesH * lesson.timeSpan.length) === 1 ? TextOverflow.MARQUEE : TextOverflow.Ellipsis)
                    })

                  Text(lesson.location + '\n' + lesson.teacher)
                    .fontColor('#000000')
                    .fontSize(9)
                    .textAlign(TextAlign.Center)
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
              }
              .clip(true)
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
                  color: lesson.color,
                  priority: lesson.priority,
                  credits: lesson.credits
                };
                this.classInfo = {
                  name: lesson.name,
                  teacher: lesson.teacher,
                  weekOfTerm: [...lesson.weekOfTerm], // 以枚举形式写出哪几周
                  timeSpan: [...lesson.timeSpan], // 应当仅包含开始和结束是第几节课
                  dayOfWeek: lesson.dayOfWeek,
                  location: lesson.location,
                  id: lesson.id,
                  color: lesson.color,
                  priority: lesson.priority,
                  credits: lesson.credits
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
              .columnStart(lesson.dayOfWeek + 1)
              .columnEnd(lesson.dayOfWeek + 1)
              .padding(2)
              .backgroundColor(lesson.color)
              .border({
                width: 0.6,
                color: $r('app.color.grid_border')
              });
            });
          }
        }
        // .id('schedule_grid')
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr') // 8 列
        .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr') // 13 行
        .height(this.gridHeight)
        .bindPopup(this.showPinchHint, {
          builder: this.pinchHintPopup(),
          placement: Placement.LeftTop,
          width: 300,
          onStateChange: (status: PopupOnStateChangeInfo) => {
            if (!status.isVisible) {
              this.showPinchHint = false;
            }
          }
        })
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .layoutWeight(1)
      .align(Alignment.Top)
      .onSizeChange((_oldValue: SizeOptions, newValue: SizeOptions) => {
        this.gridMinHeight = Math.max(208, tools.LengthToNumber(newValue.height, 1000) >> 1); // 神秘数字208
        if (this.gridHeight < this.gridMinHeight)
          this.maxLinesH = Math.max(1, ((this.gridHeight = this.gridMinHeight) / 13 - classAndTeacher) / font13fpHeight);
      })
      .gesture(PinchGesture({ fingers: 2 })
        .onActionStart(() => this.initGridHeight = this.gridHeight)
        .onActionUpdate((event: GestureEvent) => {
          let tmpHeight: number = event.scale * this.initGridHeight;
          if (tmpHeight > this.gridMinHeight && tmpHeight < 2600)
            this.maxLinesH = Math.max(1, ((this.gridHeight = tmpHeight) / 13 - classAndTeacher) / font13fpHeight);
        })
        .onActionEnd(() => UnifiedPreferences.putSync('GridHeight', this.gridHeight))
      )
    }
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .hideBackButton(true)
    .title({ builder: this.customTitle(), height: 98 }, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: (BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : '#0000')
    })
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.initSchedule(); // 在onShown中刷新显示
    })
    .onShown(() => {
      this.refreshGrid();
      setTimeout(() => this.showXiuHint = UnifiedPreferences.getBoolSync('ShowPinchHint', true), 0);
    });
  }

  @Builder customTitle() {
    Column() {
      Row({ space: 6 }) { // 上边距3，高度40
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .height(22)
            .draggable(false)
        }
        .height(40)
        .width(40)
        .onClick(() => {
          this.pathStack.pop();
        })

        Column() {
          Text(this.displayName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .maxLines(1)
            .margin({ bottom: 1 })
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .bindSheet($$this.showSheet, this.ClassDetailDialog(), {
              // 如果与 gridItem 绑定，会弹出很多个！
              detents: [SheetSize.MEDIUM, SheetSize.LARGE],
              preferType: SheetType.CENTER,
              showClose: false,
              scrollSizeMode: ScrollSizeMode.CONTINUOUS,
              backgroundColor: '#0000',
              blurStyle: BlurStyle.Regular,
              onAppear: () => {
                this.showColorHint = UnifiedPreferences.getBoolSync('ShowColorHint', true);
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
                  this.msgDialogController = new CustomDialogController({
                    builder: MessageDialog({
                      mainTitle: $r('app.string.unsaved_change'),
                      message: $r('app.string.back_to_schedule_or_not'),
                      onConfirm: () => DismissSheetAction.dismiss()
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
          Text($r('app.string.local_schedule_daily_nic'))
            .fontSize(12)
            .fontColor($r('app.color.transparent_text'))
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .bindSheet($$this.showSemesters, this.SemesterDetail(), {
          // 如果与 gridItem 绑定，会弹出很多个！
          detents: [SheetSize.LARGE, SheetSize.MEDIUM],
          preferType: SheetType.CENTER,
          showClose: false,
          scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT,
          backgroundColor: '#0000',
          blurStyle: BlurStyle.Regular
        })

        Badge({ count: this.conflictSchedule.length, style: { badgeSize: 15, badgeColor: /*'#FA2A2D'*/$r('sys.color.ohos_id_color_badge_red') } }) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Image(this.conflictSchedule.length === 0 ? $r('app.media.pile') : $r('app.media.pile_fill'))
              .height(22)
              .width(22)
              .draggable(false)
          }
          .height(40)
          .width(40)
          .onClick(() => {
            this.showConflictClass = true;
          })
          .bindSheet($$this.showConflictClass, this.ConflictClass(), {
            detents: [SheetSize.LARGE, SheetSize.MEDIUM],
            preferType: SheetType.POPUP,
            backgroundColor: '#0000',
            blurStyle: BlurStyle.Regular,
            showClose: false,
            enableOutsideInteractive: false,
            enableFloatingDragBar: true,
            mode: SheetMode.OVERLAY
          })
        }
        .height(40)
        .width(40)

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.calendar'))
            .height(22)
            .draggable(false)
        }
        .width(40)
        .height(40)
        .onClick(() => {
          this.showSemesters = true;
        })
        .bindPopup(this.showSemHint, {
          builder: this.semHintPopup(),
          placement: Placement.BottomRight,
          width: 300,
          onStateChange: (status: PopupOnStateChangeInfo) => {
            if (!status.isVisible) {
              this.showSemHint = false;
            }
          }
        })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.get'))
            .height(22)
            .draggable(false)
        }
        .width(40)
        .height(40)
        .bindMenu(this.editMenu());
      }
      .padding({ left: 12, right: 12, top: 3 })
      .width('100%')

      /**
       * 周数信息与翻页
       */
      Row() { // 高度30
        Text(new Date(this.weekStart).toLocaleString('zh-cn', { year: 'numeric', month: '2-digit', day: '2-digit' }) + ' ~ ' + new Date(this.weekStart + 518400000).toLocaleString('zh-cn', { year: 'numeric', month: '2-digit', day: '2-digit' }))
          .id('week_of_term_span')
          .fontWeight(FontWeight.Bold)
          .fontSize(14)
          .bindPopup(this.showCalendarHint, {
            builder: this.calendarHintPopup(),
            placement: Placement.BottomLeft,
            width: 300,
            onStateChange: (status: PopupOnStateChangeInfo) => {
              if (!status.isVisible) {
                this.showCalendarHint = false;
              }
            }
          })
          .onClick(() => {
            let totalWeekNum = this.semesters[this.displayTerm].totalWeekNum;
            if (totalWeekNum === 0)
              totalWeekNum = 20;
            CalendarPickerDialog.show({
              selected: new Date(this.weekStart),
              start: new Date(this.semesters[this.displayTerm].beginTime),
              end: new Date(this.semesters[this.displayTerm].beginTime + totalWeekNum * millisecondsPerWeek - 86400000),
              onAccept: (value: Date) => {
                value.setDate(value.getDate() - value.getDay());
                value.setHours(0, 0, 0, 0);
                this.weekStart = value.getTime();
                this.weekDisplayed = (this.weekStart - this.semesters[this.displayTerm].beginTime) / millisecondsPerWeek + 1;
                this.refreshGrid();
              }
            })
          })

        Blank()

        Image($r('app.media.arrow_left_circle'))
          .height(18)
          .padding({ left: 20, right: 20 })
          .draggable(false)
          .opacity(this.weekDisplayed > 1 ? 1 : 0.4)
          .onClick(() => {
            if (this.weekDisplayed > 1) {
              this.weekDisplayed--;
              this.weekStart -= millisecondsPerWeek;
              this.refreshGrid();
            }
          })

        Text($r('app.string.week_of_term_no_d', this.weekDisplayed))
          .id('week_of_term_no')
          .fontWeight(FontWeight.Bold)
          .fontSize(14)
          .onClick(() => {
            this.getUIContext().showTextPickerDialog({
              range: (tools.getContArray([[1, 20]], true) as string[]).map(count => `第 ${count} 周`),
              selected: this.weekDisplayed - 1,
              canLoop: false,
              onAccept: (value: TextPickerResult) => {
                const toJump: number = (typeof value.index === "number" ? value.index : value.index[0]) + 1;
                this.weekStart = this.weekStart + millisecondsPerWeek * (toJump - this.weekDisplayed);
                this.weekDisplayed = toJump;
                this.refreshGrid();
              }
            });
          })

        Image($r('app.media.arrow_right_circle'))
          .height(18)
          .padding({ left: 20, right: 20 })
          .objectFit(ImageFit.Contain)
          .draggable(false)
          .opacity(this.weekDisplayed < 20 ? 1 : 0.4)
          .onClick(() => {
            if (this.weekDisplayed < 20) {
              this.weekDisplayed++;
              this.weekStart += millisecondsPerWeek;
              this.refreshGrid();
            }
          })
      }
      .width('100%')
      .height(30)
      .padding({ left: 15, right: 5 })
      .border({
        width: { bottom: 0.6 },
        color: $r('app.color.grid_border')
      })

      // 星期几
      Row() { // 高度25
        Text(this.weekDisplayed === this.currentWeek ? $r('app.string.class_span') : $r('app.string.xiu'))
          .fontWeight(FontWeight.Bold)
          .fontSize(12)
          .height('100%')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .border({
            width: { right: 0.6 },
            color: $r('app.color.grid_border')
          })
          .bindPopup(this.showXiuHint, {
            builder: this.xiuHintPopup(),
            placement: Placement.Right,
            width: 300,
            onStateChange: (status: PopupOnStateChangeInfo) => {
              if (!status.isVisible) {
                this.showXiuHint = false;
              }
            }
          })
          .onClick(() => {
            if (this.weekDisplayed !== this.currentWeek) {
              this.weekDisplayed = this.currentWeek;
              this.weekStart = this.currentWeekStart;
              this.refreshGrid();
            }
          })
        Text(tools.weekTranslate[0])
          .fontWeight(FontWeight.Bold)
          .fontSize(12)
          .textAlign(TextAlign.Center)
          .height('100%')
          .layoutWeight(1)
        ForEach(tools.getContArray([[1, 6]]), (item: number) => {
          Text(tools.weekTranslate[item])
            .fontWeight(FontWeight.Bold)
            .fontSize(12)
            .textAlign(TextAlign.Center)
            .height('100%')
            .layoutWeight(1)
            .border({
              width: { left: 0.6 },
              color: $r('app.color.grid_border')
            })
        })
      }
      .width('100%')
      .height(25)
      .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
      .border({
        width: { bottom: 0.6 },
        color: $r('app.color.grid_border')
      })
    }
    .height(95)
    .width('100%')
  }


  @Builder ClassDetailDialog() {
    Column() {
      Row({ space: 6 }) {
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
            this.msgDialogController = new CustomDialogController({
              builder: MessageDialog({
                message: $r('app.string.delete_class_or_not'),
                onConfirm: () => {
                  ScheduleManager.deleteClassFromSemester(this.displayTerm, this.oriClassInfo);
                  this.refreshGrid();
                  this.showSheet = false;
                }
              }),
              autoCancel: true,
              gridCount: 4
            });
            this.msgDialogController.open();
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
            ScheduleManager.addClassToSemester(this.displayTerm, this.classInfo, this.changeAllColor);
            this.refreshGrid();
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
            this.msgDialogController = new CustomDialogController({
              builder: MessageDialog({
                mainTitle: $r('app.string.unsaved_change'),
                message: $r('app.string.back_to_schedule_or_not'),
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
              ScheduleManager.deleteClassFromSemester(this.displayTerm, this.oriClassInfo);
              ScheduleManager.addClassToSemester(this.displayTerm, this.classInfo, this.changeAllColor);
              this.refreshGrid();
            }
          } else {
            ScheduleManager.addClassToSemester(this.displayTerm, this.classInfo, this.changeAllColor);
            this.refreshGrid();
          }
          this.showSheet = false;
        });
      }
      .margin({ bottom: 7 })
      .bindPopup(this.showScrollHint, {
        builder: this.scrollHintPopup(),
        placement: Placement.Bottom,
        width: 300,
        onStateChange: (status: PopupOnStateChangeInfo) => {
          if (!status.isVisible) {
            this.showScrollHint = false;
          }
        }
      });

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

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
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
            .margin({ bottom: 5, right: 10 })

            Row() {
              Text($r('app.string.class_detail_day_of_week'))
                .textAlign(TextAlign.Start);
              Select([{ value: $r('app.string.sunday') }, { value: $r('app.string.monday') }, { value: $r('app.string.tuesday') },
                { value: $r('app.string.wednesday') }, { value: $r('app.string.thursday') }, { value: $r('app.string.friday') }, { value: $r('app.string.saturday') }])
                .value(tools.weekTranslate[this.classInfo.dayOfWeek])
                .onSelect((index: number) => {
                  this.classInfo.dayOfWeek = index;
                });
            }
            .margin({ bottom: 5 })
          }

          Row() {
            Text('学分：')
              .textAlign(TextAlign.Start);
            TextInput({ text: this.classInfo.credits })
              .layoutWeight(1)
              .type(InputType.NUMBER_DECIMAL)
              .textOverflow(TextOverflow.Ellipsis)
              .onChange((input: string) => this.classInfo.credits = input)
              .selectAll(true);
          }
          .margin({ bottom: 5 })

          Row() {
            Text($r('app.string.class_detail_color'))
              .textAlign(TextAlign.Start);
            Stack({ alignContent: Alignment.End }) {
              TextInput({ text: this.classColor })
                .textOverflow(TextOverflow.Ellipsis)
                .onChange((input: string) => {
                  // console.log('test'); 此处证明了this.classColor = input;不会导致死循环
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
                .fill(this.isColorLegal ? this.classColor : '#0000')
                .width(32)
                .height(32)
                .offset({ x: -4 })
                .stroke(this.isColorLegal ? $r('app.color.grid_border') : $r('app.color.red'))
                .bindPopup(this.showColorHint, {
                  builder: this.colorHintPopup(),
                  placement: Placement.Left,
                  width: 300,
                  onStateChange: (status: PopupOnStateChangeInfo) => {
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
                onStateChange: (popup: PopupOnStateChangeInfo) => {
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
          // .margin({ bottom: 5 })

          Row() {
            Text($r('app.string.class_detail_weeks', tools.shrinkContArrayToString(this.weekOfTerm)))
              .textAlign(TextAlign.Start)
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            CheckboxGroup({ group: `checkboxGroup${this.checkBoxGroup}` })
              .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
              .selectedColor(presetColor[BackgroundImage.themeColor][2])
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
                  .selectedColor(presetColor[BackgroundImage.themeColor][2])
                  .onChange((value: boolean) => {
                    this.rectifyWeekOfTerm[checkboxId] = value;
                  });
                Text((checkboxId).toString()).width(20);
              }
            });
          }

          Row() {
            Text($r('app.string.class_detail_priority'))
            Slider({ min: 0, max: 10, value: this.oriClassInfo.priority, step: 1, style: SliderStyle.InSet })
              .showSteps(true)
              .selectedColor(presetColor[BackgroundImage.themeColor][2])
              .layoutWeight(1)
              .onChange((value: number) => {
                this.classInfo.priority = value;
              })
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
    .padding({ top: 16, left: 16, right: 16})
    .width('100%')
    .height('100%')
  }
}
