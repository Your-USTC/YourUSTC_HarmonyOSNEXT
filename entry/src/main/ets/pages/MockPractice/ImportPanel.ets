import BackgroundImage from '../../utils/BgImageManager';
import {
  CSV_UNUSED_COLUMN,
  csvColumnMapping,
  csvImportConfig
} from '../../utils/MockPractice/constants';
import {
  detectCsvConfig,
  getObjectFromCsv,
  parseCsvLine
} from '../../utils/MockPractice/DataTransformer';
import { blankAnswerText } from '../../utils/MockPractice/BlankJudge';

const FIELD_KEYS: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8];
const FIELD_LABELS: string[] = ['章节', '题型', '题目', '答案', '解析', '难度', '知识点', '选项个数', '选项起始列'];
const PREVIEW_ROW_LIMIT: number = 8;
const START_ROW_OPTION_LIMIT: number = 50;

const HEADER_CELL_HEIGHT: number = 44;
const CELL_HEIGHT: number = 34;
const ROW_NO_WIDTH: number = 36;
const COLUMN_WIDTH: number = 108;

@Component
export struct CsvImportPanel {
  /** 待导入的 CSV 全部行 */
  @Prop @Watch('onLinesChange') lines: string[] = [];
  /** 建议使用的测试名称（默认取自文件名） */
  @Prop suggestedName: string = 'test';
  onConfirm: (name: string, config: csvImportConfig) => void = () => {};
  onCancel: () => void = () => {};

  @State testName: string = 'test';
  @State startRow: number = 2;
  @State colSection: number = CSV_UNUSED_COLUMN;
  @State colType: number = CSV_UNUSED_COLUMN;
  @State colContext: number = CSV_UNUSED_COLUMN;
  @State colAnswer: number = CSV_UNUSED_COLUMN;
  @State colAnalysis: number = CSV_UNUSED_COLUMN;
  @State colDifficulty: number = CSV_UNUSED_COLUMN;
  @State colKnowledgePoint: number = CSV_UNUSED_COLUMN;
  @State colOptionCount: number = CSV_UNUSED_COLUMN;
  @State colOptionStart: number = CSV_UNUSED_COLUMN;

  @State previewRows: string[][] = [];
  @State columnIndices: number[] = [];
  @State columnOptions: SelectOption[] = [{ value: '不使用' }];
  @State startRowOptions: SelectOption[] = [{ value: '第1行' }];

  aboutToAppear(): void {
    this.onLinesChange();
  }

  /** 文件内容变化（或首次挂载）时，重新识别列含义并重建预览 */
  onLinesChange(): void {
    const detected: csvImportConfig = detectCsvConfig(this.lines);
    this.startRow = detected.startRow;
    this.colSection = detected.columns.section;
    this.colType = detected.columns.type;
    this.colContext = detected.columns.context;
    this.colAnswer = detected.columns.answer;
    this.colAnalysis = detected.columns.analysis;
    this.colDifficulty = detected.columns.difficulty;
    this.colKnowledgePoint = detected.columns.knowledgePoint;
    this.colOptionCount = detected.columns.optionCount;
    this.colOptionStart = detected.columns.optionStart;
    this.testName = this.suggestedName;

    let columnCount = 1;
    const scanLimit = Math.min(this.lines.length, 50);
    for (let i = 0; i < scanLimit; i++) {
      const fieldCount = parseCsvLine(this.lines[i]).length;
      if (fieldCount > columnCount) {
        columnCount = fieldCount;
      }
    }
    const newColumnOptions: SelectOption[] = [{ value: '不使用' }];
    const newColumnIndices: number[] = [];
    for (let i = 1; i <= columnCount; i++) {
      newColumnIndices.push(i);
      const opt: SelectOption = { value: `第${i}列` };
      newColumnOptions.push(opt);
    }
    this.columnIndices = newColumnIndices;
    this.columnOptions = newColumnOptions;

    const rowCount = Math.min(this.lines.length, START_ROW_OPTION_LIMIT);
    const newRowOptions: SelectOption[] = [];
    for (let i = 1; i <= rowCount; i++) {
      const opt: SelectOption = { value: `第${i}行` };
      newRowOptions.push(opt);
    }
    this.startRowOptions = newRowOptions;

    const newPreviewRows: string[][] = [];
    const previewLimit = Math.min(this.lines.length, PREVIEW_ROW_LIMIT);
    for (let i = 0; i < previewLimit; i++) {
      newPreviewRows.push(parseCsvLine(this.lines[i]));
    }
    this.previewRows = newPreviewRows;
  }

