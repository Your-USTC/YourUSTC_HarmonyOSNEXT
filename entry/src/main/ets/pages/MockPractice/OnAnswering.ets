import BackgroundImage from '../../utils/BgImageManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import {
  sessionNavParam,
  sessionSummary,
  singleQuestion,
  questionStatus,
  AnswerStatus
} from '../../utils/MockPractice/constants';


@Builder
export function MPMBuilder(name: string, param?: Object) {
  MockPracticeMain({ navParam: param as sessionNavParam })
}

const answerColor: (Resource | string)[] = [$r('app.color.green'), $r('app.color.red'), '#f59e0b', $r('app.color.grid_background')];
const COLOR_GREEN = 0;
const COLOR_RED = 1;
const COLOR_YELLOW = 2;
const COLOR_NONE = 3;

/** 答题卡格子数据源：配合 LazyForEach 懒创建格子，避免题多时打开弹层一次性建满全部格子而掉帧 */
class SheetStatusSource implements IDataSource {
  private list: questionStatus[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.list.length;
  }

  getData(index: number): questionStatus {
    return this.list[index];
  }

  /** 整表替换数据并通知重建；答题卡每次打开前调用（弹层关闭期间无监听者，无需通知） */
  refresh(list: questionStatus[]): void {
    this.list = list;
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }
}

/** 答对后停留展示反馈的时长，之后切换到下一题 */
const FLASH_MS: number = 500;

@Entry
@Component
struct MockPracticeMain {
  navParam: sessionNavParam = { bankId: '', bankName: '', sessionId: '' };
  @State q: singleQuestion | null = null;
  @State current: number = 0;
  @State total: number = 0;
  /** 本次练习已完成，展示总结视图 */
  @State finished: boolean = false;
  /** 导航参数失效（记录或题库不存在） */
  @State broken: boolean = false;
  @State summary: sessionSummary | null = null;
  @State singleChoice: number = -1;
  @State multiChoice: boolean[] = [];
  @State textAnswer: string = '';
  @State optionColor: number[] = [];
  /** 答题区横向位移：切题时旧题滑出、新题从另一侧滑入 */
  @State slideX: number = 0;
  /** 答题卡半模态是否展开 */
  @State sheetOpen: boolean = false;
  /** 各题作答状态数据源（以第一次作答为准），答题卡展示用 */
  private sheetSource: SheetStatusSource = new SheetStatusSource();
  /** 答题区宽度，用作滑动距离与切题阈值 */
  private contentWidth: number = 0;
  /** 滑动切换进行中，期间忽略新的切题与拖动 */
  private swapping: boolean = false;
  /** 答对后进入下一题的延时定时器 */
  private flashTimer: number = -1;
  /** 滑出→换内容→滑入的切换定时器 */
  private swapTimer: number = -1;
  /** 新题滑入前的短暂延时定时器 */
  private enterTimer: number = -1;
  /** 答对后的推进等待期，避免停留期间重复提交 */
  private submitting: boolean = false;
  pathStack: NavPathStack = new NavPathStack();

  /** 拉取当前题并重置与单题相关的作答状态；进度（current/total）一并向 store 对齐 */
  loadQuestion(): void {
    const progress = answerStore.getProgress(this.navParam.bankId, this.navParam.sessionId);
    this.total = progress.total;
    this.current = progress.position;
    const question = answerStore.getCurrentQuestion(this.navParam.bankId, this.navParam.sessionId);
    if (question === null) {
      this.showFinish();
      return;
    }
    const optionCount = question.type === 'blank' ? 0 : question.optionCount;
    this.q = question;
    this.singleChoice = -1;
    this.multiChoice = [];
    for (let i = 0; i < optionCount; i++) {
      this.multiChoice.push(false);
    }
    this.optionColor = [];
    for (let i = 0; i < optionCount; i++) {
      this.optionColor.push(COLOR_NONE);
    }
    this.textAnswer = '';
    clearTimeout(this.flashTimer);
    this.submitting = false;
  }

  showFinish(): void {
    this.q = null;
    const progress = answerStore.getProgress(this.navParam.bankId, this.navParam.sessionId);
    this.summary = progress;
    this.finished = progress.total > 0;
    this.broken = progress.total === 0;
  }

  clearFeedback(): void {
    if (this.q !== null) {
      const optionCount = this.q.type === 'blank' ? 0 : this.q.optionCount;
      this.optionColor = [];
      for (let i = 0; i < optionCount; i++) {
        this.optionColor.push(COLOR_NONE);
      }
    }
  }

