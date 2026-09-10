/**
 * 做题记录（session）模块：依托题库产生和管理练习记录。
 * 一个 session 通过 questionNO 持有选题出的题库题号子集（可以是全部或部分题号），
 * 作答与进度即时写盘（写穿），因此无需手动保存；session 数据存放在所属题库的目录内，
 * 题库被删除时记录一并丢失（见 QuestionBankManager.removeBank）。
 * 题目内容一律通过 QuestionBankManager 读取，本模块不持久化题目。
 * 收藏本采用题库级持久化计数器（StarredCounters.json）：每个题号记录当前
 * 收藏它的 session 数，收藏/取消/删除记录时增量维护，避免每次汇总全量遍历。
 */
import {
  BasicDir,
  SessionFileName,
  StarredFileName,
  singleQuestion,
  answerMark,
  answerRecord,
  answerSession,
  sessionSummary,
  questionStatus,
  AnswerStatus,
  PracticeMode,
  SessionOrigin,
  starredCounter
} from './constants';
import { bankStore } from './QuestionBankManager';
import { judgeBlankAnswer, BLANK_JOINER } from './BlankJudge';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

function ensureDir(bankId: string): void {
  const dirPath = BasicDir + bankId + '/';
  if (!fileIo.accessSync(dirPath)) {
    fileIo.mkdirSync(dirPath, true);
  }
}

/**
 * 兼容旧版本落盘数据：补齐新增的 bankId/origin/createdAt 等字段，
 * 旧记录按"全部题号"的练习对待；下次写盘时自动转为新格式。
 */
function normalizeSession(raw: answerSession, bankId: string): answerSession {
  return {
    sessionId: raw.sessionId,
    bankId: raw.bankId !== undefined ? raw.bankId : bankId,
    origin: raw.origin !== undefined ? raw.origin : 'full',
    mode: raw.mode !== undefined ? raw.mode : 'ordered',
    createdAt: raw.createdAt !== undefined ? raw.createdAt : (raw.lastAnswerTime || 0),
    lastAnswerTime: raw.lastAnswerTime !== undefined ? raw.lastAnswerTime : 0,
    questionNO: raw.questionNO !== undefined ? raw.questionNO : [],
    answers: raw.answers !== undefined ? raw.answers : [],
    currentIndex: raw.currentIndex !== undefined ? raw.currentIndex : 0,
    marks: raw.marks !== undefined ? raw.marks : []
  };
}

function readSessionsFromDisk(bankId: string): answerSession[] {
  const filePath = BasicDir + bankId + '/' + SessionFileName;
  try {
    const text = fileIo.readTextSync(filePath);
    const rawList = JSON.parse(text) as answerSession[];
    const result: answerSession[] = [];
    for (let i = 0; i < rawList.length; i++) {
      result.push(normalizeSession(rawList[i], bankId));
    }
    return result;
  } catch (e) {
    return [];
  }
}

function buildShuffledOrder(count: number): number[] {
  const pool: number[] = [];
  for (let i = 0; i < count; i++) {
    pool.push(i);
  }
  const order: number[] = [];
  while (pool.length > 0) {
    const rand = Math.floor(Math.random() * pool.length);
    order.push(pool[rand]);
    pool.splice(rand, 1);
  }
  return order;
}

/** 校验题号子集：去重并过滤掉越界的题号，得到合法题号列表 */
function normalizeQuestionNO(questionNO: number[], bankCount: number): number[] {
  const seen: Set<number> = new Set();
  const result: number[] = [];
  for (let i = 0; i < questionNO.length; i++) {
    const no = questionNO[i];
    if (no >= 0 && no < bankCount && !seen.has(no)) {
      seen.add(no);
      result.push(no);
    }
  }
  return result;
}

class AnswerSessionStore {
  private sessions: Map<string, answerSession[]> = new Map();
  /** 题库级收藏计数缓存：bankId -> (questionIndex -> 收藏它的 session 数) */
  private starred: Map<string, Map<number, number>> = new Map();

  private ensureLoaded(bankId: string): void {
    if (!this.sessions.has(bankId)) {
      this.sessions.set(bankId, readSessionsFromDisk(bankId));
    }
  }

  /** 每次变更后立即落盘，保证中途退出不丢数据 */
  private persist(bankId: string): void {
    const list = this.sessions.get(bankId);
    if (list === undefined) {
      return;
    }
    ensureDir(bankId);
    const filePath = BasicDir + bankId + '/' + SessionFileName;
    const file = fileIo.openSync(filePath,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(list));
    fileIo.closeSync(file);
  }