  private getFieldValue(key: number): number {
    switch (key) {
      case 0: return this.colSection;
      case 1: return this.colType;
      case 2: return this.colContext;
      case 3: return this.colAnswer;
      case 4: return this.colAnalysis;
      case 5: return this.colDifficulty;
      case 6: return this.colKnowledgePoint;
      case 7: return this.colOptionCount;
      default: return this.colOptionStart;
    }
  }

  private setFieldValue(key: number, value: number): void {
    switch (key) {
      case 0: this.colSection = value; break;
      case 1: this.colType = value; break;
      case 2: this.colContext = value; break;
      case 3: this.colAnswer = value; break;
      case 4: this.colAnalysis = value; break;
      case 5: this.colDifficulty = value; break;
      case 6: this.colKnowledgePoint = value; break;
      case 7: this.colOptionCount = value; break;
      default: this.colOptionStart = value; break;
    }
  }

  private columnLabel(column: number): string {
    return column <= 0 ? '不使用' : `第${column}列`;
  }

  private buildConfig(): csvImportConfig {
    const columns: csvColumnMapping = {
      section: this.colSection,
      type: this.colType,
      context: this.colContext,
      answer: this.colAnswer,
      analysis: this.colAnalysis,
      difficulty: this.colDifficulty,
      knowledgePoint: this.colKnowledgePoint,
      optionCount: this.colOptionCount,
      optionStart: this.colOptionStart
    };
    return { startRow: this.startRow, columns: columns };
  }

  private mappingValid(): boolean {
    return this.colContext > 0 && this.colAnswer > 0 && this.startRow >= 1 && this.startRow <= this.lines.length;
  }

  private mappedLabelOfColumn(column: number): string {
    for (let i = 0; i < FIELD_KEYS.length; i++) {
      if (this.getFieldValue(FIELD_KEYS[i]) === column) {
        return FIELD_LABELS[i];
      }
    }
    return '';
  }

  private sampleText(): string {
    const idx = this.startRow - 1;
    if (idx < 0 || idx >= this.lines.length) {
      return '起始行超出文件行数，无法解析';
    }
    const config = this.buildConfig();
    config.startRow = 1;
    const parsed = getObjectFromCsv([this.lines[idx]], config);
    if (parsed.length === 0) {
      return '按当前设置无法从该行解析出题目，请确认「题目」列已指定且该行内容完整';
    }
    const q = parsed[0];
    const typeText = q.type === 'single' ? '单选题' : (q.type === 'multiple' ? '多选题' : '填空题');
    let text = `[${typeText}] ${q.context}`;
    if (q.type !== 'blank' && q.options.length > 0) {
      const optionTexts: string[] = [];
      for (let i = 0; i < q.options.length; i++) {
        optionTexts.push(`${String.fromCharCode(65 + i)}. ${q.options[i]}`);
      }
      text += `\n选项：${optionTexts.join('　')}`;
    }
    const answerText = q.type === 'blank' ? blankAnswerText(q) : q.answer;
    text += `\n答案：${q.answer === '' ? '（空）' : answerText}`;
    return text;
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Text('名称')
              .fontSize(15)
              .width(80)
            TextInput({ text: this.testName })
              .layoutWeight(1)
              .height(40)
              .onChange((value: string) => {
                this.testName = value;
              })
          }
          .width('100%')

          Row() {
            Text('数据起始行')
              .fontSize(15)
              .width(80)
            Select(this.startRowOptions)
              .selected(this.startRow - 1)
              .value(`第${this.startRow}行`)
              .onSelect((index: number) => {
                this.startRow = index + 1;
              })
            Blank()
            Text(`共 ${this.lines.length} 行`)
              .fontSize(13)
              .fontColor($r('app.color.transparent_text'))
          }
          .width('100%')
          .margin({ top: 10 })

          Text('首行通常是表头，此时数据从第 2 行开始；无表头则从第 1 行开始')
            .fontSize(12)
            .fontColor($r('app.color.transparent_text'))
            .width('100%')
            .margin({ top: 4 })

          Divider()
            .margin({ top: 12, bottom: 10 })

