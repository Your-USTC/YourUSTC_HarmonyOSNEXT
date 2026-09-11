import BackgroundImage from '../../utils/BgImageManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import {
  sessionNavParam,
  sessionSummary,
  singleQuestion,
  questionStatus,
  AnswerStatus
} from '../../utils/MockPractice/constants';
import { blankCountOf, judgeBlankAnswer, blankAnswerText, BLANK_JOINER } from '../../utils/MockPractice/BlankJudge';
import { ActionBarButton, ActionBarStyle, HdsActionBar } from '@kit.UIDesignKit';
import { LengthUnit } from '@kit.ArkUI';


@Builder
export function MPMBuilder(name: string, param?: Object) {
  MockPracticeMain({ navParam: param as sessionNavParam })
}

const answerColor: (Resource | string)[] = [$r('app.color.green'), $r('app.color.red'), '#f59e0b', $r('app.color.grid_background')];
const COLOR_GREEN = 0;
const COLOR_RED = 1;
const COLOR_YELLOW = 2;
const COLOR_NONE = 3;
/** 收藏与答错反馈共用的强调色 */
const STAR_COLOR: string = '#f59e0b';

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
  /** 填空题各空的输入与反馈着色（下标即空序），blankCount 为空数（非填空题为 0） */
  @State blankAnswers: string[] = [];
  /** 填空各空的占位提示：回看已作答的题时展示上次提交的答案 */
  @State blankHints: string[] = [];
  @State blankColors: number[] = [];
  @State blankCount: number = 0;
  /** 答错后停留展示正确答案与解析（所有题型统一） */
  @State showReveal: boolean = false;
  /** 背题模式：直接展示正确答案与解析，不可作答提交 */
  @State reciteMode: boolean = false;
  /** 当前题的收藏状态 */
  @State starred: boolean = false;
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
    this.starred = answerStore.currentStarred(this.navParam.bankId, this.navParam.sessionId);
    this.singleChoice = -1;
    this.multiChoice = [];
    for (let i = 0; i < optionCount; i++) {
      this.multiChoice.push(false);
    }
    this.optionColor = [];
    for (let i = 0; i < optionCount; i++) {
      this.optionColor.push(COLOR_NONE);
    }
    this.blankCount = question.type === 'blank' ? blankCountOf(question.context) : 0;
    this.blankAnswers = [];
    this.blankHints = [];
    this.blankColors = [];
    for (let i = 0; i < this.blankCount; i++) {
      this.blankAnswers.push('');
      this.blankHints.push('');
      this.blankColors.push(COLOR_NONE);
    }
    this.showReveal = false;
    // 回看已作答的题：恢复用户上次的提交（选择题高亮选项，填空题占位显示）
    const record = answerStore.currentAnswerRecord(this.navParam.bankId, this.navParam.sessionId);
    if (record !== null) {
      this.restoreAnswer(record.userAnswer);
    }
    if (this.reciteMode) {
      this.markCorrectOptions();
    }
    clearTimeout(this.flashTimer);
    this.submitting = false;
  }

  /** 恢复当前题上次的作答：选择题还原选中态（边框高亮），填空题把答案放入占位符 */
  restoreAnswer(userAnswer: string): void {
    const q = this.q;
    if (q === null) {
      return;
    }
    if (q.type === 'blank') {
      const parts = userAnswer.split(BLANK_JOINER);
      for (let i = 0; i < this.blankCount && i < parts.length; i++) {
        this.blankHints[i] = parts[i];
      }
      return;
    }
    const answer = userAnswer.trim().toUpperCase();
    for (let i = 0; i < q.optionCount; i++) {
      const alphabet = String.fromCharCode(65 + i);
      if (q.type === 'multiple') {
        this.multiChoice[i] = answer.includes(alphabet);
      } else if (answer === alphabet) {
        this.singleChoice = i;
      }
    }
  }

  showFinish(): void {
    this.q = null;
    const progress = answerStore.getProgress(this.navParam.bankId, this.navParam.sessionId);
    this.summary = progress;
    this.finished = progress.total > 0;
    this.broken = progress.total === 0;
  }

  clearFeedback(): void {
    if (this.q === null) {
      return;
    }
    this.showReveal = false;
    if (this.q.type === 'blank') {
      this.blankColors = [];
      for (let i = 0; i < this.blankCount; i++) {
        this.blankColors.push(COLOR_NONE);
      }
      return;
    }
    this.optionColor = [];
    for (let i = 0; i < this.q.optionCount; i++) {
      this.optionColor.push(COLOR_NONE);
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
    } else {
      // 填空题：逐空着色
      const result = judgeBlankAnswer(q, this.blankAnswers);
      for (let i = 0; i < this.blankCount; i++) {
        this.blankColors[i] = result.perBlank[i] ? COLOR_GREEN : COLOR_RED;
      }
    }
    // 答错时停留展示正确答案与解析
    this.showReveal = !isCorrect;
  }

  /** 选项背景：无反馈时保持原底色，有反馈时着对错色 */
  optionBg(index: number): Resource | string | undefined {
    const color = this.optionColor[index];
    if (color === undefined || color === COLOR_NONE) {
      return BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined;
    }
    return answerColor[color];
  }

  /** 选项边框颜色：选中时高亮，其余透明（保持恒定边宽避免选中时跳动） */
  optionBorderColor(index: number): ResourceColor {
    const q = this.q;
    if (q === null) {
      return Color.Transparent;
    }
    const selected = (q.type === 'multiple' && this.multiChoice[index] === true)
      || (q.type === 'single' && this.singleChoice === index);
    return selected ? $r('app.color.active_text') : Color.Transparent;
  }

  /** 选项文字颜色：绿/红反馈底色上改用白色保证对比度 */
  optionFontColor(index: number): ResourceColor {
    const color = this.optionColor[index];
    if (color === COLOR_GREEN || color === COLOR_RED) {
      return '#FFFFFF';
    }
    return $r('app.color.normal_text');
  }

  /** 填空输入框背景：无反馈时用输入框默认底色，有反馈时着对错色 */
  blankBg(index: number): Resource | string | undefined {
    const color = this.blankColors[index];
    if (color === undefined || color === COLOR_NONE) {
      return undefined;
    }
    return answerColor[color];
  }

  /** 填空输入文字颜色：绿/红反馈底色上改用白色保证对比度 */
  blankFontColor(index: number): ResourceColor {
    const color = this.blankColors[index];
    if (color === COLOR_GREEN || color === COLOR_RED) {
      return '#FFFFFF';
    }
    return $r('app.color.normal_text');
  }

  /** 题型标签 */
  typeLabel(): string {
    const q = this.q;
    if (q === null) {
      return '';
    }
    if (q.type === 'multiple') {
      return '多选题';
    }
    if (q.type === 'blank') {
      return '填空题';
    }
    return '单选题';
  }

  sectionText(): string {
    const q = this.q;
    return q !== null && q.section !== undefined ? q.section : '';
  }

  difficultyText(): string {
    const q = this.q;
    return q !== null && q.difficulty !== undefined ? q.difficulty : '';
  }

  knowledgePointText(): string {
    const q = this.q;
    return q !== null && q.knowledgePoint !== undefined ? q.knowledgePoint : '';
  }

  analysisText(): string {
    const q = this.q;
    return q !== null && q.analysis !== undefined ? q.analysis : '';
  }

  /** 头部进度条的完成百分比（与 1/total 计数一致）
  progressPercent(): number {
    if (this.total <= 0) {
      return 0;
    }
    return Math.round(((this.current + 1) / this.total) * 100);
  } */

  /** 正确答案展示文本：填空题把选项字母引用替换为对应选项内容 */
  correctAnswerText(): string {
    const q = this.q;
    if (q === null) {
      return '';
    }
    return q.type === 'blank' ? blankAnswerText(q) : q.answer;
  }

  /** 背题模式：把正确选项标绿，便于直接记忆（填空题答案在揭示卡片中展示） */
  markCorrectOptions(): void {
    const q = this.q;
    if (q === null || q.type === 'blank') {
      return;
    }
    const answer = q.answer.trim().toUpperCase();
    for (let i = 0; i < q.optionCount; i++) {
      const alphabet = String.fromCharCode(65 + i);
      const inAnswer = q.type === 'single' ? answer === alphabet : answer.includes(alphabet);
      this.optionColor[i] = inAnswer ? COLOR_GREEN : COLOR_NONE;
    }
  }

  /** 切换背题模式：开启后直接展示答案并清掉作答反馈，关闭则恢复作答 */
  toggleReciteMode(): void {
    this.reciteMode = !this.reciteMode;
    this.clearFeedback();
    if (this.reciteMode) {
      this.markCorrectOptions();
    }
  }

  toggleStarCurrent(): void {
    if (this.q === null || this.submitting || this.swapping) {
      return;
    }
    this.starred = answerStore.toggleCurrentStar(this.navParam.bankId, this.navParam.sessionId);
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
    // 填空题：各空都填后以「；」拼接提交
    for (let i = 0; i < this.blankCount; i++) {
      if (this.blankAnswers[i].trim() === '') {
        const tip = this.blankCount > 1 ? `请填写第 ${i + 1} 空` : '请输入答案';
        this.getUIContext().getPromptAction().showToast({ message: tip, duration: 1500 });
        return '';
      }
    }
    return this.blankAnswers.join(BLANK_JOINER);
  }

  submit(): void {
    if (this.reciteMode) {
      this.getUIContext().getPromptAction().showToast({ message: '背题模式下无需作答', duration: 1500 });
      return;
    }
    if (this.submitting || this.swapping) {
      return;
    }
    const userAnswer = this.buildUserAnswer();
    if (userAnswer === '') {
      return;
    }
    const isCorrect = answerStore.submitAnswer(this.navParam.bankId, this.navParam.sessionId, userAnswer);
    // 选项着色、答错揭示正确答案与解析：一同渐入
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
    this.pathStack.replacePath({
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

  /** 卡片底色：背景图模式下保持透明（配合毛玻璃），否则用不透明卡片色 */
  cardBg(): Resource | string | undefined {
    return BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined;
  }

  @Builder
  MetaChip(text: string, highlight: boolean) {
    Text(text)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(highlight ? $r('app.color.active_text') : $r('app.color.transparent_text'))
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .constraintSize({ maxWidth: '100%' })
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(10)
      .backgroundColor(highlight
        ? $r('app.color.list_item_count_background')
        : $r('app.color.grid_border'))
      .margin({ right: 6, top: 4 })
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
      // 收藏标记：星标在答题卡上可见
      if (st.starred) {
        Text('★')
          .fontSize(10)
          .fontColor(STAR_COLOR)
          .margin({ left: 2 })
      }
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
      .margin({ top: 3 })
      .height('15vp')

      Grid() {
        LazyForEach(this.sheetSource, (st: questionStatus) => {
          GridItem() {
            this.SheetCell(st)
          }
        }, (st: questionStatus) => `${st.position}-${st.status}-${st.starred ? 's' : ''}`)
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
    .height('calc(100% - 14vp)')
  }

  /** 答错后的揭示卡片：正确答案与解析 */
  @Builder
  RevealCard() {
    Column({ space: 6 }) {
      Text(`正确答案：${this.correctAnswerText()}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(STAR_COLOR)
        .width('100%')
      if (this.analysisText().trim() !== '') {
        Text(`解析：${this.analysisText()}`)
          .fontSize(13)
          .lineHeight(19)
          .fontColor($r('app.color.transparent_text'))
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(this.cardBg())
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .margin({ top: 10 })
    .transition(TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.EaseOut }))
    .translate({ x: this.slideX })
  }

  menuItems: Array<NavigationMenuItem> = [
    {
      value: $r('app.string.refresh'),
      icon: $r('app.media.history'),
      action: () => {
        this.openSheet();
      }
    },
    {
      value: '背题模式',
      icon: $r('app.media.lightbulb'),
      action: () => {
        this.toggleReciteMode();
      }
    }
  ];

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
            Column() {
              Text('🎉')
                .fontSize(40)
              Text('本次练习已完成')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 12 })
              if (this.summary !== null) {
                Text(`答对 ${this.summary.correct} / 共 ${this.summary.total} 题` +
                  (this.summary.answered > 0 ?
                    ` · 正确率 ${Math.round(this.summary.correct * 100 / this.summary.answered)}%` : ''))
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
          .width('100%')
          .height('80%')
          .justifyContent(FlexAlign.Center)
          .transition(TransitionEffect.OPACITY.animation({ duration: 250, curve: Curve.EaseOut }))
        } else {
          Column() {
            Scroll() {
              Column() {
                // 题目卡片：进度与收藏、元信息标签、题干、进度条
                Column() {
                  Row() {
                    Text(`${this.current + 1}/${this.total}`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.normal_text'))
                      .layoutWeight(1)
                    Text(this.starred ? '★' : '☆')
                      .fontSize(22)
                      .fontColor(this.starred ? STAR_COLOR : $r('app.color.transparent_text'))
                      .padding({ left: 8, top: 2, bottom: 2 })
                      .onClick(() => {
                        this.toggleStarCurrent();
                      })
                  }
                  .width('100%')

                  Flex({ wrap: FlexWrap.Wrap }) {
                    this.MetaChip(this.typeLabel(), true)
                    if (this.sectionText().trim() !== '') {
                      this.MetaChip(`章节：${this.sectionText()}`, false)
                    }
                    if (this.difficultyText().trim() !== '') {
                      this.MetaChip(`难度：${this.difficultyText()}`, false)
                    }
                    if (this.knowledgePointText().trim() !== '') {
                      this.MetaChip(`知识点：${this.knowledgePointText()}`, false)
                    }
                  }
                  .width('100%')
                  .margin({ top: 8 })

                  Progress({ value: this.current + 1, total: this.total, type: ProgressType.Linear })
                    .margin({ top: 12 })

                  Text(this.q?.context || '')
                    .fontSize(16)
                    .lineHeight(24)
                    .fontColor($r('app.color.normal_text'))
                    .width('100%')
                    .margin({ top: 10 })
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')
                .padding(14)
                .borderRadius(20)
                .backgroundColor(this.cardBg())
                .backgroundBlurStyle(BackgroundImage.blurLevel)

                Column() {
                  if (this.q?.type === 'blank') {
                    Column({ space: 8 }) {
                      ForEach(this.blankAnswers, (_answer: string, index: number) => {
                        Row() {
                          if (this.blankCount > 1) {
                            Text(`第${index + 1}空`)
                              .fontSize(13)
                              .fontWeight(FontWeight.Medium)
                              .fontColor($r('app.color.transparent_text'))
                          }
                          TextInput({
                            text: this.blankAnswers[index],
                            placeholder: this.blankHints[index] !== undefined && this.blankHints[index] !== ''
                              ? this.blankHints[index]
                              : (this.blankCount > 1 ? `第 ${index + 1} 空的答案` : '请输入答案')
                          })
                            .layoutWeight(1)
                            .fontSize(15)
                            .fontColor(this.blankFontColor(index))
                            .backgroundColor(this.blankBg(index))
                            .margin({ left: this.blankCount > 1 ? 8 : 0 })
                            .onChange((value: string) => {
                              this.blankAnswers[index] = value;
                              this.clearFeedback();
                            })
                            .enabled(!this.reciteMode)
                        }
                        .width('100%')
                        .alignItems(VerticalAlign.Center)
                      }, (_answer: string, index: number) => `${this.current}-${index}-${this.blankCount}`)
                    }
                    .width('100%')
                    .translate({ x: this.slideX })
                  } else {
                    Column({ space: 8 }) {
                      ForEach(this.q?.options || [], (optionContext: string, index: number) => {
                        Row() {
                          Text(String.fromCharCode(65 + index))
                            .width(24)
                            .height(24)
                            .borderRadius(12)
                            .backgroundColor($r('app.color.grid_border'))
                            .fontSize(13)
                            .fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.transparent_text'))
                            .textAlign(TextAlign.Center)
                          Text(optionContext)
                            .fontSize(15)
                            .lineHeight(21)
                            .fontColor(this.optionFontColor(index))
                            .layoutWeight(1)
                            .margin({ left: 10 })
                        }
                        .width('100%')
                        .padding({
                          left: 14,
                          right: 14,
                          top: 9,
                          bottom: 9
                        })
                        .borderRadius(16)
                        .constraintSize({ minHeight: 44 })
                        .backgroundColor(this.optionBg(index))
                        .borderWidth(2)
                        .borderColor(this.optionBorderColor(index))
                        .onClick(() => {
                          if (this.reciteMode) {
                            return;
                          }
                          if (this.q?.type === 'multiple') {
                            this.multiChoice[index] = !this.multiChoice[index];
                          } else {
                            this.singleChoice = index;
                          }
                          this.clearFeedback();
                        })
                      }, (optionContext: string, index: number) => `${this.current}-${index}-${optionContext}`)
                    }
                    .width('100%')
                    .translate({ x: this.slideX })
                  }

                  if (this.showReveal || this.reciteMode) {
                    this.RevealCard()
                  }
                }
                .margin({ top: 10 })
                .borderRadius(16)
                .clip(true)
                .width('100%')
              }
              .width('100%')
            }
            .width('calc(100% - 24vp)')
            .height('100%')
            .borderRadius(16)
            .margin({ left: 12, right: 12, top: 12, bottom: 4 }) // 4是因为下面的HdsActionBar自带8
            .align(Alignment.Top)
            .scrollBar(BarState.Auto)
            .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
            .layoutWeight(1)
          }
          .width('100%')
          .layoutWeight(1)
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

          HdsActionBar({
            startButtons: [new ActionBarButton({ baseIcon: $r('app.media.arrow_left'), onClick: () => this.navigateTo(-1) })],
            primaryButton: new ActionBarButton({ baseIcon: $r('app.media.send'), onClick: () => this.submit() }),
            endButtons: [new ActionBarButton({ baseIcon: $r('app.media.arrow_right'), onClick: () => this.navigateTo(1) })],
            isExpand: true,
            actionBarStyle: new ActionBarStyle({ backgroundBlurStyle: BackgroundImage.blurLevel, margin: { value: 8, unit: LengthUnit.VP} })
          })
          .bindSheet(this.sheetOpen, this.AnswerSheetBuilder(), {
            detents: [SheetSize.MEDIUM, SheetSize.LARGE],
            preferType: SheetType.SIDE,
            showClose: true,
            dragBar: true,
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
    .title({ main: this.navParam.bankName, sub: '妮可之记·机考自测' }, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : undefined
    })
    .menus(this.menuItems)
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
