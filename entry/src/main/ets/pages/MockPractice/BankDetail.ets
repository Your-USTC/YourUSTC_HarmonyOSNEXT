import BackgroundImage from '../../utils/BgImageManager';
import {
  bankNavParam,
  sessionNavParam,
  sessionSummary,
  SessionOrigin,
  PracticeMode
} from '../../utils/MockPractice/constants';
import { bankStore } from '../../utils/MockPractice/QuestionBankManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';


@Builder
export function MBDBuilder(name: string, param?: Object) {
  BankDetail({ navParam: param as bankNavParam })
}

const RANGE_ALL: number = 0;
const RANGE_CUSTOM: number = 1;
const RANGE_RANDOM: number = 2;

@Entry
@Component
struct BankDetail {
  navParam: bankNavParam = { bankId: '', bankName: '' };
  /** 该题库下的做题记录列表（做题记录模块） */
  @State summaries: sessionSummary[] = [];
  @State questionCount: number = 0;
  @State showSetupSheet: boolean = false;
  @State rangeType: number = RANGE_ALL;
  @State setupStart: string = '1';
  @State setupEnd: string = '';
  @State setupRandomCount: string = '20';
  @State setupRandomOrder: boolean = false;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.setupEnd = String(bankStore.getQuestionCount(this.navParam.bankId));
    this.refresh();
  }

  refresh(): void {
    this.summaries = answerStore.getSummaries(this.navParam.bankId);
    this.questionCount = bankStore.getQuestionCount(this.navParam.bankId);
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

  formatDate(ts: number): string {
    if (ts <= 0) {
      return '';
    }
    return new Date(ts).toLocaleString('zh-cn',
      { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
  }

  statusText(summary: sessionSummary): string {
    if (summary.finished) {
      return '已完成';
    }
    if (summary.answered === 0) {
      return '未开始';
    }
    return '进行中';
  }

  /** 选题面板中根据当前配置计算本次练习的题数（-1 表示配置无效） */
  setupCount(): number {
    if (this.rangeType === RANGE_ALL) {
      return this.questionCount;
    }
    if (this.rangeType === RANGE_CUSTOM) {
      const start = parseInt(this.setupStart, 10);
      const end = parseInt(this.setupEnd, 10);
      if (isNaN(start) || isNaN(end) || start < 1 || end > this.questionCount || start > end) {
        return -1;
      }
      return end - start + 1;
    }
    const count = parseInt(this.setupRandomCount, 10);
    if (isNaN(count) || count < 1 || count > this.questionCount) {
      return -1;
    }
    return count;
  }

  /** 依据面板配置生成题号子集并开始练习 */
  startSession(): void {
    const count = this.setupCount();
    if (count < 0 || this.questionCount === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '选题范围无效，请检查输入', duration: 2000 });
      return;
    }
    let questionNO: number[] = [];
    if (this.rangeType === RANGE_ALL) {
      for (let i = 1; i <= this.questionCount; i++) {
        questionNO.push(i - 1);
      }
    } else if (this.rangeType === RANGE_CUSTOM) {
      const start = parseInt(this.setupStart, 10);
      const end = parseInt(this.setupEnd, 10);
      for (let i = start; i <= end; i++) {
        questionNO.push(i - 1);
      }
    } else {
      // 随机抽取不重复的 count 道题（部分 Fisher-Yates 洗牌）
      const pool: number[] = [];
      for (let i = 0; i < this.questionCount; i++) {
        pool.push(i);
      }
      for (let i = 0; i < count; i++) {
        const j = i + Math.floor(Math.random() * (this.questionCount - i));
        const tmp = pool[i];
        pool[i] = pool[j];
        pool[j] = tmp;
      }
      for (let i = 0; i < count; i++) {
        questionNO.push(pool[i]);
      }
      if (!this.setupRandomOrder) {
        questionNO.sort((a: number, b: number): number => a - b);
      }
    }

    const mode: PracticeMode = this.setupRandomOrder ? 'random' : 'ordered';
    const origin: SessionOrigin = this.rangeType === RANGE_ALL ? 'full' : 'custom';
    const sessionId = answerStore.createSession(this.navParam.bankId, mode, origin, questionNO);
    if (sessionId === '') {
      this.getUIContext().getPromptAction().showToast({ message: '创建练习失败', duration: 2000 });
      return;
    }
    bankStore.touchBank(this.navParam.bankId);
    this.showSetupSheet = false;
    this.pushAnswering(sessionId);
  }

  pushAnswering(sessionId: string): void {
    const param: sessionNavParam = {
      bankId: this.navParam.bankId,
      bankName: this.navParam.bankName,
      sessionId: sessionId
    };
    this.pathStack.pushPath({ name: 'MockPracticeMain', param: param });
  }

  confirmDeleteSession(summary: sessionSummary): void {
    this.getUIContext().showAlertDialog({
      title: '删除做题记录',
      message: '删除后该次练习的作答情况将丢失，确定删除？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        style: DialogButtonStyle.HIGHLIGHT,
        fontColor: $r('app.color.red'),
        action: () => {
          answerStore.deleteSession(this.navParam.bankId, summary.sessionId);
          this.refresh();
        }
      },
      cancel: () => {}
    });
  }

  @Builder
  sessionMenu(summary: sessionSummary) {
    Menu() {
      if (summary.finished) {
        MenuItem({ content: '查看记录' })
          .onClick(() => {
            const param: sessionNavParam = {
              bankId: this.navParam.bankId,
              bankName: this.navParam.bankName,
              sessionId: summary.sessionId
            };
            this.pathStack.pushPath({ name: 'MockPracticeRecord', param: param });
          })
      } else {
        MenuItem({ content: '继续练习' })
          .onClick(() => {
            bankStore.touchBank(this.navParam.bankId);
            this.pushAnswering(summary.sessionId);
          })
      }
      MenuItem({ content: '删除记录' })
        .onClick(() => {
          this.confirmDeleteSession(summary);
        })
    }
  }

  @Builder
  setupSheet() {
    Column() {
      Row() {
        Text('选题范围')
          .fontSize(15)
          .width(80)
        Select([{ value: '全部题目' }, { value: '自定义题号范围' }, { value: '随机抽题' }])
          .selected(this.rangeType)
          .value(this.rangeType === RANGE_ALL ? '全部题目'
            : (this.rangeType === RANGE_CUSTOM ? '自定义题号范围' : '随机抽题'))
          .onSelect((index: number) => {
            this.rangeType = index;
          })
      }
      .width('100%')

      if (this.rangeType === RANGE_CUSTOM) {
        Row() {
          Text('题号范围')
            .fontSize(15)
            .width(80)
          TextInput({ text: this.setupStart })
            .type(InputType.Number)
            .width(90)
            .height(40)
            .onChange((value: string) => {
              this.setupStart = value;
            })
          Text('至').margin({ left: 8, right: 8 })
          TextInput({ text: this.setupEnd })
            .type(InputType.Number)
            .width(90)
            .height(40)
            .onChange((value: string) => {
              this.setupEnd = value;
            })
        }
        .width('100%')
        .margin({ top: 10 })
      } else if (this.rangeType === RANGE_RANDOM) {
        Row() {
          Text('抽取数量')
            .fontSize(15)
            .width(80)
          TextInput({ text: this.setupRandomCount })
            .type(InputType.Number)
            .width(90)
            .height(40)
            .onChange((value: string) => {
              this.setupRandomCount = value;
            })
        }
        .width('100%')
        .margin({ top: 10 })
      }

      Text(`题库共 ${this.questionCount} 题${this.rangeType === RANGE_CUSTOM ? '，题号从 1 开始' : ''}`)
        .fontSize(12)
        .fontColor($r('app.color.transparent_text'))
        .width('100%')
        .margin({ top: 4 })

      Row() {
        Text('作答顺序')
          .fontSize(15)
          .width(80)
        Select([{ value: '顺序作答' }, { value: '随机打乱' }])
          .selected(this.setupRandomOrder ? 1 : 0)
          .value(this.setupRandomOrder ? '随机打乱' : '顺序作答')
          .onSelect((index: number) => {
            this.setupRandomOrder = index === 1;
          })
      }
      .width('100%')
      .margin({ top: 10 })

      Text(this.setupCount() < 0 ? '当前选题配置无效' : `本次练习共 ${this.setupCount()} 题`)
        .fontSize(13)
        .fontColor(this.setupCount() < 0 ? $r('app.color.red') : $r('app.color.active_text'))
        .width('100%')
        .margin({ top: 12 })

      Row() {
        Button('取消')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .width('50%')
          .onClick(() => {
            this.showSetupSheet = false;
          })
        Button('开始练习')
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .width('50%')
          .enabled(this.setupCount() >= 0 && this.questionCount > 0)
          .onClick(() => {
            this.startSession();
          })
      }
      .margin({ top: 14, bottom: 6 })
      .width('100%')
    }
    .padding({ top: 4, left: 16, right: 16, bottom: 8 })
    .width('100%')
  }

  build() {
    NavDestination() {
      Column() {
        // 题库信息卡片
        Column() {
          Text(this.navParam.bankName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          Text(`题库共 ${this.questionCount} 题`)
            .fontSize(13)
            .fontColor($r('app.color.transparent_text'))
            .width('100%')
            .margin({ top: 6 })
          Button('开始新练习')
            .buttonStyle(ButtonStyleMode.EMPHASIZED)
            .width('100%')
            .margin({ top: 12 })
            .enabled(this.questionCount > 0)
            .onClick(() => {
              this.showSetupSheet = true;
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .margin({ top: 12 })
        .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .borderRadius(20)

        Text('做题记录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 16, bottom: 4 })

        List() {
          if (this.summaries.length === 0) {
            ListItem() {
              Text('还没有做题记录，点击「开始练习」创建一次练习')
                .fontSize(14)
                .fontColor($r('app.color.transparent_text'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 30, bottom: 30 })
            }
          } else {
            ForEach(this.summaries, (summary: sessionSummary) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(`${this.originLabel(summary.origin)} · ${this.modeLabel(summary.mode)}`)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                    Blank()
                    Text(this.statusText(summary))
                      .fontSize(13)
                      .fontColor(summary.finished ? $r('app.color.green') : '#f59e0b')
                  }
                  .width('100%')

                  Row() {
                    Text(`已答 ${summary.answered}/${summary.total} · 答对 ${summary.correct}` +
                      (summary.answered > 0 ? ` · 正确率 ${Math.round(summary.correct * 100 / summary.answered)}%` :
                        ''))
                      .fontSize(13)
                      .layoutWeight(1)
                    Text(this.formatDate(summary.lastAnswerTime || summary.createdAt))
                      .fontSize(12)
                      .fontColor($r('app.color.transparent_text'))
                  }
                  .width('100%')
                  .margin({ top: 6 })
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')
                .padding({ top: 12, bottom: 12, left: 16, right: 16 })
                .margin({ top: 8 })
                .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
                .backgroundBlurStyle(BackgroundImage.blurLevel)
                .borderRadius(16)
                .onClick(() => {
                  if (summary.finished) {
                    const param: sessionNavParam = {
                      bankId: this.navParam.bankId,
                      bankName: this.navParam.bankName,
                      sessionId: summary.sessionId
                    };
                    this.pathStack.pushPath({ name: 'MockPracticeRecord', param: param });
                  } else {
                    bankStore.touchBank(this.navParam.bankId);
                    this.pushAnswering(summary.sessionId);
                  }
                })
                .bindContextMenu(this.sessionMenu(summary), ResponseType.LongPress)
              }
            }, (summary: sessionSummary) => summary.sessionId)
          }
        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
        .borderRadius({ topLeft: 16, topRight: 16 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 12 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .bindSheet($$this.showSetupSheet, this.setupSheet(), {
        detents: [SheetSize.FIT_CONTENT, SheetSize.MEDIUM],
        preferType: SheetType.CENTER,
        showClose: false,
        backgroundColor: '#00d00721',
        blurStyle: BlurStyle.Regular,
        title: { title: '开始练习', subtitle: '可选题库中的全部或部分题号' }
      })
    }
    .title(this.navParam.bankName, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined
    })
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#00d00721' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .onShown(() => {
      // 从答题页/记录页返回时刷新做题记录
      this.refresh();
    })
  }
}
