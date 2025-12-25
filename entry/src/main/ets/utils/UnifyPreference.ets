
/**
 * 全局共享首选项读写功能
 */

import { preferences } from '@kit.ArkData';

// 全局变量
export const PREF_NAME = 'unified_preference';

// 每日签到
export const LAST_DAY_KEY = 'lastDay';
export const TOTAL_DAYS_KEY = 'totalDays';
export const CONSECUTIVE_DAYS_KEY = 'consecutiveDays';
export const CONTENT_KEY = 'content';

// 课表/考试
export const SCHEDULE_KEY = 'scheduleInfo';
export const START_TIME_KEY = 'termStartTime';
export const millisecondsPerWeek = 604800000;

// 自动填充
export const UID_KEY = 'studentUID';
export const PASSWORD_KEY = 'password';
export const REMIND_KEY = 'remindSetUID';

class UnifiedPreferences {

  private preferences: preferences.Preferences | null = null;

  /**
   * 初始化
   */
  init(context: Context) {
    if (!this.preferences) {
      const options: preferences.Options = { name: PREF_NAME };
      try {
        this.preferences = preferences.getPreferencesSync(context, options);
      } catch (error) {
        console.error(`getPreferencesSync ERROR: [${error.name}] ${error.message}`);
      }
    }
  }

  /**
   * 写入首选项
   * @param key 变量名
   * @param value 变量值（支持 string | number | boolean）
   */
  putSync(key: string, value: string | number | boolean) {
    try {
      this.preferences?.putSync(key, value);
    } catch (error) {
      console.error(`putSync ERROR: [${error.name}] ${error.message}`);
    }
    this.flush();
  }

  /**
   * 读取首选项（string）
   * @param key 变量名
   * @param defaultValue 读取失败时返回的默认值
   * @returns string类型的变量值
   */
  getSync(key: string, defaultValue: string = ''): string {
    try {
      return this.preferences?.getSync(key, defaultValue) as string;
    } catch (error) {
      console.error(`getSync ERROR: [${error.name}] ${error.message}`);
      return '';
    }
  }

  /**
   * 读取首选项（boolean）
   * @param key 变量名
   * @param defaultValue 读取失败时返回的默认值
   * @returns boolean类型的变量值
   */
  getBoolSync(key: string, defaultValue: boolean): boolean {
    try {
      return this.preferences?.getSync(key, defaultValue) as boolean;
    } catch (error) {
      console.error(`getSync ERROR: [${error.name}] ${error.message}`);
      return defaultValue;
    }
  }

  /**
   * 读取首选项（number）
   * @param key 变量名
   * @param defaultValue 读取失败时返回的默认值
   * @returns number类型的变量值
   */
  getNumberSync(key: string, defaultValue: number): number {
    try {
      return this.preferences?.getSync(key, defaultValue) as number;
    } catch (error) {
      console.error(`getSync ERROR: [${error.name}] ${error.message}`);
      return defaultValue;
    }
  }

  /**
   * 判断变量名是否已被写入
   * @param key 变量名
   * @returns 存在返回 true，否则返回 false
   */
  hasSync(key: string): boolean {
    try {
      return this.preferences?.hasSync(key) as boolean;
    } catch (error) {
      console.error(`hasSync ERROR: [${error.name}] ${error.message}`);
      return false;
    }
  }

  /**
   * 将首选项从缓冲区写入硬盘（持久化）
   */
  flush() {
    this.preferences?.flush()
      .catch((error: Error) => {
        console.error(`preferences flush ERROR: [${error.name}] ${error.message}`)
      })
  }

  /**
   * 清除所有首选项
   */
  clear() {
    this.preferences?.clearSync();
    this.flush();
  }

  /**
   * 删除首选项
   * @param key 变量名
   */
  deleteSync(key: string) {
    this.preferences?.deleteSync(key);
    this.flush();
  }
}

export default new UnifiedPreferences();