  private ensureStarredLoaded(bankId: string): void {
    if (this.starred.has(bankId)) {
      return;
    }
    const map: Map<number, number> = new Map();
    try {
      const text = fileIo.readTextSync(BasicDir + bankId + '/' + StarredFileName);
      const list = JSON.parse(text) as starredCounter[];
      for (let i = 0; i < list.length; i++) {
        map.set(list[i].questionIndex, list[i].count);
      }
    } catch (e) {
      // 文件不存在时从空计数开始
    }
    this.starred.set(bankId, map);
  }

  private persistStarred(bankId: string): void {
    const map = this.starred.get(bankId);
    if (map === undefined) {
      return;
    }
    ensureDir(bankId);
    const list: starredCounter[] = [];
    map.forEach((count: number, no: number): void => {
      list.push({ questionIndex: no, count: count });
    });
    list.sort((a: starredCounter, b: starredCounter): number => a.questionIndex - b.questionIndex);
    const filePath = BasicDir + bankId + '/' + StarredFileName;
    const file = fileIo.openSync(filePath,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, JSON.stringify(list));
    fileIo.closeSync(file);
  }

  /** 收藏计数增减（不落盘，由调用方随 session 变更一并 persistStarred）：归零即移出收藏本 */
  private adjustStar(bankId: string, questionIndex: number, delta: number): void {
    this.ensureStarredLoaded(bankId);
    const map = this.starred.get(bankId)!;
    const next = (map.get(questionIndex) || 0) + delta;
    if (next <= 0) {
      map.delete(questionIndex);
    } else {
      map.set(questionIndex, next);
    }
  }

  private newSession(bankId: string, origin: SessionOrigin, mode: PracticeMode,
    questionNO: number[]): answerSession {
    const marks: answerMark[] = [];
    const bankCount = bankStore.getQuestionCount(bankId);
    for (let i = 0; i < bankCount; i++) {
      marks.push({ starred: false, ignore: false });
    }
    return {
      sessionId: util.generateRandomUUID(),
      bankId: bankId,
      origin: origin,
      mode: mode,
      createdAt: Date.now(),
      lastAnswerTime: 0,
      questionNO: questionNO,
      answers: [],
      currentIndex: 0,
      marks: marks
    };
  }

  /** 核心：以给定的题号子集创建一次练习，返回 sessionId；题号为空时返回 '' */
  createSession(bankId: string, mode: PracticeMode, origin: SessionOrigin,
    questionNO: number[]): string {
    const bankCount = bankStore.getQuestionCount(bankId);
    if (bankCount === 0) {
      return '';
    }
    const nos = normalizeQuestionNO(questionNO, bankCount);
    if (nos.length === 0) {
      return '';
    }

    this.ensureLoaded(bankId);
    const list = this.sessions.get(bankId)!;
    const session = this.newSession(bankId, origin, mode, nos);
    if (mode === 'random') {
      session.questionNO = buildShuffledOrder(nos.length).map((i: number): number => nos[i]);
    }
    list.push(session);
    this.persist(bankId);
    return session.sessionId;
  }

  /** 全部题号练习 */
  createFullSession(bankId: string, mode: PracticeMode): string {
    const bankCount = bankStore.getQuestionCount(bankId);
    const all: number[] = [];
    for (let i = 0; i < bankCount; i++) {
      all.push(i);
    }
    return this.createSession(bankId, mode, 'full', all);
  }

  /**
   * 错题重做（为后续错题本功能预留 starred 维度）：从某次记录中收集做错的题
   * （以第一次作答为准，第一次答错即计为错题，重试做对也不改变），
   * 可选附加收藏题，生成一次部分题号的新练习。
   */
  createRetrySession(bankId: string, sourceSessionId: string,
    includeStarred: boolean): string {
    const source = this.getSession(bankId, sourceSessionId);
    if (source === null) {
      return '';
    }
    const firstAnswer = this.firstAnswerMap(source);
    const targets: number[] = [];
    for (let i = 0; i < source.questionNO.length; i++) {
      const no = source.questionNO[i];
      const record = firstAnswer.get(no);
      const starred = source.marks[no] !== undefined && source.marks[no].starred;
      if ((record !== undefined && !record.isCorrect) || (includeStarred && starred)) {
        targets.push(no);
      }
    }
    if (targets.length === 0) {
      return '';
    }
    return this.createSession(bankId, 'ordered', 'retry', targets);
  }

  /** 题库级收藏本：当前被任一 session 收藏的题号（升序），直接读持久化计数器的键集合 */
  starredQuestionNos(bankId: string): number[] {
    this.ensureStarredLoaded(bankId);
    const result: number[] = [];
    this.starred.get(bankId)!.forEach((_count: number, no: number): void => {
      result.push(no);
    });
    result.sort((a: number, b: number): number => a - b);
    return result;
  }