  /** 按判定结果给选项着色：绿=选对，红=选错，黄=漏选的正确项 */
  applyFeedback(isCorrect: boolean): void {
    const q = this.q;
    if (q === null) {
      return;
    }
    if (q.type === 'single') {
      for (let i = 0; i < q.optionCount; i++) {
        if (isCorrect && i === this.singleChoice) {
          this.optionColor[i] = COLOR_GREEN;
        } else if (!isCorrect && i === this.singleChoice) {
          this.optionColor[i] = COLOR_RED;
        } else if (!isCorrect && String.fromCharCode(65 + i) === q.answer.trim().toUpperCase()) {
          this.optionColor[i] = COLOR_YELLOW;
        } else {
          this.optionColor[i] = COLOR_NONE;
        }
      }
    } else if (q.type === 'multiple') {
      for (let i = 0; i < q.optionCount; i++) {
        const alphabet = String.fromCharCode(65 + i);
        const picked = this.multiChoice[i] === true;
        const inAnswer = q.answer.trim().toUpperCase().includes(alphabet);
        if (picked && inAnswer) {
          this.optionColor[i] = COLOR_GREEN;
        } else if (picked && !inAnswer) {
          this.optionColor[i] = COLOR_RED;
        } else if (!picked && inAnswer) {
          this.optionColor[i] = COLOR_YELLOW;
        } else {
          this.optionColor[i] = COLOR_NONE;
        }
      }
    }
  }

  /** 选项背景：无反馈时保持原底色，有反馈时着对错色 */
  optionBg(index: number): Resource | string | undefined {
    const color = this.optionColor[index];
    if (color === undefined || color === COLOR_NONE) {
      return BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined;
    }
    return answerColor[color];
  }

  buildUserAnswer(): string {
    const q = this.q;
    if (q === null) {
      return '';
    }
    if (q.type === 'single') {
      if (this.singleChoice < 0) {
        this.getUIContext().getPromptAction().showToast({ message: '请先选择一个选项', duration: 1500 });
        return '';
      }
      return String.fromCharCode(65 + this.singleChoice);
    }
    if (q.type === 'multiple') {
      const picked: string[] = [];
      for (let i = 0; i < q.optionCount; i++) {
        if (this.multiChoice[i] === true) {
          picked.push(String.fromCharCode(65 + i));
        }
      }
      if (picked.length === 0) {
        this.getUIContext().getPromptAction().showToast({ message: '请至少选择一个选项', duration: 1500 });
        return '';
      }
      return picked.join('');
    }
    const text = this.textAnswer.trim();
    if (text === '') {
      this.getUIContext().getPromptAction().showToast({ message: '请输入答案', duration: 1500 });
      return '';
    }
    return text;
  }

  submit(): void {
    if (this.submitting || this.swapping) {
      return;
    }
    const userAnswer = this.buildUserAnswer();
    if (userAnswer === '') {
      return;
    }
    const isCorrect = answerStore.submitAnswer(this.navParam.bankId, this.navParam.sessionId, userAnswer);
    // 选项着色与反馈文本一同渐入
    this.getUIContext().animateTo({ curve: Curve.EaseOut, duration: 200 }, () => {
      this.applyFeedback(isCorrect);
    });
    if (isCorrect) {
      // 提交时进度已自动前进；没有下一题即完成本次练习
      this.submitting = true;
      this.flashTimer = setTimeout(() => {
        this.slideSwap(1, () => this.loadQuestion());
      }, FLASH_MS);
    }
  }

  /** 按方向滑动切换：旧题滑出后换内容，新题从另一侧滑入；1=下一题，-1=上一题 */
  slideSwap(direction: number, swap: () => void): void {
    if (this.swapping) {
      return;
    }
    this.swapping = true;
    const w = this.contentWidth > 0 ? this.contentWidth : 480;
    this.getUIContext().animateTo({ curve: Curve.EaseIn, duration: 150 }, () => {
      this.slideX = direction === 1 ? -w : w;
    });
    this.swapTimer = setTimeout(() => {
      swap();
      this.slideX = direction === 1 ? w : -w;
      this.enterTimer = setTimeout(() => {
        this.getUIContext().animateTo({
          curve: Curve.EaseOut,
          duration: 220,
          onFinish: () => {
            this.swapping = false;
          }
        }, () => {
          this.slideX = 0;
        });
      }, 30);
    }, 170);
  }

  /** 拖动跟手：可切换方向整距跟随，不可切换方向给阻力 */
  handlePanUpdate(dx: number): void {
    if (this.swapping || this.submitting) {
      return;
    }
    const allowed = dx < 0 ? this.current + 1 < this.total : this.current > 0;
    this.slideX = allowed ? dx : dx * 0.25;
  }

