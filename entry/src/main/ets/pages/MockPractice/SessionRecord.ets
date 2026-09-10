import BackgroundImage from '../../utils/BgImageManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import { bankStore } from '../../utils/MockPractice/QuestionBankManager';
import { blankAnswerText } from '../../utils/MockPractice/BlankJudge';
import {
  sessionNavParam,
  sessionSummary,
  singleQuestion,
  questionStatus,
  SessionOrigin,
  PracticeMode
} from '../../utils/MockPractice/constants';

/** 收藏标记星标色（与答题页保持一致） */
const STAR_COLOR: string = '#f59e0b';


@Builder
export function MPRBuilder(name: string, param?: Object) {
  SessionRecord({ navParam: param as sessionNavParam })
}

/** 记录列表数据源：配合 LazyForEach 按需创建题目卡片，题多时避免一次性建满整页而掉帧 */
class RecordStatusSource implements IDataSource {
  private list: questionStatus[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.list.length;
  }

  getData(index: number): questionStatus {
    return this.list[index];
  }

  /** 整表替换数据并通知重建；筛选切换与页面回显时调用 */
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

@Entry
@Component
struct SessionRecord {
  navParam: sessionNavParam = { bankId: '', bankName: '', sessionId: '' };
  @State summary: sessionSummary | null = null;
  @State statuses: questionStatus[] = [];
  /** 题库中的题目，按题号索引取用 */
  @State questions: singleQuestion[] = [];
  /** 列表筛选：只看错题 */
  @State onlyWrong: boolean = true;
  /** 错题重做是否附加收藏题 */
  @State retryIncludeStarred: boolean = false;
  /** 懒加载列表的数据源，内容随筛选结果整表替换 */
  private source: RecordStatusSource = new RecordStatusSource();
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.questions = bankStore.getQuestions(this.navParam.bankId);
    this.refresh();
  }

  refresh(): void {
    this.summary = answerStore.getProgress(this.navParam.bankId, this.navParam.sessionId);
    this.statuses = answerStore.getQuestionStatus(this.navParam.bankId, this.navParam.sessionId);
    this.applyFilter();
  }

  /** 按筛选开关裁剪状态列表并整表替换数据源 */
  applyFilter(): void {
    const list: questionStatus[] = [];
    for (let i = 0; i < this.statuses.length; i++) {
      if (!this.onlyWrong || this.statuses[i].status === 'wrong') {
        list.push(this.statuses[i]);
      }
    }
    this.source.refresh(list);
  }

  originLabel(origin: SessionOrigin): string {
    if (origin === 'full') {
      return '全部题号';
    }
    if (origin === 'retry') {
      return '错题重做';
    }
    return '部分题号';
  }

  modeLabel(mode: PracticeMode): string {
    return mode === 'random' ? '随机' : '顺序';
  }

  statusLabel(status: string): string {
    if (status === 'correct') {
      return '答对';
    }
    if (status === 'wrong') {
      return '答错';
    }
    return '未作答';
  }

  statusColor(status: string): Resource {
    if (status === 'correct') {
      return $r('app.color.green');
    }
    if (status === 'wrong') {
      return $r('app.color.red');
    }
    return $r('app.color.transparent_text');
  }

  wrongCount(): number {
    let count = 0;
    for (let i = 0; i < this.statuses.length; i++) {
      if (this.statuses[i].status === 'wrong') {
        count++;
      }
    }
    return count;
  }

  questionOf(st: questionStatus): singleQuestion | null {
    if (st.questionIndex < 0 || st.questionIndex >= this.questions.length) {
      return null;
    }
    return this.questions[st.questionIndex];
  }

  /** 正确答案展示文本：填空题把选项字母引用替换为对应选项内容 */
  correctAnswerOf(q: singleQuestion): string {
    return q.type === 'blank' ? blankAnswerText(q) : q.answer;
  }

  /** 错题重做：以本次记录中做错的题号生成一次新练习，可选附加收藏题 */
  retryWrong(): void {
    const sessionId = answerStore.createRetrySession(this.navParam.bankId,
      this.navParam.sessionId, this.retryIncludeStarred);
    if (sessionId === '') {
      this.getUIContext().getPromptAction().showToast(
        { message: '没有可重做的错题或收藏题', duration: 1500 });
      return;
    }
    this.pathStack.replacePath({
      name: 'MockPracticeMain',
      param: {
        bankId: this.navParam.bankId,
        bankName: this.navParam.bankName,
        sessionId: sessionId
      } as sessionNavParam
    });
  }

