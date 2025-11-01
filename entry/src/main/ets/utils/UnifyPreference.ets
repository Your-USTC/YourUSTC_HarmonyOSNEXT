
import { preferences } from '@kit.ArkData';
import { classAttribute, obtainedData } from '../pages/Schedule';

export const PREF_NAME = 'unified_preference';

export const LAST_DAY_KEY = 'lastDay';
export const TOTAL_DAYS_KEY = 'totalDays';
export const CONSECUTIVE_DAYS_KEY = 'consecutiveDays';
export const CONTENT_KEY = 'content';

export const SCHEDULE_KEY = 'scheduleInfo';
export const START_TIME_KEY = 'termStartTime';

const millisecondsPerWeek = 604800000;

class UnifiedPreferences {
  weekDisplayed: number = 0;
  termStart: number = 0;
  weekStart: number = 0;
  weekEnd: number = 0;
  parsedSchedule: classAttribute[][][] = [];
  formattedSchedule: classAttribute[][][] = [];

  private preferences: preferences.Preferences | null = null;

  async init(context: Context) {
    if (!this.preferences) {
      const options: preferences.Options = { name: PREF_NAME };
      try {
        this.preferences = preferences.getPreferencesSync(context, options);
      } catch (error) {
        console.error(`getPreferencesSync ERROR: [${error.name}] ${error.message}`);
      }
    }
  }

  putSync(key: string, value: string | number | boolean) {
    try {
      this.preferences?.putSync(key, value);
    } catch (error) {
      console.error(`putSync ERROR: [${error.name}] ${error.message}`);
    }
    this.flush();    // 可选：立即持久化
  }

  getSync(key: string, defaultValue: string = ''): string {
    try {
      return this.preferences?.getSync(key, defaultValue) as string;
    } catch (error) {
      console.error(`getSync ERROR: [${error.name}] ${error.message}`);
      return '';
    }
  }

  hasSync(key: string): boolean {
    try {
      return this.preferences?.hasSync(key) as boolean;
    } catch (error) {
      console.error(`hasSync ERROR: [${error.name}] ${error.message}`);
      return false;
    }
  }

  flush() {
    this.preferences?.flush()
      .catch((error: Error) => {
        console.error(`preferences flush ERROR: [${error.name}] ${error.message}`)
      })
  }

  clear() {
    this.preferences?.clearSync()
  }

  refreshParsedSchedule(routerParams: obtainedData): void {
    const currentTime: Date = new Date();
    try {
      const timeTable = routerParams.timeTable.slice(1, -1).replace(/\\/g, '');
      this.termStart = Number(routerParams.startTime.replace(/[^0-9]/g, ''));
      this.parsedSchedule = JSON.parse(timeTable) as classAttribute[][][];
      this.putSync(SCHEDULE_KEY, timeTable);
      this.putSync(START_TIME_KEY, this.termStart);
      this.weekDisplayed = Math.ceil((currentTime.getTime() - this.termStart) / millisecondsPerWeek);
    } catch (err) {
      this.parsedSchedule = JSON.parse(this.getSync(SCHEDULE_KEY, '[[[]]]'))
      this.weekDisplayed = this.hasSync(START_TIME_KEY)
        ? Math.ceil((currentTime.getTime() - Number(this.getSync(START_TIME_KEY))) / millisecondsPerWeek)
        : 1;
    }
    this.weekStart = this.hasSync(START_TIME_KEY)
      ? Number(this.getSync(START_TIME_KEY)) + (this.weekDisplayed - 1) * millisecondsPerWeek
      : currentTime.getTime();
    this.weekEnd = this.weekStart + 518400000;
  }

  refreshFormattedSchedule(): void {
    this.formattedSchedule = [];
    for (let i = 0; i <= 20; i++) { // 初始化三个维度
      this.formattedSchedule[i] = [];
      for (let j = 0; j <= 6; j++)
        this.formattedSchedule[i][j] = [];
    }
    for (let i = 0; i <= 6; i++) // 星期几 -1
      if (this.parsedSchedule[i] != undefined) // 防止不存在元素
        for (let j of this.parsedSchedule[i]) // 星期几的每一节课
          for (let k of j) // 叠课判断
            for (let week of k.weekOfTerm)
              this.formattedSchedule[week][i].push(k);
  }
}

export default new UnifiedPreferences();