  /** 松手：位移达到阈值且方向可用则切题，否则回弹 */
  handlePanEnd(dx: number): void {
    if (this.swapping || this.submitting || dx === 0) {
      return;
    }
    const dir = dx < 0 ? 1 : -1;
    const allowed = dir === 1 ? this.current + 1 < this.total : this.current > 0;
    const w = this.contentWidth > 0 ? this.contentWidth : 480;
    if (allowed && Math.abs(dx) >= w * 0.25) {
      this.navigateTo(dir);
    } else {
      this.getUIContext().animateTo({ curve: Curve.EaseOut, duration: 200 }, () => {
        this.slideX = 0;
      });
    }
  }

  navigateTo(delta: number): void {
    const target = this.current + delta;
    if (this.swapping || target < 0 || target >= this.total) {
      return;
    }
    clearTimeout(this.flashTimer);
    this.submitting = false;
    this.slideSwap(delta, () => {
      answerStore.jumpTo(this.navParam.bankId, this.navParam.sessionId, target);
      this.loadQuestion();
    });
  }

  openRecord(): void {
    this.pathStack.pushPath({
      name: 'MockPracticeRecord',
      param: {
        bankId: this.navParam.bankId,
        bankName: this.navParam.bankName,
        sessionId: this.navParam.sessionId
      } as sessionNavParam
    });
  }

  /** 打开答题卡：先同步各题状态（答错重试不切题，状态只在此处刷新） */
  openSheet(): void {
    this.sheetSource.refresh(answerStore.getQuestionStatus(this.navParam.bankId, this.navParam.sessionId));
    this.sheetOpen = true;
  }

  /** 跳转到答题卡选中的题目 */
  jumpToPosition(pos: number): void {
    if (pos === this.current || pos < 0 || pos >= this.total) {
      return;
    }
    this.sheetOpen = false;
    clearTimeout(this.flashTimer);
    this.submitting = false;
    this.slideSwap(pos > this.current ? 1 : -1, () => {
      answerStore.jumpTo(this.navParam.bankId, this.navParam.sessionId, pos);
      this.loadQuestion();
    });
  }

  /** 答题卡格子配色下标：绿=答对，红=答错，无底色=未作答 */
  statusColorIndex(status: AnswerStatus): number {
    if (status === 'correct') {
      return COLOR_GREEN;
    }
    if (status === 'wrong') {
      return COLOR_RED;
    }
    return COLOR_NONE;
  }

  aboutToDisappear(): void {
    clearTimeout(this.flashTimer);
    clearTimeout(this.swapTimer);
    clearTimeout(this.enterTimer);
  }

  @Builder
  LegendItem(colorIndex: number, label: string) {
    Row() {
      Text('')
        .width(12)
        .height(12)
        .borderRadius(4)
        .backgroundColor(colorIndex === COLOR_NONE
          ? $r('app.color.grid_background')
          : answerColor[colorIndex])
        .border({ width: 1, color: $r('app.color.grid_border') })
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.transparent_text'))
        .margin({ left: 5 })
    }
    .margin({ left: 8, right: 8 })
  }

