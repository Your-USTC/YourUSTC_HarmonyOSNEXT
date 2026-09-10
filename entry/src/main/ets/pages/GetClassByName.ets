import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import BackgroundImage, { presetColor } from '../utils/BgImageManager';
import { courseFromJW, debounceSearchCourses, searchCourses, searchOption } from '../utils/Classes/RawDataModifier';
import ScheduleManager from '../utils/Classes/ScheduleManager';
import { classAttribute } from '../constants/ScheduleSources';
import { colorSet, colorSetLen, getRandomInt } from '../utils/tools';
import MessageDialog from '../view/MessageDialog';
import { ExceptionPrompt, MarginType } from '@kit.ArkUI';

@Builder
export function GCBNBuilder(name: string, param?: object) {
  GetClassByName();
}

enum SearchStatus {
  LOADING,
  WAITING_FOR_INPUT,
  GET_DATA_FAILED,
  QUERYING,
  QUERY_SUCCESS,
  NO_RESULT,
  DATA_FORMAT_ERR
}

interface SemesterListData {
  id: number;
  nameZh: string;
  code: string;
  start: string; // "YYYY-MM-DD"
  end: string;
  isLast: boolean;
}

/**
 * 缓存到本地文件的课程数据结构（位于应用 cacheDir 下）
 */
interface CachedCourseData {
  semesterId: number;
  semesterStart: string; // "YYYY-MM-DD"
  semesterEnd: string;   // "YYYY-MM-DD"
  fetchedAt: number;     // 缓存写入时间戳（毫秒）
  courses: courseFromJW[];
}

/**
 * 解析周范围字符串（支持 "1~15周"、"1~4,5,7~14周" 等）
 */
function parseWeeks(weekRange: string): number[] {
  const cleaned = weekRange.replace(/周$/, '').replace(/\s/g, '');
  if (!cleaned) return [];

  const parts = cleaned.split(',');
  const weeks: number[] = [];

  for (const part of parts) {
    if (part.includes('~')) {
      const partSplit = part.split('~');
      const startStr = partSplit[0];
      const endStr = partSplit[1];
      const start = parseInt(startStr, 10);
      const end = parseInt(endStr, 10);
      if (isNaN(start) || isNaN(end) || start > end) {
        throw new Error(`无效的周范围: ${part}`);
      }
      for (let i = start; i <= end; i++) {
        weeks.push(i);
      }
    } else {
      const num = parseInt(part, 10);
      if (isNaN(num)) throw new Error(`无效的周数: ${part}`);
      weeks.push(num);
    }
  }

  // 去重并保留首次出现顺序
  return Array.from(new Set(weeks));
}

@Entry
@Component
struct GetClassByName {

  @State requestStatus: SearchStatus = SearchStatus.LOADING;
  obtainedData: courseFromJW[] = [];
  @State shownData: courseFromJW[] = [];
  advancedFilter: searchOption = {};
  @State resultCount: number = 0;
  toGetSemesterId: number = 421;
  cachedCourseDataPath: string = '';
  currentSemesterStart: string = '';
  currentSemesterEnd: string = '';

