import BackgroundImage from '../../utils/BgImageManager';
import { bankAttribute, bankNavParam, csvImportConfig } from '../../utils/MockPractice/constants';
import { bankStore } from '../../utils/MockPractice/QuestionBankManager';
import { importBankFromCsv } from '../../utils/MockPractice/QuestionsManager';
import { readDataFromCsv } from '../../utils/MockPractice/DataTransformer';
import { answerStore } from '../../utils/MockPractice/AnswerSessionManager';
import { hostContext } from '../../constants/BasicConstants';
import { CsvImportPanel } from './ImportPanel';


@Builder
export function MPLBuilder(name: string, param?: Object) {
  MockPracticeList();
}

@Entry
@Component
struct MockPracticeList {
  /** 题库列表（题库模块） */
  @State bankList: bankAttribute[] = [];
  @State showImportSheet: boolean = false;
  @State csvLines: string[] = [];
  @State csvFileName: string = 'test';
  @State showRenameSheet: boolean = false;
  @State renameTargetId: string = '';
  @State renameInput: string = '';
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

  openRenameSheet(bank: bankAttribute): void {
    this.renameTargetId = bank.uuid;
    this.renameInput = bank.name;
    this.showRenameSheet = true;
  }

  confirmRename(): void {
    const name = this.renameInput.trim();
    if (name === '' || this.renameTargetId === '') {
      this.getUIContext().getPromptAction().showToast({ message: '名称不能为空', duration: 1500 });
      return;
    }
    bankStore.updateBankAttribute(this.renameTargetId, { name: name });
    this.showRenameSheet = false;
    this.bankList = bankStore.listBanks();
  }

  confirmRemoveBank(bank: bankAttribute): void {
    this.getUIContext().showAlertDialog({
      title: '删除题库',
      message: `将删除「${bank.name}」及其全部做题记录，且无法恢复。确定删除？`,
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
          // 做题记录存放在题库目录内：先丢弃 session 缓存，再删除整个题库目录
          answerStore.forget(bank.uuid);
          bankStore.removeBank(bank.uuid);
          this.bankList = bankStore.listBanks();
          this.getUIContext().getPromptAction().showToast({ message: '题库已删除', duration: 1500 });
        }
      },
      cancel: () => {}
    });
  }

  @Builder
  bankMenu(bank: bankAttribute) {
    Menu() {
      MenuItem({ content: '重命名' })
        .onClick(() => {
          this.openRenameSheet(bank);
        })
      MenuItem({ content: '删除题库' })
        .onClick(() => {
          this.confirmRemoveBank(bank);
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
  renameSheet() {
    Column() {
      TextInput({ text: this.renameInput })
        .height(40)
        .onChange((value: string) => {
          this.renameInput = value;
        })
      Row() {
        Button('取消')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .width('50%')
          .onClick(() => {
            this.showRenameSheet = false;
          })
        Button('确定')
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .width('50%')
          .onClick(() => {
            this.confirmRename();
          })
      }
      .margin({ top: 12 })
      .width('100%')
    }
    .padding({ top: 4, left: 16, right: 16, bottom: 8 })
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
              Text('从右上角导入教师提供的 CSV\n文件以创建题库').fontSize(18).textAlign(TextAlign.Center);
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
                  this.pathStack.pushPath({
                    name: 'MockPracticeDetail',
                    param: { bankId: singleBank.uuid, bankName: singleBank.name } as bankNavParam
                  });
                })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10, left: 16, right: 16 })
              .margin({ top: 8, bottom: 6 })
              .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
              .backgroundBlurStyle(BackgroundImage.blurLevel)
              .borderRadius(20)
              .bindContextMenu(this.bankMenu(singleBank), ResponseType.LongPress)
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
          // 重命名 sheet 绑定在 List 节点上：同一节点重复 bindSheet 会相互覆盖
          .bindSheet($$this.showRenameSheet, this.renameSheet(), {
            detents: [SheetSize.FIT_CONTENT],
            preferType: SheetType.CENTER,
            showClose: false,
            backgroundColor: '#0000',
            blurStyle: BlurStyle.Regular,
            title: { title: '重命名题库' }
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
      // 从题库详情返回时刷新（题数、最近练习时间可能已变化）
      this.bankList = bankStore.listBanks();
    })
  }
}
