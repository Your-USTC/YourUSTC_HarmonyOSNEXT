
import UnifiedPreferences from '../utils/UnifyPreference';

export interface classAttribute {
  name: string,
  teacher: string,
  weekOfTerm: number[],    // 以枚举形式写出哪几周
  timeSpan: number[],      // 应当仅包含开始和结束是第几节课
  dayOfWeek: number,
  location: string,
  id: string,
  color: string
}

export interface obtainedData {
  timeTable: string;
  startTime: string;
}

export let remindBefore: number[] = [];
export let examRemindBefore: number[] = [];

export function initSchedulePre() {
  remindBefore[0] = UnifiedPreferences.getNumberSync('remindBefore', 0) as number;
  if (remindBefore[0] == -1)
    remindBefore = [];
  examRemindBefore[0] = UnifiedPreferences.getNumberSync('examRemindBefore', 0) as number;
  if (examRemindBefore[0] == -1)
    examRemindBefore = [];
}

export function setRemindBefore(minute: number) {
  if (minute == -1)
    remindBefore = [];
  else
    remindBefore[0] = minute;
  UnifiedPreferences.putSync('remindBefore', minute);
}

export function setExamRemindBefore(minute: number) {
  if (minute == -1)
    examRemindBefore = [];
  else
    examRemindBefore[0] = minute;
  UnifiedPreferences.putSync('examRemindBefore', minute);
}

// 第几节课 -> 上课时间
export const commonClassTime: string[][] = [
  ['07:21', '11:45'],    // 排除[0]
  ['07:50', '08:35'], ['08:40', '09:25'], ['09:45', '10:30'], ['10:35', '11:20'], ['11:25', '12:10'],    // 上午
  ['14:00', '14:45'], ['14:50', '15:35'], ['15:55', '16:40'], ['16:45', '17:30'], ['17:35', '18:20'],    // 下午
  ['19:30', '20:15'], ['20:20', '21:05'], ['21:10', '21:55']    // 晚上
];

export const commonClassStamp: number[][]= [
  [26460000, 42300000],
  [28200000, 30900000], [31200000, 33900000], [35100000, 37800000], [38100000, 40800000], [41000000, 43800000],
  [50400000, 53100000], [53400000, 56100000], [57300000, 60000000], [60300000, 63000000], [63300000, 66000000],
  [70200000, 72900000], [73200000, 75900000], [76200000, 78900000]
];