  @State showExceptionPrompt: boolean = false;
  @State exceptionPromptText: string = '(点此隐藏)学期未结束，此处是上次缓存的课程数据。右上角󰀠可强制刷新';
  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      Column() {
        ExceptionPrompt({
          options: {
            icon: $r('app.media.info_circle'),
            tip: this.exceptionPromptText,
            marginType: MarginType.DEFAULT_MARGIN,
            marginTop: 7,
            isShown: this.showExceptionPrompt
          },
          onTipClick: () => this.showExceptionPrompt = false
        })

        if (this.requestStatus === SearchStatus.GET_DATA_FAILED) {
          Image($r('app.media.sorry'))
            .width(100)
            .margin({ top: 16 })
          Text() {
            Span('由于接口限制，非校园网环境无法获取课程列表，请连接校园网后')
            Span('重试')
              .fontColor($r('app.color.active_text'))
              .decoration({
                type: TextDecorationType.Underline,
                color: $r('app.color.active_text')
              })
              .onClick(() => {
                this.getData();
              })
            Span('。你无需申请校外访问权限。')
          }
          .textAlign(TextAlign.Center)
          .margin({ top: 6, left: 16, right: 16 })
        } else if (this.requestStatus === SearchStatus.LOADING) {
          Row() {
            // LoadingProgress()
            //   .height(30)
            Image($r('app.media.sr_loading_4x'))
              .height(80)
            Text($r('app.string.loading'))
          }
          .margin({ top: 16 })
        } else if (this.requestStatus === SearchStatus.WAITING_FOR_INPUT) {
          Image($r('app.media.sorry'))
            .width(100)
            .margin({ top: 16 })
          Text('获取成功！在上方的文本框键入，再等待一秒以搜索 qwq\nദ്ദി˶˃ ᵕ ˂ )✧')
            .textAlign(TextAlign.Center)
            .margin({ top: 6, left: 16, right: 16 })
        } else if (this.requestStatus === SearchStatus.NO_RESULT) {
          Image($r('app.media.sorry'))
            .width(100)
            .margin({ top: 16 })
          Text('emm…没有符合条件的搜索结果')
            .textAlign(TextAlign.Center)
            .margin({ top: 6, left: 16, right: 16 })
        } else if (this.requestStatus === SearchStatus.QUERY_SUCCESS) {
          List({ space: 6 }) {
            Repeat<courseFromJW>(this.shownData)
              .each((item: RepeatItem<courseFromJW>) => {
                ListItem() {
                  Row({ space: 10 }) {
                    Column() {
                      Text((item.index + 1).toString())
                        .fontSize(30)
                        .fontWeight(FontWeight.Bolder)
                        .textAlign(TextAlign.Center)
                      Text(`${item.item.credits} 学分`)
                        .fontSize(12)
                    }
                    .width(56)

                    Column() {
                      Text(item.item.course.cn || '无数据')
                        .fontWeight(FontWeight.Bold)
                        .fontSize(20)
                      Text() {
                        Span('教师  ')
                          .fontWeight(FontWeight.Bold)
                          .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
                        Span(item.item.teacherAssignmentList?.map(item => item.cn).join('，') || '无数据')
                      }
                      .wordBreak(WordBreak.BREAK_ALL)

                      Text() {
                        Span('时间  ')
                          .fontWeight(FontWeight.Bold)
                          .fontColor(presetColor[BackgroundImage.themeColor].accentColor)
                        Span(item.item.dateTimePlacePersonText.cn || '无数据')
                      }
                      .wordBreak(WordBreak.BREAK_ALL)
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .padding({ top: 10, bottom: 10, left: 10, right: 10 })
                  .borderRadius(20)
                  .backgroundColor($r('app.color.grid_background'))
                  .onClick(() => {
                    try {
                      const lines: string[] = item.item.dateTimePlacePersonText.cn.split('\n')
                        .filter(line => line.trim() !== '');
                      const color: string = colorSet[getRandomInt(0, colorSetLen - 1)];
                      const regex = /^([\d,~]+周)\s+(\S+)\s*:\s*(\d+)\(([\d,]+)\)\s+(.+)$/;
                      for (let idx = 0; idx < lines.length; idx++) {
                        const line = lines[idx];
                        const match = line.match(regex);
                        if (!match) {
                          console.warn(`跳过无法解析的行: ${line}`);
                          continue;
                        }

                        const weekRange = match[1];
                        const location = match[2];
                        const dayStr = match[3];
                        const sectionsStr = match[4];
                        const teacher = match[5];

                        // 1. 解析周次（支持混合格式）
                        const weeks = parseWeeks(weekRange);

                        // 2. 星期（7 → 0）
                        let day = parseInt(dayStr, 10);
                        if (day === 7) day = 0;

                        // 3. 节次
                        const sections = sectionsStr.split(',').map(s => parseInt(s, 10));

                        // 4. 构建 classAttribute 对象
                        const newClass: classAttribute = {
                          name: item.item.course.cn || '无数据',
                          teacher: teacher || '无数据',
                          weekOfTerm: weeks,
                          timeSpan: sections,
                          dayOfWeek: day,
                          location: location.trim(),
                          id: item.item.code,
                          color: color,
                          priority: 5,
                          credits: item.item.credits.toString(),
                        };
                        ScheduleManager.addClassToSemester(ScheduleManager.displaySemester, newClass);
                      }
                      this.exceptionPromptText = '(点此隐藏)添加成功';
                      this.showExceptionPrompt = true;
                    } catch (e) {
                      this.exceptionPromptText = '(点此隐藏)由于格式问题或教务系统数据缺失，暂不支持添加此课程，请手动添加'
                      this.showExceptionPrompt = true;
                    }
                  })
                }
                .margin({ top: 4 })
              })

            if (this.resultCount > 200)
              ListItem() {
                Text(`检索到 200+ 个课堂，出于性能考虑，此处只显示 200 个，请考虑使用更精确的关键词`)
              }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 12, right: 12 })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .contentStartOffset(8)
          .contentEndOffset(12)
        }
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .width('100%')
    }
    .title(this.customTitle(), {
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : '#0000'
    })
    .backButtonIcon($r('app.media.close'))
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      if (this.obtainedData.length === 0)
        this.getData();
    })
  }

  @Builder settingMenu() {
    Menu() {
      MenuItem({ startIcon: $r('sys.media.ohos_ic_public_text'), content: '区分大小写',
        endIcon: this.advancedFilter.caseSensitive ? $r('app.media.checkmark') : undefined })
        .onClick(() => {
          this.advancedFilter.caseSensitive = !this.advancedFilter.caseSensitive;
          this.shownData = searchCourses(this.obtainedData, this.advancedFilter);
        })
      MenuItem({ startIcon: $r('app.media.cloud_sync'), content: '重新获取' })
        .onClick(() => {
          this.showExceptionPrompt = false;
          this.getData(true);
        })
    }
  }

  /**
   * 获取缓存文件路径（应用 cacheDir 下）
   */
  getCacheFilePath(): string {
    if (!this.cachedCourseDataPath) {
      const cacheDir = this.getUIContext().getHostContext()?.getApplicationContext()?.cacheDir;
      if (cacheDir)
        this.cachedCourseDataPath = `${cacheDir}/courseListCache.json`;
    }
    return this.cachedCourseDataPath;
  }

  /**
   * 读取本地课程数据缓存，失败或不存在时返回 null
   */
  loadCourseCache(): CachedCourseData | null {
    const path = this.getCacheFilePath();
    if (!path) return null;
    try {
      if (fileIo.accessSync(path)) {
        return JSON.parse(fileIo.readTextSync(path)) as CachedCourseData;
      }
    } catch (e) {
      console.error('GetClassByName: failed to load course cache:', JSON.stringify(e));
    }
    return null;
  }

  /**
   * 将获取到的课程数据连同学期信息写入本地缓存（学期结束日期未知时不缓存）
   */
  saveCourseCache(courses: courseFromJW[]): void {
    const path = this.getCacheFilePath();
    if (!path || !this.currentSemesterEnd) return;
    try {
      const cacheData: CachedCourseData = {
        semesterId: this.toGetSemesterId,
        semesterStart: this.currentSemesterStart,
        semesterEnd: this.currentSemesterEnd,
        fetchedAt: Date.now(),
        courses: courses
      };
      const file = fileIo.openSync(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, JSON.stringify(cacheData));
      fileIo.closeSync(file);
    } catch (e) {
      console.error('GetClassByName: failed to save course cache:', JSON.stringify(e));
    }
  }

  /**
   * 尝试使用本地缓存：缓存存在且所属学期尚未结束时优先使用（并提示），否则返回 false 走网络请求
   */
  tryUseCache(): boolean {
    const cache = this.loadCourseCache();
    if (!cache || !cache.courses || cache.courses.length === 0)
      return false;
    // 格式化为 "YYYY-MM-DD"，用于字符串比较（字典序与日期顺序一致）
    const todayStr = new Date().toISOString().slice(0, 10);
    if (!cache.semesterEnd || todayStr > cache.semesterEnd)
      return false;
    this.toGetSemesterId = cache.semesterId;
    this.obtainedData = cache.courses;
    this.requestStatus = SearchStatus.WAITING_FOR_INPUT;
    this.showExceptionPrompt = true;
    return true;
  }

  getData(forceRefresh: boolean = false) {
    this.requestStatus = SearchStatus.LOADING;
    this.currentSemesterStart = '';
    this.currentSemesterEnd = '';

    // 非强制刷新时，若缓存学期未结束则优先使用缓存（菜单“重新获取”传 true 强制联网）
    if (!forceRefresh && this.tryUseCache())
      return;

    // 获取正在进行或将来（如果放假）的一个学期
    const termListURL = "https://catalog.ustc.edu.cn/api/teach/semester/list";
    const session = rcp.createSession();
    session.get(termListURL).then((response) => {
      if (response.statusCode === 200) {
        const today = new Date();
        // 格式化为 "YYYY-MM-DD"，用于字符串比较（字典序与日期顺序一致）
        const todayStr = today.toISOString().slice(0, 10);

        let nextId: number | null = null;
        let nextStart: string | null = null;
        let nextEnd: string | null = null;
        const obtainedData: SemesterListData[] = response.toJSON() as SemesterListData[];

        for (const sem of obtainedData) {
          // 情形1：当前日期落在学期区间内（包含边界）
          if (todayStr >= sem.start && todayStr <= sem.end) {
            this.toGetSemesterId = sem.id;
            this.currentSemesterStart = sem.start;
            this.currentSemesterEnd = sem.end;
            break;
          }

          // 情形2：学期在未来，保留开始日期最早的
          if (todayStr < sem.start) {
            if (nextStart === null || sem.start < nextStart) {
              nextStart = sem.start;
              nextEnd = sem.end;
              nextId = sem.id;
            }
          }
        }
        if (nextId) {
          this.toGetSemesterId = nextId;
          this.currentSemesterStart = nextStart!;
          this.currentSemesterEnd = nextEnd!;
        }
      } else {
        this.requestStatus = SearchStatus.GET_DATA_FAILED;
      }

      // 获取 this.toGetSemesterId 的所有课
      const getURL = `https://catalog.ustc.edu.cn/api/teach/lesson/list-for-teach/${this.toGetSemesterId}`;
      session.get(getURL).then((response) => {
        console.info(`Get semester ${this.toGetSemesterId} succeed, Response code: ${response.statusCode}`);
        if (response.statusCode === 200) {
          this.requestStatus = SearchStatus.WAITING_FOR_INPUT;
          this.obtainedData = response.toJSON() as courseFromJW[];
          this.saveCourseCache(this.obtainedData);
        } else {
          this.requestStatus = SearchStatus.GET_DATA_FAILED;
        }
      }).catch((err: BusinessError) => {
        console.error(`Response error code is ${err.code}, error data is ${err.data}`);
        this.requestStatus = SearchStatus.GET_DATA_FAILED;
      });
    }).catch((err: BusinessError) => {
      console.error(`Response error code is ${err.code}, error data is ${err.data}`);
      this.requestStatus = SearchStatus.GET_DATA_FAILED;
    });
  }

  @Builder customTitle() {
    Row({ space: 5 }) {
      Search({ value: this.advancedFilter.className, placeholder: '按课程名搜索' })
        .enabled(this.requestStatus !== SearchStatus.LOADING)
        .layoutWeight(1)
        // .onSubmit((value: string) => {
        //   this.className = value;
        //   this.searchName(value);
        // })
        .onChange((value: string) => {
          this.advancedFilter.className = value;
          if (value.length === 0)
            debounceSearchCourses([], {}, (empty) => {
              this.resultCount = 0;
              this.shownData = [];
              this.requestStatus = SearchStatus.WAITING_FOR_INPUT;
            })
          else if (this.requestStatus !== SearchStatus.GET_DATA_FAILED) {
            debounceSearchCourses(
              this.obtainedData,
              this.advancedFilter,
              (filteredCourses) => {
                this.shownData = filteredCourses;
                if (filteredCourses.length > 200)
                  this.resultCount = 201;
                else
                  this.resultCount = filteredCourses.length;

                if (this.shownData.length === 0)
                  this.requestStatus = SearchStatus.NO_RESULT;
                else
                  this.requestStatus = SearchStatus.QUERY_SUCCESS;
              }
            );
          }
        })
      Badge({ count: this.resultCount, maxCount: 200,
        style: { badgeColor: /*'#FA2A2D'*/$r('sys.color.ohos_id_color_badge_red') } }) {
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.filter'))
            .height(22)
            .width(22)
        }
        .height(40)
        .width(40)
        .onClick(() => this.underConstruction())
      }

      Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
        Image($r('app.media.setting'))
          .height(22)
          .width(22)
      }
      .height(40)
      .width(40)
      .bindMenu(this.settingMenu())
    }
    .padding({ left: 5, right: 7 })
  }


  @State showFilterDialog: boolean = false;
  targetTeacherName: string = '';
  @Builder filterDialog() {
    Column() {
      Row({ space: 5 }) {
        Text('更多筛选条件')
          .fontWeight(FontWeight.Bold)
          .fontSize(24)
          .layoutWeight(1)
          .margin({ left: 8 })

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.close'))
            .width(24)
            .height(24)
        }
        .height(42)
        .width(42)
        .onClick(() => this.showFilterDialog = false)

        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
          Image($r('app.media.search'))
            .width(24)
            .height(24)
        }
        .height(42)
        .width(42)
        .onClick(() => {
          this.shownData = searchCourses(this.obtainedData, this.advancedFilter);
          this.showFilterDialog = false;
        })
      }
      Scroll() {
        Column() {
          Row() {
            Text('教师')
            TextInput()
          }
        }
        .padding(16)
      }
    }
  }

  underConstruction() {

    if (this.requestStatus === SearchStatus.GET_DATA_FAILED)
      this.getUIContext().getPromptAction().showToast({ message: '需要先获取课程数据 qwq' })
    else
      this.getUIContext().getPromptAction().showToast({ message: '从该页面添加课程的功能正在开发中 qwq' })
  }
}