  @Builder
  SheetCell(st: questionStatus) {
    Row() {
      Text(`${st.position + 1}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(st.status === 'unanswered' ? $r('app.color.normal_text') : '#FFFFFF')
    }
    .width('100%')
    .height(36)
    .justifyContent(FlexAlign.Center)
    .borderRadius(12)
    .backgroundColor(st.status === 'unanswered'
      ? (BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
      : answerColor[this.statusColorIndex(st.status)])
    .borderWidth(st.position === this.current ? 2 : (st.status === 'unanswered' ? 1 : 0))
    .borderColor(st.position === this.current ? $r('app.color.active_text') : $r('app.color.grid_border'))
    .onClick(() => {
      this.jumpToPosition(st.position);
    })
  }

  @Builder
  AnswerSheetBuilder() {
    Column() {
      Row() {
        this.LegendItem(COLOR_GREEN, '答对')
        this.LegendItem(COLOR_RED, '答错')
        this.LegendItem(COLOR_NONE, '未作答')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 4 })

      Grid() {
        LazyForEach(this.sheetSource, (st: questionStatus) => {
          GridItem() {
            this.SheetCell(st)
          }
        }, (st: questionStatus) => `${st.position}-${st.status}`)
      }
      .columnsTemplate('repeat(auto-fill, 48vp)')
      .columnsGap(8)
      .rowsGap(8)
      .padding({ left: 12, right: 12, top: 12, bottom: 16 })
      .width('100%')
      .layoutWeight(1)
      .cachedCount(8)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
  }

  build() {
    NavDestination() {
      Column() {
        if (this.broken) {
          Column() {
            Text('未找到该做题记录')
              .fontSize(16)
            Button('返回')
              .margin({ top: 16 })
              .onClick(() => {
                this.pathStack.pop();
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.finished) {
          Column() {
            Text('🎉')
              .fontSize(40)
            Text('本次练习已完成')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 12 })
            if (this.summary !== null) {
              Text(`答对 ${this.summary.correct} / 共 ${this.summary.total} 题` +
                (this.summary.answered > 0 ? ` · 正确率 ${Math.round(this.summary.correct * 100 / this.summary.answered)}%` : ''))
                .fontSize(15)
                .margin({ top: 8 })
            }
            Row() {
              Button('查看做题记录')
                .buttonStyle(ButtonStyleMode.EMPHASIZED)
                .onClick(() => {
                  this.openRecord();
                })
              Button('返回')
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick(() => {
                  this.pathStack.pop();
                })
            }
            .margin({ top: 20 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .transition(TransitionEffect.OPACITY.animation({ duration: 250, curve: Curve.EaseOut }))
        } else {
          Column() {
            Scroll() {
              Column() {
                Text() {
                  Span(`${this.current + 1}/${this.total}  `)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                  Span(this.q?.context || '')
                }
                .width('100%')
                .constraintSize({ minHeight: 60 })
                .padding(12)
                .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
                .borderRadius(20)

                Blank().layoutWeight(1)
              }
              .width('100%')
            }
            .width('calc(100% - 24vp)')
            .borderRadius(20)
            .margin({ top: 12, left: 12, right: 12 })
            .layoutWeight(1)

            if (this.q?.type === 'blank') {
              TextInput({ text: this.textAnswer, placeholder: '请输入答案' })
                .margin({ left: 12, right: 12, top: 8 })
                .onChange((value: string) => {
                  this.textAnswer = value;
                  this.clearFeedback();
                })
            } else {
              Column() {
                ForEach(this.q?.options || [], (optionContext: string, index: number) => {
                  Row() {
                    Text(String.fromCharCode(65 + index))
                      .fontWeight(FontWeight.Bold)
                      .margin({ left: 10, right: 10 })
                    Text(optionContext)
                      .layoutWeight(1)
                  }
                  .padding(4)
                  .borderWidth((this.q?.type === 'multiple' && this.multiChoice[index])
                    || (this.q?.type === 'single' && this.singleChoice === index)
                    ? 3 : undefined)
                  .constraintSize({ minHeight: 40 })
                  .width('100%')
                  .justifyContent(FlexAlign.Start)
                  .backgroundColor(this.optionBg(index))
                  .borderRadius(20)
                  .margin({ top: 8, bottom: 6 })
                  .onClick(() => {
                    if (this.q?.type === 'multiple') {
                      this.multiChoice[index] = !this.multiChoice[index];
                    } else {
                      this.singleChoice = index;
                    }
                    this.clearFeedback();
                  })
                }, (optionContext: string, index: number) => `${this.current}-${index}-${optionContext}`)
              }
              .padding({ left: 12, right: 12 })
              .width('100%')
            }
          }
          .width('100%')
          .layoutWeight(1)
          .translate({ x: this.slideX })
          .onSizeChange((_oldValue: SizeOptions, newValue: SizeOptions) => {
            this.contentWidth = newValue.width as number;
          })
          .gesture(PanGesture({ direction: PanDirection.Horizontal, distance: 10 })
            .onActionUpdate((event: GestureEvent) => {
              this.handlePanUpdate(event.offsetX);
            })
            .onActionEnd((event: GestureEvent) => {
              this.handlePanEnd(event.offsetX);
            }))

          Row() {
            Button('答题卡')
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .onClick(() => {
                this.openSheet();
              })
            Button('上一题')
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .enabled(this.current > 0)
              .onClick(() => {
                this.navigateTo(-1);
              })

            Button('提交')
              .buttonStyle(ButtonStyleMode.EMPHASIZED)
              .onClick(() => {
                this.submit();
              })
            Button('下一题')
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .enabled(this.current + 1 < this.total)
              .onClick(() => {
                this.navigateTo(1);
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          .bindSheet(this.sheetOpen, this.AnswerSheetBuilder(), {
            height: '45%',
            showClose: true,
            dragBar: false,
            title: { title: '答题卡' },
            onDisappear: (): void => {
              this.sheetOpen = false;
            }
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title(this.navParam.bankName, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined
    })
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.loadQuestion();
    })
    .onShown(() => {
      // 从记录页返回时恢复到最新进度
      clearTimeout(this.flashTimer);
      clearTimeout(this.swapTimer);
      clearTimeout(this.enterTimer);
      this.submitting = false;
      this.swapping = false;
      this.slideX = 0;
      this.loadQuestion();
    })
  }
}