  @Builder
  RecordCard(st: questionStatus) {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Stretch }) {
      Column()
        .width(4)
        .borderRadius(2)
        .backgroundColor(this.statusColor(st.status))

      Column() {
        Row() {
          Text(`第 ${st.position + 1} 题`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
          Text(`题库题号 ${st.questionIndex + 1}`)
            .fontSize(12)
            .fontColor($r('app.color.transparent_text'))
            .margin({ left: 8 })
          if (st.starred) {
            Text('★')
              .fontSize(13)
              .fontColor(STAR_COLOR)
              .margin({ left: 4 })
          }
          Blank()
          Text(this.statusLabel(st.status))
            .fontSize(13)
            .fontColor(this.statusColor(st.status))
        }
        .width('100%')

        if (this.questionOf(st) !== null) {
          Text(this.questionOf(st)!.context)
            .fontSize(15)
            .maxLines(6)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: 6 })

          Row() {
            Text(`你的答案：${st.userAnswer === undefined ? '—' : st.userAnswer}`)
              .layoutWeight(1)
            Text(`正确答案：${this.correctAnswerOf(this.questionOf(st)!)}`)
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 6 })

          if (this.questionOf(st)!.analysis !== undefined) {
            Text(`解析：${this.questionOf(st)!.analysis}`)
              .fontSize(13)
              .fontColor($r('app.color.transparent_text'))
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 6 })
          }
        } else {
          Text('题目内容缺失（题库数据可能已被修改）')
            .fontSize(13)
            .fontColor($r('app.color.red'))
            .width('100%')
            .margin({ top: 6 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .borderRadius(16)
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          if (this.summary !== null) {
            Column() {
              Text(`${this.originLabel(this.summary.origin)} · ${this.modeLabel(this.summary.mode)}`)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
              Text(`答对 ${this.summary.correct} / 共 ${this.summary.total} 题` +
                (this.summary.answered > 0 ?
                  ` · 正确率 ${Math.round(this.summary.correct * 100 / this.summary.answered)}%` : ''))
                .fontSize(13)
                .fontColor($r('app.color.transparent_text'))
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Start)
          }

          Toggle({ type: ToggleType.Button, isOn: $$this.onlyWrong }) {
            Text('只看错题')
              .fontSize(13)
          }
          .selectedColor($r('app.color.active_text'))
          .onChange((value: boolean) => {
            this.onlyWrong = value;
            this.applyFilter();
          })
        }
        .width('100%')
        .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .borderRadius(20)
        .padding(14)
        .margin({ top: 12, bottom: 8 })
        .justifyContent(FlexAlign.SpaceBetween)

        // 只有 List/Grid/Swiper/WaterFlow 支持数据懒加载，Scroll 内的 LazyForEach 仍会全量加载，故改用 List
        List({ space: 8 }) {
          LazyForEach(this.source, (st: questionStatus) => {
            ListItem() {
              this.RecordCard(st)
            }
          }, (st: questionStatus) => `${this.navParam.sessionId}-${st.position}-${st.status}`)

          if (this.statuses.length === 0) {
            ListItem() {
              Text('本次练习还没有作答记录')
                .fontSize(13)
                .fontColor($r('app.color.transparent_text'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(20)
            }
          } else if (this.onlyWrong && this.wrongCount() === 0) {
            ListItem() {
              Text('本次练习没有错题')
                .fontSize(13)
                .fontColor($r('app.color.transparent_text'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(20)
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        // .padding({ top: 12, left: 12, right: 12, bottom: 12 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .cachedCount(3)
        .borderRadius(20)

        if (this.wrongCount() > 0) {
          Row() {
            Toggle({ type: ToggleType.Button, isOn: $$this.retryIncludeStarred }) {
              Text('含收藏题')
                .fontSize(13)
            }
            .selectedColor($r('app.color.active_text'))

            Button(`重做本次错题（${this.wrongCount()} 题）`)
              .buttonStyle(ButtonStyleMode.EMPHASIZED)
              .layoutWeight(1)
              .margin({ left: 8 })
              .onClick(() => {
                this.retryWrong();
              })
          }
          .width('100%')
          .margin({ top: 8, bottom: 12 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 12 })
    }
    .title('做题记录', {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : undefined
    })
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .onShown(() => {
      this.refresh();
    })
  }
}
