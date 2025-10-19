import { preferences } from '@kit.ArkData';

export class CheckInTools {
  static PREF_NAME = 'check_in_data';
  static LAST_DAY_KEY = 'lastDay';
  static TOTAL_DAYS_KEY = 'totalDays'
  private static CHECK_IN_CONTENT_LIST: string[] = [
    '加油数学竞赛生，你拼命的样子真美！', // TODO: Replace with meaningful content
    '把头发扎起来，兜里放几个薄荷糖',
    '不搞暖昧，上课认真',
    '多做一道题，老婆会升级！'
  ];

  static getTodayDate(): number {
    const date = new Date();
    const normalizedDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    return normalizedDate.getTime();
  }
  static getRandomContent(): string {
    return CheckInTools.CHECK_IN_CONTENT_LIST[Math.floor(Math.random() * CheckInTools.CHECK_IN_CONTENT_LIST.length)];
  }

  static doCheckIn(pref: preferences.Preferences | null): [number, string] {
    if (pref !== null) {
      const newTotal = pref.getSync(CheckInTools.TOTAL_DAYS_KEY, 0) as number + 1;
      pref.putSync(CheckInTools.LAST_DAY_KEY, CheckInTools.getTodayDate());
      pref.putSync(CheckInTools.TOTAL_DAYS_KEY, newTotal);
      pref.flushSync();
      return [newTotal, CheckInTools.getRandomContent()];
    }
    return [0, ''];
  }
}