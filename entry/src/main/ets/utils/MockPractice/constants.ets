/**
 * MockPractice 模块类型定义，分为两个模块：
 * 1. 题库（QuestionBank）：由 CSV 导入的一套题目，是作答数据的唯一来源；
 * 2. 做题记录（AnswerSession）：依托某个题库产生的一次练习（可只选题库中的部分题号），
 *    持久化在题库目录内部——删除题库时，其做题记录随之一并丢失。
 */

// ==================== 题库模块 ====================

export const BasicDir = '/data/storage/el2/base/files/MockPractice/';
export const BankAttributeFileName = 'Attributes.json';
export const QuestionFileName = 'QuestionList.json';
/** 做题记录文件，存放在所属题库的目录内，随题库一起删除 */
export const SessionFileName = 'AnswerRounds.json';
/** 收藏题计数文件：记录每个题号被多少个 session 收藏，同样随题库一起删除 */
export const StarredFileName = 'StarredCounters.json';

/**
 * 目录结构：
 * - MockPractice
 *   - bankUuid1
 *     - Attributes.json   // 题库基本属性
 *     - QuestionList.json // 题目列表
 *     - AnswerRounds.json // 该题库下的做题记录（session 列表）
 *     - StarredCounters.json // 收藏题计数（题库级收藏本）
 *   - bankUuid2
 */

export interface bankAttribute {
  uuid: string,
  name: string,
  createTime: number,
  lastOpenTime: number
}

export interface bankAttributeUpdate {
  name?: string,
  createTime?: number,
  lastOpenTime?: number
}

export type QuestionType = 'single' | 'multiple' | 'blank'

/** 题库中的一道题。作答状态（收藏等）记录在 session 中，不属于题目本身 */
export interface singleQuestion {
  section?: string,
  context: string,
  type: QuestionType,
  answer: string,
  analysis?: string,
  difficulty?: string,
  knowledgePoint?: string,
  optionCount: number,
  options: string[]
}

/** 表示 CSV 导入时某一列不参与映射 */
export const CSV_UNUSED_COLUMN: number = -1;

/**
 * CSV 各列的语义映射，取值为从 1 开始的列号，CSV_UNUSED_COLUMN 表示不使用。
 * optionStart 为第一道选项（如"选项A"）所在列，选项按其后的连续列依次读取。
 */
export interface csvColumnMapping {
  section: number,
  type: number,
  context: number,
  answer: number,
  analysis: number,
  difficulty: number,
  knowledgePoint: number,
  optionCount: number,
  optionStart: number
}

export interface csvImportConfig {
  /** 第一条数据所在行（从 1 开始计数） */
  startRow: number,
  columns: csvColumnMapping
}

// ==================== 做题记录（session）模块 ====================

/** 题目作答顺序：顺序 / 随机打乱 */
export type PracticeMode = 'ordered' | 'random'

/** 选题来源：全部题号 / 部分题号（自定义或随机抽取）/ 错题重做 */
export type SessionOrigin = 'full' | 'custom' | 'retry'

/** session 内对单题的标记（为后续错题本等能力预留） */
export interface answerMark {
  starred: boolean,
  ignore: boolean
}

/** 收藏题计数项：questionIndex 当前被多少个 session 收藏（count 归零即移出收藏本） */
export interface starredCounter {
  questionIndex: number,
  count: number
}

/** 一次作答记录；questionIndex 为题库中的题号（从 0 开始） */
export interface answerRecord {
  questionIndex: number,
  userAnswer: string,
  isCorrect: boolean,
  timestamp: number
}

/** 一次练习：questionNO 是选题出的题库题号列表（子集），answers 记录每次作答 */
export interface answerSession {
  sessionId: string,
  bankId: string,
  origin: SessionOrigin,
  mode: PracticeMode,
  createdAt: number,
  lastAnswerTime: number,
  /** 本次练习覆盖的题库题号（索引从 0 开始），允许是题库的任意子集 */
  questionNO: number[],
  answers: answerRecord[],
  /** 下一个待作答位置（questionNO 的下标）；等于 questionNO.length 表示已完成 */
  currentIndex: number,
  marks: answerMark[]
}

export interface sessionSummary {
  sessionId: string,
  bankId: string,
  origin: SessionOrigin,
  mode: PracticeMode,
  createdAt: number,
  lastAnswerTime: number,
  total: number,
  answered: number,
  correct: number,
  wrong: number,
  finished: boolean,
  /** 当前作答位置（questionNO 的下标，从 0 开始） */
  position: number
}

export type AnswerStatus = 'correct' | 'wrong' | 'unanswered'

/** session 视角下某道题的状态；questionIndex 为题库题号 */
export interface questionStatus {
  questionIndex: number,
  position: number,
  status: AnswerStatus,
  starred: boolean,
  userAnswer?: string
}

/** 页面间导航参数 */
export interface bankNavParam {
  bankId: string,
  bankName: string
}

export interface sessionNavParam extends bankNavParam {
  sessionId: string
}
