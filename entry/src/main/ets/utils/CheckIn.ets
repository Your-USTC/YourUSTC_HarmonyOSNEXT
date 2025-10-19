import { preferences } from '@kit.ArkData';

export class CheckInTools {
  static PREF_NAME = 'check_in_data';
  static LAST_DAY_KEY = 'lastDay';
  static TOTAL_DAYS_KEY = 'totalDays';
  static CONSECUTIVE_DAYS_KEY = 'consecutiveDays';
  private static CHECK_IN_CONTENT_LIST: string[] = [
    '加油数学竞赛生，你拼命的样子真美！', // TODO: Replace with meaningful content
    '把头发扎起来，兜里放几个薄荷糖',
    '不搞暖昧，上课认真',
    '多做一道题，老婆会升级！'
  ];
  private static millisecondsInADay = 86400000;
  private static defaultTimestamp = 1000000000; // 用于没有签到记录时的Unix时间戳

  static getTodayDate(): number { // 保留年、月、日，忽略时、分、秒
    const date = new Date();
    const normalizedDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    return normalizedDate.getTime();
  }
  static timeSinceLastCheckIn(pref: preferences.Preferences | null): number {
    if (pref!== null) {
      const previousTime = pref.getSync(CheckInTools.LAST_DAY_KEY, CheckInTools.defaultTimestamp) as number;
      const currentTime = CheckInTools.getTodayDate();
      return currentTime - previousTime;
    }
    return -1;
  }
  static getRandomContent(): string {
    return CheckInTools.CHECK_IN_CONTENT_LIST[Math.floor(Math.random() * CheckInTools.CHECK_IN_CONTENT_LIST.length)];
  }

  static doCheckIn(pref: preferences.Preferences | null): [number, number, string] {
    if (pref !== null) {

      // 签到次数加1，判断是否连续
      const newTotal = pref.getSync(CheckInTools.TOTAL_DAYS_KEY, 0) as number + 1;
      let newConsecutive = pref.getSync(CheckInTools.CONSECUTIVE_DAYS_KEY, 0) as number;
      if (CheckInTools.timeSinceLastCheckIn(pref) === CheckInTools.millisecondsInADay) {
        newConsecutive += 1;
      } else {
        newConsecutive = 1;
      }

      // 写入首选项并落盘
      pref.putSync(CheckInTools.LAST_DAY_KEY, CheckInTools.getTodayDate());
      pref.putSync(CheckInTools.TOTAL_DAYS_KEY, newTotal);
      pref.putSync(CheckInTools.CONSECUTIVE_DAYS_KEY, newConsecutive);
      pref.flushSync();

      return [newTotal, newConsecutive, CheckInTools.getRandomContent()];
    }
    return [0, 0, ''];
  }
}