  /** 收藏题专项练习：以题库级收藏本中的题号生成一次新练习，返回 sessionId；无收藏时返回 ''。
   *  新练习不播种收藏标记（收藏计数只由真实收藏操作与删除记录驱动），避免反复生成练习使计数膨胀 */
  createStarredSession(bankId: string): string {
    const nos = this.starredQuestionNos(bankId);
    if (nos.length === 0) {
      return '';
    }
    return this.createSession(bankId, 'ordered', 'custom', nos);
  }

  getSession(bankId: string, sessionId: string): answerSession | null {
    this.ensureLoaded(bankId);
    const list = this.sessions.get(bankId)!;
    for (let i = 0; i < list.length; i++) {
      if (list[i].sessionId === sessionId) {
        return list[i];
      }
    }
    return null;
  }

  listSessions(bankId: string): answerSession[] {
    this.ensureLoaded(bankId);
    return this.sessions.get(bankId)!;
  }

  /** 记录当前题的作答；答对推进到下一题，答错留在原题可重试（同一题以最后一次作答为准），返回是否答对 */
  submitAnswer(bankId: string, sessionId: string, userAnswer: string): boolean {
    const session = this.getSession(bankId, sessionId);
    if (session === null || session.currentIndex >= session.questionNO.length) {
      return false;
    }
    const questions = bankStore.getQuestions(bankId);
    const qIndex = session.questionNO[session.currentIndex];
    if (qIndex < 0 || qIndex >= questions.length) {
      return false;
    }

    const question = questions[qIndex];
    let isCorrect: boolean;
    if (question.type === 'blank') {
      // 填空题各空输入以「；」拼接提交，逐空判定
      isCorrect = judgeBlankAnswer(question, userAnswer.split(BLANK_JOINER)).isCorrect;
    } else {
      isCorrect = userAnswer.trim().toUpperCase() === question.answer.trim().toUpperCase();
    }

    session.answers.push({
      questionIndex: qIndex,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      timestamp: Date.now()
    });
    if (isCorrect) {
      session.currentIndex = Math.min(session.currentIndex + 1, session.questionNO.length);
    }
    session.lastAnswerTime = Date.now();
    this.persist(bankId);
    return isCorrect;
  }

  /** 手动导航（上一题/下一题/回退），越界时收缩到合法范围 */
  jumpTo(bankId: string, sessionId: string, targetIndex: number): singleQuestion | null {
    const session = this.getSession(bankId, sessionId);
    if (session === null || session.questionNO.length === 0) {
      return null;
    }
    const clamped = Math.max(0, Math.min(targetIndex, session.questionNO.length - 1));
    if (clamped !== session.currentIndex) {
      session.currentIndex = clamped;
      this.persist(bankId);
    }
    return this.getCurrentQuestion(bankId, sessionId);
  }

  getCurrentQuestion(bankId: string, sessionId: string): singleQuestion | null {
    const session = this.getSession(bankId, sessionId);
    if (session === null || session.currentIndex >= session.questionNO.length) {
      return null;
    }
    const questions = bankStore.getQuestions(bankId);
    const qIndex = session.questionNO[session.currentIndex];
    if (qIndex < 0 || qIndex >= questions.length) {
      return null;
    }
    return questions[qIndex];
  }

  toggleStar(bankId: string, sessionId: string, questionIndex: number): void {
    const session = this.getSession(bankId, sessionId);
    if (session === null || questionIndex < 0 || questionIndex >= session.marks.length) {
      return;
    }
    session.marks[questionIndex].starred = !session.marks[questionIndex].starred;
    // 同步维护题库级收藏计数，并随 session 一起写盘
    this.adjustStar(bankId, questionIndex, session.marks[questionIndex].starred ? 1 : -1);
    this.persist(bankId);
    this.persistStarred(bankId);
  }

  /** 当前作答位置题目的收藏状态；无有效作答位置时为 false */
  currentStarred(bankId: string, sessionId: string): boolean {
    const session = this.getSession(bankId, sessionId);
    if (session === null || session.currentIndex >= session.questionNO.length) {
      return false;
    }
    const qIndex = session.questionNO[session.currentIndex];
    return session.marks[qIndex] !== undefined && session.marks[qIndex].starred;
  }

