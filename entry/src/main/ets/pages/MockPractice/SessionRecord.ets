import BackgroundImage from '../../utils/BgImageManager';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import { bankStore } from '../../utils/MockPractice/QuestionBankManager';
import {
  sessionNavParam,
  sessionSummary,
  singleQuestion,
  questionStatus,
  SessionOrigin,
  PracticeMode
} from '../../utils/MockPractice/constants';


@Builder
export function MPRBuilder(name: string, param?: Object) {
  SessionRecord({ navParam: param as sessionNavParam })
}

@Entry
@Component
struct SessionRecord {
  navParam: sessionNavParam = { bankId: '', bankName: '', sessionId: '' };
  @State summary: sessionSummary | null = null;
  @State statuses: questionStatus[] = [];
  /** 题库中的题目，按题号索引取用 */
  @State questions: singleQuestion[] = [];
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.questions = bankStore.getQuestions(this.navParam.bankId);
    this.refresh();
  }

  refresh(): void {
    this.summary = answerStore.getProgress(this.navParam.bankId, this.navParam.sessionId);
    this.statuses = answerStore.getQuestionStatus(this.navParam.bankId, this.navParam.sessionId);
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

  /** 错题重做：以本次记录中做错的题号生成一次新练习（为错题本功能预留收藏维度） */
  retryWrong(): void {
    const sessionId = answerStore.createRetrySession(this.navParam.bankId, this.navParam.sessionId, false);
    if (sessionId === '') {
      this.getUIContext().getPromptAction().showToast({ message: '没有可重做的错题', duration: 1500 });
      return;
    }
    this.pathStack.pushPath({
      name: 'MockPracticeMain',
      param: {
        bankId: this.navParam.bankId,
        bankName: this.navParam.bankName,
        sessionId: sessionId
      } as sessionNavParam
    });
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            if (this.summary !== null) {
              Column() {
                Text(`${this.originLabel(this.summary.origin)} · ${this.modeLabel(this.summary.mode)}`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                Text(`答对 ${this.summary.correct} / 共 ${this.summary.total} 题` +
                  (this.summary.answered > 0 ? ` · 正确率 ${Math.round(this.summary.correct * 100 / this.summary.answered)}%` : ''))
                  .fontSize(13)
                  .fontColor($r('app.color.transparent_text'))
                  .width('100%')
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding(16)
              .margin({ top: 12 })
              .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
              .backgroundBlurStyle(BackgroundImage.blurLevel)
              .borderRadius(20)
            }

            ForEach(this.statuses, (st: questionStatus) => {
              Row() {
                Column()
                  .width(4)
                  .height('100%')
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
                      Text(`正确答案：${this.questionOf(st)!.answer}`)
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
              .alignItems(VerticalAlign.Top)
              .width('100%')
              .padding(14)
              .margin({ top: 8 })
              .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
              .backgroundBlurStyle(BackgroundImage.blurLevel)
              .borderRadius(16)
            }, (st: questionStatus) => `${this.navParam.sessionId}-${st.position}`)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

        if (this.wrongCount() > 0) {
          Button(`重做本次错题（${this.wrongCount()} 题）`)
            .buttonStyle(ButtonStyleMode.EMPHASIZED)
            .width('calc(100% - 24vp)')
            .margin({ top: 8, bottom: 12 })
            .onClick(() => {
              this.retryWrong();
            })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('做题记录', {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined
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
