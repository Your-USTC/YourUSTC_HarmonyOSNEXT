/**
 * 填空题判定工具。CSV 数据约定：
 * - 题干中以连续 3 个及以上下划线（___）表示一个空，出现几处即有几空，未出现时按 1 空处理；
 * - 多空时答案列按「；」「;」「|」「｜」分段，与各空一一对应（分段数须等于空数）；
 * - 单空时答案列可用「|」「｜」分隔多个可接受答案，命中其一即算对；
 * - 沿用旧格式约定：答案分段可以是选项字母（如 A），表示取对应选项的内容作为该空答案，
 *   判定时选项内容与字母本身都可命中，展示时一律替换为选项内容；
 * - 判定不区分大小写与首尾空格。
 * 答题页将各空输入以「；」拼接后作为 userAnswer 提交，本模块负责拆分与逐空判定。
 */
import { singleQuestion } from './constants';

/** 填空题逐空判定结果 */
export interface blankJudgeResult {
  /** 每个空是否正确，按空序排列，长度等于空数 */
  perBlank: boolean[],
  /** 全部空都正确时为 true */
  isCorrect: boolean
}

/** 多空答案的分段分隔符：分号或竖线 */
const SEGMENT_PATTERN: RegExp = /[|｜；;]/;
/** 单空可接受答案的分隔符：仅竖线 */
const VARIANT_PATTERN: RegExp = /[|｜]/;
/** 选项字母引用：单个字母 */
const LETTER_REF_PATTERN: RegExp = /^[A-Za-z]$/;
/** 页面提交多空作答时的拼接符，判定时按其拆分 */
export const BLANK_JOINER: string = '；';

/** 统计题干中的空数（连续 3 个及以上下划线记一空），至少为 1 */
export function blankCountOf(context: string): number {
  let count = 0;
  let run = 0;
  for (let i = 0; i < context.length; i++) {
    if (context.charAt(i) === '_') {
      run++;
    } else {
      if (run >= 3) {
        count++;
      }
      run = 0;
    }
  }
  if (run >= 3) {
    count++;
  }
  return count > 0 ? count : 1;
}

/** 判定用归一化：去首尾空格、转大写、连续空白折叠为单个空格 */
function normalizeBlankText(text: string): string {
  return text.trim().toUpperCase().replace(/\s+/g, ' ');
}

function splitAnswer(answer: string, pattern: RegExp): string[] {
  const parts = answer.split(pattern);
  const result: string[] = [];
  for (let i = 0; i < parts.length; i++) {
    const seg = parts[i].trim();
    if (seg !== '') {
      result.push(seg);
    }
  }
  return result;
}

/** 分段若是选项字母引用则返回选项下标，否则返回 -1 */
function optionRefIndex(seg: string, options: string[]): number {
  if (options.length === 0 || !LETTER_REF_PATTERN.test(seg)) {
    return -1;
  }
  const index = seg.toUpperCase().charCodeAt(0) - 65;
  if (index < 0 || index >= options.length || options[index].trim() === '') {
    return -1;
  }
  return index;
}

/** 某个答案分段的可接受值（已归一化）：分段本身，以及选项字母引用对应的选项内容 */
function acceptedTexts(seg: string, options: string[]): string[] {
  const result: string[] = [];
  const self = normalizeBlankText(seg);
  if (self !== '') {
    result.push(self);
  }
  const ref = optionRefIndex(seg, options);
  if (ref >= 0) {
    const content = normalizeBlankText(options[ref]);
    if (!result.includes(content)) {
      result.push(content);
    }
  }
  return result;
}

/** 某空的归一化输入是否命中其答案分段的任一可接受值 */
function matchesAccepted(input: string, seg: string, options: string[]): boolean {
  const accepted = acceptedTexts(seg, options);
  for (let i = 0; i < accepted.length; i++) {
    if (input === accepted[i]) {
      return true;
    }
  }
  return false;
}

/**
 * 逐空判定用户输入：
 * - 只有一个空时，竖线分隔的各段为可接受答案，命中其一即对；
 * - 空数大于 1 且答案分段数与空数一致时逐空比对；
 * - 其余情况退化为整串比对（各空输入以「；」拼接后与答案整体比对）。
 */
export function judgeBlankAnswer(question: singleQuestion, inputs: string[]): blankJudgeResult {
  const answer = question.answer;
  const options = question.options;
  const count = blankCountOf(question.context);
  const perBlank: boolean[] = [];
  const normalizedInputs: string[] = [];
  for (let i = 0; i < count; i++) {
    perBlank.push(false);
    let input = '';
    if (i < inputs.length) {
      input = inputs[i];
    }
    normalizedInputs.push(normalizeBlankText(input));
  }

  let isCorrect = false;
  if (count === 1) {
    const variants = splitAnswer(answer, VARIANT_PATTERN);
    const expected: string[] = variants.length > 0 ? variants : [answer.trim()];
    for (let i = 0; i < expected.length; i++) {
      if (matchesAccepted(normalizedInputs[0], expected[i], options)) {
        isCorrect = true;
        break;
      }
    }
    perBlank[0] = isCorrect;
  } else {
    const segments = splitAnswer(answer, SEGMENT_PATTERN);
    if (segments.length === count) {
      isCorrect = true;
      for (let i = 0; i < count; i++) {
        perBlank[i] = matchesAccepted(normalizedInputs[i], segments[i], options);
        if (!perBlank[i]) {
          isCorrect = false;
        }
      }
    } else {
      // 答案分段数与空数不一致：各空输入拼回整串后与答案整体比对
      let joined = '';
      for (let i = 0; i < count; i++) {
        if (i > 0) {
          joined += BLANK_JOINER;
        }
        if (i < inputs.length) {
          joined += inputs[i].trim();
        }
      }
      const normalizedJoined = normalizeBlankText(joined);
      isCorrect = acceptedTexts(answer.trim(), options).includes(normalizedJoined);
      for (let i = 0; i < count; i++) {
        perBlank[i] = isCorrect;
      }
    }
  }
  return { perBlank: perBlank, isCorrect: isCorrect };
}

function displaySegment(seg: string, options: string[]): string {
  const ref = optionRefIndex(seg.trim(), options);
  return ref >= 0 ? options[ref] : seg;
}

/** 填空题答案的展示文本：选项字母引用的分段替换为对应选项内容，其余原样保留 */
export function blankAnswerText(question: singleQuestion): string {
  const options = question.options;
  if (options.length === 0) {
    return question.answer;
  }
  const answer = question.answer;
  let result = '';
  let seg = '';
  for (let i = 0; i < answer.length; i++) {
    const ch = answer.charAt(i);
    if (SEGMENT_PATTERN.test(ch)) {
      result += displaySegment(seg, options) + ch;
      seg = '';
    } else {
      seg += ch;
    }
  }
  result += displaySegment(seg, options);
  return result;
}
