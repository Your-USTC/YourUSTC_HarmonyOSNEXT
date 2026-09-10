import BackgroundImage from '../../utils/BgImageManager';
import {
  bankAttribute,
  csvImportConfig,
  sessionSummary,
  sessionNavParam,
  SessionOrigin,
  PracticeMode
} from '../../utils/MockPractice/constants';
import { bankStore } from '../../utils/MockPractice/QuestionBankManager';
import { importBankFromCsv } from '../../utils/MockPractice/QuestionsManager';
import { readDataFromCsv } from '../../utils/MockPractice/DataTransformer';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import { hostContext } from '../../constants/BasicConstants';
import { CsvImportPanel } from './ImportPanel';
import RenameDialog from '../../view/RenameDialog';


@Builder
export function MPLBuilder(name: string, param?: Object) {
  MockPracticeList();
}

const RANGE_ALL: number = 0;
const RANGE_CUSTOM: number = 1;
const RANGE_RANDOM: number = 2;

@Entry
@Component
struct MockPracticeList {
  /** 题库列表（题库模块） */
  @State bankList: bankAttribute[] = [];
  @State showImportSheet: boolean = false;
  @State csvLines: string[] = [];
  @State csvFileName: string = 'test';
  /** 详情半模态当前展示的题库 */
  @State showDetailSheet: boolean = false;
  @State detailBankId: string = '';
  @State detailBankName: string = '';
  /** 该题库下的做题记录列表（做题记录模块） */
  @State summaries: sessionSummary[] = [];
  @State questionCount: number = 0;
  /** 当前详情题库下所有记录中收藏过的题数 */
  @State starredCount: number = 0;
  /** 详情半模态内是否切换到选题视图 */
  @State detailSetupView: boolean = false;
  @State rangeType: number = RANGE_ALL;
  @State setupStart: string = '1';
  @State setupEnd: string = '';
  @State setupRandomCount: string = '20';
  @State setupRandomOrder: boolean = false;
  renameController: CustomDialogController | undefined;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.bankList = bankStore.listBanks();
  }

  menuItems: Array<NavigationMenuItem> = [
    {
      value: 'import',
      icon: $r('app.media.import'),
      action: () => {
        this.startImport();
      }
    }
  ];

  formatDate(ts: number): string {
    return new Date(ts).toLocaleString('zh-cn', { year: 'numeric', month: '2-digit', day: '2-digit' });
  }

  formatDateTime(ts: number): string {
    if (ts <= 0) {
      return '';
    }
    return new Date(ts).toLocaleString('zh-cn',
      { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
  }

  lastPracticeLabel(ts: number): string {
    return ts <= 0 ? '尚未练习' : `最近练习 ${this.formatDate(ts)}`;
  }

  startImport(): void {
    readDataFromCsv(hostContext()).then((file) => {
      if (file.lines.length === 0) {
        this.getUIContext().getPromptAction().showToast({ message: '未读取到 CSV 内容，导入已取消', duration: 2000 });
        return;
      }
      this.csvLines = file.lines;
      this.csvFileName = file.fileName;
      this.showImportSheet = true;
    });
  }

  confirmImport(name: string, config: csvImportConfig): void {
    const uuid = importBankFromCsv(name, this.csvLines, config);
    if (uuid === '') {
      this.getUIContext().getPromptAction().showToast({ message: '未能解析出题目，请检查起始行与列设置', duration: 2500 });
      return;
    }
    this.showImportSheet = false;
    this.bankList = bankStore.listBanks();
    this.getUIContext().getPromptAction().showToast({ message: '导入成功', duration: 1500 });
  }

  /** 点击题库卡片：打开详情半模态并加载做题记录 */
  openDetailSheet(bank: bankAttribute): void {
    this.detailBankId = bank.uuid;
    this.detailBankName = bank.name;
    this.questionCount = bankStore.getQuestionCount(bank.uuid);
    this.starredCount = answerStore.starredQuestionNos(bank.uuid).length;
    this.summaries = answerStore.getSummaries(bank.uuid);
    this.detailSetupView = false;
    this.rangeType = RANGE_ALL;
    this.setupStart = '1';
    this.setupEnd = String(this.questionCount);
    this.setupRandomCount = '20';
    this.setupRandomOrder = false;
    this.showDetailSheet = true;
  }

  refreshDetail(): void {
    this.summaries = answerStore.getSummaries(this.detailBankId);
    this.questionCount = bankStore.getQuestionCount(this.detailBankId);
    this.starredCount = answerStore.starredQuestionNos(this.detailBankId).length;
  }

  /** 收藏题专项练习：汇总题库内所有记录中收藏过的题号开始一次新练习 */
  startStarredPractice(): void {
    const sessionId = answerStore.createStarredSession(this.detailBankId);
    if (sessionId === '') {
      this.getUIContext().getPromptAction().showToast(
        { message: '还没有收藏任何题目', duration: 1500 });
      return;
    }
    bankStore.touchBank(this.detailBankId);
    this.detailSetupView = false;
    this.showDetailSheet = false;
    this.pushAnswering(sessionId);
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

  statusText(summary: sessionSummary): string {
    if (summary.finished) {
      return '已完成';
    }
    if (summary.answered === 0) {
      return '未开始';
    }
    return '进行中';
  }

  /** 选题视图中根据当前配置计算本次练习的题数（-1 表示配置无效） */
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

  /** 依据选题视图配置生成题号子集并开始练习 */
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
    const sessionId = answerStore.createSession(this.detailBankId, mode, origin, questionNO);
    if (sessionId === '') {
      this.getUIContext().getPromptAction().showToast({ message: '创建练习失败', duration: 2000 });
      return;
    }
    bankStore.touchBank(this.detailBankId);
    this.detailSetupView = false;
    this.showDetailSheet = false;
    this.pushAnswering(sessionId);
  }

  pushAnswering(sessionId: string): void {
    const param: sessionNavParam = {
      bankId: this.detailBankId,
      bankName: this.detailBankName,
      sessionId: sessionId
    };
    this.pathStack.pushPath({ name: 'MockPracticeMain', param: param });
  }

  pushRecord(sessionId: string): void {
    const param: sessionNavParam = {
      bankId: this.detailBankId,
      bankName: this.detailBankName,
      sessionId: sessionId
    };
    this.pathStack.pushPath({ name: 'MockPracticeRecord', param: param });
  }

  /** 重命名使用全局的 RenameDialog */
  openRenameDialog(): void {
    this.renameController = new CustomDialogController({
      builder: RenameDialog({
        name: this.detailBankName,
        message: `为「${this.detailBankName}」设置新的名称`,
        onConfirm: (newName: string): void => {
          this.confirmRename(newName);
        }
      }),
      gridCount: 4,
      autoCancel: false
    });
    this.renameController.open();
  }

  confirmRename(newName: string): void {
    const name = newName.trim();
    if (name === '' || this.detailBankId === '') {
      this.getUIContext().getPromptAction().showToast({ message: '名称不能为空', duration: 1500 });
      return;
    }
    bankStore.updateBankAttribute(this.detailBankId, { name: name });
    this.detailBankName = name;
    this.bankList = bankStore.listBanks();
  }

  confirmRemoveBank(): void {
    this.getUIContext().showAlertDialog({
      title: '删除题库',
      message: `将删除「${this.detailBankName}」及其全部做题记录，且无法恢复。确定删除？`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        style: DialogButtonStyle.HIGHLIGHT,
        backgroundColor: $r('app.color.red'),
        action: () => {
          // 做题记录存放在题库目录内：先丢弃 session 缓存，再删除整个题库目录
          answerStore.forget(this.detailBankId);
          bankStore.removeBank(this.detailBankId);
          this.showDetailSheet = false;
          this.bankList = bankStore.listBanks();
          this.getUIContext().getPromptAction().showToast({ message: '题库已删除', duration: 1500 });
        }
      },
      cancel: () => {}
    });
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
        backgroundColor: $r('app.color.red'),
        action: () => {
          answerStore.deleteSession(this.detailBankId, summary.sessionId);
          this.refreshDetail();
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
            this.showDetailSheet = false;
            this.pushRecord(summary.sessionId);
          })
      } else {
        MenuItem({ content: '继续练习' })
          .onClick(() => {
            bankStore.touchBank(this.detailBankId);
            this.showDetailSheet = false;
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
  importSheet() {
    CsvImportPanel({
      lines: this.csvLines,
      suggestedName: this.csvFileName,
      onConfirm: (name: string, config: csvImportConfig): void => {
        this.confirmImport(name, config);
      },
      onCancel: (): void => {
        this.showImportSheet = false;
      }
    })
  }

  @Builder
  detailSheet() {
    Column() {
      if (this.detailSetupView) {
        this.setupForm()
      } else {
        Row({ space: 6 }) {
          Button('删除')
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .fontColor($r('app.color.red'))
            .onClick(() => {
              this.confirmRemoveBank();
            })
          Button('重命名')
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(() => {
              this.openRenameDialog();
            })
          if (this.starredCount > 0) {
            Button(`练习收藏题（${this.starredCount}）`)
              .buttonStyle(ButtonStyleMode.NORMAL)
              .layoutWeight(2)
              .onClick(() => {
                this.startStarredPractice();
              })
          }
          Button('新练习')
            .buttonStyle(ButtonStyleMode.EMPHASIZED)
            .layoutWeight(1)
            .enabled(this.questionCount > 0)
            .onClick(() => {
              this.detailSetupView = true;
            })
        }
        .width('100%')

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
                    Text(this.formatDateTime(summary.lastAnswerTime || summary.createdAt))
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
                  this.showDetailSheet = false;
                  if (summary.finished) {
                    this.pushRecord(summary.sessionId);
                  } else {
                    bankStore.touchBank(this.detailBankId);
                    this.pushAnswering(summary.sessionId);
                  }
                })
                .bindContextMenu(this.sessionMenu(summary), ResponseType.LongPress)
              }
            }, (summary: sessionSummary) => summary.sessionId)
          }
        }
        .width('100%')
        .layoutWeight(1)
        // .constraintSize({ maxHeight: 340 })
        .borderRadius(16)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      }
    }
    .padding({ top: 4, left: 16, right: 16, bottom: 8 })
    .width('100%')
  }

  @Builder
  setupForm() {
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
            this.detailSetupView = false;
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
    .width('100%')
  }

  build() {
    NavDestination() {
      Column() {
        if (this.bankList.length === 0) {
          Column() {
            Column() {
              Stack() {
                Image($r('app.media.board'))
                  .width(100)
                  .interpolation(ImageInterpolation.Medium)
                  .draggable(false)
                Text('404')
                  .fontColor('#fff')
                  .offset({ x: -5, y: 26 })
              }
              Text('打开教师提供的 xlsx 文件\n另存为 CSV 并从右上角\n导入 CSV 以创建题库').fontSize(18).textAlign(TextAlign.Center);
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
            ForEach(this.bankList, (singleBank: bankAttribute) => {
              ListItem() {
                Column() {
                  Text(singleBank.name)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row() {
                    Text(`共 ${bankStore.getQuestionCount(singleBank.uuid)} 题`)
                    Text(`创建 ${this.formatDate(singleBank.createTime)}`)
                    Text(this.lastPracticeLabel(singleBank.lastOpenTime))
                  }
                  .margin({ top: 6 })
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                }
                .width('100%')
                .onClick(() => {
                  this.openDetailSheet(singleBank);
                })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10, left: 16, right: 16 })
              .margin({ top: 8, bottom: 6 })
              .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
              .backgroundBlurStyle(BackgroundImage.blurLevel)
              .borderRadius(20)
            }, (singleBank: bankAttribute) => singleBank.uuid + singleBank.name)
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
          // 详情 sheet 绑定在 List 节点上：同一节点重复 bindSheet 会相互覆盖
          .bindSheet($$this.showDetailSheet, this.detailSheet(), {
            detents: [SheetSize.FIT_CONTENT, SheetSize.MEDIUM],
            preferType: SheetType.CENTER,
            showClose: false,
            backgroundColor: '#0000',
            blurStyle: BlurStyle.Regular,
            title: this.detailSetupView
              ? { title: '开始练习', subtitle: '可选题库中的全部或部分题号' }
              : { title: this.detailBankName, subtitle: `题库共 ${this.questionCount} 题` }
          })
        }
      }
      .width('100%')
      .height('100%')
      .bindSheet($$this.showImportSheet, this.importSheet(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        preferType: SheetType.CENTER,
        showClose: false,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS,
        backgroundColor: '#0000',
        blurStyle: BlurStyle.Regular,
        enableFloatingDragBar: true,
        title: { title: '导入自测卷', subtitle: '选择数据起始行并指定各列含义' }
      })
    }
    .title('自测', {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : undefined
    })
    .menus(this.menuItems)
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .onShown(() => {
      // 从答题页/记录页返回时刷新（题数、最近练习时间可能已变化）
      this.bankList = bankStore.listBanks();
      if (this.showDetailSheet) {
        this.refreshDetail();
      }
    })
  }
}
