
import { preferences } from '@kit.ArkData';

export const PREF_NAME = 'unified_preference';

export const LAST_DAY_KEY = 'lastDay';
export const TOTAL_DAYS_KEY = 'totalDays';
export const CONSECUTIVE_DAYS_KEY = 'consecutiveDays';
export const CONTENT_KEY = 'content';

export const SCHEDULE_KEY = 'scheduleInfo';
export const START_TIME_KEY = 'termStartTime';

export const millisecondsPerWeek = 604800000;

export const UID_KEY = 'studentUID';
export const PASSWORD_KEY = 'password';
export const REMIND_KEY = 'remindSetUID';

class UnifiedPreferences {
  private preferences: preferences.Preferences | null = null;

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

  getBoolSync(key: string, defaultValue: boolean): boolean {
    try {
      return this.preferences?.getSync(key, defaultValue) as boolean;
    } catch (error) {
      console.error(`getSync ERROR: [${error.name}] ${error.message}`);
      return defaultValue;
    }
  }

  getNumberSync(key: string, defaultValue: number): number {
    try {
      return this.preferences?.getSync(key, defaultValue) as number;
    } catch (error) {
      console.error(`getSync ERROR: [${error.name}] ${error.message}`);
      return defaultValue;
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
    this.preferences?.clearSync();
    this.flush();
  }

  deleteSync(key: string) {
    this.preferences?.deleteSync(key);
    this.flush();
  }

  preferenceInstance(): preferences.Preferences | null {
    return this.preferences;
  }
}

export default new UnifiedPreferences();