          Text('列设置')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 6 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(FIELD_KEYS, (key: number) => {
              Row() {
                Text(FIELD_LABELS[key])
                  .fontSize(14)
                  .width(76)
                Select(this.columnOptions)
                  .selected(this.getFieldValue(key) <= 0 ? 0 : Math.min(this.getFieldValue(key), this.columnOptions.length - 1))
                  .value(this.columnLabel(this.getFieldValue(key)))
                  .onSelect((index: number) => {
                    this.setFieldValue(key, index === 0 ? CSV_UNUSED_COLUMN : index);
                  })
              }
              .width('50%')
              .padding({ top: 4, bottom: 4 })
            }, (key: number) => `field-${key}`)
          }
          .width('100%')

          Text('「题目」与「答案」为必选；题型未指定时将按选项个数与答案格式自动判断')
            .fontSize(12)
            .fontColor($r('app.color.transparent_text'))
            .width('100%')
            .margin({ top: 4 })

          Text('填空题：题干用 ___（三个及以上下划线）表示空；答案多空用「；」分隔、单空多解用「|」分隔；答案也可填选项字母（如 A）引用选项内容')
            .fontSize(12)
            .fontColor($r('app.color.transparent_text'))
            .width('100%')
            .margin({ top: 4 })

          Divider()
            .margin({ top: 12, bottom: 10 })

          Text(`预览（前 ${this.previewRows.length} 行）`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 6 })

          Scroll() {
            Row() {
              Column() {
                Text('行')
                  .width(ROW_NO_WIDTH)
                  .height(HEADER_CELL_HEIGHT)
                  .fontSize(12)
                  .textAlign(TextAlign.Center)
                  .backgroundColor($r('app.color.grid_background'))
                ForEach(this.previewRows, (_row: string[], rowIndex: number) => {
                  Text(String(rowIndex + 1))
                    .width(ROW_NO_WIDTH)
                    .height(CELL_HEIGHT)
                    .fontSize(12)
                    .textAlign(TextAlign.Center)
                    .fontColor(rowIndex + 1 >= this.startRow ? $r('app.color.active_text') : $r('app.color.transparent_text'))
                    .backgroundColor(rowIndex + 1 >= this.startRow ? $r('app.color.list_item_count_background') : Color.Transparent)
                }, (_row: string[], rowIndex: number) => `rowno-${rowIndex}`)
              }

              ForEach(this.columnIndices, (column: number) => {
                Column() {
                  Column() {
                    Text(`第${column}列`)
                      .fontSize(12)
                      .textAlign(TextAlign.Center)
                    if (this.mappedLabelOfColumn(column) !== '') {
                      Text(this.mappedLabelOfColumn(column))
                        .fontSize(11)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.active_text'))
                        .textAlign(TextAlign.Center)
                    }
                  }
                  .width(COLUMN_WIDTH)
                  .height(HEADER_CELL_HEIGHT)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor($r('app.color.grid_background'))

                  ForEach(this.previewRows, (row: string[], rowIndex: number) => {
                    Text(column <= row.length ? row[column - 1] : '')
                      .width(COLUMN_WIDTH)
                      .height(CELL_HEIGHT)
                      .fontSize(12)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .padding({ left: 6, right: 6 })
                      .backgroundColor(rowIndex + 1 >= this.startRow ? $r('app.color.list_item_count_background') : Color.Transparent)
                  }, (row: string[], rowIndex: number) => `col-${column}-row-${rowIndex}`)
                }
              }, (column: number) => `column-${column}`)
            }
            .alignItems(VerticalAlign.Top)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Auto)
          .width('100%')
          .borderRadius(12)
          .backgroundColor($r('app.color.grid_background'))
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .padding(6)

          Text('示例解析（起始行第一条数据）')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 12, bottom: 6 })

          Text(this.sampleText())
            .fontSize(13)
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .padding(10)
            .borderRadius(12)
            .backgroundColor($r('app.color.grid_background'))
            .backgroundBlurStyle(BackgroundImage.blurLevel)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Auto)

      if (!this.mappingValid()) {
        Text('需至少指定「题目」和「答案」两列才能导入')
          .fontSize(12)
          .fontColor($r('app.color.red'))
          .width('100%')
          .margin({ top: 8 })
      }

      Row() {
        Button('取消')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .width('50%')
          .onClick(() => {
            this.onCancel();
          })

        Button('导入')
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .width('50%')
          .enabled(this.mappingValid())
          .onClick(() => {
            const name = this.testName.trim() === '' ? 'test' : this.testName.trim();
            this.onConfirm(name, this.buildConfig());
          })
      }
      .margin({ top: 10, bottom: 6 })
      .width('100%')
    }
    .padding({
      top: 4,
      left: 16,
      right: 16,
      bottom: 8
    })
    .width('100%')
    .height('100%')
  }
}
