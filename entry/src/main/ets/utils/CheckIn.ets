
import UnifiedPreferences from '../utils/UnifyPreference';
import { LAST_DAY_KEY, TOTAL_DAYS_KEY, CONSECUTIVE_DAYS_KEY, CONTENT_KEY } from '../utils/UnifyPreference';

export class CheckInTools {
  private static CHECK_IN_CONTENT_LIST: string[] = [
    '加油数学竞赛生，\n你拼命的样子真美！', // TODO: Replace with meaningful content
    '把头发扎起来，\n兜里放几个薄荷糖',
    '不搞暖昧，上课认真',
    '多做一道题，老婆会升级！'
  ];
  private static millisecondsInADay = 86400000;
  private static defaultTimestamp = '1000000000'; // 用于没有签到记录时的Unix时间戳

  static getTodayDate(): number { // 保留年、月、日，忽略时、分、秒
    const date = new Date();
    const normalizedDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    return normalizedDate.getTime();
  }

  static timeSinceLastCheckIn(): number {
    const previousTime = Number(UnifiedPreferences.getSync(LAST_DAY_KEY, CheckInTools.defaultTimestamp));
    const currentTime = CheckInTools.getTodayDate();
    return currentTime - previousTime;
  }

  static getRandomContent(): string {
    return CheckInTools.CHECK_IN_CONTENT_LIST[Math.floor(Math.random() * CheckInTools.CHECK_IN_CONTENT_LIST.length)];
  }

  static loadCheckInOnStartup(): [number, number, boolean, string] {
    const checkInTotal = Number(UnifiedPreferences.getSync(TOTAL_DAYS_KEY, '0'));
    const timeSinceLastCheckIn = CheckInTools.timeSinceLastCheckIn();
    const checkInConsecutive = timeSinceLastCheckIn <= CheckInTools.millisecondsInADay
      ? Number(UnifiedPreferences.getSync(CONSECUTIVE_DAYS_KEY, '0')) : 0; // 超过1天未签到就把“连续签到”计数归零
    const checkedInToday = timeSinceLastCheckIn === 0;
    const checkInContent = UnifiedPreferences.getSync(CONTENT_KEY, '') as string;
    return [checkInTotal, checkInConsecutive, checkedInToday, checkInContent];
  }

  static doCheckIn(): [number, number, string] {

    // 签到次数加1，判断是否连续
    const newTotal = Number(UnifiedPreferences.getSync(TOTAL_DAYS_KEY, '0')) + 1;
    let newConsecutive = Number(UnifiedPreferences.getSync(CONSECUTIVE_DAYS_KEY, '0'));
    if (CheckInTools.timeSinceLastCheckIn() === CheckInTools.millisecondsInADay) {
      newConsecutive += 1;
    } else {
      newConsecutive = 1;
    }
    const randomContent = CheckInTools.getRandomContent();

    // 写入首选项并落盘
    UnifiedPreferences.putSync(LAST_DAY_KEY, CheckInTools.getTodayDate());
    UnifiedPreferences.putSync(TOTAL_DAYS_KEY, newTotal);
    UnifiedPreferences.putSync(CONSECUTIVE_DAYS_KEY, newConsecutive);
    UnifiedPreferences.putSync(CONTENT_KEY, randomContent);

    return [newTotal, newConsecutive, randomContent];
  }
}