  /** 收藏/取消收藏当前作答位置的题目，返回操作后的收藏状态 */
  toggleCurrentStar(bankId: string, sessionId: string): boolean {
    const session = this.getSession(bankId, sessionId);
    if (session === null || session.currentIndex >= session.questionNO.length) {
      return false;
    }
    const qIndex = session.questionNO[session.currentIndex];
    this.toggleStar(bankId, sessionId, qIndex);
    return session.marks[qIndex] !== undefined && session.marks[qIndex].starred;
  }

  deleteSession(bankId: string, sessionId: string): void {
    this.ensureLoaded(bankId);
    const list = this.sessions.get(bankId)!;
    for (let i = 0; i < list.length; i++) {
      if (list[i].sessionId === sessionId) {
        const session = list[i];
        // 该记录中被收藏的题计数减一，可能使部分题移出收藏本
        let starredChanged = false;
        for (let j = 0; j < session.questionNO.length; j++) {
          const no = session.questionNO[j];
          if (session.marks[no] !== undefined && session.marks[no].starred) {
            this.adjustStar(bankId, no, -1);
            starredChanged = true;
          }
        }
        list.splice(i, 1);
        this.persist(bankId);
        if (starredChanged) {
          this.persistStarred(bankId);
        }
        return;
      }
    }
  }

  isFinished(bankId: string, sessionId: string): boolean {
    const session = this.getSession(bankId, sessionId);
    if (session === null) {
      return true;
    }
    return session.currentIndex >= session.questionNO.length;
  }

  /** 每题的首次作答记录：第一次答对/答错即定型，后续重试不改变判定 */
  private firstAnswerMap(session: answerSession): Map<number, answerRecord> {
    const firstAnswer: Map<number, answerRecord> = new Map();
    for (let i = 0; i < session.answers.length; i++) {
      const record = session.answers[i];
      if (!firstAnswer.has(record.questionIndex)) {
        firstAnswer.set(record.questionIndex, record);
      }
    }
    return firstAnswer;
  }

  getProgress(bankId: string, sessionId: string): sessionSummary {
    const session = this.getSession(bankId, sessionId);
    if (session === null) {
      return {
        sessionId: sessionId, bankId: bankId, origin: 'full', mode: 'ordered',
        createdAt: 0, lastAnswerTime: 0, total: 0, answered: 0, correct: 0,
        wrong: 0, finished: true, position: 0
      };
    }
    const firstAnswer = this.firstAnswerMap(session);
    let correct = 0;
    firstAnswer.forEach((record: answerRecord): void => {
      if (record.isCorrect) {
        correct++;
      }
    });
    return {
      sessionId: session.sessionId,
      bankId: session.bankId,
      origin: session.origin,
      mode: session.mode,
      createdAt: session.createdAt,
      lastAnswerTime: session.lastAnswerTime,
      total: session.questionNO.length,
      answered: firstAnswer.size,
      correct: correct,
      wrong: firstAnswer.size - correct,
      finished: session.currentIndex >= session.questionNO.length,
      position: session.currentIndex
    };
  }

  getSummaries(bankId: string): sessionSummary[] {
    this.ensureLoaded(bankId);
    const list = this.sessions.get(bankId)!;
    const summaries: sessionSummary[] = [];
    for (let i = 0; i < list.length; i++) {
      summaries.push(this.getProgress(bankId, list[i].sessionId));
    }
    // 最近练习的记录排在前面
    summaries.sort((a: sessionSummary, b: sessionSummary): number => {
      return (b.lastAnswerTime || b.createdAt) - (a.lastAnswerTime || a.createdAt);
    });
    return summaries;
  }

  /** session 视角下每道题的状态（以第一次作答为准：第一次答错即计为错题） */
  getQuestionStatus(bankId: string, sessionId: string): questionStatus[] {
    const session = this.getSession(bankId, sessionId);
    if (session === null) {
      return [];
    }
    const firstAnswer = this.firstAnswerMap(session);
    const result: questionStatus[] = [];
    for (let pos = 0; pos < session.questionNO.length; pos++) {
      const qIndex = session.questionNO[pos];
      const record = firstAnswer.get(qIndex);
      const status: AnswerStatus = record === undefined ? 'unanswered'
        : (record.isCorrect ? 'correct' : 'wrong');
      result.push({
        questionIndex: qIndex,
        position: pos,
        status: status,
        starred: session.marks[qIndex] !== undefined && session.marks[qIndex].starred,
        userAnswer: record === undefined ? undefined : record.userAnswer
      });
    }
    return result;
  }

  /** 题库被删除时丢弃其内存中的 session 与收藏计数缓存 */
  forget(bankId: string): void {
    this.sessions.delete(bankId);
    this.starred.delete(bankId);
  }
}

export const answerStore = new AnswerSessionStore();
